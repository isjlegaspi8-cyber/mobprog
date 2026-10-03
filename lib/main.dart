// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

// providers
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: 'assets/.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LegaspiAdvMobProg());
}

// Rename this to match your own surname_advmobprog convention if needed.
class LegaspiAdvMobProg extends StatelessWidget {
  const LegaspiAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'E-Commerce App',
            // Enhancement 1: the splash screen is now the entry point. It
            // decides between /home and /signin based on the persisted
            // token, so persistent authentication is checked on every launch.
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              // Enhancement 2: sign-in route backed by UserService.
              '/signin': (context) => const SignInScreen(),
              '/home': (context) => const HomeScreen(),
              '/cart': (context) => const CartScreen(),
              // Enhancement 3 (Act 2): settings route hosts the theme switch.
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
