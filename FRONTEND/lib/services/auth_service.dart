// services/auth_service.dart — Servicio de autenticación Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _auth   = FirebaseAuth.instance;
  final _google = GoogleSignIn(scopes: ['email', 'profile']);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential?> signInWithGoogle() async {
    final gUser = await _google.signIn();
    if (gUser == null) return null;
    final gAuth      = await gUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken, idToken: gAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);
    await cred.user!.sendEmailVerification(); // ← enviar verificación automáticamente
    return cred;
  }

  /// Reenviar correo de verificación al usuario actual.
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Refrescar el estado del usuario y retornar si el email está verificado.
  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Enviar correo para recuperar contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Cambiar contraseña: re-autentica con la contraseña actual y luego cambia.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    final credential = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  String friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':            return 'No existe cuenta con ese email';
        case 'wrong-password':            return 'Contraseña incorrecta';
        case 'invalid-credential':        return 'Email o contraseña incorrectos';
        case 'email-already-in-use':      return 'Ese email ya está registrado';
        case 'weak-password':             return 'Contraseña muy débil';
        case 'invalid-email':             return 'El formato del email no es válido';
        case 'user-disabled':             return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':         return 'Demasiados intentos. Espera unos minutos';
        case 'network-request-failed':    return 'Sin conexión a internet';
        case 'requires-recent-login':     return 'Inicia sesión de nuevo para cambiar la contraseña';
        case 'wrong-password':            return 'Contraseña actual incorrecta';
        case 'operation-not-allowed':     return 'Operación no permitida';
        default: return e.message ?? 'Error de autenticación';
      }
    }
    if (e.toString().contains('PlatformException'))
      return 'Error con Google Sign-In. Verifica el SHA-1 en Firebase Console.';
    return 'Error inesperado. Inténtalo de nuevo.';
  }
}
