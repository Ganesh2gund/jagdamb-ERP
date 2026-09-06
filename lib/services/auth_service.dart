import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'api_client.dart';

/// Authentication result model
class AuthResult {
  final bool success;
  final String? error;
  final String? userEmail;

  const AuthResult({required this.success, this.error, this.userEmail});
}

/// Abstract auth service interface — ready to swap with Fastify implementation
abstract class AuthService {
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getCurrentUserEmail();
}

/// Mock auth service using fixed credentials and SharedPreferences
class MockAuthService implements AuthService {
  static const String _validEmail = AppConstants.adminEmail;
  static const String _validPassword = AppConstants.adminPassword;

  @override
  Future<AuthResult> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.trim().toLowerCase() == _validEmail.toLowerCase() &&
        password == _validPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyAdminEmail, email);
      return AuthResult(success: true, userEmail: email);
    }

    return const AuthResult(
      success: false,
      error: 'Invalid email or password',
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyAdminEmail);
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAdminEmail);
  }
}

/// Real Fastify HTTP auth service with automatic fallback to mock
class HttpAuthService implements AuthService {
  final MockAuthService _mock = MockAuthService();

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await ApiClient.instance.post('/auth/login', body: {
        'email': email.trim(),
        'password': password.trim(),
      });

      if (response is Map && response['success'] == true) {
        final token = response['token']?.toString();
        if (token != null) {
          await ApiClient.instance.setToken(token);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyIsLoggedIn, true);
        await prefs.setString(AppConstants.keyAdminEmail, email.trim());
        return AuthResult(success: true, userEmail: email.trim());
      } else {
        final errorMsg = response is Map ? response['message']?.toString() : 'Login failed';
        return AuthResult(success: false, error: errorMsg ?? 'Invalid credentials');
      }
    } catch (_) {
      // If Fastify is offline, fallback to mock credentials
      return _mock.login(email, password);
    }
  }

  @override
  Future<void> logout() async {
    await ApiClient.instance.clearToken();
    await _mock.logout();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _mock.isLoggedIn();
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    return _mock.getCurrentUserEmail();
  }
}

