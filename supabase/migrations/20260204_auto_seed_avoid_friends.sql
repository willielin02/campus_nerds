-- ============================================================================
-- Migration: Update auto_seed_groups_for_event to avoid Facebook friends
-- ============================================================================
-- This migration modifies the auto-seeding algorithm to actively avoid placing
-- Facebook friends in the same group.
--
-- Algorithm change:
-- - OLD: Bulk assignment by ROW_NUMBER() / group_size
-- - NEW: Iterative assignment checking friendships table for each candidate
--
-- The algorithm will:
-- 1. Create empty group slots
-- 2. For each candidate (in priority order), find a group without their friends
-- 3. If all groups contain friends, assign to the group with fewest conflicts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_seed_groups_for_event(
  p_event_id   uuid,
  p_group_size integer DEFAULT NULL  -- If NULL, uses events.default_group_size
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_date      date;
  v_time_slot       public.event_time_slot;

  v_group_size      integer;
  v_half_size       integer;  -- Number of males/females per group
  v_male_count      integer;
  v_female_count    integer;
  v_total_count     integer;
  v_group_count     integer;

  v_candidate       record;
  v_group_rec       record;
  v_friend_ids      uuid[];
  v_best_group_id   uuid;
  v_min_conflicts   integer;
  v_conflict_count  integer;
  v_current_males   integer;
  v_current_females integer;
BEGIN
  -- Get event info and default group size
  SELECT e.event_date, e.time_slot, e.default_group_size
  INTO v_event_date, v_time_slot, v_group_size
  FROM public.events e
  WHERE e.id = p_event_id
    AND e.status = 'scheduled'::public.event_status;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event_not_found_or_not_scheduled';
  END IF;

  -- Override with parameter if provided
  IF p_group_size IS NOT NULL THEN
    v_group_size := p_group_size;
  END IF;

  -- Validate group_size: must be positive even number
  IF v_group_size IS NULL OR v_group_size <= 0 OR (v_group_size % 2) <> 0 THEN
    RAISE EXCEPTION 'invalid_group_size: must be a positive even number, got %', v_group_size;
  END IF;

  v_half_size := v_group_size / 2;

  -- Advisory lock to prevent concurrent grouping
  PERFORM pg_advisory_xact_lock(
    ('x' || substr(md5(p_event_id::text), 1, 16))::bit(64)::bigint
  );

  -------------------------------------------------------------------
  -- 1) Get all candidates for this event
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_group_candidates ON COMMIT DROP AS
  SELECT
    b.id                 AS booking_id,
    b.user_id,
    up.gender,
    up.age,
    up.academic_rank,
    up.os,
    COALESCE(ubs.not_grouped_count, 0)      AS not_grouped_count,
    COALESCE(ups.avg_performance_score, 0)  AS avg_performance_score,
    b.created_at          AS booking_created_at
  FROM public.bookings b
  JOIN public.user_profile_v up
    ON up.id = b.user_id
  LEFT JOIN public.user_booking_stats_v ubs
    ON ubs.user_id = b.user_id
  LEFT JOIN public.user_peer_scores_v ups
    ON ups.user_id = b.user_id
  WHERE
    b.event_id = p_event_id
    AND b.status = 'active'::public.booking_status
    AND NOT EXISTS (
      SELECT 1
      FROM public.group_members gm
      WHERE gm.booking_id = b.id
    );

  -------------------------------------------------------------------
  -- 2) Count males/females and determine how many groups we can form
  -------------------------------------------------------------------
  SELECT
    COUNT(*) FILTER (WHERE gender = 'male')   AS male_count,
    COUNT(*) FILTER (WHERE gender = 'female') AS female_count,
    COUNT(*)                                  AS total_count
  INTO v_male_count, v_female_count, v_total_count
  FROM tmp_group_candidates;

  IF v_total_count < v_group_size THEN
    RETURN;
  END IF;

  v_group_count := LEAST(
    v_male_count   / v_half_size,
    v_female_count / v_half_size,
    v_total_count  / v_group_size
  );

  IF v_group_count <= 0 THEN
    RETURN;
  END IF;

  -------------------------------------------------------------------
  -- 3) Create sorted candidate lists (males and females separately)
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_male_sorted ON COMMIT DROP AS
  SELECT
    booking_id,
    user_id,
    ROW_NUMBER() OVER (
      ORDER BY
        not_grouped_count      DESC,
        age                    NULLS LAST,
        academic_rank          NULLS LAST,
        os,
        avg_performance_score  DESC NULLS LAST,
        booking_created_at
    ) AS priority
  FROM tmp_group_candidates
  WHERE gender = 'male';

  CREATE TEMP TABLE tmp_female_sorted ON COMMIT DROP AS
  SELECT
    booking_id,
    user_id,
    ROW_NUMBER() OVER (
      ORDER BY
        not_grouped_count      DESC,
        age                    NULLS LAST,
        academic_rank          NULLS LAST,
        os,
        avg_performance_score  DESC NULLS LAST,
        booking_created_at
    ) AS priority
  FROM tmp_group_candidates
  WHERE gender = 'female';

  -------------------------------------------------------------------
  -- 4) Create empty groups
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_new_groups ON COMMIT DROP AS
  SELECT
    gs                    AS group_index,
    gen_random_uuid()     AS group_id
  FROM generate_series(1, v_group_count) AS gs;

  -- Insert groups with draft status
  INSERT INTO public.groups (id, event_id, venue_id, max_size, status)
  SELECT
    g.group_id,
    p_event_id,
    NULL::uuid,
    v_group_size,
    'draft'::public.group_status
  FROM tmp_new_groups g;

  -- Create a table to track assignments (group_id -> booking_id, user_id)
  CREATE TEMP TABLE tmp_assignments (
    group_id   uuid,
    booking_id uuid,
    user_id    uuid,
    gender     public.gender
  ) ON COMMIT DROP;

  -------------------------------------------------------------------
  -- 5) Assign males to groups, avoiding Facebook friends
  -------------------------------------------------------------------
  FOR v_candidate IN
    SELECT booking_id, user_id
    FROM tmp_male_sorted
    WHERE priority <= v_group_count * v_half_size
    ORDER BY priority
  LOOP
    -- Get this user's Facebook friends
    v_friend_ids := public.get_user_facebook_friends(v_candidate.user_id);

    -- Find the best group for this candidate
    v_best_group_id := NULL;
    v_min_conflicts := 999999;

    FOR v_group_rec IN
      SELECT g.group_id
      FROM tmp_new_groups g
    LOOP
      -- Count how many males are already in this group
      SELECT COUNT(*)
      INTO v_current_males
      FROM tmp_assignments a
      WHERE a.group_id = v_group_rec.group_id
        AND a.gender = 'male';

      -- Skip if group already has enough males
      IF v_current_males >= v_half_size THEN
        CONTINUE;
      END IF;

      -- Count conflicts (friends already in this group)
      SELECT COUNT(*)
      INTO v_conflict_count
      FROM tmp_assignments a
      WHERE a.group_id = v_group_rec.group_id
        AND a.user_id = ANY(COALESCE(v_friend_ids, ARRAY[]::uuid[]));

      -- Prefer groups with no conflicts
      IF v_conflict_count = 0 THEN
        v_best_group_id := v_group_rec.group_id;
        EXIT; -- Found a perfect group, use it
      ELSIF v_conflict_count < v_min_conflicts THEN
        v_min_conflicts := v_conflict_count;
        v_best_group_id := v_group_rec.group_id;
      END IF;
    END LOOP;

    -- Assign to the best group found
    IF v_best_group_id IS NOT NULL THEN
      INSERT INTO tmp_assignments (group_id, booking_id, user_id, gender)
      VALUES (v_best_group_id, v_candidate.booking_id, v_candidate.user_id, 'male');
    END IF;
  END LOOP;

  -------------------------------------------------------------------
  -- 6) Assign females to groups, avoiding Facebook friends
  -------------------------------------------------------------------
  FOR v_candidate IN
    SELECT booking_id, user_id
    FROM tmp_female_sorted
    WHERE priority <= v_group_count * v_half_size
    ORDER BY priority
  LOOP
    -- Get this user's Facebook friends
    v_friend_ids := public.get_user_facebook_friends(v_candidate.user_id);

    -- Find the best group for this candidate
    v_best_group_id := NULL;
    v_min_conflicts := 999999;

    FOR v_group_rec IN
      SELECT g.group_id
      FROM tmp_new_groups g
    LOOP
      -- Count how many females are already in this group
      SELECT COUNT(*)
      INTO v_current_females
      FROM tmp_assignments a
      WHERE a.group_id = v_group_rec.group_id
        AND a.gender = 'female';

      -- Skip if group already has enough females
      IF v_current_females >= v_half_size THEN
        CONTINUE;
      END IF;

      -- Count conflicts (friends already in this group)
      SELECT COUNT(*)
      INTO v_conflict_count
      FROM tmp_assignments a
      WHERE a.group_id = v_group_rec.group_id
        AND a.user_id = ANY(COALESCE(v_friend_ids, ARRAY[]::uuid[]));

      -- Prefer groups with no conflicts
      IF v_conflict_count = 0 THEN
        v_best_group_id := v_group_rec.group_id;
        EXIT; -- Found a perfect group, use it
      ELSIF v_conflict_count < v_min_conflicts THEN
        v_min_conflicts := v_conflict_count;
        v_best_group_id := v_group_rec.group_id;
      END IF;
    END LOOP;

    -- Assign to the best group found
    IF v_best_group_id IS NOT NULL THEN
      INSERT INTO tmp_assignments (group_id, booking_id, user_id, gender)
      VALUES (v_best_group_id, v_candidate.booking_id, v_candidate.user_id, 'female');
    END IF;
  END LOOP;

  -------------------------------------------------------------------
  -- 7) Write assignments to group_members
  -------------------------------------------------------------------
  INSERT INTO public.group_members (group_id, booking_id, event_id)
  SELECT
    a.group_id,
    a.booking_id,
    p_event_id
  FROM tmp_assignments a;

  -------------------------------------------------------------------
  -- 8) Delete any empty groups (groups that couldn't be filled)
  -------------------------------------------------------------------
  DELETE FROM public.groups g
  WHERE g.event_id = p_event_id
    AND g.status = 'draft'
    AND g.id IN (SELECT group_id FROM tmp_new_groups)
    AND NOT EXISTS (
      SELECT 1 FROM public.group_members gm WHERE gm.group_id = g.id
    );

END;
$$;

COMMENT ON FUNCTION public.auto_seed_groups_for_event(uuid, integer) IS
'Auto-seeds groups for an event with flexible group sizes.

IMPORTANT: This function actively AVOIDS placing Facebook friends in the same group.
It uses the friendships table to check for friend relationships.

Parameters:
  - p_event_id: The event to create groups for
  - p_group_size: Override group size (if NULL, uses events.default_group_size)

Algorithm:
1. Get all candidates and sort by priority (not_grouped_count, age, etc.)
2. Create empty groups
3. For each candidate, find a group that:
   - Has room for their gender
   - Preferably has NO Facebook friends already assigned
   - If all groups have friends, pick the one with fewest conflicts
4. Write assignments to group_members

Each group will have equal male/female distribution (N/2 males + N/2 females).
Groups are created with status=draft and max_size set to the group size.';