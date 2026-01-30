/// Domain validation utilities for school email verification
///
/// Used to validate that email addresses belong to supported universities.
class DomainValidators {
  /// Extract the base domain from an email address
  ///
  /// Handles Taiwan university email formats like:
  /// - gs.ncku.edu.tw -> ncku.edu.tw
  /// - mail.ntu.edu.tw -> ntu.edu.tw
  /// - student.mit.edu -> mit.edu
  static String extractBaseDomain(String email) {
    if (!email.contains('@')) return '';

    final domain = email.split('@').last.toLowerCase();
    final parts = domain.split('.');

    if (domain.endsWith('.edu.tw')) {
      // Taiwan university domains: gs.ncku.edu.tw -> ncku.edu.tw
      if (parts.length >= 3) {
        return parts.sublist(parts.length - 3).join('.');
      } else {
        return domain;
      }
    } else {
      // Other domains: take last two parts (e.g., mit.edu)
      if (parts.length >= 2) {
        return parts.sublist(parts.length - 2).join('.');
      } else {
        return domain;
      }
    }
  }

  /// Check if an email domain is in the allowed domains list
  ///
  /// Returns true if:
  /// - Email domain exactly matches an allowed domain
  /// - Email domain ends with an allowed domain (subdomain support)
  ///
  /// Example:
  /// - email: "student@gs.ncku.edu.tw"
  /// - allowedDomains: ["ncku.edu.tw"]
  /// - Returns: true (because gs.ncku.edu.tw ends with .ncku.edu.tw)
  static bool isEmailDomainAllowed(String email, List<String> allowedDomains) {
    final cleanedEmail = email.trim().toLowerCase();
    final parts = cleanedEmail.split('@');

    if (parts.length != 2) {
      return false;
    }

    final emailDomain = parts[1];

    for (final rawDomain in allowedDomains) {
      final domain = rawDomain.trim().toLowerCase();
      if (domain.isEmpty) continue;

      if (emailDomain == domain || emailDomain.endsWith('.$domain')) {
        return true;
      }
    }

    return false;
  }
}
