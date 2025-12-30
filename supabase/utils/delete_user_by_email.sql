-- =====================================================
-- Delete Specific User by Email
-- =====================================================
-- This script deletes a specific user and all their related data
-- Replace 'user@example.com' with the actual email address
-- =====================================================

DO $$
DECLARE
  target_email TEXT := 'user@example.com'; -- ⚠️ CHANGE THIS EMAIL
  target_auth_user_id UUID;
  target_alumnus_id UUID;
BEGIN
  RAISE NOTICE '🔍 Looking for user with email: %', target_email;

  -- Find the auth user ID
  SELECT id INTO target_auth_user_id
  FROM auth.users
  WHERE email = target_email;

  IF target_auth_user_id IS NULL THEN
    RAISE NOTICE '❌ No user found with email: %', target_email;
    RETURN;
  END IF;

  RAISE NOTICE '📧 Found auth user: % (ID: %)', target_email, target_auth_user_id;

  -- Find the alumnus ID
  SELECT id INTO target_alumnus_id
  FROM alumni
  WHERE auth_user_id = target_auth_user_id;

  IF target_alumnus_id IS NULL THEN
    RAISE NOTICE '⚠️  No alumnus profile found, but will delete auth user';
  ELSE
    RAISE NOTICE '👤 Found alumnus profile: %', target_alumnus_id;

    -- Delete message read receipts for this user
    DELETE FROM message_read_receipts WHERE alumnus_id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted message read receipts';

    -- Delete messages sent by this user
    DELETE FROM messages WHERE sender_id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted messages sent by user';

    -- Delete messages in conversations where user is a member
    DELETE FROM messages
    WHERE conversation_id IN (
      SELECT conversation_id
      FROM conversation_members
      WHERE alumnus_id = target_alumnus_id
    );
    RAISE NOTICE '✅ Deleted messages in user conversations';

    -- Delete conversation members
    DELETE FROM conversation_members WHERE alumnus_id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted conversation memberships';

    -- Delete empty conversations (conversations with no members left)
    DELETE FROM conversations WHERE id IN (
      SELECT id FROM conversations c
      WHERE NOT EXISTS (
        SELECT 1 FROM conversation_members cm
        WHERE cm.conversation_id = c.id
      )
    );
    RAISE NOTICE '✅ Deleted empty conversations';

    -- Delete location history
    DELETE FROM location_history WHERE alumnus_id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted location history';

    -- Delete user preferences
    DELETE FROM user_preferences WHERE alumnus_id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted user preferences';

    -- Delete alumnus record
    DELETE FROM alumni WHERE id = target_alumnus_id;
    RAISE NOTICE '✅ Deleted alumnus profile';
  END IF;

  -- Delete auth user
  DELETE FROM auth.users WHERE id = target_auth_user_id;
  RAISE NOTICE '✅ Deleted auth user';

  RAISE NOTICE '🎉 Successfully deleted user: %', target_email;
END $$;

-- INSTRUCTIONS:
-- 1. Find line 10: target_email TEXT := 'user@example.com';
-- 2. Replace 'user@example.com' with the actual email address
-- 3. Copy the entire script
-- 4. Go to your Supabase project dashboard
-- 5. Navigate to SQL Editor
-- 6. Paste the script
-- 7. Review the email is correct
-- 8. Click "Run" to execute

-- Example:
-- target_email TEXT := 'john.doe@example.com';
