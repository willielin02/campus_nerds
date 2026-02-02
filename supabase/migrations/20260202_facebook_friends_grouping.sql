-- ============================================================================
-- Facebook Friends Grouping Logic for Campus Nerds
-- ============================================================================
-- This migration adds functions for:
-- 1. Getting a user's Facebook friends (for group matching)
-- 2. Checking if two users are Facebook friends
-- 3. Validating groups don't contain Facebook friend pairs
-- 4. Updates handle_group_status_scheduled to check Facebook friends
-- 5. Updates auto_seed_groups_for_event to avoid Facebook friends
-- ============================================================================

-- ============================================================================
-- 1. Helper function: Get user's Facebook friends
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_facebook_friends(p_user_id UUID)
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN ARRAY(
    SELECT CASE
      WHEN f.user_low_id = p_user_id THEN f.user_high_id
      ELSE f.user_low_id
    END
    FROM friendships f
    WHERE f.user_low_id = p_user_id OR f.user_high_id = p_user_id
  );
END;
$$;

-- ============================================================================
-- 2. Helper function: Check if two users are Facebook friends
-- ============================================================================
CREATE OR REPLACE FUNCTION are_facebook_friends(p_user_a UUID, p_user_b UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
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
    SELECT 1 FROM friendships
    WHERE user_low_id = v_user_low_id AND user_high_id = v_user_high_id
  );
END;
$$;

