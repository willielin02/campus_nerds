-- ============================================================================
-- Migration: Remove goal_check_close_at from groups
-- ============================================================================
-- Goal check-off deadline is now implicitly "when the event moves from
-- Upcoming to History" (event_date < today in Taipei time), which is the
-- same cutoff used by run_move_events_to_history() and the Flutter frontend.
-- No separate column needed.
-- ============================================================================

-- 1. Drop the view first (can't remove columns with CREATE OR REPLACE)
DROP VIEW IF EXISTS public.my_events_v;

-- 2. Drop the column from groups table
ALTER TABLE public.groups DROP COLUMN IF EXISTS goal_check_close_at;

-- 3. Recreate my_events_v WITHOUT goal_check_close_at
CREATE VIEW public.my_events_v WITH (security_invoker = on) AS
SELECT DISTINCT ON (b.id)
  b.id            AS booking_id,
  b.user_id,
  b.event_id,
  b.status        AS booking_status,
  b.created_at    AS booking_created_at,
  b.cancelled_at,
  e.category      AS event_category,
  e.city_id,
  e.university_id,
  e.event_date,
  e.time_slot,
  e.location_detail,
  e.status        AS event_status,
  g.id            AS group_id,
  v.start_at      AS group_start_at,
  g.status        AS group_status,
  g.chat_open_at,
  g.venue_id,
  v.type          AS venue_type,
  v.name          AS venue_name,
  v.address       AS venue_address,
  v.google_map_url AS venue_google_map_url,
  e.signup_deadline_at,
  g.feedback_sent_at,
  g.goal_close_at,
  ((gm.id IS NOT NULL) AND (g.id IS NOT NULL) AND EXISTS (
    SELECT 1 FROM public.event_feedbacks ef
    WHERE ef.group_id = g.id AND ef.member_id = gm.id
  )) AS has_event_feedback,
  ((gm.id IS NOT NULL) AND (g.id IS NOT NULL) AND (
    (SELECT count(*) FROM public.peer_feedbacks pf
     JOIN public.group_members tgt
       ON tgt.group_id = pf.group_id
      AND tgt.id = pf.to_member_id
      AND tgt.left_at IS NULL
     WHERE pf.group_id = g.id
       AND pf.from_member_id = gm.id
       AND pf.to_member_id <> gm.id)
    >=
    (SELECT GREATEST(count(*) - 1, 0)
     FROM public.group_members m2
     WHERE m2.group_id = g.id AND m2.left_at IS NULL)
  )) AS has_peer_feedback_all,
  ((gm.id IS NOT NULL) AND (g.id IS NOT NULL)
   AND EXISTS (
     SELECT 1 FROM public.event_feedbacks ef
     WHERE ef.group_id = g.id AND ef.member_id = gm.id
   )
   AND (
     (SELECT count(*) FROM public.peer_feedbacks pf
      JOIN public.group_members tgt
        ON tgt.group_id = pf.group_id
       AND tgt.id = pf.to_member_id
       AND tgt.left_at IS NULL
      WHERE pf.group_id = g.id
        AND pf.from_member_id = gm.id
        AND pf.to_member_id <> gm.id)
     >=
     (SELECT GREATEST(count(*) - 1, 0)
      FROM public.group_members m2
      WHERE m2.group_id = g.id AND m2.left_at IS NULL)
   )) AS has_filled_feedback_all
FROM public.bookings b
JOIN public.events e ON e.id = b.event_id
LEFT JOIN public.group_members gm ON gm.booking_id = b.id
LEFT JOIN public.groups g ON g.id = gm.group_id
LEFT JOIN public.venues v ON v.id = g.venue_id
ORDER BY b.id, gm.joined_at DESC NULLS LAST;

-- 4. Restore view grants
GRANT SELECT ON public.my_events_v TO anon;
GRANT SELECT ON public.my_events_v TO authenticated;
GRANT SELECT ON public.my_events_v TO service_role;

-- 5. Update set_group_times() trigger to remove goal_check_close_at logic
CREATE OR REPLACE FUNCTION public.set_group_times()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = 'public', 'pg_catalog'
AS $$
DECLARE
  v_event_date     date;
  v_time_slot      public.events.time_slot%type;
  v_venue_start_at timestamptz;
BEGIN
  --------------------------------------------------------------------
  -- 依 venue.start_at 自動填 chat_open_at / goal_close_at（若尚未填）
  --------------------------------------------------------------------
  IF NEW.venue_id IS NOT NULL THEN
    SELECT v.start_at
    INTO v_venue_start_at
    FROM public.venues v
    WHERE v.id = NEW.venue_id;

    IF v_venue_start_at IS NOT NULL THEN
      IF NEW.chat_open_at IS NULL THEN
        NEW.chat_open_at := v_venue_start_at - interval '1 hour';
      END IF;

      IF NEW.goal_close_at IS NULL THEN
        NEW.goal_close_at := v_venue_start_at + interval '1 hour';
      END IF;
    END IF;
  END IF;

  --------------------------------------------------------------------
  -- 依 event_date + time_slot 自動填 feedback_sent_at
  -- (goal_check_close_at removed: deadline is event_date < today)
  --------------------------------------------------------------------
  IF NEW.feedback_sent_at IS NULL THEN
    SELECT e.event_date, e.time_slot
    INTO v_event_date, v_time_slot
    FROM public.events e
    WHERE e.id = NEW.event_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Event % for group % not found', NEW.event_id, NEW.id;
    END IF;

    IF v_event_date IS NULL THEN
      RAISE EXCEPTION 'Event % has no event_date; cannot compute group times', NEW.event_id;
    END IF;

    -- feedback_sent_at：活動日 12:00 / 17:00 / 22:00（Asia/Taipei）
    NEW.feedback_sent_at :=
      CASE v_time_slot
        WHEN 'morning'   THEN (v_event_date + time '12:00') AT TIME ZONE 'Asia/Taipei'
        WHEN 'afternoon' THEN (v_event_date + time '17:00') AT TIME ZONE 'Asia/Taipei'
        WHEN 'evening'   THEN (v_event_date + time '22:00') AT TIME ZONE 'Asia/Taipei'
        ELSE NULL
      END;
  END IF;

  RETURN NEW;
END;
$$;
