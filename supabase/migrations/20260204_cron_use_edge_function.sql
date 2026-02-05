-- ============================================================================
-- Migration: Update cron job to use Edge Function for auto-grouping
-- ============================================================================
-- This migration:
-- 1. Enables pg_net extension for HTTP calls from SQL
-- 2. Updates the cron job to call run-auto-grouping Edge Function
--
-- Why: The Edge Function syncs Facebook friends BEFORE auto-grouping,
--      ensuring the latest friend relationships are used for grouping.
-- ============================================================================

-- 1. Enable pg_net extension (creates 'net' schema automatically)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. First, unschedule the old cron job
SELECT cron.unschedule('auto-seed-groups-two-days-out');

-- 3. Create new cron job that calls the Edge Function via pg_net
-- Schedule: 0 16 * * * (16:00 UTC = 00:00 台北時間)
SELECT cron.schedule(
  'auto-seed-groups-two-days-out',
  '0 16 * * *',
  $$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'supabase_url') || '/functions/v1/run-auto-grouping',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 300000  -- 5 minute timeout
  ) AS request_id;
  $$
);

-- ============================================================================
-- IMPORTANT: You must add these secrets to vault for the cron job to work!
-- Run these commands manually in SQL Editor with your actual values:
-- ============================================================================
-- SELECT vault.create_secret('https://lzafwlmznlkvmbdxcxop.supabase.co', 'supabase_url');
-- SELECT vault.create_secret('YOUR_SERVICE_ROLE_KEY', 'service_role_key');
-- ============================================================================

COMMENT ON EXTENSION pg_net IS 'Async HTTP - used to call Edge Functions from cron jobs';
