import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../widgets/chemical_search_bar.dart';
import '../widgets/chemical_info_card.dart';

/// Home screen — opens directly to a chemical name input field.
///
/// Header: "ChemiCalc" title + SVG molecule image
/// Input: Autocomplete search field
/// Result: Chemical detail card below when selected
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    // Header: App name + SVG molecule
                    _buildHeader(),

                    const SizedBox(height: AppSpacing.lg),

                    // Search bar with autocomplete
                    ChemicalSearchBar(
                      controller: _textController,
                      suggestions: _controller.suggestions,
                      onChanged: (query) {
                        _controller.onQueryChanged(query);
                      },
                      onSelected: (chemical) {
                        _textController.text = chemical.name;
                        _controller.selectChemical(chemical);
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                      },
                      onClear: () {
                        _textController.clear();
                        _controller.clearSelection();
                      },
                    ),

                    // Chemical detail card
                    if (_controller.selectedChemical != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ChemicalInfoCard(
                        chemical: _controller.selectedChemical!,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Disclaimer footer
                    _buildDisclaimer(),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ChemiCalc',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All Chemical Formulas\nin One Place',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // SVG molecule image from assets
        Transform.translate(
          offset: const Offset(-12, 0),
          child: SizedBox(
            width: 100,
            height: 100,
            child: SvgPicture.asset(
              'assets/images/head-image.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For educational reference — always verify critical calculations.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
