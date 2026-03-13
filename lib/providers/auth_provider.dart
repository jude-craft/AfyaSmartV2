import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth  _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn  _googleSignIn = GoogleSignIn();

  AuthStatus _status       = AuthStatus.initial;
  UserModel? _user;
  String?    _errorMessage;

  // ── Getters ──────────────────────────────────────────
  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading       => _status == AuthStatus.loading;
  bool get hasError        => _status == AuthStatus.error;

  AuthProvider() {
    _init();
  }

  // ── Listen to Firebase auth state changes ─────────────
  void _init() {
    _status = AuthStatus.loading;
    notifyListeners();

    _firebaseAuth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        _user   = _mapFirebaseUser(firebaseUser);
        _status = AuthStatus.authenticated;
      } else {
        _user   = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ── Google Sign In ────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      _setLoading();

      // 1. Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // 2. Get auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // 5. Map to our UserModel
      if (userCredential.user != null) {
        _user   = _mapFirebaseUser(userCredential.user!);
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
    } catch (e) {
      _setError('Sign in failed. Please try again.');
    }
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    try {
      _setLoading();
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _user   = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed. Please try again.');
    }
  }

  // ── Reload user (refresh profile data) ───────────────
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      final refreshed = _firebaseAuth.currentUser;
      if (refreshed != null) {
        _user = _mapFirebaseUser(refreshed);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Mappers ───────────────────────────────────────────
  UserModel _mapFirebaseUser(User firebaseUser) {
    return UserModel(
      id:        firebaseUser.uid,
      name:      firebaseUser.displayName ?? 'AfyaSmart User',
      email:     firebaseUser.email ?? '',
      photoUrl:  firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'account-exists-with-different-credential' =>
          'An account already exists with a different sign-in method.',
      'invalid-credential' =>
          'Invalid credentials. Please try again.',
      'user-disabled' =>
          'This account has been disabled. Contact support.',
      'user-not-found' =>
          'No account found. Please sign up first.',
      'network-request-failed' =>
          'Network error. Check your connection.',
      'sign_in_canceled' =>
          'Sign in was cancelled.',
      'sign_in_failed' =>
          'Sign in failed. Please try again.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  // ── Private helpers ───────────────────────────────────
  void _setLoading() {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status       = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}