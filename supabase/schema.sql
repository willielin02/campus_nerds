


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."booking_status" AS ENUM (
    'active',
    'cancelled',
    'unmatched',
    'event_cancelled'
);


ALTER TYPE "public"."booking_status" OWNER TO "postgres";


CREATE TYPE "public"."client_os" AS ENUM (
    'ios',
    'android',
    'web',
    'unknown'
);


ALTER TYPE "public"."client_os" OWNER TO "postgres";


CREATE TYPE "public"."event_category" AS ENUM (
    'focused_study',
    'english_games'
);


ALTER TYPE "public"."event_category" OWNER TO "postgres";


CREATE TYPE "public"."event_location_detail" AS ENUM (
    'ntu_main_library_reading_area',
    'nycu_haoran_library_reading_area',
    'nycu_yangming_campus_library_reading_area',
    'nthu_main_library_reading_area',
    'ncku_main_library_reading_area',
    'nccu_daxian_library_reading_area',
    'ncu_main_library_reading_area',
    'nsysu_library_reading_area',
    'nchu_main_library_reading_area',
    'ccu_library_reading_area',
    'ntnu_main_library_reading_area',
    'ntpu_library_reading_area',
    'ntust_library_reading_area',
    'ntut_library_reading_area',
    'library_or_cafe',
    'boardgame_or_escape_room'
);


ALTER TYPE "public"."event_location_detail" OWNER TO "postgres";


CREATE TYPE "public"."event_status" AS ENUM (
    'draft',
    'scheduled',
    'notified',
    'cancelled',
    'completed'
);


ALTER TYPE "public"."event_status" OWNER TO "postgres";


CREATE TYPE "public"."event_time_slot" AS ENUM (
    'morning',
    'afternoon',
    'evening'
);


ALTER TYPE "public"."event_time_slot" OWNER TO "postgres";


CREATE TYPE "public"."gender" AS ENUM (
    'male',
    'female'
);


ALTER TYPE "public"."gender" OWNER TO "postgres";


CREATE TYPE "public"."group_status" AS ENUM (
    'draft',
    'scheduled',
    'cancelled'
);


ALTER TYPE "public"."group_status" OWNER TO "postgres";


CREATE TYPE "public"."message_type" AS ENUM (
    'user',
    'system'
);


ALTER TYPE "public"."message_type" OWNER TO "postgres";


CREATE TYPE "public"."order_status" AS ENUM (
    'pending',
    'paid',
    'cancelled',
    'refunded'
);


ALTER TYPE "public"."order_status" OWNER TO "postgres";


CREATE TYPE "public"."school_email_status" AS ENUM (
    'pending',
    'verified',
    'rejected'
);


ALTER TYPE "public"."school_email_status" OWNER TO "postgres";


CREATE TYPE "public"."sync_status" AS ENUM (
    'success',
    'failed'
);


ALTER TYPE "public"."sync_status" OWNER TO "postgres";


CREATE TYPE "public"."ticket_ledger_reason" AS ENUM (
    'purchase_credit',
    'booking_debit',
    'booking_refund',
    'admin_adjust'
);


ALTER TYPE "public"."ticket_ledger_reason" OWNER TO "postgres";


CREATE TYPE "public"."ticket_type" AS ENUM (
    'study',
    'games'
);


ALTER TYPE "public"."ticket_type" OWNER TO "postgres";


CREATE TYPE "public"."venue_type" AS ENUM (
    'university_library',
    'public_library',
    'cafe',
    'boardgame',
    'escape'
);


ALTER TYPE "public"."venue_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") RETURNS TABLE("order_id" "uuid", "order_status" "public"."order_status", "credited" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid;
  v_ticket_type public.ticket_type;
  v_pack_size int;
  v_already_paid boolean := false;
begin
  -- 鎖定該筆 order，避免並發重送造成競態
  select o.user_id, o.ticket_type_snapshot, o.pack_size_snapshot,
         (o.status = 'paid'::public.order_status)
  into v_user_id, v_ticket_type, v_pack_size, v_already_paid
  from public.orders o
  where o.id = p_order_id
  for update;

  if not found then
    raise exception 'order not found: %', p_order_id;
  end if;

  -- 先 upsert ecpay_payments（避免重送重寫）
  insert into public.ecpay_payments (
    order_id, trade_no, rtn_code, rtn_msg, paid_at, trade_amt, check_mac_value, raw
  )
  values (
    p_order_id, p_trade_no, p_rtn_code, p_rtn_msg,
    case when p_rtn_code = 1 then now() else null end,
    p_trade_amt, p_check_mac_value, coalesce(p_raw, '{}'::jsonb)
  )
  on conflict (order_id) do update set
    trade_no = excluded.trade_no,
    rtn_code = excluded.rtn_code,
    rtn_msg = excluded.rtn_msg,
    paid_at = excluded.paid_at,
    trade_amt = excluded.trade_amt,
    check_mac_value = excluded.check_mac_value,
    raw = excluded.raw,
    updated_at = now();

  -- 若已 paid，直接回傳（不重複加票）
  if v_already_paid then
    order_id := p_order_id;
    order_status := 'paid'::public.order_status;
    credited := false;
    return next;
    return;
  end if;

  -- 只有成功付款才進入 paid（綠界常見 rtn_code=1 表示成功）
  if p_rtn_code = 1 then
    update public.orders
    set status = 'paid'::public.order_status,
        paid_at = now(),
        updated_at = now()
    where id = p_order_id;

    -- 寫入 ticket_ledger：purchase_credit
    -- 這裡若被重送，partial unique index 會擋掉
    begin
      insert into public.ticket_ledger (
        user_id, order_id, delta_study, delta_games, reason
      )
      values (
        v_user_id,
        p_order_id,
        case when v_ticket_type = 'study'::public.ticket_type then v_pack_size else 0 end,
        case when v_ticket_type = 'games'::public.ticket_type then v_pack_size else 0 end,
        'purchase_credit'::public.ticket_ledger_reason
      );

      credited := true;
    exception when unique_violation then
      -- 已經加過票 => 視為冪等成功
      credited := false;
    end;

    order_id := p_order_id;
    order_status := 'paid'::public.order_status;
    return next;
    return;
  else
    -- 付款失敗：不改 paid（你也可以在此改成 cancelled / pending 視你的流程）
    order_id := p_order_id;
    order_status := (select status from public.orders where id = p_order_id);
    credited := false;
    return next;
    return;
  end if;
end $$;


ALTER FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."assign_english_contents_for_group"("p_group_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_event_id uuid;
  v_category public.event_category;
  v_n int;
  v_assigned int;
begin
  select g.event_id into v_event_id
  from public.groups g
  where g.id = p_group_id;

  if v_event_id is null then
    raise exception 'group not found: %', p_group_id;
  end if;

  select e.category into v_category
  from public.events e
  where e.id = v_event_id;

  if v_category <> 'english_games'::event_category then
    raise exception 'group % is not english_games event', p_group_id;
  end if;

  -- members
  create temp table tmp_members on commit drop as
  select
    gm.id as member_id,
    b.user_id,
    row_number() over (order by gm.id) as rn
  from public.group_members gm
  join public.bookings b on b.id = gm.booking_id
  where gm.group_id = p_group_id;

  select count(*) into v_n from tmp_members;

  if v_n <= 0 then
    return 0;
  end if;

  -- 已經分配過就不重複做（你也可以改成允許重跑：先 delete 再重建）
  if exists (select 1 from public.group_english_assignments where group_id = p_group_id) then
    return 0;
  end if;

  -- candidates：排除「該組任一成員」已曝光過的內容
  create temp table tmp_candidates on commit drop as
  select
    c.id as content_id,
    c.content_en,
    c.content_zh,
    row_number() over (order by random()) as rn
  from public.english_contents c
  where c.is_active = true
    and not exists (
      select 1
      from public.english_content_exposures ex
      join tmp_members m on m.user_id = ex.user_id
      where ex.content_id = c.id
    );

  if (select count(*) from tmp_candidates) < v_n then
    raise exception 'not enough fresh english contents: need %, have %',
      v_n, (select count(*) from tmp_candidates);
  end if;

  -- 指派：member rn 對 candidate rn
  insert into public.group_english_assignments (
    group_id, member_id, content_id,
    content_en_snapshot, content_zh_snapshot, used_count
  )
  select
    p_group_id,
    m.member_id,
    c.content_id,
    c.content_en,
    c.content_zh,
    0
  from tmp_members m
  join tmp_candidates c on c.rn = m.rn;

  get diagnostics v_assigned = row_count;

  -- exposures：整組所有人都視為看過這批內容（包含別人的題）
  insert into public.english_content_exposures (user_id, content_id, first_seen_group_id)
  select
    m.user_id,
    a.content_id,
    p_group_id
  from tmp_members m
  cross join (select distinct content_id from public.group_english_assignments where group_id = p_group_id) a
  on conflict do nothing;

  return v_assigned;
end;
$$;


ALTER FUNCTION "public"."assign_english_contents_for_group"("p_group_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auto_seed_groups_for_event"("p_event_id" "uuid", "p_group_size" integer DEFAULT 4) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_event_date      date;
  v_time_slot       public.event_time_slot;

  v_group_size      integer := p_group_size;
  v_male_count      integer;
  v_female_count    integer;
  v_total_count     integer;
  v_group_count     integer;
BEGIN
  -- 目前只支援 4 人一組（且必須是偶數）
  IF v_group_size IS NULL OR v_group_size <= 0 OR (v_group_size % 2) <> 0 THEN
    RAISE EXCEPTION 'invalid_group_size';
  END IF;

  IF v_group_size <> 4 THEN
    RAISE EXCEPTION 'only_group_size_4_supported_for_now';
  END IF;

  -- 確認活動存在且為 scheduled（只是 sanity check）
  SELECT e.event_date, e.time_slot
  INTO v_event_date, v_time_slot
  FROM public.events e
  WHERE e.id = p_event_id
    AND e.status = 'scheduled'::public.event_status;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event_not_found_or_not_scheduled';
  END IF;

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
  -- 2) 計算男女數量、總人數，決定最多可以組出幾個「4 人、男女各 2」的小組
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

  -- 每組 2 男 2 女 → 男 / 女 都要能切出 pair，且總人數要夠塞滿 group_size
  v_group_count := LEAST(
    v_male_count   / 2,
    v_female_count / 2,
    v_total_count  / v_group_size
  );

  IF v_group_count <= 0 THEN
    RETURN;
  END IF;

  -------------------------------------------------------------------
  -- 3) 依優先條件排序，切出「男生配對」、「女生配對」
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

  -- 只取出足以組 v_group_count 組 4 人團的前 2 * v_group_count 位男女，
  -- 兩人一個 pair，pair_index = 1,2,3,...
  CREATE TEMP TABLE tmp_male_pairs ON COMMIT DROP AS
  SELECT
    booking_id,
    CEIL(rn / 2.0)::integer AS pair_index
  FROM tmp_male
  WHERE rn <= v_group_count * 2;

  CREATE TEMP TABLE tmp_female_pairs ON COMMIT DROP AS
  SELECT
    booking_id,
    CEIL(rn / 2.0)::integer AS pair_index
  FROM tmp_female
  WHERE rn <= v_group_count * 2;

  -------------------------------------------------------------------
  -- 4) 產生要建立的小組清單，然後寫入 groups / group_members
  -------------------------------------------------------------------
  CREATE TEMP TABLE tmp_new_groups ON COMMIT DROP AS
  SELECT
    gs                    AS group_index,
    gen_random_uuid()     AS group_id
  FROM generate_series(1, v_group_count) AS gs;

  -- 寫入 groups：全部先建立成 draft、max_size = 4
  INSERT INTO public.groups (id, event_id, venue_id, max_size, status)
  SELECT
    g.group_id,
    p_event_id,
    NULL::uuid,
    v_group_size,
    'draft'::public.group_status
  FROM tmp_new_groups g;

  -- 寫入 group_members：每組 2 男 + 2 女，event_id 跟著 p_event_id
  INSERT INTO public.group_members (group_id, booking_id, event_id)
  SELECT
    g.group_id,
    m.booking_id,
    p_event_id
  FROM tmp_new_groups g
  JOIN (
    SELECT pair_index, booking_id FROM tmp_male_pairs
    UNION ALL
    SELECT pair_index, booking_id FROM tmp_female_pairs
  ) AS m
    ON m.pair_index = g.group_index;

END;
$$;


