-- ============================================================
-- 1. Add read_at and push_sent_at to in_app_notifications
-- ============================================================
ALTER TABLE public.in_app_notifications
  ADD COLUMN IF NOT EXISTS read_at timestamptz,
  ADD COLUMN IF NOT EXISTS push_sent_at timestamptz;

-- ============================================================
-- 2. Create device_tokens table for FCM push tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_select_own" ON public.device_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "device_tokens_insert_own" ON public.device_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_delete_own" ON public.device_tokens
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER trg_set_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 3. RPC: upsert_device_token
-- ============================================================
CREATE OR REPLACE FUNCTION public.upsert_device_token(
  p_token text,
  p_platform text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Remove this token from any OTHER user (handles account switching on same device)
  DELETE FROM public.device_tokens
  WHERE token = p_token
    AND user_id <> auth.uid();

  -- Upsert for the current user
  INSERT INTO public.device_tokens (user_id, token, platform)
  VALUES (auth.uid(), p_token, p_platform)
  ON CONFLICT (user_id, token)
  DO UPDATE SET
    platform = EXCLUDED.platform,
    updated_at = now();
END;
$$;

-- ============================================================
-- 4. RPC: remove_device_token
-- ============================================================
CREATE OR REPLACE FUNCTION public.remove_device_token(
  p_token text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  DELETE FROM public.device_tokens
  WHERE user_id = auth.uid() AND token = p_token;
END;
$$;

-- ============================================================
-- 5. RPC: get_unread_notifications
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_unread_notifications()
RETURNS TABLE (
  id uuid,
  event_id uuid,
  booking_id uuid,
  group_id uuid,
  type text,
  title text,
  body text,
  data jsonb,
  created_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT
    n.id,
    n.event_id,
    n.booking_id,
    n.group_id,
    n.type,
    n.title,
    n.body,
    n.data,
    n.created_at
  FROM public.in_app_notifications n
  WHERE n.user_id = auth.uid()
    AND n.read_at IS NULL
  ORDER BY n.created_at DESC;
$$;

-- ============================================================
-- 6. RPC: mark_notification_read
-- ============================================================
CREATE OR REPLACE FUNCTION public.mark_notification_read(
  p_notification_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  UPDATE public.in_app_notifications
  SET read_at = now()
  WHERE id = p_notification_id
    AND user_id = auth.uid()
    AND read_at IS NULL;
END;
$$;

-- ============================================================
-- 7. Add in_app_notifications to Realtime publication
-- ============================================================
ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY public.in_app_notifications;

-- ============================================================
-- 8. AFTER trigger: send push via Edge Function on event notified
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_push_on_event_notified()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_supabase_url  text;
  v_service_key   text;
BEGIN
  IF NEW.status <> 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;
  IF OLD.status = 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;

  SELECT decrypted_secret INTO v_supabase_url
  FROM vault.decrypted_secrets
  WHERE name = 'supabase_url';

  SELECT decrypted_secret INTO v_service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key';

  PERFORM net.http_post(
    url     := v_supabase_url || '/functions/v1/send-push-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body    := jsonb_build_object('event_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_push_on_event_notified
  AFTER UPDATE OF status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_push_on_event_notified();

-- ============================================================
-- 9. Update notification trigger to include category in data
-- ============================================================
CREATE OR REPLACE FUNCTION "public"."handle_event_status_notified"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_bad_groups integer;
  v_now        timestamptz;
BEGIN
  IF NEW.status <> 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.status = 'notified'::public.event_status THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.status <> 'scheduled'::public.event_status THEN
    RAISE EXCEPTION
      'events.status can only change to notified from scheduled (event=% old=% new=%)',
      NEW.id, OLD.status, NEW.status;
  END IF;

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

  INSERT INTO public.in_app_notifications (
    user_id, booking_id, event_id, group_id, type, title, body, data
  )
  SELECT
    b.user_id,
    b.id AS booking_id,
    b.event_id,
    gm.group_id,
    'event_group_result' AS type,
    CASE WHEN gm.group_id IS NULL
      THEN '這次活動沒有成團'
      ELSE '您的活動已成功分組'
    END AS title,
    CASE WHEN gm.group_id IS NULL
      THEN '很抱歉，本次活動未成團。立即報名下一場活動，您將獲得優先分組權利。'
      ELSE '已為您完成分組，快去查看您的分組吧！'
    END AS body,
    jsonb_build_object(
      'event_id',   b.event_id,
      'booking_id', b.id,
      'group_id',   gm.group_id,
      'is_grouped', gm.group_id IS NOT NULL,
      'category',   NEW.category::text
    ) AS data
  FROM public.bookings b
  LEFT JOIN LATERAL (
    SELECT gm.group_id
    FROM public.group_members gm
    WHERE gm.booking_id = b.id
      AND gm.left_at IS NULL
    ORDER BY gm.joined_at DESC NULLS LAST
    LIMIT 1
  ) gm ON true
  WHERE b.event_id = NEW.id
    AND b.status = 'active'::public.booking_status
  ON CONFLICT (event_id, booking_id, type) DO NOTHING;

  NEW.notify_sent_at := v_now;

  RETURN NEW;
END;
$$;
