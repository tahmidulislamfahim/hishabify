import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AuthStatus {
  success,
  failed,
  noCredentials,
  notAvailable,
}

class AuthResult {
  final AuthStatus status;
  final String? message;

  const AuthResult({required this.status, this.message});

  bool get isSuccess => status == AuthStatus.success;
  bool get isNoCredentials => status == AuthStatus.noCredentials;
}

class AppLockService {
  static final AppLockService instance = AppLockService._();
  final LocalAuthentication _auth = LocalAuthentication();

  AppLockService._();

  static Future<bool> authenticate({String reason = 'Confirm your screen lock PIN, Pattern or Password'}) async {
    final result = await instance._doAuthenticate(reason: reason);
    return result.isSuccess;
  }

  static Future<AuthResult> authenticateDetailed({
    String reason = 'Confirm your screen lock PIN, Pattern or Password',
  }) =>
      instance._doAuthenticate(reason: reason);

  static Future<bool> checkBiometrics() => instance.canCheckBiometrics();

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> _doAuthenticate({
    String reason = 'Confirm your screen lock PIN, Pattern or Password',
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) {
        return const AuthResult(
          status: AuthStatus.notAvailable,
          message: 'Screen lock or biometric authentication is not supported on this device',
        );
      }
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        return const AuthResult(status: AuthStatus.success);
      } else {
        return const AuthResult(status: AuthStatus.failed, message: 'Authentication cancelled');
      }
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('nocredentials') ||
          code.contains('passcodenotset') ||
          code.contains('notenrolled')) {
        return const AuthResult(
          status: AuthStatus.noCredentials,
          message: 'No screen lock credentials set on this device',
        );
      }
      return AuthResult(status: AuthStatus.failed, message: e.message ?? 'Authentication failed');
    } catch (e) {
      final errString = e.toString().toLowerCase();
      String errCode = '';
      try {
        errCode = (e as dynamic).code?.toString().toLowerCase() ?? '';
      } catch (_) {}

      if (errCode.contains('nocredentials') ||
          errCode.contains('passcodenotset') ||
          errCode.contains('notenrolled') ||
          errString.contains('nocredentialsset') ||
          errString.contains('passcodenotset') ||
          errString.contains('notenrolled')) {
        return const AuthResult(
          status: AuthStatus.noCredentials,
          message: 'No screen lock credentials set on this device',
        );
      }
      return const AuthResult(status: AuthStatus.failed, message: 'Authentication failed');
    }
  }
}
