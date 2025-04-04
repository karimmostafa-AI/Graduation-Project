class Validators {
  // Username validation: Arabic, max 20 characters
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال اسم المستخدم';
    }

    final arabicRegex = RegExp(r'^[\u0600-\u06FF\s]+$');
    if (!arabicRegex.hasMatch(value)) {
      return 'الرجاء إدخال اسم المستخدم باللغة العربية فقط';
    }

    if (value.length > 20) {
      return 'اسم المستخدم يجب أن يكون أقل من ٢٠ حرف';
    }
    
    return null;
  }

  // National ID validation: 14 digits
  static String? validateNationalId(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الرقم القومي';
    }

    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return 'الرقم القومي يجب أن يتكون من أرقام فقط';
    }

    if (value.length != 14) {
      return 'الرقم القومي يجب أن يتكون من ١٤ رقم';
    }
    
    return null;
  }

  // Password validation: min 8 chars with at least one number
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }

    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون على الأقل ٨ أحرف';
    }

    final containsNumberRegex = RegExp(r'[0-9]');
    if (!containsNumberRegex.hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على الأقل رقم واحد';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }

    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    
    return null;
  }

  // Phone validation: 11 digits, starting with 01
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return 'رقم الهاتف يجب أن يتكون من أرقام فقط';
    }

    if (value.length != 11) {
      return 'رقم الهاتف يجب أن يتكون من ١١ رقم';
    }

    if (!value.startsWith('01')) {
      return 'رقم الهاتف يجب أن يبدأ بـ ٠١';
    }
    
    return null;
  }
}