-- ============================================================================
-- 3. Function: Check if a group contains any Facebook friend pairs
-- Returns the problematic user pairs if found
-- ============================================================================
CREATE OR REPLACE FUNCTION check_group_for_facebook_friends(p_group_id UUID)
RETURNS TABLE(user_a_id UUID, user_b_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    LEAST(gm1.user_id, gm2.user_id) as user_a_id,
    GREATEST(gm1.user_id, gm2.user_id) as user_b_id
  FROM group_members gm1
  JOIN group_members gm2 ON gm1.group_id = gm2.group_id AND gm1.user_id < gm2.user_id
  JOIN friendships f ON (
    (f.user_low_id = LEAST(gm1.user_id, gm2.user_id) AND f.user_high_id = GREATEST(gm1.user_id, gm2.user_id))
  )
  WHERE gm1.group_id = p_group_id
    AND gm1.left_at IS NULL
    AND gm2.left_at IS NULL;
END;
$$;

-- ============================================================================
-- 4. Helper function: Check if user has any Facebook friends in a group
-- ============================================================================
CREATE OR REPLACE FUNCTION has_facebook_friend_in_group(p_user_id UUID, p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_friend_ids UUID[];
BEGIN
  -- Get user's Facebook friends
  v_friend_ids := get_user_facebook_friends(p_user_id);

  -- Check if any friend is in the group
  RETURN EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = p_group_id
      AND gm.left_at IS NULL
      AND gm.user_id = ANY(COALESCE(v_friend_ids, ARRAY[]::UUID[]))
  );
END;
$$;

-- ============================================================================
-- 5. Updated trigger function: Validate group on status change to 'scheduled'
-- Now includes Facebook friends validation
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_group_status_scheduled()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_member_count INT;
  v_gender_counts RECORD;
  v_fb_conflicts RECORD;
  v_errors TEXT[] := ARRAY[]::TEXT[];
BEGIN
  -- Only validate when status changes to 'scheduled'
  IF NEW.status = 'scheduled' AND (OLD.status IS NULL OR OLD.status != 'scheduled') THEN

    -- Check 1: Member count equals max_size
    SELECT COUNT(*) INTO v_member_count
    FROM group_members gm
    WHERE gm.group_id = NEW.id AND gm.left_at IS NULL;

    IF v_member_count != NEW.max_size THEN
      v_errors := v_errors || format('人數不正確: 期望 %s 人，實際 %s 人', NEW.max_size, v_member_count);
    END IF;

    -- Check 2: Gender ratio is 1:1 (assuming max_size is even)
    SELECT
      COUNT(*) FILTER (WHERE u.gender = 'male') as male_count,
      COUNT(*) FILTER (WHERE u.gender = 'female') as female_count
    INTO v_gender_counts
    FROM group_members gm
    JOIN users u ON u.id = gm.user_id
    WHERE gm.group_id = NEW.id AND gm.left_at IS NULL;

    IF v_gender_counts.male_count != v_gender_counts.female_count THEN
      v_errors := v_errors || format('性別比例不正確: 男 %s 人，女 %s 人', v_gender_counts.male_count, v_gender_counts.female_count);
    END IF;

    -- Check 3: venue_id is not NULL
    IF NEW.venue_id IS NULL THEN
      v_errors := v_errors || '場地 (venue_id) 未設定';
    END IF;

    -- Check 4: chat_open_at is not NULL
    IF NEW.chat_open_at IS NULL THEN
      v_errors := v_errors || '聊天開啟時間 (chat_open_at) 未設定';
    END IF;

    -- Check 5: goal_close_at is not NULL
    IF NEW.goal_close_at IS NULL THEN
      v_errors := v_errors || '目標截止時間 (goal_close_at) 未設定';
    END IF;

    -- Check 6: feedback_sent_at is not NULL (existing check from original function)
    -- Note: This might be set later, uncomment if needed
    -- IF NEW.feedback_sent_at IS NULL THEN
    --   v_errors := v_errors || '回饋發送時間 (feedback_sent_at) 未設定';
    -- END IF;

    -- Check 7: No Facebook friends in the same group (NEW)
    FOR v_fb_conflicts IN
      SELECT * FROM check_group_for_facebook_friends(NEW.id)
    LOOP
      v_errors := v_errors || format('臉書好友衝突: 用戶 %s 和 %s 是臉書好友', v_fb_conflicts.user_a_id, v_fb_conflicts.user_b_id);
    END LOOP;

    -- If there are any errors, raise exception to prevent the update
    IF array_length(v_errors, 1) > 0 THEN
      RAISE EXCEPTION '群組驗證失敗: %', array_to_string(v_errors, '; ');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Ensure trigger exists on groups table
DROP TRIGGER IF EXISTS validate_group_scheduled_trigger ON groups;
CREATE TRIGGER validate_group_scheduled_trigger
  BEFORE UPDATE ON groups
  FOR EACH ROW
  EXECUTE FUNCTION handle_group_status_scheduled();

-- ============================================================================
-- 6. Updated auto_seed_groups_for_event function
-- Now avoids placing Facebook friends in the same group
-- ============================================================================
CREATE OR REPLACE FUNCTION auto_seed_groups_for_event(
  p_event_id UUID,
  p_group_size INT DEFAULT 4
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event RECORD;
  v_male_users UUID[];
  v_female_users UUID[];
  v_male_idx INT := 1;
  v_female_idx INT := 1;
  v_group_id UUID;
  v_groups_created INT := 0;
  v_users_assigned INT := 0;
  v_half_size INT;
  v_current_male UUID;
  v_current_female UUID;
  v_group_males UUID[];
  v_group_females UUID[];
  v_male_friend_ids UUID[];
  v_female_friend_ids UUID[];
  v_skip_male BOOLEAN;
  v_skip_female BOOLEAN;
  v_attempts INT;
  v_max_attempts INT := 100;
BEGIN
  -- Calculate half size (number of each gender per group)
  v_half_size := p_group_size / 2;

  -- Get event
  SELECT * INTO v_event FROM events WHERE id = p_event_id;
  IF v_event IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Event not found');
  END IF;

  -- Get male users sorted by priority criteria
  -- Priority: not_grouped_count ASC, age ASC, academic_rank ASC, os ASC, performance_score DESC
  SELECT ARRAY_AGG(u.id ORDER BY
    COALESCE(u.not_grouped_count, 0) ASC,
    COALESCE(EXTRACT(YEAR FROM AGE(u.birthday)), 99) ASC,
    COALESCE(u.academic_rank, 99) ASC,
    CASE WHEN u.os = 'ios' THEN 0 ELSE 1 END ASC,
    COALESCE(u.performance_score, 0) DESC
  )
  INTO v_male_users
  FROM bookings b
  JOIN users u ON u.id = b.user_id
  WHERE b.event_id = p_event_id
    AND b.status = 'pending'
    AND u.gender = 'male';

  -- Get female users sorted by priority criteria
  SELECT ARRAY_AGG(u.id ORDER BY
    COALESCE(u.not_grouped_count, 0) ASC,
    COALESCE(EXTRACT(YEAR FROM AGE(u.birthday)), 99) ASC,
    COALESCE(u.academic_rank, 99) ASC,
    CASE WHEN u.os = 'ios' THEN 0 ELSE 1 END ASC,
    COALESCE(u.performance_score, 0) DESC
  )
  INTO v_female_users
  FROM bookings b
  JOIN users u ON u.id = b.user_id
  WHERE b.event_id = p_event_id
    AND b.status = 'pending'
    AND u.gender = 'female';

  -- Initialize arrays if null
  v_male_users := COALESCE(v_male_users, ARRAY[]::UUID[]);
  v_female_users := COALESCE(v_female_users, ARRAY[]::UUID[]);

  -- Create groups while we have enough users of both genders
  v_attempts := 0;
  WHILE v_male_idx <= array_length(v_male_users, 1) - v_half_size + 1
    AND v_female_idx <= array_length(v_female_users, 1) - v_half_size + 1
    AND v_attempts < v_max_attempts
  LOOP
    v_attempts := v_attempts + 1;
    v_group_males := ARRAY[]::UUID[];
    v_group_females := ARRAY[]::UUID[];

    -- Select males for this group, avoiding Facebook friends
    FOR i IN 1..v_half_size LOOP
      v_skip_male := TRUE;

      WHILE v_skip_male AND v_male_idx <= array_length(v_male_users, 1) LOOP
        v_current_male := v_male_users[v_male_idx];
        v_male_friend_ids := get_user_facebook_friends(v_current_male);

        -- Check if this male is friends with any already selected male
        v_skip_male := FALSE;
        IF array_length(v_group_males, 1) > 0 THEN
          FOR j IN 1..array_length(v_group_males, 1) LOOP
            IF v_group_males[j] = ANY(v_male_friend_ids) THEN
              v_skip_male := TRUE;
              EXIT;
            END IF;
          END LOOP;
        END IF;

        IF v_skip_male THEN
          v_male_idx := v_male_idx + 1;
        ELSE
          v_group_males := array_append(v_group_males, v_current_male);
          v_male_idx := v_male_idx + 1;
        END IF;
      END LOOP;
    END LOOP;

    -- If we couldn't get enough males, break
    IF array_length(v_group_males, 1) IS NULL OR array_length(v_group_males, 1) < v_half_size THEN
      EXIT;
    END IF;

    -- Collect all male friend IDs for checking females
    v_male_friend_ids := ARRAY[]::UUID[];
    FOR i IN 1..array_length(v_group_males, 1) LOOP
      v_male_friend_ids := v_male_friend_ids || get_user_facebook_friends(v_group_males[i]);
    END LOOP;

    -- Select females for this group, avoiding Facebook friends with selected males
    FOR i IN 1..v_half_size LOOP
      v_skip_female := TRUE;

      WHILE v_skip_female AND v_female_idx <= array_length(v_female_users, 1) LOOP
        v_current_female := v_female_users[v_female_idx];
        v_female_friend_ids := get_user_facebook_friends(v_current_female);

        -- Check if this female is friends with any selected male
        v_skip_female := FALSE;
        IF v_current_female = ANY(v_male_friend_ids) THEN
          v_skip_female := TRUE;
        END IF;

        -- Check if this female is friends with any already selected female
        IF NOT v_skip_female AND array_length(v_group_females, 1) > 0 THEN
          FOR j IN 1..array_length(v_group_females, 1) LOOP
            IF v_group_females[j] = ANY(v_female_friend_ids) THEN
              v_skip_female := TRUE;
              EXIT;
            END IF;
          END LOOP;
        END IF;

        IF v_skip_female THEN
          v_female_idx := v_female_idx + 1;
        ELSE
          v_group_females := array_append(v_group_females, v_current_female);
          v_female_idx := v_female_idx + 1;
        END IF;
      END LOOP;
    END LOOP;

    -- If we couldn't get enough females, break
    IF array_length(v_group_females, 1) IS NULL OR array_length(v_group_females, 1) < v_half_size THEN
      EXIT;
    END IF;

    -- Create the group
    INSERT INTO groups (event_id, max_size, status, created_at)
    VALUES (p_event_id, p_group_size, 'pending', NOW())
    RETURNING id INTO v_group_id;

    v_groups_created := v_groups_created + 1;

    -- Add males to group
    FOR i IN 1..array_length(v_group_males, 1) LOOP
      INSERT INTO group_members (group_id, user_id, event_id, booking_id, joined_at)
      SELECT v_group_id, v_group_males[i], p_event_id, b.id, NOW()
      FROM bookings b
      WHERE b.event_id = p_event_id AND b.user_id = v_group_males[i];

      -- Update booking status
      UPDATE bookings SET status = 'matched', updated_at = NOW()
      WHERE event_id = p_event_id AND user_id = v_group_males[i];

      v_users_assigned := v_users_assigned + 1;
    END LOOP;

    -- Add females to group
    FOR i IN 1..array_length(v_group_females, 1) LOOP
      INSERT INTO group_members (group_id, user_id, event_id, booking_id, joined_at)
      SELECT v_group_id, v_group_females[i], p_event_id, b.id, NOW()
      FROM bookings b
      WHERE b.event_id = p_event_id AND b.user_id = v_group_females[i];

      -- Update booking status
      UPDATE bookings SET status = 'matched', updated_at = NOW()
      WHERE event_id = p_event_id AND user_id = v_group_females[i];

      v_users_assigned := v_users_assigned + 1;
    END LOOP;
  END LOOP;

  -- Update not_grouped_count for users who weren't assigned
  UPDATE users SET not_grouped_count = COALESCE(not_grouped_count, 0) + 1
  WHERE id IN (
    SELECT b.user_id FROM bookings b
    WHERE b.event_id = p_event_id AND b.status = 'pending'
  );

  RETURN json_build_object(
    'success', true,
    'groups_created', v_groups_created,
    'users_assigned', v_users_assigned,
    'remaining_males', array_length(v_male_users, 1) - v_male_idx + 1,
    'remaining_females', array_length(v_female_users, 1) - v_female_idx + 1
  );
END;
$$;

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_user_facebook_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION are_facebook_friends(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_group_for_facebook_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION has_facebook_friend_in_group(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION auto_seed_groups_for_event(UUID, INT) TO service_role;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON FUNCTION get_user_facebook_friends IS 'Returns array of user IDs who are Facebook friends with the given user';
COMMENT ON FUNCTION are_facebook_friends IS 'Checks if two users are Facebook friends';
COMMENT ON FUNCTION check_group_for_facebook_friends IS 'Returns pairs of users in a group who are Facebook friends';
COMMENT ON FUNCTION has_facebook_friend_in_group IS 'Checks if a user has any Facebook friends in a specific group';
COMMENT ON FUNCTION handle_group_status_scheduled IS 'Trigger function that validates group constraints (including no Facebook friends) when status changes to scheduled';
COMMENT ON FUNCTION auto_seed_groups_for_event IS 'Auto-assigns pending bookings to groups while avoiding Facebook friends, maintaining gender balance';
