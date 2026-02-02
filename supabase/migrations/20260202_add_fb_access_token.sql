-- ============================================================================
-- Add Facebook access token storage for background sync
-- ============================================================================
-- This migration adds:
-- 1. fb_access_token column to users table (for long-lived tokens)
-- 2. The token is optional - users can choose not to store it
-- 3. Used by run-auto-grouping Edge Function for background sync
-- ============================================================================

-- Add column for storing Facebook long-lived access token
-- Note: In production, consider encrypting this value
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS fb_access_token TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.users.fb_access_token IS 'Facebook long-lived access token for background friend sync. Optional - user must consent.';

-- Ensure RLS policies don't expose the token to other users
-- The token column should only be readable by the user themselves or service role

-- Update RLS policy for users table if needed
-- (Assuming RLS is already set up, we just need to ensure fb_access_token is not exposed)

-- Create a secure view that excludes the token for general queries
CREATE OR REPLACE VIEW public.user_public_profile_v AS
SELECT
  id,
  gender,
  birthday,
  nickname,
  fb_user_id,
  fb_connected_at,
  fb_last_sync_at,
  fb_last_sync_status,
  os,
  created_at,
  updated_at
  -- NOTE: fb_access_token is intentionally excluded
FROM public.users;

COMMENT ON VIEW public.user_public_profile_v IS 'Public user profile view that excludes sensitive data like fb_access_token';

-- Grant access to the view
GRANT SELECT ON public.user_public_profile_v TO authenticated;
GRANT SELECT ON public.user_public_profile_v TO anon;
