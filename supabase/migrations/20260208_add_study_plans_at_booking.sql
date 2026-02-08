
-- 1. Trigger: auto-create 3 focused study plan slots when a focused_study booking is created
CREATE OR REPLACE FUNCTION create_study_plans_on_booking()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 'active' AND EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = NEW.event_id
    AND e.category = 'focused_study'
  ) THEN
    INSERT INTO focused_study_plans (booking_id, slot)
    VALUES (NEW.id, 1), (NEW.id, 2), (NEW.id, 3)
    ON CONFLICT (booking_id, slot) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_study_plans_on_booking
AFTER INSERT ON bookings
FOR EACH ROW
EXECUTE FUNCTION create_study_plans_on_booking();

-- 2. RLS policy: allow users to view their own focused study plans (even before grouping)
CREATE POLICY fsp_select_own ON focused_study_plans
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM bookings b
    WHERE b.id = focused_study_plans.booking_id
    AND b.user_id = auth.uid()
  )
);

-- 3. RPC: get own focused study plans by booking_id (pre-grouping)
CREATE OR REPLACE FUNCTION get_my_focused_study_plans(p_booking_id uuid)
RETURNS TABLE(
  booking_id uuid,
  user_id uuid,
  display_name text,
  plan1_id uuid,
  plan1_content text,
  plan1_done boolean,
  plan2_id uuid,
  plan2_content text,
  plan2_done boolean,
  plan3_id uuid,
  plan3_content text,
  plan3_done boolean
)
LANGUAGE sql
SECURITY DEFINER
AS $$
SELECT
  b.id AS booking_id,
  b.user_id,
  COALESCE(up.nickname, '') AS display_name,
  MAX(CASE WHEN fsp.slot = 1 THEN fsp.id::text END)::uuid AS plan1_id,
  MAX(CASE WHEN fsp.slot = 1 THEN fsp.content END) AS plan1_content,
  COALESCE(BOOL_OR(fsp.slot = 1 AND fsp.is_done), false) AS plan1_done,
  MAX(CASE WHEN fsp.slot = 2 THEN fsp.id::text END)::uuid AS plan2_id,
  MAX(CASE WHEN fsp.slot = 2 THEN fsp.content END) AS plan2_content,
  COALESCE(BOOL_OR(fsp.slot = 2 AND fsp.is_done), false) AS plan2_done,
  MAX(CASE WHEN fsp.slot = 3 THEN fsp.id::text END)::uuid AS plan3_id,
  MAX(CASE WHEN fsp.slot = 3 THEN fsp.content END) AS plan3_content,
  COALESCE(BOOL_OR(fsp.slot = 3 AND fsp.is_done), false) AS plan3_done
FROM bookings b
JOIN focused_study_plans fsp ON fsp.booking_id = b.id
LEFT JOIN user_profile_v up ON up.id = b.user_id
WHERE b.id = p_booking_id
  AND b.user_id = auth.uid()
GROUP BY b.id, b.user_id, up.nickname;
$$;

-- 4. Backfill: create study plans for existing focused_study bookings that don't have them
INSERT INTO focused_study_plans (booking_id, slot)
SELECT b.id, s.slot
FROM bookings b
CROSS JOIN (VALUES (1), (2), (3)) AS s(slot)
JOIN events e ON e.id = b.event_id
WHERE e.category = 'focused_study'
  AND b.status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM focused_study_plans fsp
    WHERE fsp.booking_id = b.id AND fsp.slot = s.slot
  )
ON CONFLICT (booking_id, slot) DO NOTHING;
