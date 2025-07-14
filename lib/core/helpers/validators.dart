class Validators {
  // Email validation
  static String? validateEMAIL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  // Username validation (email or username)
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kullanıcı adı veya e-posta gerekli';
    }

    if (value.trim().length < 3) {
      return 'En az 3 karakter olmalı';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 4) {
      return 'Şifre en az 4 karakter olmalı';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }
    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove spaces and special characters
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanPhone.length < 10) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }

  // Domain validation
  static String? validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Domain gerekli';
    }

    // Basic domain validation
    if (!value.contains('.')) {
      return 'Geçerli bir domain girin (örn: company.com)';
    }

    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bu alan'} gerekli';
    }

    if (double.tryParse(value) == null) {
      return 'Sadece sayı giriniz';
    }

    return null;
  }

  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL gerekli';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&=]*)$'
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL girin';
    }

    return null;
  }
}