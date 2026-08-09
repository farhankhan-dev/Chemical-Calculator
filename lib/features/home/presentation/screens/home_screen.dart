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
              ] else if (_controller.recentSearches.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildRecentSearches(),
              ],

              const SizedBox(height: AppSpacing.sm),

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
                'Chemical Formulas\n in One Place',
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
            width: 90,
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
                await _controller.clearRecentSearches();
                setState(() {});
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Clear',
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
