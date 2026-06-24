// repository/user_repository.dart
import '../model/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserRepository {
  static final UserRepository _i = UserRepository._();
  factory UserRepository() => _i;
  UserRepository._();

  final _api  = ApiService();
  final _auth = AuthService();

  Stream<dynamic> get authStateChanges    => _auth.authStateChanges;
  dynamic         get currentFirebaseUser => _auth.currentUser;

  Future<dynamic> signInWithGoogle()              => _auth.signInWithGoogle();
  Future<dynamic> signInWithEmail(String e, String p) => _auth.signInWithEmail(e, p);
  Future<dynamic> register(String e, String p, String n) => _auth.register(e, p, n);
  Future<void>    signOut()                        => _auth.signOut();
  String          friendlyError(dynamic e)         => _auth.friendlyError(e);
  bool            get isEmailVerified              => _auth.isEmailVerified;
  Future<bool>    reloadAndCheckVerified()         => _auth.reloadAndCheckVerified();
  Future<void>    sendVerificationEmail()          => _auth.sendVerificationEmail();
  Future<void>    sendPasswordResetEmail(String e) => _auth.sendPasswordResetEmail(e);
  Future<void>    changePassword(String cur, String n) => _auth.changePassword(cur, n);

  Future<UserModel>  getProfile()                  => _api.getMe();
  Future<void>       updateProfile(Map<String, dynamic> data) => _api.updateMe(data);

  Future<void> savePhysicalData({
    required double h, required double w,
    required int age, required String sex, required double years,
  }) => _api.savePhysicalData(heightCm: h, weightKg: w, age: age, sex: sex, trainingYears: years);

  Future<void>                becomeCoach()          => _api.becomeCoach();
  Future<String>              generateInviteCode()   => _api.generateInviteCode();
  Future<Map<String,dynamic>> linkWithCode(String c) => _api.linkWithCode(c);
  Future<List<dynamic>>       getMyAthletes()        => _api.getMyAthletes();
  Future<List<dynamic>>       getAthleteSessions(String id) => _api.getAthleteSessions(id);
  Future<void>                addSessionNotes(String s, String n) => _api.addSessionNotes(s, n);

  Future<Map<String,dynamic>> getAdminDashboard()   => _api.getAdminDashboard();
  Future<List<dynamic>>       getAdminUsers({String? role, String? search}) =>
      _api.getAdminUsers(role: role, search: search);
  Future<void>                userAction(String id, String action, {String? value}) =>
      _api.userAction(id, action, value: value);
  Future<Map<String,dynamic>> getClassifierInfo()   => _api.getClassifierInfo();
}
