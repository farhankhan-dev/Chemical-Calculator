import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/periodic_table_controller.dart';
import '../../models/element_model.dart';
import '../widgets/periodic_table_grid.dart';
import '../widgets/category_legend.dart';
import 'element_detail_screen.dart';

class LandscapePeriodicTableScreen extends StatefulWidget {
  const LandscapePeriodicTableScreen({super.key});

  @override
  State<LandscapePeriodicTableScreen> createState() => _LandscapePeriodicTableScreenState();
}

class _LandscapePeriodicTableScreenState extends State<LandscapePeriodicTableScreen> {
  final PeriodicTableController _controller = PeriodicTableController();
  late final Map<int, ElementModel> _elementsMap;

  @override
  void initState() {
    super.initState();
    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _elementsMap = {
      for (var e in _controller.allElements) e.atomicNumber: e
    };
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Restore portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CategoryLegend(
                      selectedCategory: _controller.selectedCategory,
                      onCategoryTap: _controller.toggleCategory,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_controller.selectedCategory != null)
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.screen_rotation, color: AppColors.primary),
                    tooltip: 'Return to Vertical Mode',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: PeriodicTableGrid(
                  elementsMap: _elementsMap,
                  matchingAtomicNumbers: _controller.matchingAtomicNumbers,
                  hasActiveFilter: _controller.selectedCategory != null,
                  selectedCategory: _controller.selectedCategory,
                  onElementSelected: (element) {
                    ElementDetailScreen.show(context, element);
                  },
                  onCategorySelected: _controller.toggleCategory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
