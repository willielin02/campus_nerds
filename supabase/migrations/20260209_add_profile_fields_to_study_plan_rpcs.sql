-- Add gender, university_name, age fields to focused study plan RPCs
-- so the Flutter app can display profile popups on StudyPlanCard headers.

-- 1. Drop and recreate get_group_focused_study_plans with new return columns
DROP FUNCTION IF EXISTS get_group_focused_study_plans(uuid);

CREATE OR REPLACE FUNCTION get_group_focused_study_plans(p_group_id uuid)
RETURNS TABLE(
  group_id uuid,
  booking_id uuid,
  user_id uuid,
  display_name text,
  is_me boolean,
  sort_key integer,
  joined_at timestamptz,
  gender text,
  university_name text,
  age integer,
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
SET search_path = 'public'
SET row_security = off
AS $$
  select
    gm.group_id,
    gm.booking_id,
    b.user_id,
    coalesce(up.nickname, '') as display_name,
    (b.user_id = auth.uid()) as is_me,
    case when b.user_id = auth.uid() then 0 else 1 end as sort_key,
    gm.joined_at,
    up.gender::text as gender,
    up.university_name as university_name,
    up.age as age,

    (max(case when fsp.slot = 1 then fsp.id::text end))::uuid as plan1_id,
    max(case when fsp.slot = 1 then fsp.content end)          as plan1_content,
    bool_or(fsp.slot = 1 and fsp.is_done)                     as plan1_done,

    (max(case when fsp.slot = 2 then fsp.id::text end))::uuid as plan2_id,
    max(case when fsp.slot = 2 then fsp.content end)          as plan2_content,
    bool_or(fsp.slot = 2 and fsp.is_done)                     as plan2_done,

    (max(case when fsp.slot = 3 then fsp.id::text end))::uuid as plan3_id,
    max(case when fsp.slot = 3 then fsp.content end)          as plan3_content,
    bool_or(fsp.slot = 3 and fsp.is_done)                     as plan3_done

  from public.group_members gm
  join public.bookings b on b.id = gm.booking_id
  left join public.user_profile_v up on up.id = b.user_id
  join public.focused_study_plans fsp on fsp.booking_id = gm.booking_id

  where gm.group_id = p_group_id
    and gm.left_at is null
    and exists (
      select 1 from public.group_members gm_me
      join public.bookings b_me on b_me.id = gm_me.booking_id
      where gm_me.group_id = p_group_id
        and gm_me.left_at is null
        and b_me.user_id = auth.uid()
    )

  group by gm.group_id, gm.booking_id, b.user_id, up.nickname, gm.joined_at,
           up.gender, up.university_name, up.age
  order by sort_key, gm.joined_at;
$$;

-- 2. Drop and recreate get_my_focused_study_plans with new return columns
DROP FUNCTION IF EXISTS get_my_focused_study_plans(uuid);

CREATE OR REPLACE FUNCTION get_my_focused_study_plans(p_booking_id uuid)
RETURNS TABLE(
  booking_id uuid,
  user_id uuid,
  display_name text,
  gender text,
  university_name text,
  age integer,
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
  up.gender::text AS gender,
  up.university_name AS university_name,
  up.age AS age,
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
GROUP BY b.id, b.user_id, up.nickname, up.gender, up.university_name, up.age;
$$;
