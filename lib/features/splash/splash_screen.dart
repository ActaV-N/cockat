import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate after checking onboarding status
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1500));

    // If authenticated, wait for DB loading to complete
    if (ref.read(isAuthenticatedProvider)) {
      final startTime = DateTime.now();
      const timeout = Duration(seconds: 5);

      // Wait for DB preferences to load (max 5 seconds)
      while (DateTime.now().difference(startTime) < timeout) {
        final dbPrefs = ref.read(userPreferencesDbProvider);
        if (dbPrefs.hasValue || dbPrefs.hasError) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (mounted && !_navigationDone) {
      _navigationDone = true;
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    bool onboardingCompleted;

    if (isAuthenticated) {
      final dbPrefs = ref.read(userPreferencesDbProvider);
      // Use DB value if available, otherwise fallback to local
      onboardingCompleted = dbPrefs.valueOrNull?['onboarding_completed'] ??
          ref.read(onboardingCompletedLocalProvider);
    } else {
      onboardingCompleted = ref.read(onboardingCompletedLocalProvider);
    }

    final nextScreen = onboardingCompleted
        ? const HomeScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/logos/cockat-transparent.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'Cockat',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Personal Bartender',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