ALTER FUNCTION "public"."auto_seed_groups_for_event"("p_event_id" "uuid", "p_group_size" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cancel_booking_and_refund_ticket"("p_booking_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id      uuid := auth.uid();
  v_booking      public.bookings%rowtype;
  v_event        public.events%rowtype;
  v_refund_study int := 0;
  v_refund_games int := 0;
begin
  -- 必須已登入
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 鎖定這筆 booking，避免併發重複取消
  select *
    into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found';
  end if;

  -- 只能取消自己的 booking
  if v_booking.user_id <> v_user_id then
    raise exception 'forbidden';
  end if;

  -- 只能取消 active 的 booking
  if v_booking.status <> 'active'::booking_status then
    raise exception 'booking_not_active';
  end if;

  -- 讀取對應活動
  select *
    into v_event
  from public.events e
  where e.id = v_booking.event_id;

  if not found then
    raise exception 'event_not_found';
  end if;

  -- 活動已取消或已完成就不能再取消報名
  if v_event.status in ('cancelled'::event_status, 'completed'::event_status) then
    raise exception 'event_not_cancellable';
  end if;

  -- 可取消時間 = 可報名時間：signup_open_at <= now() < signup_deadline_at
  -- （signup_open_at / signup_deadline_at 本身你已經用「活動日 -23 天 00:00」、
  --  「活動開始日 -3 天 23:59」算好存進去）
  if now() < v_event.signup_open_at
     or now() >= v_event.signup_deadline_at then
    raise exception 'cancel_deadline_passed';
  end if;

  -- 決定要退哪種票
  if v_event.category = 'focused_study'::event_category then
    v_refund_study := 1;
  elsif v_event.category = 'english_games'::event_category then
    v_refund_games := 1;
  else
    raise exception 'unknown_event_category';
  end if;

  -- 1) 更新 booking 狀態為 cancelled
  update public.bookings
  set status       = 'cancelled'::booking_status,
      cancelled_at = now(),
      updated_at   = now()
  where id = p_booking_id;

  -- 2) 寫入退票 ledger
  --    注意：你已經有 partial unique index，會保證同一 booking 只會有一筆 booking_refund
  insert into public.ticket_ledger (
    user_id,
    booking_id,
    delta_study,
    delta_games,
    reason,
    created_at,
    updated_at
  ) values (
    v_user_id,
    p_booking_id,
    v_refund_study,
    v_refund_games,
    'booking_refund'::ticket_ledger_reason,
    now(),
    now()
  );

  return p_booking_id;
end;
$$;


ALTER FUNCTION "public"."cancel_booking_and_refund_ticket"("p_booking_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."group_chat_timeline" (
    "item_id" "text" NOT NULL,
    "group_id" "uuid" NOT NULL,
    "item_type" "text" NOT NULL,
    "sort_ts" timestamp with time zone NOT NULL,
    "sort_rank" integer NOT NULL,
    "message_id" "uuid",
    "message_type" "public"."message_type",
    "content" "text",
    "sender_user_id" "uuid",
    "sender_nickname" "text",
    "divider_date" "date",
    "metadata" "jsonb",
    "divider_label" "text"
);

ALTER TABLE ONLY "public"."group_chat_timeline" REPLICA IDENTITY FULL;


ALTER TABLE "public"."group_chat_timeline" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."chat_fetch_timeline_page"("p_group_id" "uuid", "p_before_sort_ts" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_before_sort_rank" integer DEFAULT NULL::integer, "p_before_item_id" "text" DEFAULT NULL::"text", "p_limit" integer DEFAULT 50) RETURNS SETOF "public"."group_chat_timeline"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 權限/開放檢查：跟 chat_mark_joined 一致
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
  select *
  from public.group_chat_timeline t
  where t.group_id = p_group_id
    and (
      p_before_sort_ts is null
      or (t.sort_ts, t.sort_rank, t.item_id) < (p_before_sort_ts, p_before_sort_rank, p_before_item_id)
    )
  order by t.sort_ts desc, t.sort_rank desc, t.item_id desc
  limit greatest(1, least(p_limit, 200));
end $$;


ALTER FUNCTION "public"."chat_fetch_timeline_page"("p_group_id" "uuid", "p_before_sort_ts" timestamp with time zone, "p_before_sort_rank" integer, "p_before_item_id" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_chat_open_at timestamptz;
  v_event_status public.event_status;
  v_nick text;
  v_inserted boolean := false;
  v_updated_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 找到「這個 user 在這個 group」的 member row
  select
    gm.id,
    g.chat_open_at,
    e.status
  into
    v_member_id,
    v_chat_open_at,
    v_event_status
  from public.group_members gm
  join public.bookings b on b.id = gm.booking_id
  join public.events e on e.id = b.event_id
  join public.groups g on g.id = gm.group_id
  where gm.group_id = p_group_id
    and b.user_id = v_user_id
    and gm.left_at is null
  limit 1;

  if v_member_id is null then
    raise exception 'not_a_member';
  end if;

  if v_event_status <> all(array['notified'::public.event_status, 'completed'::public.event_status]) then
    raise exception 'event_not_ready_for_chat';
  end if;

  if v_chat_open_at is null or now() < v_chat_open_at then
    raise exception 'chat_not_open';
  end if;

  -- ✅ 核心：原子去重
  update public.group_members
  set chat_joined_at = now()
  where id = v_member_id
    and chat_joined_at is null
  returning id into v_updated_id;

  -- 只有第一次成功 update 的那次才插入 system message
  if v_updated_id is not null then
    select coalesce(up.nickname, '某位成員')
    into v_nick
    from public.user_profile_v up
    where up.id = v_user_id;

    insert into public.group_messages (group_id, user_id, type, content, metadata)
    values (
      p_group_id,
      v_user_id,
      'system'::public.message_type,
      v_nick || ' 已加入聊天室',
      jsonb_build_object(
        'event', 'member_joined',
        'user_id', v_user_id,
        'nickname', v_nick
      )
    );

    v_inserted := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'inserted_join_message', v_inserted
  );
end;
$$;


ALTER FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") RETURNS TABLE("message_id" "uuid", "group_id" "uuid", "type" "public"."message_type", "content" "text", "sender_user_id" "uuid", "sender_nickname" "text", "created_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    SET "row_security" TO 'off'
    AS $$
declare
  v_is_member boolean;
  v_msg_id uuid;
begin
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = auth.uid()
  ) into v_is_member;

  if not v_is_member then
    raise exception 'Not a member of this group';
  end if;

  insert into public.group_messages (
    group_id, type, content, user_id, metadata, created_at
  )
  values (
    p_group_id,
    'user'::public.message_type,
    p_content,
    auth.uid(),
    '{}'::jsonb,
    now()
  )
  returning id into v_msg_id;

  return query
  select
    v.message_id,
    v.group_id,
    v.type,
    v.content,
    v.sender_user_id,
    v.sender_nickname,
    v.created_at,
    v.metadata
  from public.group_chat_messages_v v
  where v.message_id = v_msg_id;
end;
$$;


ALTER FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_booking_and_consume_ticket"("p_event_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id        uuid := auth.uid();
  v_booking_id     uuid;
  v_category       public.event_category;
  v_study_balance  int;
  v_games_balance  int;
  v_university_id  uuid;
  v_event_date     date;
  v_time_slot      public.event_time_slot;
begin
  -- 1) 必須登入
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 2) Happy Path 檢查（學校信箱、基本資料等）
  perform public.require_user_happy_path_ready(v_user_id);

  -- 3) 取得目前 university_id，沒有就擋
  select cu.university_id
    into v_university_id
  from public.user_current_university_v cu
  where cu.user_id = v_user_id;

  if v_university_id is null then
    raise exception 'university_id_required';
  end if;

  -- 4) 活動是否可報名：狀態、時間窗、學校限制
  --    ※ 只多抓 event_date / time_slot，不改原本條件
  select e.category,
         e.event_date,
         e.time_slot
    into v_category,
         v_event_date,
         v_time_slot
  from public.events e
  left join public.user_current_university_v cu
         on cu.user_id = v_user_id
  where e.id = p_event_id
    and e.status = 'scheduled'::public.event_status
    and e.signup_open_at <= now()
    and e.signup_deadline_at > now()
    and (
      e.university_id is null
      or e.university_id = cu.university_id
    );

  if not found then
    raise exception 'event_not_open_or_forbidden';
  end if;

  -- 5) 用 user-level advisory lock 避免並發 double booking
  perform pg_advisory_xact_lock(
    ('x' || substr(md5(v_user_id::text), 1, 16))::bit(64)::bigint
  );

  -- 6) 🔴 新增：檢查同一 user 是否已在同日同 slot 有 active booking（未取消）
  if exists (
    select 1
    from public.bookings b
    join public.events e2 on e2.id = b.event_id
    where b.user_id = v_user_id
      and b.status = 'active'::public.booking_status
      and b.cancelled_at is null
      and e2.event_date = v_event_date
      and e2.time_slot  = v_time_slot
  ) then
    raise exception 'conflict_same_date_slot';
  end if;

  -- 7) 讀取票券餘額
  select study_balance, games_balance
    into v_study_balance, v_games_balance
  from public.user_ticket_balances_v
  where user_id = v_user_id;

  if v_category = 'focused_study'
     and coalesce(v_study_balance, 0) < 1 then
    raise exception 'insufficient_study_tickets';
  end if;

  if v_category = 'english_games'
     and coalesce(v_games_balance, 0) < 1 then
    raise exception 'insufficient_games_tickets';
  end if;

  -- 8) 建立 booking（active）
  insert into public.bookings(user_id, event_id, status)
  values (v_user_id, p_event_id, 'active'::public.booking_status)
  returning id into v_booking_id;

  -- 9) 扣票（沿用原本 booking_debit 設計）
  insert into public.ticket_ledger(user_id, booking_id, delta_study, delta_games, reason)
  values (
    v_user_id,
    v_booking_id,
    case when v_category = 'focused_study'  then -1 else 0 end,
    case when v_category = 'english_games' then -1 else 0 end,
    'booking_debit'::public.ticket_ledger_reason
  );

  return v_booking_id;
end;
$$;


