import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/element_category.dart';

class CategoryLegend extends StatelessWidget {
  final ElementCategory? selectedCategory;
  final ValueChanged<ElementCategory> onCategoryTap;

  const CategoryLegend({
    super.key,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ElementCategory.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              onTap: () => onCategoryTap(cat),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : cat.bgTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : cat.borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
