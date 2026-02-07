-- Create fb_data_deletion_requests table
-- Tracks Facebook data deletion callback requests for compliance

CREATE TABLE IF NOT EXISTS public.fb_data_deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fb_user_id text NOT NULL,
  user_id uuid REFERENCES public.users(id),
  confirmation_code text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for lookup
CREATE INDEX IF NOT EXISTS idx_fb_data_deletion_requests_fb_user_id
  ON public.fb_data_deletion_requests (fb_user_id);

CREATE INDEX IF NOT EXISTS idx_fb_data_deletion_requests_confirmation_code
  ON public.fb_data_deletion_requests (confirmation_code);

-- Enable RLS (service_role bypasses)
ALTER TABLE public.fb_data_deletion_requests ENABLE ROW LEVEL SECURITY;
