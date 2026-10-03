import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

/// On launch, Firebase's persisted authentication state determines whether
/// the returning user goes to the home screen or sign-in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Hydrate the profile before showing the authenticated screen.
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/nuicon.jpeg',
                  width: 150.w,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school,
                    size: 96.sp,
                    color: ThemeProvider.primaryNavy,
                  ),
                ),
                SizedBox(height: 24.h),
                CustomText(
                  text: 'NUBD Exchange',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: 'Advanced Mobile Programming',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: 26.w,
                  height: 26.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ThemeProvider.accentGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
