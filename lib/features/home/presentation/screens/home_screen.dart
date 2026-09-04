import 'package:flutter/material.dart';
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
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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

  bool handleBackPress() {
    if (_textController.text.isNotEmpty || FocusScope.of(context).hasFocus) {
      _textController.clear();
      _controller.clearSelection();
      FocusScope.of(context).unfocus();
      if (mounted) setState(() {});
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                hasSelection: _controller.selectedChemical != null,
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
              ] else if (_controller.recentSearches.isNotEmpty || _controller.canUndoClear) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildRecentSearches(),
              ],

              const SizedBox(height: AppSpacing.xl),
              _buildDisclaimer(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
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
                ' Chemical Calculators\n In One Place',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Molecule image from assets
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 100,
            height: 90,
            child: Image.asset(
              'assets/images/head-image.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.science,
                    size: 40,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Searched',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () async {
                if (_controller.canUndoClear) {
                  await _controller.undoClearRecentSearches();
                } else {
                  await _controller.clearRecentSearches();
                }
                setState(() {});
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _controller.canUndoClear ? 'Undo' : 'Clear All',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controller.recentSearches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final chemical = _controller.recentSearches[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    chemical.name,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    chemical.formula,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.north_west,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                  onTap: () {
                    _textController.text = chemical.name;
                    _controller.selectChemical(chemical);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
