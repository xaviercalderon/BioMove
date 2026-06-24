// viewmodel/auth_viewmodel.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../repository/user_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final _repo = UserRepository();

  AuthStatus _status  = AuthStatus.unknown;
  UserModel? _user;
  String?    _error;
  bool       _loading = false;

  static const _skipGuideKey  = 'skip_prerecord_guide';
  // FIX: clave nueva para persistir onboarding entre sesiones
  static const _onboardingKey = 'onboarding_done_local';

  AuthStatus   get status          => _status;
  UserModel?   get user            => _user;
  String?      get error           => _error;
  bool         get loading         => _loading;
  bool         get isAuth          => _status == AuthStatus.authenticated;
  String       get displayName {
    // Prioridad: 1) nombre Firebase (nombre real) 2) display_name del backend 3) email sin @
    final fbName = _repo.currentFirebaseUser?.displayName;
    if (fbName != null && fbName.isNotEmpty && fbName != 'Usuario') return fbName;
    final n = _user?.displayName;
    if (n != null && n.isNotEmpty && n != 'Usuario' && n != 'Atleta' && !n.contains('@')) return n;
    final email = _user?.email ?? _repo.currentFirebaseUser?.email ?? '';
    if (email.contains('@')) {
      // Capitalizar primera letra del nombre antes del @
      final local = email.split('@').first;
      return local.isNotEmpty ? '${local[0].toUpperCase()}${local.substring(1)}' : 'Atleta';
    }
    return 'Atleta';
  }
  String       get photoUrl        => _user?.photoUrl ?? _repo.currentFirebaseUser?.photoURL ?? '';
  String?      get currentEmail    => _user?.email ?? _repo.currentFirebaseUser?.email;
  bool         get isAdmin         => _user?.isAdmin   ?? false;
  bool         get isCoach         => _user?.isCoach   ?? false;
  bool         get isAthlete       => _user?.isAthlete ?? true;
  bool         get onboardingDone  => _user?.onboardingDone ?? false;
  bool         get hasPhysicalData => _user?.hasPhysicalData ?? false;
  String       get role            => _user?.role ?? 'athlete';

  AuthViewModel() {
    _repo.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(dynamic fb) async {
    if (fb == null) {
      _status = AuthStatus.unauthenticated;
      _user   = null;
      notifyListeners();
      return;
    }

    // FIX BUG 1 — SESIÓN SIEMPRE EN LOGIN:
    // El código anterior hacía _status = AuthStatus.authenticated ANTES de
    // cargar el perfil. El router recibía authenticated + onboardingDone=false
    // (porque _user era null) y mandaba a /onboarding aunque ya estuviera hecho.
    // Solución: mantener unknown hasta tener el perfil cargado.
    _status = AuthStatus.unknown;
    notifyListeners();

    await _waitForToken();
    // Timeout de seguridad: si el backend no responde en 8s, entrar igual
    // usando el caché local para no quedar atascado en la pantalla de inicio.
    try {
      await _loadProfile().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Backend no respondió: construir usuario mínimo desde Firebase + caché local
      if (_user == null) {
        final fb = _repo.currentFirebaseUser;
        if (fb != null) {
          final prefs = await SharedPreferences.getInstance();
          final localDone = prefs.getBool(_onboardingKey) ?? false;
          _user = UserModel(
            id: fb.uid,
            email: fb.email ?? '',
            displayName: fb.displayName ?? (fb.email?.split('@').first ?? 'Atleta'),
            photoUrl: fb.photoURL,
            onboardingDone: localDone,
          );
        }
      }
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _waitForToken() async {
    for (int i = 0; i < 10; i++) {
      try {
        // FIX: i > 0 → solo forzar refresh en reintentos, no siempre.
        // getIdToken(true) en cada intento causa throttling en Firebase.
        final token = await FirebaseAuth.instance.currentUser?.getIdToken(i > 0);
        if (token != null && token.isNotEmpty) return;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _loadProfile() async {
    try {
      _user = await _repo.getProfile();
      // Caché: guardar timestamp para arranque rápido
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setInt('profile_cached_at', DateTime.now().millisecondsSinceEpoch);

      // FIX BUG 2 — DATOS FÍSICOS SE PIDEN SIEMPRE (parte 1):
      // Si el backend confirma onboarding=true, guardarlo en local
      // para que sobreviva reinicios aunque el backend falle
      if (_user?.onboardingDone == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingKey, true);
      }

      // FIX: Si backend devuelve onboarding=false pero local dice true,
      // usar el valor local. Esto pasa cuando hay timing issues en el
      // GET /users/me justo después del POST /physical-data
      if (_user != null && !_user!.onboardingDone) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(_onboardingKey) ?? false) {
          _user = _rebuildUser(_user!, onboardingDone: true);
        }
      }
    } catch (e) {
      // Si el backend no responde, construir user mínimo desde Firebase
      // y recuperar onboarding del caché local para no bloquear al usuario
      final fb = _repo.currentFirebaseUser;
      if (fb != null) {
        final prefs = await SharedPreferences.getInstance();
        final localDone = prefs.getBool(_onboardingKey) ?? false;
        _user = UserModel(
          id: fb.uid,
          email: fb.email ?? '',
          displayName: fb.displayName ?? 'Usuario',
          photoUrl: fb.photoURL,
          onboardingDone: localDone,
        );
      }
    }
  }

  // ── Sign in / Register ────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _repo.signInWithGoogle();
      if (result == null) { _setLoading(false); return false; }
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _repo.register(email, password, name);
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  /// Verifica si el email actual está verificado (refresca desde Firebase).
  Future<bool> checkEmailVerified() async {
    return await _repo.reloadAndCheckVerified();
  }

  bool get isEmailVerified => _repo.isEmailVerified;

  /// Reenviar correo de verificación.
  Future<void> sendVerificationEmail() async {
    _setLoading(true);
    try {
      await _repo.sendVerificationEmail();
      _setLoading(false);
    } catch (e) { _setError(_repo.friendlyError(e)); }
  }

  /// Recuperar contraseña por email.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _repo.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  /// Cambiar contraseña desde perfil (requiere contraseña actual).
  Future<bool> changePassword(String currentPass, String newPass) async {
    _setLoading(true);
    try {
      await _repo.changePassword(currentPass, newPass);
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  Future<void> signOut() async {
    // FIX: NO borrar _onboardingKey al cerrar sesión.
    // El usuario ya completó el onboarding — no pedírselo de nuevo al volver.
    await _repo.signOut();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Datos físicos ─────────────────────────────────────────────────────────

  Future<bool> savePhysicalData({
    required double h, required double w,
    required int age, required String sex, required double years,
  }) async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await _repo.savePhysicalData(h: h, w: w, age: age, sex: sex, years: years);

      // FIX BUG 2 — DATOS FÍSICOS SE PIDEN SIEMPRE (parte 2):
      // El código anterior solo hacía refreshProfile() que llama GET /users/me.
      // Si ese GET tenía cualquier problema de timing, onboardingDone seguía
      // siendo false y el router mandaba a /onboarding otra vez.
      // Solución: guardar en SharedPreferences PRIMERO, luego actualizar _user
      // en memoria de inmediato sin esperar al backend.

      // 1. Persistir en local — esto es lo que importa para el router
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);

      // 2. Actualizar _user en memoria inmediatamente
      if (_user != null) {
        _user = _rebuildUser(
          _user!,
          heightCm: h, weightKg: w, age: age, sex: sex,
          trainingYears: years,
          onboardingDone: true,
          hasPhysicalData: true,
        );
        notifyListeners();
      }

      // 3. Refrescar desde backend (opcional, no bloqueante)
      try { await refreshProfile(); } catch (_) {}

      return true;
    } catch (e) {
      _setError('Error al guardar: ${_repo.friendlyError(e)}');
      return false;
    }
  }

  // ── Coach / roles ─────────────────────────────────────────────────────────

  Future<bool> becomeCoach() async {
    _setLoading(true);
    try {
      await _repo.becomeCoach();
      await refreshProfile();
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  Future<bool> linkCoachCode(String code) async {
    _setLoading(true);
    try {
      await _repo.linkWithCode(code);
      await refreshProfile();
      _setLoading(false);
      return true;
    } catch (e) { _setError(_repo.friendlyError(e)); return false; }
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _repo.getProfile();
      // Sincronizar onboarding local al refrescar también
      if (_user?.onboardingDone == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingKey, true);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Pre-record guide ──────────────────────────────────────────────────────

  Future<bool> shouldShowPreRecordGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_skipGuideKey) ?? false);
  }

  Future<void> neverShowPreRecordGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipGuideKey, true);
  }

  // ── Utilidad interna ──────────────────────────────────────────────────────
  // UserModel no tiene copyWith — lo reconstruimos manualmente.

  UserModel _rebuildUser(
    UserModel base, {
    double? heightCm, double? weightKg, int? age, String? sex,
    double? trainingYears, bool? onboardingDone, bool? hasPhysicalData,
  }) {
    return UserModel(
      id: base.id,
      firebaseUid: base.firebaseUid,
      email: base.email,
      displayName: base.displayName,
      photoUrl: base.photoUrl,
      role: base.role,
      heightCm: heightCm ?? base.heightCm,
      weightKg: weightKg ?? base.weightKg,
      age: age ?? base.age,
      sex: sex ?? base.sex,
      trainingYears: trainingYears ?? base.trainingYears,
      onboardingDone: onboardingDone ?? base.onboardingDone,
      hasPhysicalData: hasPhysicalData ?? base.hasPhysicalData,
      features: base.features,
    );
  }

  void _setLoading(bool v) { _loading = v; _error = null; notifyListeners(); }
  void _setError(String m)  { _error = m; _loading = false; notifyListeners(); }
  void clearError()          { _error = null; notifyListeners(); }
}
