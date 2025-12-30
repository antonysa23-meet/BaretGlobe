/// Supabase API Configuration
///
/// IMPORTANT: Replace these values with your actual Supabase project credentials
/// 1. Go to https://supabase.com/dashboard
/// 2. Select your project
/// 3. Go to Project Settings → API
/// 4. Copy the URL and anon public key
///
/// NOTE: For production, consider using environment variables or a secure secrets manager
class ApiConstants {
  ApiConstants._(); // Private constructor

  /// Supabase Project URL
  /// Get this from: Project Settings → API → Project URL
  ///
  /// Example: 'https://your-project-id.supabase.co'
  static const String supabaseUrl = 'https://sbxveinfnjshlffumcup.supabase.co';

  /// Supabase Anon Public Key
  /// Get this from: Project Settings → API → Project API keys → anon public
  ///
  /// This key is safe to use in client-side code as it's protected by RLS policies
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNieHZlaW5mbmpzaGxmZnVtY3VwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDg2MzQsImV4cCI6MjA4MjMyNDYzNH0.DDa9rrG4qgZgXF-aH0UAoSq6R3d77psi1mCwZE69zSQ';

  /// Realtime configuration
  static const bool enableRealtime = true;

  /// API timeout in seconds
  static const int apiTimeout = 30;

  // ==================
  // TABLE NAMES
  // ==================

  static const String alumniTable = 'alumni';
  static const String locationsTable = 'locations';
  static const String locationHistoryTable = 'location_history';

  // Messaging tables
  static const String conversationsTable = 'conversations';
  static const String conversationMembersTable = 'conversation_members';
  static const String messagesTable = 'messages';
  static const String messageReadReceiptsTable = 'message_read_receipts';

  // ==================
  // FUNCTIONS
  // ==================

  static const String getCurrentLocationsFunction = 'get_current_alumni_locations';
  static const String updateLocationFunction = 'update_alumnus_location';
  static const String canCheckInFunction = 'can_check_in';

  // Messaging functions
  static const String getOrCreateDirectConversationFunction = 'get_or_create_direct_conversation';
  static const String getUserConversationsFunction = 'get_user_conversations';
  static const String getUnreadCountFunction = 'get_unread_count';
  static const String getTotalUnreadCountFunction = 'get_total_unread_count';

  // ==================
  // RATE LIMITING
  // ==================

  /// Minimum hours between check-ins (enforced by database function)
  static const int minHoursBetweenCheckIns = 1;

  /// Background location update interval in minutes
  static const int backgroundUpdateIntervalMinutes = 30;

  /// Minimum distance change in meters to trigger update
  static const double minDistanceChangeMeters = 500;
}
