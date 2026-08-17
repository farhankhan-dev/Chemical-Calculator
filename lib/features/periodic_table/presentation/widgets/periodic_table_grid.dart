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

class _PeriodicTableGridState extends State<PeriodicTableGrid>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformController;
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;

  // Cached layout values, set during build
  double _tileWidth = 44.0;
  double _tileHeight = 52.0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..addListener(() {
        if (_animation != null) {
          _transformController.value = _animation!.value;
        }
      });
  }

  @override
  void didUpdateWidget(PeriodicTableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // We no longer pan/zoom to the category. Highlighting is handled by the tiles themselves.
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Region mapping: each category maps to a rectangle in the grid
  // col/row are 0-indexed; isFBlock = true for lanthanide / actinide rows
  // ---------------------------------------------------------------------------
  _GridRegion _regionForCategory(ElementCategory cat) {
    switch (cat) {
      case ElementCategory.alkaliMetal:
        // Group 1 (col 0), periods 2-7 (rows 1-6)
        return const _GridRegion(col: 0, endCol: 0, row: 1, endRow: 6);
      case ElementCategory.alkalineEarthMetal:
        // Group 2 (col 1), periods 2-7
        return const _GridRegion(col: 1, endCol: 1, row: 1, endRow: 6);
      case ElementCategory.transitionMetal:
        // Groups 3-12 (cols 2-11), periods 4-7
        return const _GridRegion(col: 2, endCol: 11, row: 3, endRow: 6);
      case ElementCategory.postTransitionMetal:
        // Groups 13-16 (cols 12-15), periods 4-6
        return const _GridRegion(col: 12, endCol: 15, row: 3, endRow: 5);
      case ElementCategory.metalloid:
        // Groups 13-17 (cols 12-16), periods 2-5
        return const _GridRegion(col: 12, endCol: 16, row: 1, endRow: 5);
      case ElementCategory.reactiveNonmetal:
        // Groups 14-17 (cols 13-16), periods 2-4
        return const _GridRegion(col: 13, endCol: 16, row: 1, endRow: 3);
      case ElementCategory.halogen:
        // Group 17 (col 16), periods 2-6
        return const _GridRegion(col: 16, endCol: 16, row: 1, endRow: 5);
      case ElementCategory.nobleGas:
        // Group 18 (col 17), periods 1-6
        return const _GridRegion(col: 17, endCol: 17, row: 0, endRow: 5);
      case ElementCategory.lanthanide:
        // f-block first row (lanthanides)
        return const _GridRegion(col: 2, endCol: 16, row: 0, endRow: 0, isFBlock: true);
      case ElementCategory.actinide:
        // f-block second row (actinides)
        return const _GridRegion(col: 2, endCol: 16, row: 1, endRow: 1, isFBlock: true);
      case ElementCategory.unknown:
        // Period 7, groups 4-18
        return const _GridRegion(col: 3, endCol: 17, row: 6, endRow: 6);
    }
  }

  void _scrollToCategory(ElementCategory cat) {
    if (_viewportWidth == 0 || _viewportHeight == 0) return;

    final region = _regionForCategory(cat);
    final colStep = _tileWidth + 3.0;  // tile width + gap
    final rowStep = _tileHeight + 3.0; // tile height + gap
    const headerH = 16.0;             // group number row height estimate
    const padding = 4.0;

    final mainGridH = 7 * rowStep;

    double targetX;
    double targetY;
    double regionW;
    double regionH;

    if (region.isFBlock) {
      final fBlockY = padding + headerH + 3 + mainGridH + 10;
      final fRow = region.row; // 0 = lanthanides, 1 = actinides
      final leftOffset = _tileWidth * 2 + 6;

      targetX = leftOffset + region.col * colStep;
      targetY = fBlockY + fRow * (rowStep + 3);
      regionW = (region.endCol - region.col + 1) * colStep;
      regionH = rowStep;
    } else {
      targetX = padding + region.col * colStep;
      targetY = padding + headerH + 3 + region.row * rowStep;
      regionW = (region.endCol - region.col + 1) * colStep;
      regionH = (region.endRow - region.row + 1) * rowStep;
    }

    // Use a standard size zoom level for all categories.
    // 1.0 keeps the table readable without extreme zoom-in or zoom-out.
    const double scale = 1.0;

    // Pan so the center of the region is centered in the viewport
    final regionCenterX = targetX + regionW / 2;
    final regionCenterY = targetY + regionH / 2;
    final tx = _viewportWidth / 2 - regionCenterX * scale;
    final ty = _viewportHeight / 2 - regionCenterY * scale;

    final target = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..setTranslationRaw(tx, ty, 0);

    _animateTo(target);
  }

  void _animateTo(Matrix4 target) {
    // 1. Capture the current transform BEFORE any reset.
    final Matrix4 begin = _transformController.value.clone();
    // 2. Null out _animation so the listener is a no-op during reset().
    _animation = null;
    _animController.reset();
    // 3. Build the new tween from the captured position → target.
    _animation = Matrix4Tween(begin: begin, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
    _animController.forward();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute tile dimensions from available width
        final availableWidth = constraints.maxWidth;
        final computedTileWidth = (availableWidth - (17 * 3.0)) / 18;
        
        // Use the original clamp values
        _tileWidth = computedTileWidth.clamp(36.0, 56.0);
        _tileHeight = _tileWidth * 1.18;
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;

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
          transformationController: _transformController,
          minScale: 0.05,
          maxScale: 6.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      range,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 6, color: category.color),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

/// Describes a rectangular region in the periodic table grid (0-indexed cols/rows).
class _GridRegion {
  final int col;
  final int endCol;
  final int row;
  final int endRow;
  /// True for lanthanide / actinide f-block rows (below the main 7-period grid).
  final bool isFBlock;

  const _GridRegion({
    required this.col,
    required this.endCol,
    required this.row,
    required this.endRow,
    this.isFBlock = false,
  });
}
