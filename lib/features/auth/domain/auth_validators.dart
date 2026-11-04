class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'emailRequired';
    if (!RegExp(
          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+$",
        ).hasMatch(email) ||
        email.length > 254 ||
        email.split('@').first.length > 64 ||
        email.startsWith('.') ||
        email.contains('..') ||
        email.contains('.@') ||
        !RegExp(r'\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'emailInvalid';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 6) return 'passwordTooShort';
    if (password.length > 128) return 'passwordTooLong';
    if (!RegExp(r'[A-ZА-ЯЁӘҒҚҢӨҰҮҺІ]').hasMatch(password)) {
      return 'passwordNeedsUppercase';
    }
    if (RegExp(r'\s').hasMatch(password)) return 'passwordHasSpaces';
    return null;
  }
}
