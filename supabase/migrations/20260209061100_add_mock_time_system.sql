-- ============================================================
-- Mock Time System for Integration Testing
-- ============================================================
-- Allows overriding now() globally via a stored time offset.
-- When no offset is set, public.now() returns pg_catalog.now()
-- (identical to default behavior, zero production impact).
--
-- Usage:
--   SELECT test_set_now('2026-02-20 10:00:00+08');  -- set mock time
--   SELECT test_clear_now();                         -- clear mock time
--   SELECT now();                                    -- returns mock or real time
-- ============================================================

-- 1. Config table to store mock time offset
CREATE TABLE IF NOT EXISTS public.test_config (
  key text PRIMARY KEY,
  value text NOT NULL
);
ALTER TABLE public.test_config ENABLE ROW LEVEL SECURITY;

-- 2. Override public.now()
CREATE OR REPLACE FUNCTION public.now()
RETURNS timestamptz
LANGUAGE sql
STABLE
AS $$
  SELECT pg_catalog.now() + COALESCE(
    (SELECT value::interval FROM public.test_config WHERE key = 'time_offset'),
    interval '0'
  );
$$;

-- 3. Helper: set mock time to a specific timestamp
CREATE OR REPLACE FUNCTION public.test_set_now(target timestamptz)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $$
  INSERT INTO public.test_config (key, value)
  VALUES ('time_offset', (target - pg_catalog.now())::text)
  ON CONFLICT (key) DO UPDATE SET value = (target - pg_catalog.now())::text;
$$;

-- 4. Helper: clear mock time
CREATE OR REPLACE FUNCTION public.test_clear_now()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $$
  DELETE FROM public.test_config WHERE key = 'time_offset';
$$;

-- 5. Helper: get current server time (for Flutter AppClock sync)
CREATE OR REPLACE FUNCTION public.get_server_now()
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $$
  SELECT public.now();
$$;

-- ============================================================
-- 6. Update SECURITY DEFINER functions search_path
-- ============================================================

ALTER FUNCTION public.apply_paid_order(uuid, text, integer, integer, text, text, jsonb)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.cancel_booking_and_refund_ticket(uuid)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.chat_fetch_timeline_page(uuid, timestamptz, integer, text, integer)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.chat_mark_joined(uuid)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.chat_send_message(uuid, text)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.create_booking_and_consume_ticket(uuid)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.handle_new_user()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.update_focused_study_plan(uuid, text, boolean)
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.run_move_events_to_history()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.run_auto_seed_for_events_two_days_out()
  SET search_path = 'public', 'pg_catalog';

-- ============================================================
-- 7. Update trigger functions search_path
-- ============================================================

ALTER FUNCTION public.handle_event_status_notified()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.set_updated_at()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.sync_users_university_after_verified()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.set_event_signup_times()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.set_group_times()
  SET search_path = 'public', 'pg_catalog';

ALTER FUNCTION public.gen_merchant_trade_no()
  SET search_path = 'public', 'pg_catalog';

-- ============================================================
-- 8. Update role search_paths for views and RLS
-- ============================================================

ALTER ROLE authenticator SET search_path = 'public', 'pg_catalog';
ALTER ROLE authenticated SET search_path = 'public', 'pg_catalog';
ALTER ROLE anon SET search_path = 'public', 'pg_catalog';
ALTER ROLE service_role SET search_path = 'public', 'pg_catalog';
