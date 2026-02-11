-- Relax group validation: allow odd max_size and non-1:1 gender ratio
-- The trigger still validates: member count = max_size, venue/timing set, no FB friends
-- Gender ratio and even max_size are now handled by admin UI warnings only

CREATE OR REPLACE FUNCTION public.handle_group_status_scheduled()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_member_count  integer;
  v_category      public.event_category;
  v_fb_conflict   RECORD;
BEGIN
  -- 只在變成 scheduled 的那一刻處理
  IF NEW.status <> 'scheduled'::public.group_status THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.status = 'scheduled'::public.group_status THEN
    RETURN NEW;
  END IF;

  --------------------------------------------------------------------
  -- 1. 人數必須剛好等於 max_size（只算 still in group 的人）
  --------------------------------------------------------------------
  SELECT count(*)
  INTO v_member_count
  FROM public.group_members gm
  WHERE gm.group_id = NEW.id
    AND gm.left_at IS NULL;

  IF v_member_count <> NEW.max_size THEN
    RAISE EXCEPTION
      'group % is not full: members=%, max_size=%',
      NEW.id, v_member_count, NEW.max_size;
  END IF;

  --------------------------------------------------------------------
  -- 2. (已移除) 性別比與偶數 max_size 檢查
  --    改由後台 UI 以警告方式提示，管理員可執意放行
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  -- 3. 場地與時間欄位不得為 NULL
  --------------------------------------------------------------------
  IF NEW.venue_id IS NULL THEN
    RAISE EXCEPTION 'groups.venue_id is required when status = scheduled (group=%)', NEW.id;
  END IF;

  IF NEW.chat_open_at IS NULL
     OR NEW.goal_close_at IS NULL
     OR NEW.feedback_sent_at IS NULL THEN
    RAISE EXCEPTION
      'group % times must be set when status = scheduled (chat_open_at / goal_close_at / feedback_sent_at)',
      NEW.id;
  END IF;

  --------------------------------------------------------------------
  -- 4. 檢查群組中是否有臉書好友
  --------------------------------------------------------------------
  FOR v_fb_conflict IN
    SELECT * FROM public.check_group_for_facebook_friends(NEW.id)
  LOOP
    RAISE EXCEPTION
      'group % contains Facebook friends: user % and user % are friends',
      NEW.id, v_fb_conflict.user_a_id, v_fb_conflict.user_b_id;
  END LOOP;

  --------------------------------------------------------------------
  -- 5. 依活動類型建立學習內容 / 題目
  --------------------------------------------------------------------
  SELECT e.category
  INTO v_category
  FROM public.events e
  WHERE e.id = NEW.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event % for group % not found', NEW.event_id, NEW.id;
  END IF;

  IF v_category = 'focused_study'::public.event_category THEN
    PERFORM public.create_focused_study_plans_for_group(NEW.id);
  ELSIF v_category = 'english_games'::public.event_category THEN
    PERFORM public.assign_english_contents_for_group(NEW.id);
  ELSE
    RAISE EXCEPTION 'unsupported event_category % for group %', v_category, NEW.id;
  END IF;

  RETURN NEW;
END;
$$;