ALTER FUNCTION "public"."create_booking_and_consume_ticket"("p_event_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_focused_study_plans_for_group"("p_group_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_event_id uuid;
  v_category public.event_category;
  v_inserted int := 0;
begin
  -- 找 group 對應的 event
  select g.event_id into v_event_id
  from public.groups g
  where g.id = p_group_id;

  if not found then
    raise exception 'group_not_found: %', p_group_id;
  end if;

  -- 確認是 Focused Study
  select e.category into v_category
  from public.events e
  where e.id = v_event_id;

  if v_category <> 'focused_study'::public.event_category then
    raise exception 'not_focused_study_event: group=% event=% category=%', p_group_id, v_event_id, v_category;
  end if;

  -- 對該 group 內每個「仍在組內」的 booking，建立 slot 1~3 的 plans
  with members as (
    select gm.booking_id
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.left_at is null
  ),
  slots as (
    select 1::smallint as slot
    union all select 2::smallint
    union all select 3::smallint
  ),
  ins as (
    insert into public.focused_study_plans (booking_id, slot)
    select m.booking_id, s.slot
    from members m
    cross join slots s
    on conflict (booking_id, slot) do nothing
    returning 1
  )
  select count(*) into v_inserted from ins;

  return v_inserted;
end;
$$;


ALTER FUNCTION "public"."create_focused_study_plans_for_group"("p_group_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_group_scheduled_requires_venue"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.status = 'scheduled' and new.venue_id is null then
    raise exception 'groups.venue_id is required when status = scheduled';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_group_scheduled_requires_venue"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_group_venue_matches_event"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_cat public.event_category;
  e_cat public.event_category;
begin
  if new.venue_id is null then
    return new;
  end if;

  select category into e_cat from public.events where id = new.event_id;
  select category into v_cat from public.venues where id = new.venue_id;

  if e_cat is null or v_cat is null then
    raise exception 'missing category (event_id=% venue_id=%)', new.event_id, new.venue_id;
  end if;

  if v_cat <> e_cat then
    raise exception 'venue.category (%) does not match event.category (%)', v_cat, e_cat;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_group_venue_matches_event"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."extract_school_base_domain"("full_domain" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
declare
  d      text := lower(trim(full_domain));
  parts  text[];
  n      int;
begin
  if d is null or d = '' then
    return null;
  end if;

  parts := string_to_array(d, '.');
  n := array_length(parts, 1);

  if n is null then
    return null;
  end if;

  -- 台灣學校：xxx.edu.tw -> 取最後三段 (例如 gs.ncku.edu.tw -> ncku.edu.tw)
  if n >= 3 and d like '%.edu.tw' then
    return array_to_string(parts[n-2:n], '.');

  -- 其他：先簡單取最後兩段 (mit.edu / ox.ac.uk 等)
  elsif n >= 2 then
    return array_to_string(parts[n-1:n], '.');

  else
    return d;
  end if;
end;
$$;


ALTER FUNCTION "public"."extract_school_base_domain"("full_domain" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."gen_merchant_trade_no"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
declare
  prefix text := 'CN';                -- 你也可以改成 'CN'/'CBD' 等，但注意總長
  d text := to_char(now(), 'YYMMDD'); -- 6
  -- 產生 10 碼「類 base32」：只用 0-9 + A-Z 去掉 I/O/L/U (降低混淆)
  alphabet text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  out text := '';
  i int;
  b bytea := gen_random_bytes(8);     -- 64-bit 隨機
  v int;
begin
  for i in 0..9 loop
    v := get_byte(b, i % 8) % length(alphabet);
    out := out || substr(alphabet, v + 1, 1);
  end loop;

  return prefix || d || out; -- 18 chars
end $$;


ALTER FUNCTION "public"."gen_merchant_trade_no"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_group_focused_study_plans"("p_group_id" "uuid") RETURNS TABLE("group_id" "uuid", "booking_id" "uuid", "user_id" "uuid", "display_name" "text", "is_me" boolean, "sort_key" integer, "joined_at" timestamp with time zone, "gender" "text", "university_name" "text", "age" integer, "plan1_id" "uuid", "plan1_content" "text", "plan1_done" boolean, "plan2_id" "uuid", "plan2_content" "text", "plan2_done" boolean, "plan3_id" "uuid", "plan3_content" "text", "plan3_done" boolean)
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
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
  join public.groups grp on grp.id = gm.group_id
  join public.events ev on ev.id = grp.event_id
  left join public.user_profile_v up on up.id = b.user_id
  join public.focused_study_plans fsp on fsp.booking_id = gm.booking_id

  where gm.group_id = p_group_id
    and gm.left_at is null
    and ev.status in ('notified', 'completed')
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


ALTER FUNCTION "public"."get_group_focused_study_plans"("p_group_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_event_status_notified"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_bad_groups integer;
  v_now        timestamptz;
BEGIN
  -- 只處理「變成 notified」的情況
  IF NEW.status <> 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;

  -- 避免重複處理已是 notified 的列（例如只是改其他欄位）
  IF TG_OP = 'UPDATE'
     AND OLD.status = 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;

  -- 嚴格限制：只能從 scheduled → notified
  IF TG_OP = 'UPDATE'
     AND OLD.status <> 'scheduled'::public.event_status THEN
    RAISE EXCEPTION
      'events.status can only change to notified from scheduled (event=% old=% new=%)',
      NEW.id, OLD.status, NEW.status;
  END IF;

  --------------------------------------------------------------------
  -- 1. 檢查所有 groups 都是 scheduled（或根本沒有 group 也 OK）
  --------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_bad_groups
  FROM public.groups g
  WHERE g.event_id = NEW.id
    AND g.status <> 'scheduled'::public.group_status;

  IF v_bad_groups > 0 THEN
    RAISE EXCEPTION
      'event % has % group(s) whose status is not scheduled',
      NEW.id, v_bad_groups;
  END IF;

  v_now := now();

  --------------------------------------------------------------------
  -- 2. 為所有報名者建立「分組結果」的 App 內彈窗通知
  --    有 group 的：成團通知
  --    沒 group 的：未成團通知
  --------------------------------------------------------------------
  INSERT INTO public.in_app_notifications (
    user_id,
    booking_id,
    event_id,
    group_id,
    type,
    title,
    body,
    data
  )
  SELECT
    b.user_id,
    b.id          AS booking_id,
    b.event_id,
    gm.group_id,
    'event_group_result' AS type,

    -- 成團 / 未成團：App 內彈窗標題
    CASE
      WHEN gm.group_id IS NULL
        THEN '這次活動沒有成團'
      ELSE
        '您的活動已成功分組'
    END AS title,

    -- 成團 / 未成團：App 內彈窗內文
    CASE
      WHEN gm.group_id IS NULL
        THEN '很抱歉，本次活動未成團。立即報名下一場活動，您將獲得優先分組權利。'
      ELSE
        '已為您完成分組，快去查看您的分組吧！'
    END AS body,

    -- 給 App 用的 payload：讓前端知道是哪場 / 有沒有分組
    jsonb_build_object(
      'event_id',   b.event_id,
      'booking_id', b.id,
      'group_id',   gm.group_id,
      'is_grouped', gm.group_id IS NOT NULL
    ) AS data

  FROM public.bookings b

  -- 找出這個 booking 目前所在的 group（若有多筆就拿最後加入的那個）
  LEFT JOIN LATERAL (
    SELECT gm.group_id
    FROM public.group_members gm
    WHERE gm.booking_id = b.id
      AND gm.left_at IS NULL
    ORDER BY gm.joined_at DESC NULLS LAST
    LIMIT 1
  ) gm ON TRUE

  WHERE b.event_id = NEW.id
    AND b.status = 'active'::public.booking_status

  -- 避免重複通知同一個 event + booking + type
  ON CONFLICT (event_id, booking_id, type)
  DO NOTHING;

  --------------------------------------------------------------------
  -- 3. 寫入 notify_sent_at
  --------------------------------------------------------------------
  IF NEW.notify_sent_at IS NULL THEN
    NEW.notify_sent_at := v_now;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_event_status_notified"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_group_for_facebook_friends"("p_group_id" "uuid")
RETURNS TABLE("user_a_id" "uuid", "user_b_id" "uuid")
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    LEAST(b1.user_id, b2.user_id) as user_a_id,
    GREATEST(b1.user_id, b2.user_id) as user_b_id
  FROM public.group_members gm1
  JOIN public.bookings b1 ON b1.id = gm1.booking_id
  JOIN public.group_members gm2
    ON gm1.group_id = gm2.group_id AND b1.user_id < (SELECT user_id FROM public.bookings WHERE id = gm2.booking_id)
  JOIN public.bookings b2 ON b2.id = gm2.booking_id
  JOIN public.friendships f
    ON f.user_low_id = LEAST(b1.user_id, b2.user_id)
    AND f.user_high_id = GREATEST(b1.user_id, b2.user_id)
  WHERE gm1.group_id = p_group_id
    AND gm1.left_at IS NULL
    AND gm2.left_at IS NULL;
END;
$$;


ALTER FUNCTION "public"."check_group_for_facebook_friends"("p_group_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_group_status_scheduled"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_member_count  integer;
  v_category      public.event_category;
  v_fb_conflict   RECORD;
BEGIN
  -- 只在變成 scheduled 的那一刻處理
  IF NEW.status <> 'scheduled'::public.group_status THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.status = 'scheduled'::public.group_status THEN
    RETURN NEW;
  END IF;

  --------------------------------------------------------------------
  -- 1. 人數必須剛好等於 max_size（只算 still in group 的人）
  --------------------------------------------------------------------
  SELECT count(*)
  INTO v_member_count
  FROM public.group_members gm
  WHERE gm.group_id = NEW.id
    AND gm.left_at IS NULL;

  IF v_member_count <> NEW.max_size THEN
    RAISE EXCEPTION
      'group % is not full: members=%, max_size=%',
      NEW.id, v_member_count, NEW.max_size;
  END IF;

  --------------------------------------------------------------------
  -- 2. (已移除) 性別比與偶數 max_size 檢查
  --    改由後台 UI 以警告方式提示，管理員可執意放行
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  -- 3. 場地與時間欄位不得為 NULL
  --------------------------------------------------------------------
  IF NEW.venue_id IS NULL THEN
    RAISE EXCEPTION 'groups.venue_id is required when status = scheduled (group=%)', NEW.id;
  END IF;

  IF NEW.chat_open_at IS NULL
     OR NEW.goal_close_at IS NULL
     OR NEW.feedback_sent_at IS NULL THEN
    RAISE EXCEPTION
      'group % times must be set when status = scheduled (chat_open_at / goal_close_at / feedback_sent_at)',
      NEW.id;
  END IF;

  --------------------------------------------------------------------
  -- 4. 檢查群組中是否有臉書好友
  --------------------------------------------------------------------
  FOR v_fb_conflict IN
    SELECT * FROM public.check_group_for_facebook_friends(NEW.id)
  LOOP
    RAISE EXCEPTION
      'group % contains Facebook friends: user % and user % are friends',
      NEW.id, v_fb_conflict.user_a_id, v_fb_conflict.user_b_id;
  END LOOP;

  --------------------------------------------------------------------
  -- 5. 依活動類型建立學習內容 / 題目
  --------------------------------------------------------------------
  SELECT e.category
  INTO v_category
  FROM public.events e
  WHERE e.id = NEW.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event % for group % not found', NEW.event_id, NEW.id;
  END IF;

  IF v_category = 'focused_study'::public.event_category THEN
    PERFORM public.create_focused_study_plans_for_group(NEW.id);
  ELSIF v_category = 'english_games'::public.event_category THEN
    PERFORM public.assign_english_contents_for_group(NEW.id);
  ELSE
    RAISE EXCEPTION 'unsupported event_category % for group %', v_category, NEW.id;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_group_status_scheduled"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO public."users" (id, gender, created_at, updated_at)
  VALUES (NEW.id, NULL, now(), now())
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."require_user_happy_path_ready"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if p_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 1) 必須有 verified + is_active 的 school email
  if not exists (
    select 1
    from public.user_school_emails usem
    where usem.user_id   = p_user_id
      and usem.status    = 'verified'
      and usem.is_active = true
  ) then
    raise exception 'school_email_not_verified';
  end if;

  -- 2) 基本資料必填：nickname / gender / birthday / os
  if not exists (
    select 1
    from public.users u
    where u.id       = p_user_id
      and u.nickname is not null
      and u.gender   is not null
      and u.birthday is not null
      and u.os       is not null
  ) then
    raise exception 'profile_incomplete';
  end if;
end;
$$;


ALTER FUNCTION "public"."require_user_happy_path_ready"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_create_order"("p_product_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
DECLARE
  v_user_id uuid;
  v_ticket_type ticket_type;
  v_pack_size int;
  v_price_twd int;
  v_title text;
  v_merchant_trade_no varchar(20);
  v_order_id uuid;
  v_attempt int := 0;
BEGIN
  v_user_id := auth.uid()::uuid;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT p.ticket_type, p.pack_size, p.price_twd, p.title
    INTO v_ticket_type, v_pack_size, v_price_twd, v_title
  FROM public.products p
  WHERE p.id = p_product_id
    AND p.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'product not found or inactive';
  END IF;

  -- Generate a <=20 char unique merchant_trade_no; retry on rare collisions
  LOOP
    v_attempt := v_attempt + 1;
    IF v_attempt > 10 THEN
      RAISE EXCEPTION 'failed to generate unique merchant_trade_no';
    END IF;

    v_merchant_trade_no := (
      to_char(clock_timestamp(), 'YYMMDDHH24MISS') || substr(md5(random()::text), 1, 8)
    )::varchar(20);

    BEGIN
      INSERT INTO public.orders (
        user_id,
        product_id,
        merchant_trade_no,
        ticket_type_snapshot,
        pack_size_snapshot,
        title_snapshot,
        price_snapshot_twd,
        total_amount,
        status,
        paid_at
      )
      VALUES (
        v_user_id,
        p_product_id,
        v_merchant_trade_no,
        v_ticket_type,
        v_pack_size,
        v_title,
        v_price_twd,
        v_price_twd,
        'created'::order_status,
        NULL
      )
      RETURNING id INTO v_order_id;

      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        -- retry
        NULL;
    END;
  END LOOP;

  RETURN v_order_id;
END;
$$;


ALTER FUNCTION "public"."rpc_create_order"("p_product_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."run_auto_seed_for_events_two_days_out"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_target_date date;
  rec record;
BEGIN
  -- 以台北時間為基準：「今天 + 2 天」就是要分組的 event_date
  v_target_date := (now() AT TIME ZONE 'Asia/Taipei')::date + 2;

  -- 針對該日期、狀態為 scheduled 的活動逐一執行 auto_seed
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


ALTER FUNCTION "public"."run_auto_seed_for_events_two_days_out"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."run_move_events_to_history"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  taipei_today date;
begin
  -- 以台北時區判斷「今天」
  taipei_today := (timezone('Asia/Taipei', now()))::date;

  update public.events e
  set status = 'completed',
      updated_at = now()
  where e.status = 'notified'
    and e.event_date < taipei_today; -- 活動日隔天00:00起，taipei_today 會大於 event_date
end;
$$;


ALTER FUNCTION "public"."run_move_events_to_history"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_event_signup_times"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.event_date is null then
    return new;
  end if;

  -- signup_open_at：只在 NULL 時填
  if new.signup_open_at is null then
    new.signup_open_at :=
      ((new.event_date - interval '23 days') at time zone 'Asia/Taipei');
  end if;

  -- signup_deadline_at：只在 NULL 時填
  if new.signup_deadline_at is null then
    new.signup_deadline_at :=
      (((new.event_date - interval '3 days') + time '23:59')
        at time zone 'Asia/Taipei');
  end if;

  -- notify_deadline_at：只在 NULL 時填
  if new.notify_deadline_at is null then
    new.notify_deadline_at :=
      (((new.event_date - interval '2 days') + time '23:59')
        at time zone 'Asia/Taipei');
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."set_event_signup_times"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_group_times"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_event_date       date;
  v_time_slot        public.events.time_slot%type;
  v_venue_start_time time;
  v_actual_start     timestamptz;
BEGIN
  -- Always fetch event info (needed for multiple calculations)
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

  --------------------------------------------------------------------
  -- 依 venue.start_at (time) + event_date 自動填 chat_open_at / goal_close_at
  --------------------------------------------------------------------
  IF NEW.venue_id IS NOT NULL THEN
    SELECT v.start_at
    INTO v_venue_start_time
    FROM public.venues v
    WHERE v.id = NEW.venue_id;

    IF v_venue_start_time IS NOT NULL THEN
      v_actual_start := (v_event_date + v_venue_start_time) AT TIME ZONE 'Asia/Taipei';

      IF NEW.chat_open_at IS NULL THEN
        NEW.chat_open_at := v_actual_start - interval '1 hour';
      END IF;

      IF NEW.goal_close_at IS NULL THEN
        NEW.goal_close_at := v_actual_start + interval '1 hour';
      END IF;
    END IF;
  END IF;

  --------------------------------------------------------------------
  -- feedback_sent_at：活動日 12:00 / 17:00 / 22:00（Asia/Taipei）
  --------------------------------------------------------------------
  IF NEW.feedback_sent_at IS NULL THEN
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


ALTER FUNCTION "public"."set_group_times"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_users_university_after_verified"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    IF (NEW.status = 'verified'::school_email_status AND OLD.status IS DISTINCT FROM 'verified'::school_email_status) THEN
      UPDATE public.users SET university_id = NEW.university_id, updated_at = now() WHERE id = NEW.user_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_users_university_after_verified"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_group_messages_to_timeline"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_local_date date;
  v_divider_item_id text;
  v_sender_nickname text;
begin
  v_local_date := (new.created_at at time zone 'Asia/Taipei')::date;
  v_divider_item_id := 'd|' || new.group_id::text || '|' || v_local_date::text;

  -- 產生 sender_nickname（只針對 user message）
  if new.type = 'user'::public.message_type then
    select coalesce(up.nickname, '')
      into v_sender_nickname
    from public.user_profile_v up
    where up.id = new.user_id;
  else
    v_sender_nickname := '';
  end if;

  -- divider：on conflict 防止併發重複
  insert into public.group_chat_timeline (
    item_id, group_id, item_type, sort_ts, sort_rank,
    divider_date, divider_label,
    message_id, message_type, content, sender_user_id, sender_nickname, metadata
  )
  values (
    v_divider_item_id, new.group_id, 'divider',
    new.created_at - interval '1 microsecond', 1,
    v_local_date, null,
    null, null, null, null, null, null
  )
  on conflict (item_id) do nothing;

  -- message item
  insert into public.group_chat_timeline (
    item_id, group_id, item_type, sort_ts, sort_rank,
    message_id, message_type, content, sender_user_id, sender_nickname, metadata,
    divider_date, divider_label
  )
  values (
    'm|' || new.id::text, new.group_id, 'message',
    new.created_at, 0,
    new.id, new.type, new.content, new.user_id, v_sender_nickname, new.metadata,
    null, null
  )
  on conflict (item_id) do nothing;

  return new;
end $$;


ALTER FUNCTION "public"."trg_group_messages_to_timeline"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_orders_require_happy_path_ready"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- NEW.user_id 一定要是當事本人；若不是本人，你現有 RLS/邏輯應該也會擋
  perform public.require_user_happy_path_ready(new.user_id);
  return new;
end;
$$;


ALTER FUNCTION "public"."trg_orders_require_happy_path_ready"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_focused_study_plan"("p_plan_id" "uuid", "p_content" "text", "p_done" boolean) RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  update public.focused_study_plans fsp
  set content    = p_content,
      is_done    = p_done,
      updated_at = now()
  where fsp.id = p_plan_id
    and exists (
      select 1
      from public.bookings b
      where b.id = fsp.booking_id
        and b.user_id = auth.uid()  -- 確保只能改到自己的 booking/目標
    );
$$;


ALTER FUNCTION "public"."update_focused_study_plan"("p_plan_id" "uuid", "p_content" "text", "p_done" boolean) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "status" "public"."booking_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cancelled_at" timestamp with time zone,
    "unmatched_at" timestamp with time zone,
    CONSTRAINT "chk_bookings_status_fields" CHECK (((("status" = 'active'::"public"."booking_status") AND ("cancelled_at" IS NULL) AND ("unmatched_at" IS NULL)) OR (("status" = 'cancelled'::"public"."booking_status") AND ("cancelled_at" IS NOT NULL)) OR (("status" = 'unmatched'::"public"."booking_status") AND ("unmatched_at" IS NOT NULL))))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_cities_slug_format" CHECK ((("slug" = "lower"("slug")) AND ("slug" ~ '^[a-z0-9-]+$'::"text")))
);


ALTER TABLE "public"."cities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ecpay_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "trade_no" character varying(20),
    "rtn_code" integer,
    "rtn_msg" "text",
    "paid_at" timestamp with time zone,
    "trade_amt" integer,
    "check_mac_value" "text",
    "raw" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ecpay_payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."english_content_exposures" (
    "user_id" "uuid" NOT NULL,
    "content_id" "uuid" NOT NULL,
    "first_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "first_seen_group_id" "uuid"
);


ALTER TABLE "public"."english_content_exposures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."english_contents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_en" "text" NOT NULL,
    "content_zh" "text" NOT NULL,
    "note" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."english_contents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."event_feedbacks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "venue_rating" integer NOT NULL,
    "flow_rating" integer NOT NULL,
    "vibe_rating" integer NOT NULL,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "event_feedbacks_flow_rating_check" CHECK ((("flow_rating" >= 1) AND ("flow_rating" <= 5))),
    CONSTRAINT "event_feedbacks_venue_rating_check" CHECK ((("venue_rating" >= 1) AND ("venue_rating" <= 5))),
    CONSTRAINT "event_feedbacks_vibe_rating_check" CHECK ((("vibe_rating" >= 1) AND ("vibe_rating" <= 5)))
);


ALTER TABLE "public"."event_feedbacks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "university_id" "uuid",
    "city_id" "uuid" NOT NULL,
    "category" "public"."event_category" NOT NULL,
    "event_date" "date" NOT NULL,
    "time_slot" "public"."event_time_slot" NOT NULL,
    "status" "public"."event_status" DEFAULT 'draft'::"public"."event_status" NOT NULL,
    "signup_deadline_at" timestamp with time zone NOT NULL,
    "notify_sent_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "signup_open_at" timestamp with time zone NOT NULL,
    "location_detail" "public"."event_location_detail" DEFAULT 'library_or_cafe'::"public"."event_location_detail" NOT NULL,
    "notify_deadline_at" timestamp with time zone,
    CONSTRAINT "events_signup_time_window_chk" CHECK (("signup_open_at" < "signup_deadline_at"))
);


ALTER TABLE "public"."events" OWNER TO "postgres";


COMMENT ON COLUMN "public"."events"."location_detail" IS '更精確地點（ENUM）。例如：圖書館/ 咖啡廳、或各校圖書館閱覽區';



CREATE TABLE IF NOT EXISTS "public"."fb_friend_sync_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "status" "public"."sync_status" NOT NULL,
    "error_code" "text",
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."fb_friend_sync_attempts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."focused_study_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "slot" smallint NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "is_done" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "focused_study_plans_slot_check" CHECK ((("slot" >= 1) AND ("slot" <= 3)))
);


ALTER TABLE "public"."focused_study_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."friendships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_low_id" "uuid" NOT NULL,
    "user_high_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_friendships_canonical_order" CHECK (("user_low_id" < "user_high_id")),
    CONSTRAINT "chk_friendships_not_self" CHECK (("user_low_id" <> "user_high_id"))
);


