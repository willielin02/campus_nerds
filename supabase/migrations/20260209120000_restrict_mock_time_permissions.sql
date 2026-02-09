-- Restrict test_set_now and test_clear_now to service_role only
-- (Supabase SQL Editor and admin dashboard use service_role)
-- This prevents any authenticated/anonymous user from manipulating server time

REVOKE EXECUTE ON FUNCTION public.test_set_now(timestamptz) FROM public;
REVOKE EXECUTE ON FUNCTION public.test_set_now(timestamptz) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.test_set_now(timestamptz) FROM anon;

REVOKE EXECUTE ON FUNCTION public.test_clear_now() FROM public;
REVOKE EXECUTE ON FUNCTION public.test_clear_now() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.test_clear_now() FROM anon;
