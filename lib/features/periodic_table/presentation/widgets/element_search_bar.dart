import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class ElementSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ElementSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search element name, symbol, or atomic number...',
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: AppColors.textTertiary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 38,
          ),
          suffixIcon: query.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.clear,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 38,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