ALTER TABLE "public"."friendships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "content" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "type" "public"."message_type" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    CONSTRAINT "chk_group_messages_type_fields" CHECK (((("type" = 'user'::"public"."message_type") AND ("user_id" IS NOT NULL) AND ("content" IS NOT NULL)) OR (("type" = 'system'::"public"."message_type") AND ("content" IS NOT NULL))))
);


ALTER TABLE "public"."group_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."universities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "city_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "short_name" "text",
    "slug" "text" NOT NULL,
    "code" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "academic_rank" integer,
    CONSTRAINT "chk_universities_code_format" CHECK ((("code" = "upper"("code")) AND ("code" ~ '^[A-Z0-9_]+$'::"text"))),
    CONSTRAINT "chk_universities_slug_format" CHECK ((("slug" = "lower"("slug")) AND ("slug" ~ '^[a-z0-9-]+$'::"text"))),
    CONSTRAINT "universities_academic_rank_range_chk" CHECK ((("academic_rank" IS NULL) OR (("academic_rank" >= 1) AND ("academic_rank" <= 149))))
);


ALTER TABLE "public"."universities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."university_email_domains" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "university_id" "uuid" NOT NULL,
    "domain" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_university_email_domains_domain_lower_no_at" CHECK ((("domain" = "lower"("domain")) AND (POSITION(('@'::"text") IN ("domain")) = 0)))
);


ALTER TABLE "public"."university_email_domains" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_school_emails" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "school_email" "text" NOT NULL,
    "status" "public"."school_email_status" DEFAULT 'pending'::"public"."school_email_status" NOT NULL,
    "verified_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "released_at" timestamp with time zone,
    "released_reason" "text",
    "released_by" "uuid",
    CONSTRAINT "user_school_emails_school_email_check" CHECK ((("school_email" = "lower"("school_email")) AND (POSITION(('@'::"text") IN ("school_email")) > 0)))
);


ALTER TABLE "public"."user_school_emails" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "gender" "public"."gender",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fb_user_id" "text",
    "fb_connected_at" timestamp with time zone,
    "fb_last_sync_at" timestamp with time zone,
    "fb_last_sync_status" "public"."sync_status",
    "birthday" "date",
    "nickname" "text",
    "os" "public"."client_os",
    CONSTRAINT "chk_users_fb_last_sync_status_time" CHECK ((("fb_last_sync_status" IS NULL) OR ("fb_last_sync_at" IS NOT NULL))),
    CONSTRAINT "chk_users_fb_user_connected_consistency" CHECK (((("fb_user_id" IS NULL) AND ("fb_connected_at" IS NULL)) OR (("fb_user_id" IS NOT NULL) AND ("fb_connected_at" IS NOT NULL)))),
    CONSTRAINT "users_nickname_length_chk" CHECK ((("nickname" IS NULL) OR ("length"("nickname") <= 12)))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_current_university_v" WITH ("security_invoker"='on') AS
 SELECT "u"."id" AS "user_id",
    "usem"."school_email",
    "uni"."id" AS "university_id",
    "uni"."name" AS "university_name",
    "uni"."code" AS "university_code",
    "usem"."status",
    "usem"."verified_at",
    "usem"."created_at",
    "uni"."academic_rank"
   FROM ((("public"."users" "u"
     LEFT JOIN LATERAL ( SELECT "usem_1"."id",
            "usem_1"."user_id",
            "usem_1"."school_email",
            "usem_1"."status",
            "usem_1"."verified_at",
            "usem_1"."created_at",
            "usem_1"."updated_at",
            "usem_1"."is_active"
           FROM "public"."user_school_emails" "usem_1"
          WHERE (("usem_1"."user_id" = "u"."id") AND ("usem_1"."status" = 'verified'::"public"."school_email_status") AND ("usem_1"."is_active" = true))
          ORDER BY COALESCE("usem_1"."verified_at", "usem_1"."created_at") DESC
         LIMIT 1) "usem" ON (true))
     LEFT JOIN "public"."university_email_domains" "ued" ON (("ued"."domain" = "public"."extract_school_base_domain"("split_part"("usem"."school_email", '@'::"text", 2)))))
     LEFT JOIN "public"."universities" "uni" ON (("uni"."id" = "ued"."university_id")));


ALTER VIEW "public"."user_current_university_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_profile_v" WITH ("security_invoker"='on') AS
 SELECT "u"."id",
    "u"."gender",
    "u"."birthday",
    ("date_part"('year'::"text", "age"((CURRENT_DATE)::timestamp with time zone, ("u"."birthday")::timestamp with time zone)))::integer AS "age",
    "u"."created_at",
    "u"."updated_at",
    "cu"."school_email",
    "cu"."status" AS "school_email_status",
    "cu"."verified_at" AS "school_email_verified_at",
    "cu"."university_id",
    "cu"."university_name",
    "cu"."university_code",
    "u"."nickname",
    "u"."os",
    "cu"."academic_rank"
   FROM ("public"."users" "u"
     LEFT JOIN "public"."user_current_university_v" "cu" ON (("cu"."user_id" = "u"."id")));


ALTER VIEW "public"."user_profile_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."group_chat_messages_v" WITH ("security_invoker"='on') AS
 SELECT "gm"."id" AS "message_id",
    "gm"."group_id",
    "gm"."type",
    "gm"."content",
    "gm"."user_id" AS "sender_user_id",
        CASE
            WHEN ("gm"."type" = 'user'::"public"."message_type") THEN COALESCE("up"."nickname", ''::"text")
            ELSE ''::"text"
        END AS "sender_nickname",
    "gm"."created_at",
    "gm"."metadata"
   FROM ("public"."group_messages" "gm"
     LEFT JOIN "public"."user_profile_v" "up" ON (("up"."id" = "gm"."user_id")));


ALTER VIEW "public"."group_chat_messages_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_english_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "content_id" "uuid" NOT NULL,
    "content_en_snapshot" "text" NOT NULL,
    "content_zh_snapshot" "text" NOT NULL,
    "used_count" integer DEFAULT 0 NOT NULL,
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "group_english_assignments_used_count_check" CHECK (("used_count" >= 0))
);


ALTER TABLE "public"."group_english_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "booking_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "left_at" timestamp with time zone,
    "chat_joined_at" timestamp with time zone
);


