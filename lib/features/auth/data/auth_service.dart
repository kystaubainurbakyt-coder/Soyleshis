import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soyle/features/auth/domain/auth_validators.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

/// Device-local accounts. Passwords are salted PBKDF2 hashes, never plaintext.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'soyle.accounts.v1';
  static const _sessionKey = 'soyle.auth.session.v1';
  bool _busy = false;
  final Map<String, int> _attempts = {};
  final Map<String, DateTime> _lockedUntil = {};
  static String normalize(String email) => email.trim().toLowerCase();

  Future<void> saveSession(String email) =>
      _storage.write(key: _sessionKey, value: normalize(email));

  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Future<Map<String, dynamic>?> restoreSession() async {
    final email = await _storage.read(key: _sessionKey);
    if (email == null || email.isEmpty) return null;
    final account = (await _accounts())[normalize(email)];
    if (account is! Map) {
      await clearSession();
      return null;
    }
    return {'name': account['name'] as String, 'email': normalize(email)};
  }

  Future<Map<String, dynamic>> _accounts() async {
    final raw = await _storage.read(key: _key);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<String> _hash(String password, List<int> salt) =>
      compute(_derivePassword, {'password': password, 'salt': salt});
  void _validate(String email, String password) {
    final error =
        AuthValidators.email(email) ?? AuthValidators.password(password);
    if (error != null) throw AuthException(error);
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    if (_busy) throw const AuthException('pleaseWait');
    _validate(email, password);
    if (name.trim().length < 2) {
      throw const AuthException('nameTooShort');
    }
    _busy = true;
    try {
      final accounts = await _accounts();
      final address = normalize(email);
      if (accounts.containsKey(address)) {
        throw const AuthException('emailAlreadyRegistered');
      }
      final random = Random.secure();
      final salt = List<int>.generate(16, (_) => random.nextInt(256));
      final account = <String, dynamic>{
        'name': name.trim(),
        'email': address,
        'salt': base64Encode(salt),
        'hash': await _hash(password, salt),
      };
      accounts[address] = account;
      await _storage.write(key: _key, value: jsonEncode(accounts));
      return account;
    } finally {
      _busy = false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_busy) throw const AuthException('pleaseWait');
    _validate(email, password);
    final address = normalize(email);
    final until = _lockedUntil[address];
    if (until != null && DateTime.now().isBefore(until)) {
      throw const AuthException('tooManyLoginAttempts');
    }
    _busy = true;
    try {
      final account = (await _accounts())[address] as Map<String, dynamic>?;
      // Derive even for unknown accounts, so a failed request does comparable work.
      final actual = await _hash(
        password,
        account == null
            ? List<int>.filled(16, 0)
            : base64Decode(account['salt'] as String),
      );
      final expected =
          account?['hash'] as String? ?? base64Encode(List<int>.filled(32, 0));
      final a = base64Decode(actual), b = base64Decode(expected);
      var difference = a.length ^ b.length;
      for (var i = 0; i < a.length && i < b.length; i++) {
        difference |= a[i] ^ b[i];
      }
      if (account == null || difference != 0) {
        final count = (_attempts[address] ?? 0) + 1;
        _attempts[address] = count;
        if (count >= 5) {
          _lockedUntil[address] = DateTime.now().add(
            const Duration(seconds: 30),
          );
          _attempts[address] = 0;
        }
        throw const AuthException('invalidCredentials');
      }
      _attempts.remove(address);
      _lockedUntil.remove(address);
      return account;
    } finally {
      _busy = false;
    }
  }
}

Future<String> _derivePassword(Map<String, Object> input) async {
  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );
  final key = await algorithm.deriveKeyFromPassword(
    password: input['password'] as String,
    nonce: input['salt'] as List<int>,
  );
  return base64Encode(await key.extractBytes());
}
