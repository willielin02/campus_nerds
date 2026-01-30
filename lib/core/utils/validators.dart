/// Form validation utilities
class Validators {
  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入電子郵件';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return '請輸入有效的電子郵件格式';
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '請輸入$fieldName' : '此欄位為必填';
    }
    return null;
  }

  /// Validate nickname (max 12 characters)
  static String? nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入暱稱';
    }
    if (value.length > 12) {
      return '暱稱不得超過 12 個字元';
    }
    return null;
  }

  /// Validate verification code (6 digits)
  static String? verificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入驗證碼';
    }
    if (value.length != 6) {
      return '驗證碼應為 6 位數字';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return '驗證碼只能包含數字';
    }
    return null;
  }

  /// Validate birthday (must be 18+ years old)
  static String? birthday(DateTime? value) {
    if (value == null) {
      return '請選擇生日';
    }

    final now = DateTime.now();
    final age = now.year -
        value.year -
        (now.month < value.month ||
                (now.month == value.month && now.day < value.day)
            ? 1
            : 0);

    if (age < 18) {
      return '您必須年滿 18 歲才能使用本服務';
    }

    return null;
  }

  /// Validate phone number (Taiwan format)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入手機號碼';
    }

    // Taiwan mobile: 09XXXXXXXX
    final phoneRegex = RegExp(r'^09\d{8}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
      return '請輸入有效的台灣手機號碼';
    }

    return null;
  }
}
