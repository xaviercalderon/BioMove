// lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../api/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _auth   = FirebaseAuth.instance;
  final _google = GoogleSignIn(scopes: ['email', 'profile']);
  final _api    = ApiClient();

  AuthStatus _status  = AuthStatus.unknown;
  UserModel? _user;
  String?    _error;
  bool       _loading = false;

  AuthStatus  get status          => _status;
  UserModel?  get user            => _user;
  String?     get error           => _error;
  bool        get loading         => _loading;
  bool        get isAuth          => _status == AuthStatus.authenticated;
  String      get displayName     => _user?.displayName ?? _auth.currentUser?.displayName ?? 'Usuario';
  String      get photoUrl        => _user?.photoUrl    ?? _auth.currentUser?.photoURL    ?? '';
  bool        get isAdmin         => _user?.isAdmin     ?? false;
  bool        get isCoach         => _user?.isCoach     ?? false;
  bool        get isAthlete       => _user?.isAthlete   ?? true;
  bool        get onboardingDone  => _user?.onboardingDone  ?? false;
  bool        get hasPhysicalData => _user?.hasPhysicalData ?? false;
  String      get role            => _user?.role ?? 'athlete';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? fb) async {
    if (fb == null) {
      _status = AuthStatus.unauthenticated;
      _user   = null;
    } else {
      _status = AuthStatus.authenticated;
      await _loadProfile();
    }
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      _user = await _api.getMe();
    } catch (_) {
      final fb = _auth.currentUser;
      if (fb != null) _user = UserModel(id: fb.uid, email: fb.email ?? '',
          displayName: fb.displayName ?? 'Usuario', photoUrl: fb.photoURL);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final gUser = await _google.signIn();
      if (gUser == null) { _setLoading(false); return false; }
      final gAuth      = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      await _auth.signInWithCredential(credential);
      _setLoading(false); return true;
    } catch (e) { _setError(_friendly(e)); return false; }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false); return true;
    } catch (e) { _setError(_friendly(e)); return false; }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user!.updateDisplayName(name);
      _setLoading(false); return true;
    } catch (e) { _setError(_friendly(e)); return false; }
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
    _user = null;
  }

  Future<bool> savePhysicalData({required double h, required double w,
      required int age, required String sex, required double years}) async {
    try {
      await _api.savePhysicalData(heightCm: h, weightKg: w, age: age, sex: sex, trainingYears: years);
      await refreshProfile(); return true;
    } catch (e) { _setError('Error: $e'); return false; }
  }

  Future<void> refreshProfile() async { await _loadProfile(); notifyListeners(); }
  void _setLoading(bool v) { _loading = v; _error = null; notifyListeners(); }
  void _setError(String m)  { _error = m; _loading = false; notifyListeners(); }
  void clearError()          { _error = null; notifyListeners(); }

  String _friendly(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':         return 'No existe cuenta con ese email';
        case 'wrong-password':         return 'Contraseña incorrecta';
        case 'email-already-in-use':   return 'Ese email ya está registrado';
        case 'weak-password':          return 'Contraseña muy débil (mín. 6 caracteres)';
        case 'network-request-failed': return 'Sin conexión a internet';
        default: return e.message ?? 'Error de autenticación';
      }
    }
    if (e.toString().contains('PlatformException'))
      return 'Error con Google Sign-In. Verifica el SHA-1 en Firebase Console.';
    return 'Error inesperado. Inténtalo de nuevo.';
  }
}
