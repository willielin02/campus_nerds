-- ============================================================
-- 客服工單系統
-- ============================================================

-- 1. support_tickets
CREATE TABLE public.support_tickets (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  category text NOT NULL CHECK (category IN ('school_verification', 'payment', 'bug_report', 'other')),
  subject text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz NOT NULL DEFAULT public.now(),
  updated_at timestamptz NOT NULL DEFAULT public.now(),
  resolved_at timestamptz
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tickets"
  ON public.support_tickets FOR SELECT
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can create own tickets"
  ON public.support_tickets FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own tickets"
  ON public.support_tickets FOR UPDATE
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Service role full access on support_tickets"
  ON public.support_tickets FOR ALL
  USING (auth.role() = 'service_role');

-- 2. support_messages
CREATE TABLE public.support_messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_type text NOT NULL CHECK (sender_type IN ('user', 'admin')),
  sender_id uuid NOT NULL REFERENCES auth.users(id),
  content text,
  image_path text,
  created_at timestamptz NOT NULL DEFAULT public.now()
);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ticket messages"
  ON public.support_messages FOR SELECT
  USING (
    ticket_id IN (
      SELECT id FROM public.support_tickets WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can insert messages to own tickets"
  ON public.support_messages FOR INSERT
  WITH CHECK (
    sender_type = 'user'
    AND sender_id = (SELECT auth.uid())
    AND ticket_id IN (
      SELECT id FROM public.support_tickets WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Service role full access on support_messages"
  ON public.support_messages FOR ALL
  USING (auth.role() = 'service_role');

-- 3. Triggers
CREATE OR REPLACE FUNCTION public.trg_support_ticket_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  NEW.updated_at := public.now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.trg_support_ticket_updated_at();

CREATE OR REPLACE FUNCTION public.trg_support_message_touch_ticket()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  UPDATE public.support_tickets
  SET updated_at = public.now()
  WHERE id = NEW.ticket_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_support_messages_touch_ticket
  AFTER INSERT ON public.support_messages
  FOR EACH ROW EXECUTE FUNCTION public.trg_support_message_touch_ticket();

-- 4. Storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('support-attachments', 'support-attachments', false);

-- 5. Storage RLS
CREATE POLICY "Users upload own support attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'support-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY "Users read own support attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'support-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY "Service role full access on support attachments"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'support-attachments'
    AND auth.role() = 'service_role'
  );

-- 6. Indexes
CREATE INDEX idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX idx_support_tickets_category ON public.support_tickets(category);
CREATE INDEX idx_support_messages_ticket_id ON public.support_messages(ticket_id);
