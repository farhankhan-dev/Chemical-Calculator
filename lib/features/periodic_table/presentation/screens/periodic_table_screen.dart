import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../controllers/periodic_table_controller.dart';
import '../../models/element_model.dart';
import '../widgets/category_legend.dart';
import '../widgets/element_search_bar.dart';
import '../widgets/periodic_table_grid.dart';
import 'element_detail_screen.dart';

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  final PeriodicTableController _controller = PeriodicTableController();
  late final Map<int, ElementModel> _elementsMap;

  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    // Build quick atomic number lookup map
    _elementsMap = {
      for (var e in _controller.allElements) e.atomicNumber: e
    };
    _controller.addListener(_onControllerChanged);
    _restorePortraitOrientation();
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _restorePortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        _setLandscapeOrientation();
      } else {
        _restorePortraitOrientation();
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _restorePortraitOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchingNums = _controller.matchingAtomicNumbers;
    final hasActiveFilter = _controller.searchQuery.isNotEmpty || _controller.selectedCategory != null;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _restorePortraitOrientation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Control Header: Title, Search Bar & Category Legend
                Row(
                  children: [
                    Text(
                      'Periodic Table',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '118 Elements',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isLandscape && hasActiveFilter) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _controller.clearFilters,
                        icon: const Icon(Icons.filter_alt_off, size: 14, color: AppColors.error),
                        label: const Text('Reset', style: TextStyle(fontSize: 11, color: AppColors.error)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isLandscape ? Icons.screen_lock_portrait : Icons.screen_rotation,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleOrientation,
                    ),
                  ],
                ),
                
                if (!_isLandscape) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElementSearchBar(
                          query: _controller.searchQuery,
                          onChanged: _controller.updateSearchQuery,
                          onClear: () => _controller.updateSearchQuery(''),
                        ),
                      ),
                      if (hasActiveFilter) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _controller.clearFilters,
                          icon: const Icon(Icons.filter_alt_off, size: 14, color: AppColors.error),
                          label: const Text('Reset', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // Category Legend Bar
                CategoryLegend(
                  selectedCategory: _controller.selectedCategory,
                  onCategoryTap: _controller.toggleCategory,
                ),

                const SizedBox(height: 6),

                // Periodic Table Interactive Grid
                Expanded(
                  child: PeriodicTableGrid(
                    elementsMap: _elementsMap,
                    matchingAtomicNumbers: matchingNums,
                    hasActiveFilter: hasActiveFilter,
                    selectedCategory: _controller.selectedCategory,
                    onElementSelected: (element) {
                      ElementDetailScreen.show(context, element, isLandscape: _isLandscape);
                    },
                    onCategorySelected: _controller.toggleCategory,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
