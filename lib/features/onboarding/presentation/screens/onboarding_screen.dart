import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    await PreferencesService.setSeenOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Top bar — Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSlide1(screenHeight),
                    _buildSlide2(screenHeight),
                    _buildSlide3(screenHeight),
                  ],
                ),
              ),

              // Bottom — Dots + Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    // Dots
                    Row(
                      children: List.generate(3, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(right: 8),
                          height: 6,
                          width: isActive ? 28 : 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _currentPage == 2
                          ? FilledButton(
                              key: const ValueKey('start'),
                              onPressed: _completeOnboarding,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Get Started',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('next'),
                              width: 52,
                              height: 52,
                              child: FilledButton(
                                onPressed: _nextPage,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── Slide 1: Welcome ────────────────────────

  Widget _buildSlide1(double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: const DecorationImage(
                image: AssetImage('assets/images/logo_bg.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'ChemiCalc',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your pocket chemistry companion',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Feature chips — floating scattered layout
          Column(
            children: [
              Align(
                alignment: const Alignment(-0.5, 0),
                child: _chip('🔬', 'Easy to Use'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: const Alignment(0.55, 0),
                child: _chip('✨', 'Precise Results'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: const Alignment(-0.15, 0),
                child: _chip('🧮', '6 Calculators'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Slide 2: Features ────────────────────────

  Widget _buildSlide2(double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Everything you need',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Built for students, teachers, and researchers',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _featureRow(
            '🧮',
            'Smart Formula Parser',
            'Handles hydrates, brackets, and complex formulas like CuSO₄·5H₂O',
          ),
          const SizedBox(height: 16),
          _featureRow(
            '🧪',
            'Full Periodic Table',
            '118 elements with detailed properties and interactive exploration',
          ),
          const SizedBox(height: 16),
          _featureRow(
            '📚',
            'Chemical Library',
            'Browse 431 chemicals with instant search and detailed info',
          ),
          const SizedBox(height: 16),
          _featureRow(
            '📌',
            'Pin & Quick Access',
            'Pin your frequently used chemicals for fast calculation',
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Slide 3: Get Started ────────────────────────

  Widget _buildSlide3(double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative molecule-like layout
          SizedBox(
            height: 120,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: Colors.white, size: 30),
                ),
                // Small orbiting dots
                Positioned(
                  top: 8,
                  left: 30,
                  child: _orbitDot(18, AppColors.primary.withValues(alpha: 0.5)),
                ),
                Positioned(
                  bottom: 12,
                  right: 24,
                  child: _orbitDot(14, AppColors.primaryLight.withValues(alpha: 0.4)),
                ),
                Positioned(
                  top: 20,
                  right: 40,
                  child: _orbitDot(10, AppColors.primary.withValues(alpha: 0.3)),
                ),
                Positioned(
                  bottom: 6,
                  left: 50,
                  child: _orbitDot(12, AppColors.accent.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Your lab notebook,\nalways with you',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Save custom chemicals, export your data,\nand access everything on the go.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trustBadge(Icons.flash_on_rounded, 'Lightning\nFast'),
              const SizedBox(width: 24),
              _trustBadge(Icons.lock_outline_rounded, 'Private\n& Secure'),
              const SizedBox(width: 24),
              _trustBadge(Icons.speed_rounded, 'Instant\nResults'),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Helper Widgets ────────────────────────

  Widget _chip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orbitDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
