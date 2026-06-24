// main.dart — Entry point con patrón MVVM
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'services/notification_service.dart';
import 'viewmodel/progression_viewmodel.dart';
import 'viewmodel/chat_viewmodel.dart';
import 'viewmodel/best_rep_viewmodel.dart';
import 'services/haptic_service.dart';
import 'services/theme_service.dart';
import 'services/settings_service.dart';
import 'services/pdf_service.dart';
import 'services/websocket_service.dart';
import 'viewmodel/analysis_viewmodel.dart';
import 'app/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null); // requerido para DateFormat en español
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BM.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  await NotificationService().init();
  runApp(const BioMoveApp());
}

class BioMoveApp extends StatefulWidget {
  const BioMoveApp({super.key});
  @override
  State<BioMoveApp> createState() => _BioMoveAppState();
}

class _BioMoveAppState extends State<BioMoveApp> {
  late final AuthViewModel _authVM;
  late final AnalysisViewModel _analysisVM;
  late final ProgressionViewModel _progressionVM;
  late final ChatViewModel _chatVM;
  late final BestRepViewModel _bestRepVM;
  final ThemeService _themeService = ThemeService();
  final SettingsService _settingsService = SettingsService();
  late final GoRouterWrapper _routerWrapper;

  @override
  void initState() {
    super.initState();
    _authVM        = AuthViewModel();
    _analysisVM    = AnalysisViewModel();
    _progressionVM = ProgressionViewModel();
    _chatVM = ChatViewModel();
    _bestRepVM = BestRepViewModel();
    _themeService.init();
    _settingsService.init();
    // CRÍTICO: Router creado una sola vez en initState — nunca dentro de build()
    _routerWrapper = GoRouterWrapper(_authVM);
    // Conectar notificaciones con el router para navegar al tocar
    NotificationService.onTap = (route) => _routerWrapper.router.go(route);
    // Iniciar WebSocket cuando el usuario se autentica
    _authVM.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authVM.isAuth) {
      _chatVM.initWebSocket();
    }
  }

  @override
  void dispose() {
    _authVM.removeListener(_onAuthChanged);
    _routerWrapper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _authVM),
      ChangeNotifierProvider.value(value: _analysisVM),
      ChangeNotifierProvider.value(value: _progressionVM),
      ChangeNotifierProvider.value(value: _chatVM),
      ChangeNotifierProvider.value(value: _bestRepVM),
      ChangeNotifierProvider.value(value: _themeService),
    ],
    child: AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) => MaterialApp.router(
      title: 'BioMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeService.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _routerWrapper.router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: child!,
      ),
    )),
  );
}