ALTER TABLE "public"."group_members" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."group_english_assignments_v" WITH ("security_invoker"='on') AS
 SELECT "a"."group_id",
    "b"."user_id",
    "a"."content_en_snapshot" AS "content_en",
    "a"."content_zh_snapshot" AS "content_zh",
    "a"."used_count",
    "a"."assigned_at"
   FROM (("public"."group_english_assignments" "a"
     JOIN "public"."group_members" "gm" ON (("gm"."id" = "a"."member_id")))
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")));


ALTER VIEW "public"."group_english_assignments_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."group_focused_study_plans_v" WITH ("security_invoker"='on') AS
 SELECT "gm"."group_id",
    "b"."user_id",
    "p"."slot",
    "p"."content",
    "p"."is_done",
    "p"."updated_at"
   FROM (("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
     JOIN "public"."focused_study_plans" "p" ON (("p"."booking_id" = "b"."id")));


ALTER VIEW "public"."group_focused_study_plans_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."group_members_profile_v" WITH ("security_invoker"='on') AS
 SELECT "gm"."group_id",
    "gm"."id" AS "member_id",
    "gm"."booking_id",
    "b"."user_id",
    "up"."nickname",
    "up"."gender",
    "up"."os" AS "client_os",
    "up"."academic_rank"
   FROM (("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
     JOIN "public"."user_profile_v" "up" ON (("up"."id" = "b"."user_id")));


ALTER VIEW "public"."group_members_profile_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "venue_id" "uuid",
    "max_size" integer NOT NULL,
    "status" "public"."group_status" DEFAULT 'draft'::"public"."group_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "chat_open_at" timestamp with time zone,
    "feedback_sent_at" timestamp with time zone,
    "goal_close_at" timestamp with time zone,
    "goal_check_close_at" timestamp with time zone,
    CONSTRAINT "groups_max_size_check" CHECK (("max_size" > 0))
);


ALTER TABLE "public"."groups" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."home_events_v" WITH ("security_invoker"='on') AS
 SELECT "id",
    "university_id",
    "city_id",
    "category",
    "event_date",
    "time_slot",
    "status",
    "signup_deadline_at",
    "notify_sent_at",
    "created_at",
    "updated_at",
    "signup_open_at",
    "location_detail",
    "notify_deadline_at",
    (EXISTS ( SELECT 1
           FROM ("public"."bookings" "b"
             JOIN "public"."events" "e2" ON (("e2"."id" = "b"."event_id")))
          WHERE (("b"."user_id" = "auth"."uid"()) AND ("b"."status" = 'active'::"public"."booking_status") AND ("b"."cancelled_at" IS NULL) AND ("e2"."event_date" = "e"."event_date") AND ("e2"."time_slot" = "e"."time_slot")))) AS "has_conflict_same_slot"
   FROM "public"."events" "e"
  WHERE (("signup_open_at" <= "now"()) AND ("signup_deadline_at" > "now"()) AND ("status" = 'scheduled'::"public"."event_status") AND (NOT (EXISTS ( SELECT 1
           FROM "public"."bookings" "b"
          WHERE (("b"."event_id" = "e"."id") AND ("b"."user_id" = "auth"."uid"()) AND ("b"."status" = 'active'::"public"."booking_status") AND ("b"."cancelled_at" IS NULL))))));


ALTER VIEW "public"."home_events_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."in_app_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "booking_id" "uuid",
    "event_id" "uuid" NOT NULL,
    "group_id" "uuid",
    "type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."in_app_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."peer_feedbacks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "from_member_id" "uuid" NOT NULL,
    "to_member_id" "uuid" NOT NULL,
    "no_show" boolean DEFAULT false NOT NULL,
    "focus_rating" integer,
    "has_discomfort_behavior" boolean DEFAULT false NOT NULL,
    "discomfort_behavior_note" "text",
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "has_profile_mismatch" boolean DEFAULT false NOT NULL,
    "profile_mismatch_note" "text",
    "performance_score" smallint GENERATED ALWAYS AS (
CASE
    WHEN ("no_show" OR "has_discomfort_behavior" OR "has_profile_mismatch") THEN 0
    WHEN ("focus_rating" IS NULL) THEN NULL::integer
    ELSE "focus_rating"
END) STORED,
    CONSTRAINT "chk_peer_not_self" CHECK (("from_member_id" <> "to_member_id")),
    CONSTRAINT "peer_feedbacks_discomfort_note_check" CHECK (((("has_discomfort_behavior" = false) AND ("discomfort_behavior_note" IS NULL)) OR (("has_discomfort_behavior" = true) AND ("discomfort_behavior_note" IS NOT NULL) AND ("length"("btrim"("discomfort_behavior_note")) > 0)))),
    CONSTRAINT "peer_feedbacks_focus_rating_check" CHECK ((("focus_rating" IS NULL) OR (("focus_rating" >= 1) AND ("focus_rating" <= 5)))),
    CONSTRAINT "peer_feedbacks_no_show_clean_check" CHECK ((("no_show" = false) OR (("focus_rating" IS NULL) AND ("has_discomfort_behavior" = false) AND ("has_profile_mismatch" = false) AND ("discomfort_behavior_note" IS NULL) AND ("profile_mismatch_note" IS NULL)))),
    CONSTRAINT "peer_feedbacks_profile_mismatch_note_check" CHECK (((("has_profile_mismatch" = false) AND ("profile_mismatch_note" IS NULL)) OR (("has_profile_mismatch" = true) AND ("profile_mismatch_note" IS NOT NULL) AND ("length"("btrim"("profile_mismatch_note")) > 0))))
);


ALTER TABLE "public"."peer_feedbacks" OWNER TO "postgres";


COMMENT ON COLUMN "public"."peer_feedbacks"."has_discomfort_behavior" IS 'True if the rated member had uncomfortable behavior (annoying repetitive actions, harassment, etc.).';



CREATE TABLE IF NOT EXISTS "public"."venues" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "university_id" "uuid",
    "city_id" "uuid" NOT NULL,
    "type" "public"."venue_type" NOT NULL,
    "name" "text" NOT NULL,
    "address" "text" NOT NULL,
    "google_map_url" "text" NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "category" "public"."event_category" NOT NULL,
    "start_at" time without time zone,
    CONSTRAINT "CHK_venues_type_constraints" CHECK (((("type" = 'university_library'::"public"."venue_type") AND ("university_id" IS NOT NULL)) OR (("type" = 'public_library'::"public"."venue_type") AND ("university_id" IS NULL)) OR (("type" = ANY (ARRAY['cafe'::"public"."venue_type", 'boardgame'::"public"."venue_type", 'escape'::"public"."venue_type"])) AND ("university_id" IS NULL)))),
    CONSTRAINT "chk_venues_google_map_url_http" CHECK (("google_map_url" ~~ 'http%'::"text"))
);


ALTER TABLE "public"."venues" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."my_events_v" WITH ("security_invoker"='on') AS
 SELECT DISTINCT ON ("b"."id") "b"."id" AS "booking_id",
    "b"."user_id",
    "b"."event_id",
    "b"."status" AS "booking_status",
    "b"."created_at" AS "booking_created_at",
    "b"."cancelled_at",
    "e"."category" AS "event_category",
    "e"."city_id",
    "e"."university_id",
    "e"."event_date",
    "e"."time_slot",
    "e"."location_detail",
    "e"."status" AS "event_status",
    "g"."id" AS "group_id",
    CASE WHEN "v"."start_at" IS NOT NULL THEN ("e"."event_date" + "v"."start_at") AT TIME ZONE 'Asia/Taipei' ELSE NULL END AS "group_start_at",
    "g"."status" AS "group_status",
    "g"."chat_open_at",
    "g"."venue_id",
    "v"."type" AS "venue_type",
    "v"."name" AS "venue_name",
    "v"."address" AS "venue_address",
    "v"."google_map_url" AS "venue_google_map_url",
    "e"."signup_deadline_at",
    "g"."feedback_sent_at",
    "g"."goal_close_at",
    (("gm"."id" IS NOT NULL) AND ("g"."id" IS NOT NULL) AND (EXISTS ( SELECT 1
           FROM "public"."event_feedbacks" "ef"
          WHERE (("ef"."group_id" = "g"."id") AND ("ef"."member_id" = "gm"."id"))))) AS "has_event_feedback",
    (("gm"."id" IS NOT NULL) AND ("g"."id" IS NOT NULL) AND (( SELECT "count"(*) AS "count"
           FROM ("public"."peer_feedbacks" "pf"
             JOIN "public"."group_members" "tgt" ON ((("tgt"."group_id" = "pf"."group_id") AND ("tgt"."id" = "pf"."to_member_id") AND ("tgt"."left_at" IS NULL))))
          WHERE (("pf"."group_id" = "g"."id") AND ("pf"."from_member_id" = "gm"."id") AND ("pf"."to_member_id" <> "gm"."id"))) >= ( SELECT GREATEST(("count"(*) - 1), (0)::bigint) AS "greatest"
           FROM "public"."group_members" "m2"
          WHERE (("m2"."group_id" = "g"."id") AND ("m2"."left_at" IS NULL))))) AS "has_peer_feedback_all",
    (("gm"."id" IS NOT NULL) AND ("g"."id" IS NOT NULL) AND (EXISTS ( SELECT 1
           FROM "public"."event_feedbacks" "ef"
          WHERE (("ef"."group_id" = "g"."id") AND ("ef"."member_id" = "gm"."id")))) AND (( SELECT "count"(*) AS "count"
           FROM ("public"."peer_feedbacks" "pf"
             JOIN "public"."group_members" "tgt" ON ((("tgt"."group_id" = "pf"."group_id") AND ("tgt"."id" = "pf"."to_member_id") AND ("tgt"."left_at" IS NULL))))
          WHERE (("pf"."group_id" = "g"."id") AND ("pf"."from_member_id" = "gm"."id") AND ("pf"."to_member_id" <> "gm"."id"))) >= ( SELECT GREATEST(("count"(*) - 1), (0)::bigint) AS "greatest"
           FROM "public"."group_members" "m2"
          WHERE (("m2"."group_id" = "g"."id") AND ("m2"."left_at" IS NULL))))) AS "has_filled_feedback_all"
   FROM (((("public"."bookings" "b"
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
     LEFT JOIN "public"."group_members" "gm" ON (("gm"."booking_id" = "b"."id") AND ("gm"."left_at" IS NULL) AND ("e"."status" IN ('notified', 'completed'))))
     LEFT JOIN "public"."groups" "g" ON (("g"."id" = "gm"."group_id")))
     LEFT JOIN "public"."venues" "v" ON (("v"."id" = "g"."venue_id")))
  ORDER BY "b"."id", "gm"."joined_at" DESC NULLS LAST;


ALTER VIEW "public"."my_events_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "merchant_trade_no" character varying(20) NOT NULL,
    "ticket_type_snapshot" "public"."ticket_type" NOT NULL,
    "pack_size_snapshot" integer NOT NULL,
    "title_snapshot" "text" NOT NULL,
    "price_snapshot_twd" integer NOT NULL,
    "total_amount" integer NOT NULL,
    "currency" character(3) DEFAULT 'TWD'::"bpchar" NOT NULL,
    "status" "public"."order_status" DEFAULT 'pending'::"public"."order_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "paid_at" timestamp with time zone,
    "checkout_token_hash" "text",
    "checkout_token_expires_at" timestamp with time zone,
    CONSTRAINT "chk_orders_merchant_trade_no_alnum" CHECK ((("merchant_trade_no")::"text" ~ '^[A-Za-z0-9]{1,20}$'::"text")),
    CONSTRAINT "orders_check" CHECK (("total_amount" = "price_snapshot_twd")),
    CONSTRAINT "orders_pack_size_snapshot_check" CHECK (("pack_size_snapshot" > 0)),
    CONSTRAINT "orders_price_snapshot_twd_check" CHECK (("price_snapshot_twd" > 0))
);


ALTER TABLE "public"."orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ticket_type" "public"."ticket_type" NOT NULL,
    "pack_size" integer NOT NULL,
    "price_twd" integer NOT NULL,
    "title" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "percent_off" smallint DEFAULT 0 NOT NULL,
    "unit_price_twd" integer GENERATED ALWAYS AS (("price_twd" / NULLIF("pack_size", 0))) STORED,
    CONSTRAINT "products_pack_size_check" CHECK (("pack_size" > 0)),
    CONSTRAINT "products_percent_off_check" CHECK ((("percent_off" >= 0) AND ("percent_off" <= 100))),
    CONSTRAINT "products_price_twd_check" CHECK (("price_twd" > 0))
);


ALTER TABLE "public"."products" OWNER TO "postgres";


COMMENT ON COLUMN "public"."products"."percent_off" IS 'Discount percent (0-100). 25 means 25% off.';



COMMENT ON COLUMN "public"."products"."unit_price_twd" IS 'Unit price (TWD) computed as price_twd / pack_size.';



CREATE TABLE IF NOT EXISTS "public"."school_email_verifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "school_email" "text" NOT NULL,
    "code_hash" "text" NOT NULL,
    "salt" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "consumed_at" timestamp with time zone,
    "fail_count" integer DEFAULT 0 NOT NULL,
    "sent_count" integer DEFAULT 1 NOT NULL,
    "last_sent_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "school_email_verifications_school_email_check" CHECK ((("school_email" = "lower"("school_email")) AND (POSITION(('@'::"text") IN ("school_email")) > 0)))
);


