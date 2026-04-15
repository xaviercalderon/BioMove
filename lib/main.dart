import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/analysis_provider.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BM.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp();
  runApp(const BioMoveApp());
}

class BioMoveApp extends StatefulWidget {
  const BioMoveApp({super.key});
  @override
  State<BioMoveApp> createState() => _BioMoveAppState();
}

class _BioMoveAppState extends State<BioMoveApp> {
  late final AuthProvider     _auth;
  late final AnalysisProvider _analysis;

  @override
  void initState() {
    super.initState();
    _auth     = AuthProvider();
    _analysis = AnalysisProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _analysis),
      ],
      builder: (context, _) {
        final router = buildRouter(_auth);
        return MaterialApp.router(
          title: 'BioMove',
          debugShowCheckedModeBanner: false,
          theme: BioMoveTheme.dark,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          ),
        );
      },
    );
  }
}
