import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../models/element_model.dart';
import '../../models/element_category.dart';
import 'element_tile.dart';

class PeriodicTableGrid extends StatefulWidget {
  final Map<int, ElementModel> elementsMap;
  final Set<int> matchingAtomicNumbers;
  final bool hasActiveFilter;
  final ValueChanged<ElementModel> onElementSelected;
  final ValueChanged<ElementCategory>? onCategorySelected;
  final ElementCategory? selectedCategory;

  const PeriodicTableGrid({
    super.key,
    required this.elementsMap,
    required this.matchingAtomicNumbers,
    required this.hasActiveFilter,
    required this.onElementSelected,
    this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  State<PeriodicTableGrid> createState() => _PeriodicTableGridState();
}

class _PeriodicTableGridState extends State<PeriodicTableGrid> with SingleTickerProviderStateMixin {
  // Cached layout values, set during build
  double _tileWidth = 44.0;
  double _tileHeight = 52.0;

  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void didUpdateWidget(PeriodicTableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory &&
        widget.selectedCategory != null) {
      _panToCategory(widget.selectedCategory!);
    }
  }

  void _panToCategory(ElementCategory category) {
    double minCol = 18;
    double maxCol = 1;
    double minRow = 10;
    double maxRow = 1;

    for (final element in widget.elementsMap.values) {
      if (element.category == category) {
        double c = element.group.toDouble();
        double r = element.period.toDouble();

        if (element.atomicNumber >= 57 && element.atomicNumber <= 71) {
          r = 9;
          c = 3.0 + (element.atomicNumber - 56);
        } else if (element.atomicNumber >= 89 && element.atomicNumber <= 103) {
          r = 10;
          c = 3.0 + (element.atomicNumber - 88);
        }

        if (c < minCol) minCol = c;
        if (c > maxCol) maxCol = c;
        if (r < minRow) minRow = r;
        if (r > maxRow) maxRow = r;
      }
    }

    if (minCol > maxCol || minRow > maxRow) return;

    final centerX = ((minCol + maxCol) / 2) * (_tileWidth + 3);
    final centerY = ((minRow + maxRow) / 2) * (_tileHeight + 3);

    final size = MediaQuery.of(context).size;
    final viewWidth = size.width;
    final viewHeight = size.height;

    final currentMatrix = _transformationController.value;
    final scale = currentMatrix.getMaxScaleOnAxis();

    // Center horizontally, and place slightly above vertical center
    final dx = (viewWidth / 2) - (centerX * scale);
    final dy = (viewHeight / 3) - (centerY * scale);

    final targetMatrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Set optimal readable tile dimensions for standard portrait/landscape screens
        // 18 columns * 44px + gaps = ~843px width
        _tileWidth = 44.0;
        _tileHeight = 52.0;

        final Widget gridContent = Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Group Numbers (1 to 18)
              _buildGroupHeaders(_tileWidth),
              const SizedBox(height: 3),

              // Main Periodic Table Grid (18 columns × 7 periods)
              _buildMainGrid(context, _tileWidth, _tileHeight),

              const SizedBox(height: 10),

              // f-block: Lanthanides / Actinides
              _buildFBlockGrid(_tileWidth, _tileHeight),
            ],
          ),
        );

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.01,
          maxScale: 4.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(32.0),
          child: RepaintBoundary(child: gridContent),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders (unchanged logic, just use widget.xxx instead of xxx)
  // ---------------------------------------------------------------------------

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

  Widget _buildMainGrid(
      BuildContext context, double tileWidth, double tileHeight) {
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
                return Container(
                  width: tileWidth,
                  height: tileHeight,
                  margin: EdgeInsets.only(right: gIndex == 17 ? 0 : 3),
                );
              }

              if (atomicNum == -57) {
                return _buildSeriesPlaceholder(
                  context,
                  tileWidth,
                  tileHeight,
                  '57-71',
                  'Lanthanides',
                  ElementCategory.lanthanide,
                  () => widget.onCategorySelected
                      ?.call(ElementCategory.lanthanide),
                );
              }

              if (atomicNum == -89) {
                return _buildSeriesPlaceholder(
                  context,
                  tileWidth,
                  tileHeight,
                  '89-103',
                  'Actinides',
                  ElementCategory.actinide,
                  () =>
                      widget.onCategorySelected?.call(ElementCategory.actinide),
                );
              }

              final element = widget.elementsMap[atomicNum];
              if (element == null) {
                return SizedBox(width: tileWidth, height: tileHeight);
              }

              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: EdgeInsets.only(right: gIndex == 17 ? 0 : 3),
                child: ElementTile(
                  element: element,
                  isHighlighted:
                      widget.matchingAtomicNumbers.contains(atomicNum),
                  hasActiveFilter: widget.hasActiveFilter,
                  onTap: () => widget.onElementSelected(element),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildFBlockGrid(double tileWidth, double tileHeight) {
    final lanthanideNums = List.generate(15, (i) => 57 + i);
    final actinideNums = List.generate(15, (i) => 89 + i);
    final leftOffsetWidth = tileWidth * 2 + 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lanthanides row
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
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            ...lanthanideNums.map((atomicN) {
              final element = widget.elementsMap[atomicN];
              if (element == null) {
                return SizedBox(width: tileWidth, height: tileHeight);
              }
              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: const EdgeInsets.only(right: 3),
                child: ElementTile(
                  element: element,
                  isHighlighted: widget.matchingAtomicNumbers.contains(atomicN),
                  hasActiveFilter: widget.hasActiveFilter,
                  onTap: () => widget.onElementSelected(element),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 3),

        // Actinides row
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
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            ...actinideNums.map((atomicN) {
              final element = widget.elementsMap[atomicN];
              if (element == null) {
                return SizedBox(width: tileWidth, height: tileHeight);
              }
              return Container(
                width: tileWidth,
                height: tileHeight,
                margin: const EdgeInsets.only(right: 3),
                child: ElementTile(
                  element: element,
                  isHighlighted: widget.matchingAtomicNumbers.contains(atomicN),
                  hasActiveFilter: widget.hasActiveFilter,
                  onTap: () => widget.onElementSelected(element),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSeriesPlaceholder(
    BuildContext context,
    double width,
    double height,
    String range,
    String title,
    ElementCategory category,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Material(
        color: category.bgTint,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: category.borderColor, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 6, color: category.color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Maps (period, group) → atomic number for the standard 18-column grid.
  int? _getAtomicNumberForMainGrid(int period, int group) {
    if (period == 1) {
      if (group == 1) return 1;  // H
      if (group == 18) return 2; // He
      return null;
    }
    if (period == 2) {
      if (group == 1) return 3;
      if (group == 2) return 4;
      if (group >= 13 && group <= 18) return 5 + (group - 13);
      return null;
    }
    if (period == 3) {
      if (group == 1) return 11;
      if (group == 2) return 12;
      if (group >= 13 && group <= 18) return 13 + (group - 13);
      return null;
    }
    if (period == 4) return 19 + (group - 1); // K–Kr
    if (period == 5) return 37 + (group - 1); // Rb–Xe
    if (period == 6) {
      if (group == 1) return 55;
      if (group == 2) return 56;
      if (group == 3) return -57; // lanthanide placeholder
      if (group >= 4 && group <= 18) return 72 + (group - 4); // Hf–Rn
      return null;
    }
    if (period == 7) {
      if (group == 1) return 87;
      if (group == 2) return 88;
      if (group == 3) return -89; // actinide placeholder
      if (group >= 4 && group <= 18) return 104 + (group - 4); // Rf–Og
      return null;
    }
    return null;
  }
}
