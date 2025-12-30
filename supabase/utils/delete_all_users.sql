-- =====================================================
-- Delete All Users and Related Data
-- =====================================================
-- WARNING: This script will permanently delete ALL user data
-- Use with extreme caution - preferably in development only!
-- =====================================================

DO $$
DECLARE
  messages_count INTEGER;
  read_receipts_count INTEGER;
  members_count INTEGER;
  conversations_count INTEGER;
  location_history_count INTEGER;
  preferences_count INTEGER;
  alumni_count INTEGER;
  auth_users_count INTEGER;
BEGIN
  RAISE NOTICE '⚠️  Starting deletion of ALL users and data...';

  -- 1. Delete all message read receipts
  SELECT COUNT(*) INTO read_receipts_count FROM message_read_receipts;
  DELETE FROM message_read_receipts;
  RAISE NOTICE '✅ Deleted % message read receipts', read_receipts_count;

  -- 2. Delete all messages
  SELECT COUNT(*) INTO messages_count FROM messages;
  DELETE FROM messages;
  RAISE NOTICE '✅ Deleted % messages', messages_count;

  -- 3. Delete all conversation members
  SELECT COUNT(*) INTO members_count FROM conversation_members;
  DELETE FROM conversation_members;
  RAISE NOTICE '✅ Deleted % conversation members', members_count;

  -- 4. Delete all conversations
  SELECT COUNT(*) INTO conversations_count FROM conversations;
  DELETE FROM conversations;
  RAISE NOTICE '✅ Deleted % conversations', conversations_count;

  -- 5. Delete all location history
  SELECT COUNT(*) INTO location_history_count FROM location_history;
  DELETE FROM location_history;
  RAISE NOTICE '✅ Deleted % location history records', location_history_count;

  -- 6. Delete all user preferences
  SELECT COUNT(*) INTO preferences_count FROM user_preferences;
  DELETE FROM user_preferences;
  RAISE NOTICE '✅ Deleted % user preferences', preferences_count;

  -- 7. Delete all alumni records
  SELECT COUNT(*) INTO alumni_count FROM alumni;
  DELETE FROM alumni;
  RAISE NOTICE '✅ Deleted % alumni records', alumni_count;

  -- 8. Delete all auth users
  SELECT COUNT(*) INTO auth_users_count FROM auth.users;
  DELETE FROM auth.users;
  RAISE NOTICE '✅ Deleted % auth users', auth_users_count;

  RAISE NOTICE '🎉 All user data deleted successfully!';
  RAISE NOTICE '📊 Summary: % messages, % read receipts, % members, % conversations, % location records, % preferences, % alumni, % auth users',
    messages_count, read_receipts_count, members_count, conversations_count, location_history_count, preferences_count, alumni_count, auth_users_count;
END $$;

-- To use this script:
-- 1. Copy the entire script
-- 2. Go to your Supabase project dashboard
-- 3. Navigate to SQL Editor
-- 4. Paste the script
-- 5. Review carefully before running (THIS DELETES EVERYTHING!)
-- 6. Click "Run" to execute