ALTER TABLE "public"."school_email_verifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ticket_ledger" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "order_id" "uuid",
    "booking_id" "uuid",
    "delta_study" integer DEFAULT 0 NOT NULL,
    "delta_games" integer DEFAULT 0 NOT NULL,
    "reason" "public"."ticket_ledger_reason" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chk_ticket_ledger_delta" CHECK (((("delta_study" <> 0) AND ("delta_games" = 0)) OR (("delta_study" = 0) AND ("delta_games" <> 0)))),
    CONSTRAINT "chk_ticket_ledger_reason_delta_sign" CHECK (((("reason" = 'purchase_credit'::"public"."ticket_ledger_reason") AND ((("delta_study" > 0) AND ("delta_games" = 0)) OR (("delta_games" > 0) AND ("delta_study" = 0)))) OR (("reason" = 'booking_debit'::"public"."ticket_ledger_reason") AND ((("delta_study" < 0) AND ("delta_games" = 0)) OR (("delta_games" < 0) AND ("delta_study" = 0)))) OR (("reason" = 'booking_refund'::"public"."ticket_ledger_reason") AND ((("delta_study" > 0) AND ("delta_games" = 0)) OR (("delta_games" > 0) AND ("delta_study" = 0)))) OR ("reason" = 'admin_adjust'::"public"."ticket_ledger_reason"))),
    CONSTRAINT "chk_ticket_ledger_reason_refs" CHECK (((("reason" = 'purchase_credit'::"public"."ticket_ledger_reason") AND ("order_id" IS NOT NULL) AND ("booking_id" IS NULL)) OR (("reason" = ANY (ARRAY['booking_debit'::"public"."ticket_ledger_reason", 'booking_refund'::"public"."ticket_ledger_reason"])) AND ("booking_id" IS NOT NULL) AND ("order_id" IS NULL)) OR (("reason" = 'admin_adjust'::"public"."ticket_ledger_reason") AND (NOT (("order_id" IS NOT NULL) AND ("booking_id" IS NOT NULL))))))
);


ALTER TABLE "public"."ticket_ledger" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_booking_stats_v" WITH ("security_invoker"='on') AS
 SELECT "u"."id" AS "user_id",
    "count"(*) FILTER (WHERE ("b"."status" = ANY (ARRAY['unmatched'::"public"."booking_status", 'event_cancelled'::"public"."booking_status"]))) AS "not_grouped_count",
    "count"(*) AS "total_bookings",
    "count"(*) FILTER (WHERE ("b"."status" = 'cancelled'::"public"."booking_status")) AS "cancelled_count",
    "count"(*) FILTER (WHERE ("b"."status" = 'active'::"public"."booking_status")) AS "active_count",
    "count"(*) FILTER (WHERE ("b"."status" = 'unmatched'::"public"."booking_status")) AS "unmatched_count",
    "count"(*) FILTER (WHERE ("b"."status" = 'event_cancelled'::"public"."booking_status")) AS "event_cancelled_count"
   FROM ("public"."users" "u"
     LEFT JOIN "public"."bookings" "b" ON (("b"."user_id" = "u"."id")))
  GROUP BY "u"."id";


