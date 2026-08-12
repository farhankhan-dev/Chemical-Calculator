import 'package:flutter/material.dart';
import '../../data/datasources/chemical_local_datasource.dart';
import '../../data/models/chemical_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class ChemicalSelector {
  static Future<ChemicalModel?> show(BuildContext context) async {
    return showModalBottomSheet<ChemicalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ChemicalSelectionSheet(),
    );
  }
}

class _ChemicalSelectionSheet extends StatefulWidget {
  const _ChemicalSelectionSheet();

  @override
  State<_ChemicalSelectionSheet> createState() => _ChemicalSelectionSheetState();
}

class _ChemicalSelectionSheetState extends State<_ChemicalSelectionSheet> {
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();
  final TextEditingController _searchController = TextEditingController();
  
  List<ChemicalModel> _allChemicals = [];
  List<ChemicalModel> _filteredChemicals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChemicals();
  }

  Future<void> _loadChemicals() async {
    final chemicals = await _datasource.getAllChemicals();
    chemicals.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        _allChemicals = chemicals;
        _filteredChemicals = chemicals;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredChemicals = _allChemicals;
      });
      return;
    }

    final q = query.trim().toLowerCase();
    setState(() {
      _filteredChemicals = _allChemicals.where((c) {
        return c.name.toLowerCase().contains(q) || 
               c.formula.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Material(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Chemical',
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search chemicals...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: controller,
                        itemCount: _filteredChemicals.length,
                        itemBuilder: (context, index) {
                          final chem = _filteredChemicals[index];
                          return ListTile(
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
                              chem.name,
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              chem.formula,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context, chem);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
