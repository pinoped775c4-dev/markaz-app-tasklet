import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/teacher_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MarkazApp());
}

class MarkazApp extends StatelessWidget {
  const MarkazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'مركز السنة للعلوم الشرعية',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF075E54),
            primary: const Color(0xFF075E54),
            secondary: const Color(0xFF128C7E),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF075E54),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          cardTheme: CardTheme(
            elevation: 1,
            shadowColor: const Color(0x1F0B141A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18))),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDEF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9EDEF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF128C7E), width: 1.6),
            ),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Color(0xFFDCF8C6),
            labelTextStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/root': (_) => const RootGate(),
        },
      ),
    );
  }
}

/// يقرأ الحالة ويعرض الشاشة المناسبة
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isAdmin) {
      return state.adminLoggedIn ? const AdminHomeScreen() : const LoginScreen();
    }
    return const TeacherHomeScreen();
  }
}