ALTER VIEW "public"."user_booking_stats_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_peer_scores_v" WITH ("security_invoker"='on') AS
 WITH "per_feedback" AS (
         SELECT "b"."user_id" AS "rated_user_id",
            "pf"."performance_score"
           FROM (("public"."peer_feedbacks" "pf"
             JOIN "public"."group_members" "gm" ON (("gm"."id" = "pf"."to_member_id")))
             JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
        )
 SELECT "rated_user_id" AS "user_id",
    "count"(*) FILTER (WHERE ("performance_score" IS NOT NULL)) AS "feedback_count",
    ("avg"("performance_score"))::numeric(5,2) AS "avg_performance_score"
   FROM "per_feedback"
  GROUP BY "rated_user_id";


ALTER VIEW "public"."user_peer_scores_v" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_ticket_balances_v" WITH ("security_invoker"='on') AS
 WITH "latest_paid" AS (
         SELECT "o"."user_id",
            "max"(
                CASE
                    WHEN ("o"."ticket_type_snapshot" = 'study'::"public"."ticket_type") THEN COALESCE("o"."paid_at", "o"."created_at")
                    ELSE NULL::timestamp with time zone
                END) AS "last_study_paid_at",
            "max"(
                CASE
                    WHEN ("o"."ticket_type_snapshot" = 'games'::"public"."ticket_type") THEN COALESCE("o"."paid_at", "o"."created_at")
                    ELSE NULL::timestamp with time zone
                END) AS "last_games_paid_at"
           FROM "public"."orders" "o"
          WHERE ("o"."status" = 'paid'::"public"."order_status")
          GROUP BY "o"."user_id"
        ), "raw_balances" AS (
         SELECT "u"."id" AS "user_id",
            (COALESCE("sum"("tl"."delta_study"), (0)::bigint))::integer AS "study_balance_raw",
            (COALESCE("sum"("tl"."delta_games"), (0)::bigint))::integer AS "games_balance_raw",
            "max"("tl"."created_at") AS "updated_at"
           FROM ("public"."users" "u"
             LEFT JOIN "public"."ticket_ledger" "tl" ON (("tl"."user_id" = "u"."id")))
          GROUP BY "u"."id"
        )
 SELECT "rb"."user_id",
        CASE
            WHEN ("lp"."last_study_paid_at" IS NULL) THEN "rb"."study_balance_raw"
            WHEN (("lp"."last_study_paid_at" + '1 year'::interval) > "now"()) THEN "rb"."study_balance_raw"
            ELSE 0
        END AS "study_balance",
        CASE
            WHEN ("lp"."last_games_paid_at" IS NULL) THEN "rb"."games_balance_raw"
            WHEN (("lp"."last_games_paid_at" + '1 year'::interval) > "now"()) THEN "rb"."games_balance_raw"
            ELSE 0
        END AS "games_balance",
    "rb"."updated_at"
   FROM ("raw_balances" "rb"
     LEFT JOIN "latest_paid" "lp" ON (("lp"."user_id" = "rb"."user_id")));


ALTER VIEW "public"."user_ticket_balances_v" OWNER TO "postgres";


ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "cities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ecpay_payments"
    ADD CONSTRAINT "ecpay_payments_order_id_key" UNIQUE ("order_id");



ALTER TABLE ONLY "public"."ecpay_payments"
    ADD CONSTRAINT "ecpay_payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."english_content_exposures"
    ADD CONSTRAINT "english_content_exposures_pkey" PRIMARY KEY ("user_id", "content_id");



ALTER TABLE ONLY "public"."english_contents"
    ADD CONSTRAINT "english_contents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_feedbacks"
    ADD CONSTRAINT "event_feedbacks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fb_friend_sync_attempts"
    ADD CONSTRAINT "fb_friend_sync_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."focused_study_plans"
    ADD CONSTRAINT "focused_study_plans_booking_id_slot_key" UNIQUE ("booking_id", "slot");



ALTER TABLE ONLY "public"."focused_study_plans"
    ADD CONSTRAINT "focused_study_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_chat_timeline"
    ADD CONSTRAINT "group_chat_timeline_pkey" PRIMARY KEY ("item_id");



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_group_id_content_id_key" UNIQUE ("group_id", "content_id");



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_group_id_member_id_key" UNIQUE ("group_id", "member_id");



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_group_id_id_key" UNIQUE ("group_id", "id");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_messages"
    ADD CONSTRAINT "group_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_id_event_id_key" UNIQUE ("id", "event_id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_event_booking_type_unique" UNIQUE ("event_id", "booking_id", "type");



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_merchant_trade_no_key" UNIQUE ("merchant_trade_no");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."peer_feedbacks"
    ADD CONSTRAINT "peer_feedbacks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_ticket_type_pack_size_key" UNIQUE ("ticket_type", "pack_size");



ALTER TABLE ONLY "public"."school_email_verifications"
    ADD CONSTRAINT "school_email_verifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ticket_ledger"
    ADD CONSTRAINT "ticket_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "universities_id_city_id_key" UNIQUE ("id", "city_id");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "universities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."university_email_domains"
    ADD CONSTRAINT "university_email_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "uq_bookings_id_event" UNIQUE ("id", "event_id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "uq_bookings_id_user" UNIQUE ("id", "user_id");



ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "uq_cities_name" UNIQUE ("name");



ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "uq_cities_slug" UNIQUE ("slug");



ALTER TABLE ONLY "public"."event_feedbacks"
    ADD CONSTRAINT "uq_event_feedback_once" UNIQUE ("group_id", "member_id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "uq_friendships_pair" UNIQUE ("user_low_id", "user_high_id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "uq_orders_id_user" UNIQUE ("id", "user_id");



ALTER TABLE ONLY "public"."peer_feedbacks"
    ADD CONSTRAINT "uq_peer_once" UNIQUE ("group_id", "from_member_id", "to_member_id");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "uq_universities_city_name" UNIQUE ("city_id", "name");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "uq_universities_code" UNIQUE ("code");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "uq_universities_slug" UNIQUE ("slug");



ALTER TABLE ONLY "public"."university_email_domains"
    ADD CONSTRAINT "uq_university_email_domains_domain" UNIQUE ("domain");



ALTER TABLE ONLY "public"."user_school_emails"
    ADD CONSTRAINT "user_school_emails_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_fb_user_id_key" UNIQUE ("fb_user_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venues"
    ADD CONSTRAINT "venues_pkey" PRIMARY KEY ("id");



CREATE INDEX "bookings_event_idx" ON "public"."bookings" USING "btree" ("event_id");



CREATE INDEX "bookings_user_idx" ON "public"."bookings" USING "btree" ("user_id");



CREATE INDEX "event_feedbacks_group_idx" ON "public"."event_feedbacks" USING "btree" ("group_id");



CREATE INDEX "group_chat_timeline_group_sort_idx" ON "public"."group_chat_timeline" USING "btree" ("group_id", "sort_ts" DESC, "sort_rank" DESC);



CREATE UNIQUE INDEX "group_members_active_booking_idx" ON "public"."group_members" USING "btree" ("booking_id") WHERE ("left_at" IS NULL);



CREATE INDEX "group_members_event_idx" ON "public"."group_members" USING "btree" ("event_id");



CREATE INDEX "group_members_group_id_chat_joined_at_idx" ON "public"."group_members" USING "btree" ("group_id", "chat_joined_at");



CREATE INDEX "group_members_group_idx" ON "public"."group_members" USING "btree" ("group_id");



CREATE INDEX "group_messages_group_time_idx" ON "public"."group_messages" USING "btree" ("group_id", "created_at");



CREATE UNIQUE INDEX "group_messages_member_joined_once_uq" ON "public"."group_messages" USING "btree" ("group_id", (("metadata" ->> 'event'::"text")), (("metadata" ->> 'user_id'::"text"))) WHERE (("type" = 'system'::"public"."message_type") AND (("metadata" ->> 'event'::"text") = 'member_joined'::"text"));



CREATE INDEX "idx_venues_city_category_active" ON "public"."venues" USING "btree" ("city_id", "category") WHERE ("is_active" = true);



CREATE INDEX "orders_checkout_token_hash_idx" ON "public"."orders" USING "btree" ("checkout_token_hash");



CREATE INDEX "orders_status_idx" ON "public"."orders" USING "btree" ("status");



CREATE INDEX "orders_user_idx" ON "public"."orders" USING "btree" ("user_id");



CREATE INDEX "peer_feedbacks_group_idx" ON "public"."peer_feedbacks" USING "btree" ("group_id");



CREATE INDEX "school_email_verifications_user_email_idx" ON "public"."school_email_verifications" USING "btree" ("user_id", "school_email");



CREATE UNIQUE INDEX "ticket_ledger_one_refund_per_booking" ON "public"."ticket_ledger" USING "btree" ("booking_id") WHERE (("booking_id" IS NOT NULL) AND ("reason" = 'booking_refund'::"public"."ticket_ledger_reason"));



CREATE INDEX "ticket_ledger_user_created_at_idx" ON "public"."ticket_ledger" USING "btree" ("user_id", "created_at" DESC);



CREATE UNIQUE INDEX "uq_bookings_user_event_active" ON "public"."bookings" USING "btree" ("user_id", "event_id") WHERE ("status" = 'active'::"public"."booking_status");



CREATE UNIQUE INDEX "uq_orders_merchant_trade_no" ON "public"."orders" USING "btree" ("merchant_trade_no");



CREATE UNIQUE INDEX "uq_ticket_ledger_booking_debit_booking" ON "public"."ticket_ledger" USING "btree" ("booking_id") WHERE (("reason" = 'booking_debit'::"public"."ticket_ledger_reason") AND ("booking_id" IS NOT NULL));



CREATE UNIQUE INDEX "uq_ticket_ledger_booking_refund_booking" ON "public"."ticket_ledger" USING "btree" ("booking_id") WHERE (("reason" = 'booking_refund'::"public"."ticket_ledger_reason") AND ("booking_id" IS NOT NULL));



CREATE UNIQUE INDEX "uq_ticket_ledger_purchase_credit_order" ON "public"."ticket_ledger" USING "btree" ("order_id") WHERE (("reason" = 'purchase_credit'::"public"."ticket_ledger_reason") AND ("order_id" IS NOT NULL));



CREATE UNIQUE INDEX "user_school_emails_active_email_key" ON "public"."user_school_emails" USING "btree" ("school_email") WHERE ("is_active" = true);



CREATE UNIQUE INDEX "user_school_emails_user_email_key" ON "public"."user_school_emails" USING "btree" ("user_id", "school_email");



CREATE UNIQUE INDEX "user_school_emails_user_email_uniq" ON "public"."user_school_emails" USING "btree" ("user_id", "school_email");



CREATE INDEX "venues_city_type_idx" ON "public"."venues" USING "btree" ("city_id", "type");



CREATE OR REPLACE TRIGGER "group_messages_to_timeline" AFTER INSERT ON "public"."group_messages" FOR EACH ROW EXECUTE FUNCTION "public"."trg_group_messages_to_timeline"();



CREATE OR REPLACE TRIGGER "orders_require_happy_path_ready" BEFORE INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."trg_orders_require_happy_path_ready"();



CREATE OR REPLACE TRIGGER "trg_events_status_notified" BEFORE UPDATE OF "status" ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_event_status_notified"();



CREATE OR REPLACE TRIGGER "trg_groups_enforce_venue_matches_event" BEFORE INSERT OR UPDATE OF "venue_id", "event_id" ON "public"."groups" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_group_venue_matches_event"();



CREATE OR REPLACE TRIGGER "trg_groups_require_venue_on_scheduled" BEFORE INSERT OR UPDATE OF "status", "venue_id" ON "public"."groups" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_group_scheduled_requires_venue"();



CREATE OR REPLACE TRIGGER "trg_groups_status_scheduled" AFTER INSERT OR UPDATE OF "status" ON "public"."groups" FOR EACH ROW EXECUTE FUNCTION "public"."handle_group_status_scheduled"();



CREATE OR REPLACE TRIGGER "trg_set_event_signup_times" BEFORE INSERT OR UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."set_event_signup_times"();



CREATE OR REPLACE TRIGGER "trg_set_group_times" BEFORE INSERT OR UPDATE ON "public"."groups" FOR EACH ROW EXECUTE FUNCTION "public"."set_group_times"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."cities" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."ecpay_payments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."event_feedbacks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."fb_friend_sync_attempts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."friendships" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."group_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."groups" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."peer_feedbacks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."ticket_ledger" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."universities" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."university_email_domains" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."venues" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "FK_bookings_event_id" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "FK_bookings_user_id" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."event_feedbacks"
    ADD CONSTRAINT "FK_event_feedbacks_member" FOREIGN KEY ("group_id", "member_id") REFERENCES "public"."group_members"("group_id", "id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "FK_events_city_id" FOREIGN KEY ("city_id") REFERENCES "public"."cities"("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "FK_events_university_city" FOREIGN KEY ("university_id", "city_id") REFERENCES "public"."universities"("id", "city_id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "FK_events_university_id" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "FK_group_members_booking_event" FOREIGN KEY ("booking_id", "event_id") REFERENCES "public"."bookings"("id", "event_id");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "FK_group_members_group_event" FOREIGN KEY ("group_id", "event_id") REFERENCES "public"."groups"("id", "event_id");



ALTER TABLE ONLY "public"."group_messages"
    ADD CONSTRAINT "FK_group_messages_group_id" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id");



ALTER TABLE ONLY "public"."group_messages"
    ADD CONSTRAINT "FK_group_messages_user_id" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "FK_groups_event_id" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "FK_groups_venue_id" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id");



ALTER TABLE ONLY "public"."peer_feedbacks"
    ADD CONSTRAINT "FK_peer_feedbacks_from_member" FOREIGN KEY ("group_id", "from_member_id") REFERENCES "public"."group_members"("group_id", "id");



ALTER TABLE ONLY "public"."peer_feedbacks"
    ADD CONSTRAINT "FK_peer_feedbacks_to_member" FOREIGN KEY ("group_id", "to_member_id") REFERENCES "public"."group_members"("group_id", "id");



ALTER TABLE ONLY "public"."ticket_ledger"
    ADD CONSTRAINT "FK_ticket_ledger_booking_user" FOREIGN KEY ("booking_id", "user_id") REFERENCES "public"."bookings"("id", "user_id");



ALTER TABLE ONLY "public"."ticket_ledger"
    ADD CONSTRAINT "FK_ticket_ledger_order_user" FOREIGN KEY ("order_id", "user_id") REFERENCES "public"."orders"("id", "user_id");



ALTER TABLE ONLY "public"."venues"
    ADD CONSTRAINT "FK_venues_city_id" FOREIGN KEY ("city_id") REFERENCES "public"."cities"("id");



ALTER TABLE ONLY "public"."venues"
    ADD CONSTRAINT "FK_venues_university_city" FOREIGN KEY ("university_id", "city_id") REFERENCES "public"."universities"("id", "city_id");



ALTER TABLE ONLY "public"."venues"
    ADD CONSTRAINT "FK_venues_university_id" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id");



ALTER TABLE ONLY "public"."ecpay_payments"
    ADD CONSTRAINT "ecpay_payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id");



ALTER TABLE ONLY "public"."english_content_exposures"
    ADD CONSTRAINT "english_content_exposures_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."english_contents"("id");



ALTER TABLE ONLY "public"."english_content_exposures"
    ADD CONSTRAINT "english_content_exposures_first_seen_group_id_fkey" FOREIGN KEY ("first_seen_group_id") REFERENCES "public"."groups"("id");



ALTER TABLE ONLY "public"."english_content_exposures"
    ADD CONSTRAINT "english_content_exposures_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fb_friend_sync_attempts"
    ADD CONSTRAINT "fb_friend_sync_attempts_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id");



ALTER TABLE ONLY "public"."fb_friend_sync_attempts"
    ADD CONSTRAINT "fb_friend_sync_attempts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."focused_study_plans"
    ADD CONSTRAINT "focused_study_plans_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_user_high_id_fkey" FOREIGN KEY ("user_high_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_user_low_id_fkey" FOREIGN KEY ("user_low_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."english_contents"("id");



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_english_assignments"
    ADD CONSTRAINT "group_english_assignments_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."group_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."in_app_notifications"
    ADD CONSTRAINT "in_app_notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."school_email_verifications"
    ADD CONSTRAINT "school_email_verifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ticket_ledger"
    ADD CONSTRAINT "ticket_ledger_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."universities"
    ADD CONSTRAINT "universities_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."cities"("id");



ALTER TABLE ONLY "public"."university_email_domains"
    ADD CONSTRAINT "university_email_domains_university_id_fkey" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_school_emails"
    ADD CONSTRAINT "user_school_emails_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow select timeline in my groups" ON "public"."group_chat_timeline" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
     JOIN "public"."groups" "g" ON (("g"."id" = "gm"."group_id")))
  WHERE (("gm"."group_id" = "group_chat_timeline"."group_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL) AND ("e"."status" = ANY (ARRAY['notified'::"public"."event_status", 'completed'::"public"."event_status"])) AND ("g"."chat_open_at" IS NOT NULL) AND ("now"() >= "g"."chat_open_at")))));



CREATE POLICY "allow_insert_own_event_feedback" ON "public"."event_feedbacks" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON ((("b"."id" = "gm"."booking_id") AND ("b"."event_id" = "gm"."event_id"))))
  WHERE (("gm"."group_id" = "event_feedbacks"."group_id") AND ("gm"."id" = "event_feedbacks"."member_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL)))));



CREATE POLICY "allow_insert_own_peer_feedback" ON "public"."peer_feedbacks" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON ((("b"."id" = "gm"."booking_id") AND ("b"."event_id" = "gm"."event_id"))))
  WHERE (("gm"."group_id" = "peer_feedbacks"."group_id") AND ("gm"."id" = "peer_feedbacks"."from_member_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL)))));



CREATE POLICY "allow_insert_user_message_in_my_groups" ON "public"."group_messages" FOR INSERT TO "authenticated" WITH CHECK ((("type" = 'user'::"public"."message_type") AND ("user_id" = "auth"."uid"()) AND ("content" IS NOT NULL) AND ("length"("btrim"("content")) > 0) AND (EXISTS ( SELECT 1
   FROM ((("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
     JOIN "public"."groups" "g" ON (("g"."id" = "gm"."group_id")))
  WHERE (("gm"."group_id" = "group_messages"."group_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL) AND ("e"."status" = ANY (ARRAY['notified'::"public"."event_status", 'completed'::"public"."event_status"])) AND ("g"."chat_open_at" IS NOT NULL) AND ("now"() >= "g"."chat_open_at"))))));



CREATE POLICY "allow_select_cities" ON "public"."cities" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow_select_cities_anon" ON "public"."cities" FOR SELECT TO "anon" USING (true);



CREATE POLICY "allow_select_event_feedbacks_in_my_groups" ON "public"."event_feedbacks" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON ((("b"."id" = "gm"."booking_id") AND ("b"."event_id" = "gm"."event_id"))))
  WHERE (("gm"."group_id" = "event_feedbacks"."group_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL)))));



CREATE POLICY "allow_select_events" ON "public"."events" FOR SELECT TO "authenticated" USING (("status" = 'scheduled'::"public"."event_status"));



CREATE POLICY "allow_select_events_anon" ON "public"."events" FOR SELECT TO "anon" USING (("status" = 'scheduled'::"public"."event_status"));



CREATE POLICY "allow_select_messages_in_my_groups" ON "public"."group_messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ((("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
     JOIN "public"."groups" "g" ON (("g"."id" = "gm"."group_id")))
  WHERE (("gm"."group_id" = "group_messages"."group_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL) AND ("e"."status" = ANY (ARRAY['notified'::"public"."event_status", 'completed'::"public"."event_status"])) AND ("g"."chat_open_at" IS NOT NULL) AND ("now"() >= "g"."chat_open_at")))));



CREATE POLICY "allow_select_own_bookings" ON "public"."bookings" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "allow_select_own_ecpay_payments" ON "public"."ecpay_payments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "ecpay_payments"."order_id") AND ("o"."user_id" = "auth"."uid"())))));



CREATE POLICY "allow_select_own_fb_friend_sync_attempts" ON "public"."fb_friend_sync_attempts" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "allow_select_own_friendships" ON "public"."friendships" FOR SELECT TO "authenticated" USING ((("user_low_id" = "auth"."uid"()) OR ("user_high_id" = "auth"."uid"())));



CREATE POLICY "allow_select_own_groups" ON "public"."groups" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON ((("b"."id" = "gm"."booking_id") AND ("b"."event_id" = "gm"."event_id"))))
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
  WHERE (("gm"."group_id" = "groups"."id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL) AND ("e"."status" = ANY (ARRAY['notified'::"public"."event_status", 'completed'::"public"."event_status"]))))));



CREATE POLICY "allow_select_own_orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "allow_select_own_user" ON "public"."users" FOR SELECT TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "allow_select_peer_feedbacks_in_my_groups" ON "public"."peer_feedbacks" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON ((("b"."id" = "gm"."booking_id") AND ("b"."event_id" = "gm"."event_id"))))
  WHERE (("gm"."group_id" = "peer_feedbacks"."group_id") AND ("b"."user_id" = "auth"."uid"()) AND ("gm"."left_at" IS NULL)))));



CREATE POLICY "allow_select_products" ON "public"."products" FOR SELECT TO "authenticated" USING (("is_active" = true));



CREATE POLICY "allow_select_products_anon" ON "public"."products" FOR SELECT TO "anon" USING (("is_active" = true));



CREATE POLICY "allow_select_universities" ON "public"."universities" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow_select_universities_anon" ON "public"."universities" FOR SELECT TO "anon" USING (true);



CREATE POLICY "allow_select_university_email_domains" ON "public"."university_email_domains" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow_select_venues" ON "public"."venues" FOR SELECT TO "authenticated" USING (("is_active" = true));



CREATE POLICY "allow_select_venues_anon" ON "public"."venues" FOR SELECT TO "anon" USING (("is_active" = true));



CREATE POLICY "allow_update_own_user" ON "public"."users" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ecpay_payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."english_content_exposures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."english_contents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."event_feedbacks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "events_select_by_university" ON "public"."events" FOR SELECT TO "authenticated" USING ((("university_id" IS NULL) OR (EXISTS ( SELECT 1
   FROM "public"."user_current_university_v" "cu"
  WHERE (("cu"."user_id" = "auth"."uid"()) AND ("cu"."university_id" = "events"."university_id"))))));



ALTER TABLE "public"."fb_friend_sync_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."focused_study_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."friendships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "fsp_select_same_group" ON "public"."focused_study_plans" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (("public"."group_members" "gm_target"
     JOIN "public"."group_members" "gm_me" ON (("gm_me"."group_id" = "gm_target"."group_id")))
     JOIN "public"."bookings" "b_me" ON (("b_me"."id" = "gm_me"."booking_id")))
  WHERE (("gm_target"."booking_id" = "focused_study_plans"."booking_id") AND ("b_me"."user_id" = "auth"."uid"())))));



CREATE POLICY "fsp_update_owner" ON "public"."focused_study_plans" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "focused_study_plans"."booking_id") AND ("b"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."bookings" "b"
  WHERE (("b"."id" = "focused_study_plans"."booking_id") AND ("b"."user_id" = "auth"."uid"())))));



CREATE POLICY "fsp_write_owner" ON "public"."focused_study_plans" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."bookings" "b"
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
  WHERE (("b"."id" = "focused_study_plans"."booking_id") AND ("b"."user_id" = "auth"."uid"()) AND ("e"."category" = 'focused_study'::"public"."event_category")))));



CREATE POLICY "gea_select_same_group" ON "public"."group_english_assignments" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm_me"
     JOIN "public"."bookings" "b_me" ON (("b_me"."id" = "gm_me"."booking_id")))
  WHERE (("gm_me"."group_id" = "group_english_assignments"."group_id") AND ("b_me"."user_id" = "auth"."uid"())))));



CREATE POLICY "gea_update_owner_used_count" ON "public"."group_english_assignments" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
  WHERE (("gm"."id" = "group_english_assignments"."member_id") AND ("b"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."group_members" "gm"
     JOIN "public"."bookings" "b" ON (("b"."id" = "gm"."booking_id")))
  WHERE (("gm"."id" = "group_english_assignments"."member_id") AND ("b"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."group_chat_timeline" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."group_english_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."group_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "group_members_select_own_via_booking" ON "public"."group_members" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."bookings" "b"
     JOIN "public"."events" "e" ON (("e"."id" = "b"."event_id")))
  WHERE (("b"."id" = "group_members"."booking_id") AND ("b"."user_id" = "auth"."uid"()) AND ("e"."status" = ANY (ARRAY['notified'::"public"."event_status", 'completed'::"public"."event_status"]))))));



