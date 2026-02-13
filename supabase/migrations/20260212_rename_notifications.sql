-- Rename in_app_notifications → notifications
ALTER TABLE public.in_app_notifications RENAME TO notifications;

ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_pkey TO notifications_pkey;
ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_event_booking_type_unique TO notifications_event_booking_type_unique;
ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_booking_id_fkey TO notifications_booking_id_fkey;
ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_event_id_fkey TO notifications_event_id_fkey;
ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_group_id_fkey TO notifications_group_id_fkey;
ALTER TABLE public.notifications
  RENAME CONSTRAINT in_app_notifications_user_id_fkey TO notifications_user_id_fkey;

ALTER POLICY in_app_notifications_select_own ON public.notifications
  RENAME TO notifications_select_own;

-- Update Realtime publication
ALTER PUBLICATION "supabase_realtime" DROP TABLE public.notifications;
ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY public.notifications;
