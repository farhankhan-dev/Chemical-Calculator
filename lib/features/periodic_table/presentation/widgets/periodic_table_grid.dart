import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../models/element_model.dart';
import 'element_tile.dart';

class PeriodicTableGrid extends StatelessWidget {
  final Map<int, ElementModel> elementsMap;
  final Set<int> matchingAtomicNumbers;
  final bool hasActiveFilter;
  final ValueChanged<ElementModel> onElementSelected;

  const PeriodicTableGrid({
    super.key,
    required this.elementsMap,
    required this.matchingAtomicNumbers,
    required this.hasActiveFilter,
    required this.onElementSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standard table requires 18 columns.
        // We compute tileSize based on available constraints or fallback minimum.
        final availableWidth = constraints.maxWidth;
        final computedTileWidth = (availableWidth - (17 * 3.0)) / 18;
        final tileWidth = computedTileWidth.clamp(36.0, 56.0);
        final tileHeight = tileWidth * 1.18;

        Widget gridContent = Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Group Numbers (1 to 18)
              _buildGroupHeaders(tileWidth),
              const SizedBox(height: 3),

              // Main Periodic Table Grid (18 columns x 7 periods)
              _buildMainGrid(tileWidth, tileHeight),

              const SizedBox(height: 10),

              // Separator and Lanthanides / Actinides section
              _buildFBlockGrid(tileWidth, tileHeight),
            ],
          ),
        );

        return InteractiveViewer(
          minScale: 0.2,
          maxScale: 4.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(20),
          child: gridContent,
        );
      },
    );
  }

  Widget _buildGroupHeaders(double tileWidth) {
    return Row(
      children: List.generate(18, (index) {
        final groupNum = index + 1;
        return Container(
          width: tileWidth,
          margin: EdgeInsets.only(right: index == 17 ? 0 : 3),
          alignment: Alignment.center,
          child: Text(
            '$groupNum',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textTertiary,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMainGrid(double tileWidth, double tileHeight) {
    return Column(
      children: List.generate(7, (pIndex) {
        final period = pIndex + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 3.0),
          child: Row(
            children: List.generate(18, (gIndex) {
              final group = gIndex + 1;
              final atomicNum = _getAtomicNumberForMainGrid(period, group);

              if (atomicNum == null) {
                // Empty cell in the periodic grid
                return Container(
                  width: tileWidth,
                  height: tileHeight,
                  margin: EdgeInsets.only(right: gIndex == 17 ? 0 : 3),
                );
              }

              if (atomicNum == -57) {
                // Placeholder cell for Lanthanides (57-71)
                return _buildSeriesPlaceholder(
                  tileWidth, tileHeight, '57-71', 'Lanthanides', AppColors.primarySurface);
              }

              if (atomicNum == -89) {
                // Placeholder cell for Actinides (89-103)
                return _buildSeriesPlaceholder(
                  tileWidth, tileHeight, '89-103', 'Actinides', AppColors.primarySurface);
              }

              final element = elementsMap[atomicNum];
              if (element == null) {
                return SizedBox(width: tileWidth, height: tileHeight);
              }

              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: EdgeInsets.only(right: gIndex == 17 ? 0 : 3),
                child: ElementTile(
                  element: element,
                  isHighlighted: matchingAtomicNumbers.contains(atomicNum),
                  hasActiveFilter: hasActiveFilter,
                  onTap: () => onElementSelected(element),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildFBlockGrid(double tileWidth, double tileHeight) {
    // Lanthanides (57-71) and Actinides (89-103)
    final lanthanideNums = List.generate(15, (i) => 57 + i);
    final actinideNums = List.generate(15, (i) => 89 + i);

    final leftOffsetWidth = tileWidth * 2 + 6; // Offset by 2 columns to align under Group 3

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lanthanides Row
        Row(
          children: [
            SizedBox(
              width: leftOffsetWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    'Lanthanides (57-71)',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            ...lanthanideNums.map((num) {
              final element = elementsMap[num];
              if (element == null) return SizedBox(width: tileWidth, height: tileHeight);

              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: const EdgeInsets.only(right: 3),
                child: ElementTile(
                  element: element,
                  isHighlighted: matchingAtomicNumbers.contains(num),
                  hasActiveFilter: hasActiveFilter,
                  onTap: () => onElementSelected(element),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 3),

        // Actinides Row
        Row(
          children: [
            SizedBox(
              width: leftOffsetWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    'Actinides (89-103)',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            ...actinideNums.map((num) {
              final element = elementsMap[num];
              if (element == null) return SizedBox(width: tileWidth, height: tileHeight);

              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: const EdgeInsets.only(right: 3),
                child: ElementTile(
                  element: element,
                  isHighlighted: matchingAtomicNumbers.contains(num),
                  hasActiveFilter: hasActiveFilter,
                  onTap: () => onElementSelected(element),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSeriesPlaceholder(
    double width, double height, String range, String title, Color bg) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            range,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 6,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Map (Period, Group) to Atomic Number for standard 18-column grid
  int? _getAtomicNumberForMainGrid(int period, int group) {
    // Period 1
    if (period == 1) {
      if (group == 1) return 1; // H
      if (group == 18) return 2; // He
      return null;
    }

    // Period 2
    if (period == 2) {
      if (group == 1) return 3; // Li
      if (group == 2) return 4; // Be
      if (group >= 13 && group <= 18) return 5 + (group - 13); // B (5) to Ne (10)
      return null;
    }

    // Period 3
    if (period == 3) {
      if (group == 1) return 11; // Na
      if (group == 2) return 12; // Mg
      if (group >= 13 && group <= 18) return 13 + (group - 13); // Al (13) to Ar (18)
      return null;
    }

    // Period 4
    if (period == 4) {
      return 19 + (group - 1); // K (19) to Kr (36)
    }

    // Period 5
    if (period == 5) {
      return 37 + (group - 1); // Rb (37) to Xe (54)
    }

    // Period 6
    if (period == 6) {
      if (group == 1) return 55; // Cs
      if (group == 2) return 56; // Ba
      if (group == 3) return -57; // Lanthanides Placeholder
      if (group >= 4 && group <= 18) return 72 + (group - 4); // Hf (72) to Rn (86)
      return null;
    }

    // Period 7
    if (period == 7) {
      if (group == 1) return 87; // Fr
      if (group == 2) return 88; // Ra
      if (group == 3) return -89; // Actinides Placeholder
      if (group >= 4 && group <= 18) return 104 + (group - 4); // Rf (104) to Og (118)
      return null;
    }

    return null;
  }
}
