// cspell:ignore Chemicalc Devriz
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/preferences_service.dart';

/// Animated splash screen — 1.4 seconds.
///
/// Shows the app logo with scale animation, "Chemicalc" text with fade-in,
/// and "Powered by Devriz" at the bottom.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  static const String _devText = 'Developed by Codevelop Solutions';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scales from 0 → 1
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    // Text fades in
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
      ),
    );

    // No addListener needed for typing animation anymore

    _controller.forward();

    // Navigate to home after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () async {
      final hasSeenOnboarding = await PreferencesService.hasSeenOnboarding();
      if (mounted) {
        if (hasSeenOnboarding) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    });
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primarySurface,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                const Spacer(flex: 3),

                // Logo with scale animation
                Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icons/logo 2.png',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: _textFade.value,
                  child: Text(
                    'Chemicalc',
                    style: AppTextStyles.splashTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _textFade.value,
                  child: Text(
                    'Chemical Calculators in One Place',
                    style: AppTextStyles.splashSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Static bottom text
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Opacity(
                    opacity: _textFade.value,
                    child: Text(
                      _devText,
                      style: AppTextStyles.splashSubtitle.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
