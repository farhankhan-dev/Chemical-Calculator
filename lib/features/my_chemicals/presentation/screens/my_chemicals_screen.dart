import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/chemical_io_service.dart';
import '../../data/custom_chemical_repository.dart';
import '../../models/custom_chemical_model.dart';
import '../widgets/add_edit_chemical_dialog.dart';
import '../widgets/custom_chemical_table.dart';
import 'export_selection_screen.dart';

/// Personal Chemical Notebook Screen ("My Chemicals").
///
/// Allows users to view, search, add, edit, and delete their own custom chemical entries.
class MyChemicalsScreen extends StatefulWidget {
  const MyChemicalsScreen({super.key});

  @override
  State<MyChemicalsScreen> createState() => _MyChemicalsScreenState();
}

class _MyChemicalsScreenState extends State<MyChemicalsScreen> {
  final CustomChemicalRepository _repository = CustomChemicalRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CustomChemicalModel> _chemicals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChemicals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChemicals() async {
    setState(() => _isLoading = true);
    final results = await _repository.search(_searchQuery);
    if (mounted) {
      setState(() {
        _chemicals = results;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadChemicals();
  }

  void _onClearSearch() {
    _searchController.clear();
    _searchQuery = '';
    _loadChemicals();
  }

  Future<void> _openAddDialog() async {
    final result = await AddEditChemicalDialog.show(context);
    if (result != null) {
      await _repository.save(result);
      await _loadChemicals();
    }
  }

  Future<void> _openEditDialog(CustomChemicalModel chemical) async {
    final result = await AddEditChemicalDialog.show(
      context,
      existingChemical: chemical,
    );
    if (result != null) {
      await _repository.save(result);
      await _loadChemicals();
    }
  }

  Future<void> _deleteChemical(CustomChemicalModel chemical) async {
    await _repository.delete(chemical.id);
    await _loadChemicals();
  }

  Future<void> _deleteMultiple(Set<String> ids) async {
    await _repository.deleteMultiple(ids);
    await _loadChemicals();
  }

  Future<void> _togglePin(Set<String> ids, bool pinned) async {
    await _repository.togglePin(ids, pinned);
    await _loadChemicals();
  }

  void _showImportExportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                title: const Text('Import Chemicals'),
                subtitle: const Text('Import from a .txt file'),
                onTap: () {
                  Navigator.pop(ctx);
                  _doImport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                title: const Text('Export Chemicals'),
                subtitle: const Text('Export to a .txt file'),
                onTap: () {
                  Navigator.pop(ctx);
                  _doExport();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doImport() async {
    final result = await ChemicalIOService.importChemicals();

    if (!mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Save imported chemicals, skipping duplicates
    final existingChemicals = await _repository.getAll();
    final existingKeys = existingChemicals
        .map((c) => '${c.name.toLowerCase()}|${c.formula.toLowerCase()}')
        .toSet();

    int imported = 0;
    int duplicates = 0;

    for (final chem in result.chemicals) {
      final key = '${chem.name.toLowerCase()}|${chem.formula.toLowerCase()}';
      if (existingKeys.contains(key)) {
        duplicates++;
      } else {
        await _repository.save(chem);
        existingKeys.add(key);
        imported++;
      }
    }
    await _loadChemicals();

    if (!mounted) return;

    final parts = <String>[];
    if (imported > 0) parts.add('Imported $imported chemical${imported == 1 ? '' : 's'}.');
    if (duplicates > 0) parts.add('$duplicates duplicate${duplicates == 1 ? '' : 's'} skipped.');
    if (result.skippedRows > 0) parts.add('${result.skippedRows} invalid row${result.skippedRows == 1 ? '' : 's'} skipped.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.join(' ')),
        backgroundColor: imported > 0 ? AppColors.success : AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _doExport() async {
    // Load all chemicals (not just searched ones)
    final all = await _repository.getAll();
    if (!mounted) return;

    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No chemicals to export.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final exported = await ExportSelectionScreen.show(context, all);
    if (exported == true && mounted) {
      // Reload in case something changed
      await _loadChemicals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Header Bar
              Row(
                children: [
                  Text(
                    'My Chemicals',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Notebook',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.import_export, color: AppColors.primary, size: 24),
                    tooltip: 'Import / Export',
                    onPressed: _showImportExportSheet,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Personal Laboratory Chemical Notebook',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search chemicals...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                          onPressed: _onClearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Body Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _chemicals.isEmpty
                        ? _buildEmptyState(context, isSearching)
                        : CustomChemicalTable(
                            chemicals: _chemicals,
                            onEdit: _openEditDialog,
                            onDelete: _deleteChemical,
                            onDeleteMultiple: _deleteMultiple,
                            onTogglePin: _togglePin,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    if (isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No chemicals found.',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'No entry matching "$_searchQuery"',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No custom chemicals yet.',
                style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your laboratory chemicals to access them quickly in your personal notebook.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
