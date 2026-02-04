-- ============================================================================
-- Fix fb_friend_sync_attempts table schema
-- ============================================================================
-- Issue: Edge Function tries to insert columns that don't exist
--   - friends_count (integer)
--   - raw_response (jsonb)
--
-- Solution: Add a JSONB column for flexible logging data
-- Reference: https://elephas.io/audit-logging-using-jsonb-in-postgres/
--
-- Best Practice: Use JSONB for audit/logging tables because:
--   1. Flexible schema - no migrations needed when adding new fields
--   2. Can store any structured data (counts, API responses, metadata)
--   3. Queryable with PostgreSQL JSONB operators
-- ============================================================================

-- Add friends_count column for successful sync stats
ALTER TABLE public.fb_friend_sync_attempts
ADD COLUMN IF NOT EXISTS friends_count integer;

COMMENT ON COLUMN public.fb_friend_sync_attempts.friends_count IS
'Number of friendships created/updated during sync. Only set on successful syncs.';

-- Add raw_response JSONB column for flexible logging
ALTER TABLE public.fb_friend_sync_attempts
ADD COLUMN IF NOT EXISTS raw_response jsonb;

COMMENT ON COLUMN public.fb_friend_sync_attempts.raw_response IS
'Raw response data from Facebook API or detailed sync results.
Flexible JSONB allows storing varying data structures without schema changes.
Example success: {"total_fb_friends": 150, "matched_app_users": 5, "inserted_friendships": 3}
Example error: {"message": "Invalid token", "type": "OAuthException", "code": 190}';

-- Create index on raw_response for efficient querying (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_fb_sync_attempts_raw_response
ON public.fb_friend_sync_attempts USING GIN (raw_response);

-- ============================================================================
-- Verify the Edge Function column usage matches the table
-- ============================================================================
-- Edge Function (sync-facebook-friends/index.ts) inserts:
--   ✅ user_id      - exists
--   ✅ status       - exists
--   ✅ error_message - exists
--   ✅ friends_count - NOW EXISTS (added above)
--   ✅ raw_response  - NOW EXISTS (added above)
-- ============================================================================
