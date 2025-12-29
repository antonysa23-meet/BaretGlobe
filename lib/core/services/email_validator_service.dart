/// Service for validating email domains and formats
class EmailValidatorService {
  EmailValidatorService._();

  /// The required email domain for Baret Scholars
  static const String requiredDomain = '@baretscholars.org';

  /// Validates if an email belongs to the @baretscholars.org domain
  ///
  /// Returns true if the email ends with @baretscholars.org (case-insensitive)
  static bool isValidBaretScholarsEmail(String email) {
    if (email.isEmpty) return false;

    // Convert to lowercase for case-insensitive comparison
    final emailLower = email.toLowerCase().trim();

    // Check if email ends with the required domain
    return emailLower.endsWith(requiredDomain.toLowerCase());
  }

  /// Validates basic email format (contains @ and .)
  ///
  /// This is a simple validation. More thorough validation happens on the backend.
  static bool isValidEmailFormat(String email) {
    if (email.isEmpty) return false;

    // Basic regex for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Comprehensive email validation for Baret Scholars
  ///
  /// Checks both format and domain requirements
  /// Returns a ValidationResult with details
  static EmailValidationResult validate(String email) {
    // Check if email is empty
    if (email.isEmpty) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'Email cannot be empty',
      );
    }

    // Check basic email format
    if (!isValidEmailFormat(email)) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid email address',
      );
    }

    // Check domain requirement
    if (!isValidBaretScholarsEmail(email)) {
      return EmailValidationResult(
        isValid: false,
        errorMessage:
            'Only @baretscholars.org email addresses are allowed.\n\nPlease sign in with your Baret Scholars email.',
      );
    }

    // All validations passed
    return EmailValidationResult(
      isValid: true,
      errorMessage: null,
    );
  }

  /// Extract the username part from an email (before the @)
  static String? extractUsername(String email) {
    if (!isValidEmailFormat(email)) return null;

    final parts = email.trim().split('@');
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Get a user-friendly error message for OAuth failures
  static String getOAuthErrorMessage(String? error) {
    if (error == null) {
      return 'An unknown error occurred during sign-in';
    }

    final errorLower = error.toLowerCase();

    if (errorLower.contains('cancel')) {
      return 'Sign-in was cancelled';
    } else if (errorLower.contains('network')) {
      return 'Network error. Please check your internet connection';
    } else {
      // Return the full error message so we can see what Supabase is saying
      return error;
    }
  }
}

/// Result of email validation
class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;

  EmailValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
