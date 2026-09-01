import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/element_model.dart';

class ElementTile extends StatelessWidget {
  final ElementModel element;
  final bool isHighlighted;
  final bool hasActiveFilter;
  final VoidCallback onTap;

  const ElementTile({
    super.key,
    required this.element,
    this.isHighlighted = false,
    this.hasActiveFilter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = element.category.color;
    final isDimmed = hasActiveFilter && !isHighlighted;

    return Semantics(
      label: element.semanticLabel,
      button: true,
      enabled: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isDimmed ? 0.3 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isHighlighted ? categoryColor : element.category.bgTint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHighlighted ? AppColors.primary : element.category.borderColor,
                  width: isHighlighted ? 2.0 : 1.0,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Atomic Number
                  Flexible(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${element.atomicNumber}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? Colors.white : AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center: Symbol (Prominent)
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        element.symbol,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isHighlighted ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // Bottom: Name (Compact)
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        element.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: isHighlighted ? Colors.white : AppColors.textPrimary,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
