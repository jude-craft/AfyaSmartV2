import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String?   _errorMessage;

  // ── Getters ──────────────────────────────────────────
  AuthStatus get status        => _status;
  UserModel? get user          => _user;
  String?    get errorMessage  => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading       => _status == AuthStatus.loading;
  bool get hasError        => _status == AuthStatus.error;

  AuthProvider() {
    _checkAuthState();
  }

  // ── Check persisted session ───────────────────────────
  Future<void> _checkAuthState() async {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    // TODO: restore session from SharedPreferences when backend is ready
  }

  // ── Google Sign In (UI stub) ──────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      _setLoading();

      // Simulate network delay — replace with real Google Sign-In later
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful user
      _user = UserModel(
        id:        'mock_uid_001',
        name:      'Derick Jude',
        email:     'jude.dev@gmail.com',
        photoUrl:  null,
        createdAt: DateTime.now(),
      );

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Sign in failed. Please try again.');
    }
  }

  // ── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}