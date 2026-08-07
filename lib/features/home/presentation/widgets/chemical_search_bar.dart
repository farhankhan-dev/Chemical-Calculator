import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';

/// Search/input field with autocomplete overlay.
///
/// Shows suggestion items filtered by name as user types.
/// Each suggestion row displays: chemical name + formula.
class ChemicalSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final List<ChemicalModel> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<ChemicalModel> onSelected;
  final VoidCallback? onClear;

  const ChemicalSearchBar({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onChanged,
    required this.onSelected,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Enter Chemical Name',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Type any chemical name to get results',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search input field
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Type chemical name...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),

        // Suggestions dropdown
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildSuggestionsList(),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Related Chemicals',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Results will appear here as you type',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chem = suggestions[index];
                return _SuggestionTile(
                  chemical: chem,
                  onTap: () => onSelected(chem),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final ChemicalModel chemical;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.chemical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Dot indicator
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Chemical name and formula
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chemical.name,
                    style: AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chemical.formula,
                    style: AppTextStyles.formulaBase.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
