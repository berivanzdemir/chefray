import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/common/app_logo.dart';
import '../../repositories/user_health_profile_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final hasSession = Supabase.instance.client.auth.currentSession != null;

    if (!mounted) return;

    if (hasSession) {
      // Check whether the user has completed the health profile setup.
      final isSetupComplete =
          await UserHealthProfileRepository.instance.isProfileSetupCompleted();
      if (!mounted) return;
      if (isSetupComplete) {
        context.go('/home');
      } else {
        context.go('/health-profile-setup');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.white,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            radius: 1.2,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
            child: const AppLogo(size: 140, showText: true),
          ),
        ),
      ),
    );
  }
}