ALTER TABLE "public"."group_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."groups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."in_app_notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "in_app_notifications_select_own" ON "public"."in_app_notifications" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."peer_feedbacks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."school_email_verifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "school_email_verifications_user_own" ON "public"."school_email_verifications" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."ticket_ledger" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ticket_ledger_select_own" ON "public"."ticket_ledger" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."universities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."university_email_domains" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_school_emails" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_school_emails_insert_own" ON "public"."user_school_emails" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "user_school_emails_select_own" ON "public"."user_school_emails" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_school_emails_update_own" ON "public"."user_school_emails" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venues" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."group_chat_timeline";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."group_messages";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON TYPE "public"."booking_status" TO "anon";
GRANT ALL ON TYPE "public"."booking_status" TO "authenticated";
GRANT ALL ON TYPE "public"."booking_status" TO "service_role";



GRANT ALL ON TYPE "public"."event_category" TO "anon";
GRANT ALL ON TYPE "public"."event_category" TO "authenticated";
GRANT ALL ON TYPE "public"."event_category" TO "service_role";



GRANT ALL ON TYPE "public"."event_time_slot" TO "anon";
GRANT ALL ON TYPE "public"."event_time_slot" TO "authenticated";
GRANT ALL ON TYPE "public"."event_time_slot" TO "service_role";



GRANT ALL ON TYPE "public"."message_type" TO "anon";
GRANT ALL ON TYPE "public"."message_type" TO "authenticated";
GRANT ALL ON TYPE "public"."message_type" TO "service_role";



GRANT ALL ON TYPE "public"."school_email_status" TO "anon";
GRANT ALL ON TYPE "public"."school_email_status" TO "authenticated";
GRANT ALL ON TYPE "public"."school_email_status" TO "service_role";



GRANT ALL ON TYPE "public"."sync_status" TO "anon";
GRANT ALL ON TYPE "public"."sync_status" TO "authenticated";
GRANT ALL ON TYPE "public"."sync_status" TO "service_role";



GRANT ALL ON TYPE "public"."ticket_ledger_reason" TO "anon";
GRANT ALL ON TYPE "public"."ticket_ledger_reason" TO "authenticated";
GRANT ALL ON TYPE "public"."ticket_ledger_reason" TO "service_role";



GRANT ALL ON TYPE "public"."ticket_type" TO "anon";
GRANT ALL ON TYPE "public"."ticket_type" TO "authenticated";
GRANT ALL ON TYPE "public"."ticket_type" TO "service_role";



GRANT ALL ON TYPE "public"."venue_type" TO "anon";
GRANT ALL ON TYPE "public"."venue_type" TO "authenticated";
GRANT ALL ON TYPE "public"."venue_type" TO "service_role";














































































































































































REVOKE ALL ON FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_paid_order"("p_order_id" "uuid", "p_trade_no" "text", "p_trade_amt" integer, "p_rtn_code" integer, "p_rtn_msg" "text", "p_check_mac_value" "text", "p_raw" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."assign_english_contents_for_group"("p_group_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."assign_english_contents_for_group"("p_group_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."assign_english_contents_for_group"("p_group_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."auto_seed_groups_for_event"("p_event_id" "uuid", "p_group_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."auto_seed_groups_for_event"("p_event_id" "uuid", "p_group_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_seed_groups_for_event"("p_event_id" "uuid", "p_group_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."cancel_booking_and_refund_ticket"("p_booking_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."cancel_booking_and_refund_ticket"("p_booking_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cancel_booking_and_refund_ticket"("p_booking_id" "uuid") TO "service_role";



GRANT ALL ON TABLE "public"."group_chat_timeline" TO "anon";
GRANT ALL ON TABLE "public"."group_chat_timeline" TO "authenticated";
GRANT ALL ON TABLE "public"."group_chat_timeline" TO "service_role";



GRANT ALL ON FUNCTION "public"."chat_fetch_timeline_page"("p_group_id" "uuid", "p_before_sort_ts" timestamp with time zone, "p_before_sort_rank" integer, "p_before_item_id" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."chat_fetch_timeline_page"("p_group_id" "uuid", "p_before_sort_ts" timestamp with time zone, "p_before_sort_rank" integer, "p_before_item_id" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."chat_fetch_timeline_page"("p_group_id" "uuid", "p_before_sort_ts" timestamp with time zone, "p_before_sort_rank" integer, "p_before_item_id" "text", "p_limit" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."chat_mark_joined"("p_group_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."chat_send_message"("p_group_id" "uuid", "p_content" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_booking_and_consume_ticket"("p_event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_booking_and_consume_ticket"("p_event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_booking_and_consume_ticket"("p_event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_focused_study_plans_for_group"("p_group_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_focused_study_plans_for_group"("p_group_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_focused_study_plans_for_group"("p_group_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_group_scheduled_requires_venue"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_group_scheduled_requires_venue"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_group_scheduled_requires_venue"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_group_venue_matches_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_group_venue_matches_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_group_venue_matches_event"() TO "service_role";



GRANT ALL ON FUNCTION "public"."extract_school_base_domain"("full_domain" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."extract_school_base_domain"("full_domain" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."extract_school_base_domain"("full_domain" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."gen_merchant_trade_no"() TO "anon";
GRANT ALL ON FUNCTION "public"."gen_merchant_trade_no"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."gen_merchant_trade_no"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_group_focused_study_plans"("p_group_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_group_focused_study_plans"("p_group_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_group_focused_study_plans"("p_group_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_event_status_notified"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_event_status_notified"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_event_status_notified"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_group_status_scheduled"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_group_status_scheduled"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_group_status_scheduled"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."require_user_happy_path_ready"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."require_user_happy_path_ready"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."require_user_happy_path_ready"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_create_order"("p_product_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_create_order"("p_product_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_create_order"("p_product_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."run_auto_seed_for_events_two_days_out"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_auto_seed_for_events_two_days_out"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_auto_seed_for_events_two_days_out"() TO "service_role";



GRANT ALL ON FUNCTION "public"."run_move_events_to_history"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_move_events_to_history"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_move_events_to_history"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_event_signup_times"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_event_signup_times"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_event_signup_times"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_group_times"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_group_times"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_group_times"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_users_university_after_verified"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_users_university_after_verified"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_users_university_after_verified"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_group_messages_to_timeline"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_group_messages_to_timeline"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_group_messages_to_timeline"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_orders_require_happy_path_ready"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_orders_require_happy_path_ready"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_orders_require_happy_path_ready"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_focused_study_plan"("p_plan_id" "uuid", "p_content" "text", "p_done" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."update_focused_study_plan"("p_plan_id" "uuid", "p_content" "text", "p_done" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_focused_study_plan"("p_plan_id" "uuid", "p_content" "text", "p_done" boolean) TO "service_role";
























GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."cities" TO "anon";
GRANT ALL ON TABLE "public"."cities" TO "authenticated";
GRANT ALL ON TABLE "public"."cities" TO "service_role";



GRANT ALL ON TABLE "public"."ecpay_payments" TO "anon";
GRANT ALL ON TABLE "public"."ecpay_payments" TO "authenticated";
GRANT ALL ON TABLE "public"."ecpay_payments" TO "service_role";



GRANT ALL ON TABLE "public"."english_content_exposures" TO "service_role";



GRANT ALL ON TABLE "public"."english_contents" TO "anon";
GRANT ALL ON TABLE "public"."english_contents" TO "authenticated";
GRANT ALL ON TABLE "public"."english_contents" TO "service_role";



GRANT ALL ON TABLE "public"."event_feedbacks" TO "anon";
GRANT ALL ON TABLE "public"."event_feedbacks" TO "authenticated";
GRANT ALL ON TABLE "public"."event_feedbacks" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."fb_friend_sync_attempts" TO "anon";
GRANT ALL ON TABLE "public"."fb_friend_sync_attempts" TO "authenticated";
GRANT ALL ON TABLE "public"."fb_friend_sync_attempts" TO "service_role";



GRANT ALL ON TABLE "public"."focused_study_plans" TO "anon";
GRANT ALL ON TABLE "public"."focused_study_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."focused_study_plans" TO "service_role";



GRANT ALL ON TABLE "public"."friendships" TO "anon";
GRANT ALL ON TABLE "public"."friendships" TO "authenticated";
GRANT ALL ON TABLE "public"."friendships" TO "service_role";



GRANT ALL ON TABLE "public"."group_messages" TO "anon";
GRANT ALL ON TABLE "public"."group_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."group_messages" TO "service_role";



GRANT ALL ON TABLE "public"."universities" TO "anon";
GRANT ALL ON TABLE "public"."universities" TO "authenticated";
GRANT ALL ON TABLE "public"."universities" TO "service_role";



GRANT ALL ON TABLE "public"."university_email_domains" TO "anon";
GRANT ALL ON TABLE "public"."university_email_domains" TO "authenticated";
GRANT ALL ON TABLE "public"."university_email_domains" TO "service_role";



GRANT ALL ON TABLE "public"."user_school_emails" TO "anon";
GRANT ALL ON TABLE "public"."user_school_emails" TO "authenticated";
GRANT ALL ON TABLE "public"."user_school_emails" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."user_current_university_v" TO "anon";
GRANT ALL ON TABLE "public"."user_current_university_v" TO "authenticated";
GRANT ALL ON TABLE "public"."user_current_university_v" TO "service_role";



GRANT ALL ON TABLE "public"."user_profile_v" TO "anon";
GRANT ALL ON TABLE "public"."user_profile_v" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profile_v" TO "service_role";



GRANT ALL ON TABLE "public"."group_chat_messages_v" TO "anon";
GRANT ALL ON TABLE "public"."group_chat_messages_v" TO "authenticated";
GRANT ALL ON TABLE "public"."group_chat_messages_v" TO "service_role";



GRANT ALL ON TABLE "public"."group_english_assignments" TO "anon";
GRANT ALL ON TABLE "public"."group_english_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."group_english_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."group_members" TO "anon";
GRANT ALL ON TABLE "public"."group_members" TO "authenticated";
GRANT ALL ON TABLE "public"."group_members" TO "service_role";



GRANT ALL ON TABLE "public"."group_english_assignments_v" TO "anon";
GRANT ALL ON TABLE "public"."group_english_assignments_v" TO "authenticated";
GRANT ALL ON TABLE "public"."group_english_assignments_v" TO "service_role";



GRANT ALL ON TABLE "public"."group_focused_study_plans_v" TO "anon";
GRANT ALL ON TABLE "public"."group_focused_study_plans_v" TO "authenticated";
GRANT ALL ON TABLE "public"."group_focused_study_plans_v" TO "service_role";



GRANT ALL ON TABLE "public"."group_members_profile_v" TO "anon";
GRANT ALL ON TABLE "public"."group_members_profile_v" TO "authenticated";
GRANT ALL ON TABLE "public"."group_members_profile_v" TO "service_role";



GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";



GRANT ALL ON TABLE "public"."home_events_v" TO "anon";
GRANT ALL ON TABLE "public"."home_events_v" TO "authenticated";
GRANT ALL ON TABLE "public"."home_events_v" TO "service_role";



GRANT ALL ON TABLE "public"."in_app_notifications" TO "anon";
GRANT ALL ON TABLE "public"."in_app_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."in_app_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."peer_feedbacks" TO "anon";
GRANT ALL ON TABLE "public"."peer_feedbacks" TO "authenticated";
GRANT ALL ON TABLE "public"."peer_feedbacks" TO "service_role";



GRANT ALL ON TABLE "public"."venues" TO "anon";
GRANT ALL ON TABLE "public"."venues" TO "authenticated";
GRANT ALL ON TABLE "public"."venues" TO "service_role";



GRANT ALL ON TABLE "public"."my_events_v" TO "anon";
GRANT ALL ON TABLE "public"."my_events_v" TO "authenticated";
GRANT ALL ON TABLE "public"."my_events_v" TO "service_role";



GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."school_email_verifications" TO "anon";
GRANT ALL ON TABLE "public"."school_email_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."school_email_verifications" TO "service_role";



GRANT ALL ON TABLE "public"."ticket_ledger" TO "anon";
GRANT ALL ON TABLE "public"."ticket_ledger" TO "authenticated";
GRANT ALL ON TABLE "public"."ticket_ledger" TO "service_role";



GRANT ALL ON TABLE "public"."user_booking_stats_v" TO "anon";
GRANT ALL ON TABLE "public"."user_booking_stats_v" TO "authenticated";
GRANT ALL ON TABLE "public"."user_booking_stats_v" TO "service_role";



GRANT ALL ON TABLE "public"."user_peer_scores_v" TO "anon";
GRANT ALL ON TABLE "public"."user_peer_scores_v" TO "authenticated";
GRANT ALL ON TABLE "public"."user_peer_scores_v" TO "service_role";



GRANT ALL ON TABLE "public"."user_ticket_balances_v" TO "anon";
GRANT ALL ON TABLE "public"."user_ticket_balances_v" TO "authenticated";
GRANT ALL ON TABLE "public"."user_ticket_balances_v" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































