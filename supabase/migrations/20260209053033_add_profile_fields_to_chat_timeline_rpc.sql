-- Add sender profile fields (gender, university_name, age) to chat_fetch_timeline_page RPC
-- so the Flutter app can display profile popups on chat message sender names.

DROP FUNCTION IF EXISTS chat_fetch_timeline_page(uuid, timestamptz, integer, text, integer);

CREATE OR REPLACE FUNCTION chat_fetch_timeline_page(
  p_group_id uuid,
  p_before_sort_ts timestamptz DEFAULT NULL,
  p_before_sort_rank integer DEFAULT NULL,
  p_before_item_id text DEFAULT NULL,
  p_limit integer DEFAULT 50
)
RETURNS TABLE(
  item_id text,
  group_id uuid,
  item_type text,
  sort_ts timestamptz,
  sort_rank integer,
  message_id uuid,
  message_type message_type,
  content text,
  sender_user_id uuid,
  sender_nickname text,
  divider_date date,
  metadata jsonb,
  divider_label text,
  sender_gender text,
  sender_university_name text,
  sender_age integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
SET row_security = off
AS $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not exists (
    select 1
    from public.group_members gm
    join public.bookings b on b.id = gm.booking_id
    join public.events   e on e.id = b.event_id
    join public.groups   g on g.id = gm.group_id
    where gm.group_id = p_group_id
      and b.user_id = v_user_id
      and gm.left_at is null
      and e.status = any (array['notified'::public.event_status, 'completed'::public.event_status])
      and g.chat_open_at is not null
      and now() >= g.chat_open_at
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select
    t.item_id,
    t.group_id,
    t.item_type,
    t.sort_ts,
    t.sort_rank,
    t.message_id,
    t.message_type,
    t.content,
    t.sender_user_id,
    t.sender_nickname,
    t.divider_date,
    t.metadata,
    t.divider_label,
    up.gender::text as sender_gender,
    up.university_name as sender_university_name,
    up.age as sender_age
  from public.group_chat_timeline t
  left join public.user_profile_v up on up.id = t.sender_user_id
  where t.group_id = p_group_id
    and (
      p_before_sort_ts is null
      or (t.sort_ts, t.sort_rank, t.item_id) < (p_before_sort_ts, p_before_sort_rank, p_before_item_id)
    )
  order by t.sort_ts desc, t.sort_rank desc, t.item_id desc
  limit greatest(1, least(p_limit, 200));
end $function$;
