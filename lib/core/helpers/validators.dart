class Validators {
  /// ✅ GENERIC: Required field validation - UNIFIED
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} zorunludur';
    }
    return null;
  }

  /// ✅ GENERIC: Email validation - UNIFIED
  static String? validateEmail(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'E-posta'} zorunludur';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '${fieldName ?? 'E-posta'} geçerli bir e-posta adresi olmalıdır';
    }

    return null;
  }

  /// ✅ Legacy email validator for backward compatibility
  static String? validateEMAIL(String? value) {
    return validateEmail(value, fieldName: 'E-posta');
  }

  /// ✅ GENERIC: Username validation - UNIFIED
  static String? validateUsername(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Kullanıcı adı'} zorunludur';
    }

    if (value.trim().length < 3) {
      return '${fieldName ?? 'Kullanıcı adı'} en az 3 karakter olmalıdır';
    }

    return null;
  }

  /// ✅ GENERIC: Password validation - UNIFIED
  static String? validatePassword(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Şifre'} zorunludur';
    }

    if (value.length < 4) {
      return '${fieldName ?? 'Şifre'} en az 4 karakter olmalıdır';
    }

    return null;
  }

  /// ✅ GENERIC: Phone validation - UNIFIED
  static String? validatePhone(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Telefon'} zorunludur';
    }

    // Remove spaces and formatting
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

    // Turkish phone number validation (10 or 11 digits)
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return '${fieldName ?? 'Telefon'} geçerli bir telefon numarası olmalıdır';
    }

    return null;
  }

  /// ✅ GENERIC: Domain validation - UNIFIED
  static String? validateDomain(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Domain'} zorunludur';
    }

    // Basic domain validation
    if (!value.contains('.')) {
      return '${fieldName ?? 'Domain'} geçerli bir domain olmalıdır (örn: company.com)';
    }

    return null;
  }

  /// ✅ GENERIC: Number validation - UNIFIED
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Sayı'} zorunludur';
    }

    if (double.tryParse(value.trim()) == null) {
      return '${fieldName ?? 'Sayı'} geçerli bir sayı olmalıdır';
    }

    return null;
  }

  /// ✅ Legacy numeric validator for backward compatibility
  static String? validateNumeric(String? value, {String? fieldName}) {
    return validateNumber(value, fieldName: fieldName);
  }

  /// ✅ GENERIC: URL validation - UNIFIED
  static String? validateUrl(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Web adresi'} zorunludur';
    }

    final urlRegex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');

    if (!urlRegex.hasMatch(value.trim())) {
      return '${fieldName ?? 'Web adresi'} geçerli bir web adresi olmalıdır (örn: https://ornek.com)';
    }

    return null;
  }

  /// ✅ Legacy URL validator for backward compatibility
  static String? validateURL(String? value) {
    return validateUrl(value, fieldName: 'URL');
  }

  /// ✅ GENERIC: Length validation
  static String? validateLength(
    String? value, {
    String? fieldName,
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} zorunludur';
    }

    final length = value.trim().length;

    if (minLength != null && length < minLength) {
      return '${fieldName ?? 'Bu alan'} en az $minLength karakter olmalıdır';
    }

    if (maxLength != null && length > maxLength) {
      return '${fieldName ?? 'Bu alan'} en fazla $maxLength karakter olmalıdır';
    }

    return null;
  }

  /// ✅ GENERIC: Turkish Tax Number validation
  static String? validateTaxNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Vergi numarası'} zorunludur';
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s\-]+'), '');

    if (cleanValue.length != 10) {
      return '${fieldName ?? 'Vergi numarası'} 10 haneli olmalıdır';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return '${fieldName ?? 'Vergi numarası'} sadece rakam içermelidir';
    }

    return null;
  }

  /// ✅ GENERIC: IBAN validation
  static String? validateIban(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'IBAN'} zorunludur';
    }

    final cleanIban = value.replaceAll(RegExp(r'[\s]+'), '').toUpperCase();

    if (!cleanIban.startsWith('TR')) {
      return '${fieldName ?? 'IBAN'} TR ile başlamalıdır';
    }

    if (cleanIban.length != 26) {
      return '${fieldName ?? 'IBAN'} 26 karakter olmalıdır';
    }

    return null;
  }

  /// ✅ GENERIC: Multi-purpose field validator - MAIN VALIDATOR
  static String? validateField(
    String? value, {
    required String fieldName,
    required String fieldKey,
    bool isRequired = false,
  }) {
    // Required check
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '$fieldName zorunludur';
    }

    // If empty and not required, skip validation
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final keyLower = fieldKey.toLowerCase();
    final fieldLower = fieldName.toLowerCase();

    // Email validation
    if (keyLower.contains('email') ||
        keyLower.contains('mail') ||
        fieldLower.contains('email') ||
        fieldLower.contains('mail') ||
        fieldLower.contains('e-posta')) {
      return validateEmail(value, fieldName: fieldName);
    }

    // Phone validation
    if (keyLower.contains('phone') || keyLower.contains('tel') || fieldLower.contains('telefon') || fieldLower.contains('phone')) {
      return validatePhone(value, fieldName: fieldName);
    }

    // URL validation
    if (keyLower.contains('web') || keyLower.contains('url') || fieldLower.contains('web') || fieldLower.contains('site')) {
      return validateUrl(value, fieldName: fieldName);
    }

    // Domain validation
    if (keyLower.contains('domain') || fieldLower.contains('domain')) {
      return validateDomain(value, fieldName: fieldName);
    }

    // Tax number validation
    if (keyLower.contains('tax') || keyLower.contains('vergi')) {
      return validateTaxNumber(value, fieldName: fieldName);
    }

    // IBAN validation
    if (keyLower.contains('iban')) {
      return validateIban(value, fieldName: fieldName);
    }

    // Number validation
    if (keyLower.contains('amount') ||
        keyLower.contains('price') ||
        keyLower.contains('tutar') ||
        fieldLower.contains('tutar') ||
        fieldLower.contains('fiyat') ||
        fieldLower.contains('miktar')) {
      return validateNumber(value, fieldName: fieldName);
    }

    return null; // No specific validation needed
  }
}
