import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Trigger Auth Check
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Allow at least 2.5 seconds for the logo animation to look great
    await Future.wait([
      authProvider.checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (mounted) {
      // GoRouter redirect will automatically trigger because we listened to AuthProvider.
      // But in case the redirect isn't automatic from initial route, we force it.
      if (authProvider.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004680), // JoharFix Brand Blue
      body: Stack(
        children: [
          // Background subtle circular glowing shapes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Logo & Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated App Icon Container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon label if asset not present
                        return const Icon(
                          Icons.build_rounded,
                          size: 48,
                          color: Color(0xFF004680),
                        );
                      },
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Animated App Name
                const Text(
                  'JoharFix',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOutQuad),

                const SizedBox(height: 6),

                // Animated Tagline
                Text(
                  'Premium Doorstep Services',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 850.ms, duration: 600.ms)
                    .slideY(begin: 0.4, end: 0.0, curve: Curves.easeOutQuad),
              ],
            ),
          ),
          
          // Bottom loading bar
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.7),
                  strokeWidth: 3,
                ),
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
