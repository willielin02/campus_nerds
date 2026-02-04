-- ============================================================================
-- Migration: Flexible group sizes with events.default_group_size
-- ============================================================================
-- Changes:
-- 1. Add events.default_group_size column (used during auto-seeding)
-- 2. Update auto_seed_groups_for_event to support any even group size
-- 3. Update run_auto_seed_for_events_two_days_out (reads from events table)
--
-- NOTE: groups.max_size is KEPT - auto-seeding writes to it, and validation
--       still checks member_count = max_size when scheduling.
-- ============================================================================

-- ============================================================================
-- Step 1: Add events.default_group_size column
-- ============================================================================
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS default_group_size integer NOT NULL DEFAULT 4;

-- Add constraint: must be positive even number
ALTER TABLE public.events
ADD CONSTRAINT events_default_group_size_check
CHECK (default_group_size > 0 AND default_group_size % 2 = 0);

COMMENT ON COLUMN public.events.default_group_size IS
'Default group size for auto-seeding. Must be a positive even number.
This value is written to groups.max_size during auto-seeding.';

-- ============================================================================
-- Step 2: Update auto_seed_groups_for_event
-- - Read default_group_size from events table
-- - Support any even group size (not just 4)
-- - Still writes to groups.max_size
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
  v_half_size       integer;  -- 每組需要的男生/女生人數
  v_male_count      integer;
  v_female_count    integer;
  v_total_count     integer;
  v_group_count     integer;
BEGIN
  -- 從 events 表取得活動資訊和預設組別人數
  SELECT e.event_date, e.time_slot, e.default_group_size
  INTO v_event_date, v_time_slot, v_group_size
  FROM public.events e
  WHERE e.id = p_event_id
    AND e.status = 'scheduled'::public.event_status;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event_not_found_or_not_scheduled';
  END IF;

  -- 如果有傳入 p_group_size，使用傳入的值覆蓋
  IF p_group_size IS NOT NULL THEN
    v_group_size := p_group_size;
  END IF;

  -- 驗證 group_size：必須是正偶數
  IF v_group_size IS NULL OR v_group_size <= 0 OR (v_group_size % 2) <> 0 THEN
    RAISE EXCEPTION 'invalid_group_size: must be a positive even number, got %', v_group_size;
  END IF;

  -- 計算每組需要的男生/女生人數
  v_half_size := v_group_size / 2;

  -- 以活動 id 做 advisory lock，避免併發重複分組
  PERFORM pg_advisory_xact_lock(
    ('x' || substr(md5(p_event_id::text), 1, 16))::bit(64)::bigint
  );

  -------------------------------------------------------------------
  -- 1) 取出本活動、尚未被分組、且 booking_status = active 的所有候選
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
  -- 2) 計算男女數量、總人數，決定最多可以組出幾個小組
  --    每組需要 v_half_size 男 + v_half_size 女
  -------------------------------------------------------------------
  SELECT
    COUNT(*) FILTER (WHERE gender = 'male')   AS male_count,
    COUNT(*) FILTER (WHERE gender = 'female') AS female_count,
    COUNT(*)                                  AS total_count
  INTO v_male_count, v_female_count, v_total_count
  FROM tmp_group_candidates;

  IF v_total_count < v_group_size THEN
    -- 人數不足 1 組，直接結束
    RETURN;
  END IF;

  -- 每組需要 v_half_size 男 + v_half_size 女
  -- 計算最多可以組出幾組
  v_group_count := LEAST(
    v_male_count   / v_half_size,
    v_female_count / v_half_size,
    v_total_count  / v_group_size
  );

  IF v_group_count <= 0 THEN
    RETURN;
  END IF;

  -------------------------------------------------------------------
  -- 3) 依優先條件排序
  --    排序權重（由前到後）：
  --    1. 未成團次數多 → 優先
  --    2. 年齡相近
  --    3. 學歷相近
  --    4. OS 相近
  --    5. 綜合得分高 → 優先
  --    6. booking 較早報名者優先
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_male ON COMMIT DROP AS
  SELECT
    *,
    ROW_NUMBER() OVER (
      ORDER BY
        not_grouped_count      DESC,
        age                    NULLS LAST,
        academic_rank          NULLS LAST,
        os,
        avg_performance_score  DESC NULLS LAST,
        booking_created_at
    ) AS rn
  FROM tmp_group_candidates
  WHERE gender = 'male';

  CREATE TEMP TABLE tmp_female ON COMMIT DROP AS
  SELECT
    *,
    ROW_NUMBER() OVER (
      ORDER BY
        not_grouped_count      DESC,
        age                    NULLS LAST,
        academic_rank          NULLS LAST,
        os,
        avg_performance_score  DESC NULLS LAST,
        booking_created_at
    ) AS rn
  FROM tmp_group_candidates
  WHERE gender = 'female';

  -- 將男生分配到各組：每 v_half_size 人一組
  CREATE TEMP TABLE tmp_male_assignments ON COMMIT DROP AS
  SELECT
    booking_id,
    CEIL(rn / v_half_size::float)::integer AS group_index
  FROM tmp_male
  WHERE rn <= v_group_count * v_half_size;

  -- 將女生分配到各組：每 v_half_size 人一組
  CREATE TEMP TABLE tmp_female_assignments ON COMMIT DROP AS
  SELECT
    booking_id,
    CEIL(rn / v_half_size::float)::integer AS group_index
  FROM tmp_female
  WHERE rn <= v_group_count * v_half_size;

  -------------------------------------------------------------------
  -- 4) 產生要建立的小組清單，然後寫入 groups / group_members
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_new_groups ON COMMIT DROP AS
  SELECT
    gs                    AS group_index,
    gen_random_uuid()     AS group_id
  FROM generate_series(1, v_group_count) AS gs;

  -- 寫入 groups：全部先建立成 draft，max_size = v_group_size
  INSERT INTO public.groups (id, event_id, venue_id, max_size, status)
  SELECT
    g.group_id,
    p_event_id,
    NULL::uuid,
    v_group_size,
    'draft'::public.group_status
  FROM tmp_new_groups g;

  -- 寫入 group_members：每組 v_half_size 男 + v_half_size 女
  INSERT INTO public.group_members (group_id, booking_id, event_id)
  SELECT
    g.group_id,
    m.booking_id,
    p_event_id
  FROM tmp_new_groups g
  JOIN (
    SELECT group_index, booking_id FROM tmp_male_assignments
    UNION ALL
    SELECT group_index, booking_id FROM tmp_female_assignments
  ) AS m
    ON m.group_index = g.group_index;

