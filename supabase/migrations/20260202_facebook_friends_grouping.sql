-- ============================================================================
-- Facebook Friends Grouping Logic for Campus Nerds
-- ============================================================================
-- This migration adds:
-- 1. Helper functions for Facebook friends checking
-- 2. Updates handle_group_status_scheduled to validate no Facebook friends
--
-- NOTE: auto_seed_groups_for_event is NOT modified. It creates groups as 'draft'
--       status, and staff will review. The Facebook friend check happens when
--       staff changes status to 'scheduled' via the trigger.
-- ============================================================================

-- ============================================================================
-- 1. Helper function: Get user's Facebook friends
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_facebook_friends(p_user_id UUID)
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN ARRAY(
    SELECT CASE
      WHEN f.user_low_id = p_user_id THEN f.user_high_id
      ELSE f.user_low_id
    END
    FROM public.friendships f
    WHERE f.user_low_id = p_user_id OR f.user_high_id = p_user_id
  );
END;
$$;

-- ============================================================================
-- 2. Helper function: Check if two users are Facebook friends
-- ============================================================================
CREATE OR REPLACE FUNCTION public.are_facebook_friends(p_user_a UUID, p_user_b UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_user_low_id UUID;
  v_user_high_id UUID;
BEGIN
  -- Normalize the pair (lower id first)
  IF p_user_a < p_user_b THEN
    v_user_low_id := p_user_a;
    v_user_high_id := p_user_b;
  ELSE
    v_user_low_id := p_user_b;
    v_user_high_id := p_user_a;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.friendships
    WHERE user_low_id = v_user_low_id AND user_high_id = v_user_high_id
  );
END;
$$;

-- ============================================================================
-- 3. Function: Check if a group contains any Facebook friend pairs
-- Returns the problematic user pairs if found
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_group_for_facebook_friends(p_group_id UUID)
RETURNS TABLE(user_a_id UUID, user_b_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    LEAST(gm1.user_id, gm2.user_id) as user_a_id,
    GREATEST(gm1.user_id, gm2.user_id) as user_b_id
  FROM public.group_members gm1
  JOIN public.group_members gm2
    ON gm1.group_id = gm2.group_id AND gm1.user_id < gm2.user_id
  JOIN public.friendships f
    ON f.user_low_id = LEAST(gm1.user_id, gm2.user_id)
    AND f.user_high_id = GREATEST(gm1.user_id, gm2.user_id)
  WHERE gm1.group_id = p_group_id
    AND gm1.left_at IS NULL
    AND gm2.left_at IS NULL;
END;
$$;

-- ============================================================================
-- 4. Helper function: Check if user has any Facebook friends in a group
-- ============================================================================
CREATE OR REPLACE FUNCTION public.has_facebook_friend_in_group(p_user_id UUID, p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_friend_ids UUID[];
BEGIN
  -- Get user's Facebook friends
  v_friend_ids := public.get_user_facebook_friends(p_user_id);

  -- Check if any friend is in the group
  RETURN EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = p_group_id
      AND gm.left_at IS NULL
      AND gm.user_id = ANY(COALESCE(v_friend_ids, ARRAY[]::UUID[]))
  );
END;
$$;

-- ============================================================================
-- 5. Updated trigger function: Validate group on status change to 'scheduled'
-- PRESERVES ALL ORIGINAL LOGIC + adds Facebook friends check
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_group_status_scheduled()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_member_count  integer;
  v_male_count    integer;
  v_female_count  integer;
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
  -- 2. 性別必須 1:1（目前 gender enum 只有 male / female）
  --------------------------------------------------------------------
  IF NEW.max_size % 2 <> 0 THEN
    RAISE EXCEPTION
      'group % max_size % is not even; cannot enforce 1:1 gender',
      NEW.id, NEW.max_size;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE up.gender = 'male')   AS male_count,
    COUNT(*) FILTER (WHERE up.gender = 'female') AS female_count
  INTO v_male_count, v_female_count
  FROM public.group_members gm
  JOIN public.bookings b
    ON b.id = gm.booking_id
  JOIN public.user_profile_v up
    ON up.id = b.user_id
  WHERE gm.group_id = NEW.id
    AND gm.left_at IS NULL;

  IF v_male_count <> v_female_count
     OR v_male_count + v_female_count <> NEW.max_size THEN
    RAISE EXCEPTION
      'group % gender ratio must be 1:1, got male=% female=% total=%',
      NEW.id, v_male_count, v_female_count, NEW.max_size;
  END IF;

  --------------------------------------------------------------------
  -- 3. 場地與時間欄位不得為 NULL
  --    （venue_id 其實已有另一顆 BEFORE trigger 在檢查，但這裡再保險一次）
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
  -- 4. 檢查群組中是否有臉書好友（NEW - Facebook friends check）
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

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.get_user_facebook_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.are_facebook_friends(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_group_for_facebook_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_facebook_friend_in_group(UUID, UUID) TO authenticated;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON FUNCTION public.get_user_facebook_friends IS 'Returns array of user IDs who are Facebook friends with the given user';
COMMENT ON FUNCTION public.are_facebook_friends IS 'Checks if two users are Facebook friends';
COMMENT ON FUNCTION public.check_group_for_facebook_friends IS 'Returns pairs of users in a group who are Facebook friends';
COMMENT ON FUNCTION public.has_facebook_friend_in_group IS 'Checks if a user has any Facebook friends in a specific group';
COMMENT ON FUNCTION public.handle_group_status_scheduled IS 'Trigger function that validates group constraints (including no Facebook friends) when status changes to scheduled';
