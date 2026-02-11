-- ============================================================================
-- Migration: Make cron jobs mock-time aware
-- ============================================================================
-- Problem: pg_cron uses PostgreSQL system clock for scheduling, ignoring
--          the mock time system (public.now() override). This means cron
--          jobs fire at real midnight, not mock midnight.
--
-- Solution: Change cron to run every minute. A wrapper function checks if
--           now() (which respects mock time) is at 00:00 Taipei time.
--           If yes, run the actual jobs. Cost: ~1 lightweight SQL check/min.
-- ============================================================================

-- 1. Create the wrapper function
CREATE OR REPLACE FUNCTION cron_midnight_taipei()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $$
DECLARE
  _taipei_time timestamptz;
  _hour int;
  _minute int;
BEGIN
  _taipei_time := now();
  _hour   := extract(hour   FROM _taipei_time AT TIME ZONE 'Asia/Taipei');
  _minute := extract(minute FROM _taipei_time AT TIME ZONE 'Asia/Taipei');

  -- Only execute at 00:00 Taipei time (first minute of the day)
  IF _hour = 0 AND _minute = 0 THEN
    -- Job 1: Move completed events to history
    PERFORM run_move_events_to_history();

    -- Job 2: Trigger auto-grouping Edge Function via pg_net
    PERFORM net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'supabase_url')
             || '/functions/v1/run-auto-grouping',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key')
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 300000
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION cron_midnight_taipei() IS
  'Wrapper for midnight cron jobs. Runs every minute via pg_cron but only '
  'executes at 00:00 Taipei time based on now() (mock-time aware).';

-- 2. Remove the two existing cron jobs
SELECT cron.unschedule('move_events_to_history_daily');
SELECT cron.unschedule('auto-seed-groups-two-days-out');

-- 3. Create one unified cron job running every minute
SELECT cron.schedule(
  'midnight-taipei-jobs',
  '* * * * *',
  $$SELECT cron_midnight_taipei();$$
);