END;
$$;

COMMENT ON FUNCTION public.auto_seed_groups_for_event(uuid, integer) IS
'Auto-seeds groups for an event with flexible group sizes.
Parameters:
  - p_event_id: The event to create groups for
  - p_group_size: Override group size (if NULL, uses events.default_group_size)

Each group will have equal male/female distribution (N/2 males + N/2 females).
Groups are created with status=draft and max_size set to the group size.';

-- ============================================================================
-- Step 3: Update run_auto_seed_for_events_two_days_out
-- - No longer needs to pass group_size (function reads from events table)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.run_auto_seed_for_events_two_days_out()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_target_date date;
  rec record;
BEGIN
  -- 以台北時間為基準：「今天 + 2 天」就是要分組的 event_date
  v_target_date := (now() AT TIME ZONE 'Asia/Taipei')::date + 2;

  -- 針對該日期、狀態為 scheduled 的活動逐一執行 auto_seed
  -- 每個活動會使用自己的 default_group_size
  FOR rec IN
    SELECT id
    FROM public.events
    WHERE event_date = v_target_date
      AND status = 'scheduled'::public.event_status
  LOOP
    PERFORM public.auto_seed_groups_for_event(rec.id);
  END LOOP;
END;
$$;

-- ============================================================================
-- NOTE: handle_group_status_scheduled is NOT modified.
-- It still validates:
--   - member_count = max_size (group must be full)
--   - gender ratio 1:1
--   - venue_id required
--   - time fields required
-- ============================================================================

-- ============================================================================
-- Summary of changes:
-- ============================================================================
-- 1. events.default_group_size: New column for auto-seeding group size
-- 2. auto_seed_groups_for_event: Now supports any even group size
-- 3. groups.max_size: KEPT - still written during auto-seeding
-- 4. handle_group_status_scheduled: UNCHANGED - still validates max_size
-- ============================================================================