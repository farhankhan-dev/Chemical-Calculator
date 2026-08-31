import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await AddEditChemicalDialog.show(context);
    if (result != null) {
      await _repository.save(result);
    }
    // Always load chemicals because custom fields might have been added/deleted
    await _loadChemicals();
  }

  Future<void> _openEditDialog(CustomChemicalModel chemical) async {
    final result = await AddEditChemicalDialog.show(
      context,
      existingChemical: chemical,
    );
    if (result != null) {
      await _repository.save(result);
    }
    // Always load chemicals because custom fields might have been added/deleted
    await _loadChemicals();
  }

  Future<void> _deleteChemical(CustomChemicalModel chemical) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _repository.delete(chemical.id);
    await _loadChemicals();
  }

  Future<void> _deleteMultiple(Set<String> ids) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _repository.deleteMultiple(ids);
    await _loadChemicals();
  }

  Future<void> _togglePin(Set<String> ids, bool pinned) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _repository.togglePin(ids, pinned);
    await _loadChemicals();
  }

  void _showChemicalDetails(CustomChemicalModel chemical) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chemical.name,
                          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildDetailRow('Formula', chemical.formula),
                  _buildDetailRow('Molecular Weight', '${chemical.molecularWeight.toStringAsFixed(2)} g/mol'),
                  if (chemical.customFields.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Custom Fields', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    ...chemical.customFields.entries.map((e) => _buildDetailRow(e.key, e.value)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  void _showImportExportSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
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

    final existingChemicals = await _repository.getAll();
    final existingMap = <String, CustomChemicalModel>{};
    for (final c in existingChemicals) {
      existingMap['${c.name.toLowerCase()}|${c.formula.toLowerCase()}'] = c;
    }

    int imported = 0;
    int updated = 0;
    int duplicatesSkipped = 0;

    for (final importedChem in result.chemicals) {
      final key = '${importedChem.name.toLowerCase()}|${importedChem.formula.toLowerCase()}';
      final existingChem = existingMap[key];

      if (existingChem != null) {
        // Merge custom fields
        bool hasChanges = false;
        final mergedFields = Map<String, String>.from(existingChem.customFields);

        for (final entry in importedChem.customFields.entries) {
          final importedKey = entry.key;
          final importedVal = entry.value;

          if (!mergedFields.containsKey(importedKey) || mergedFields[importedKey] != importedVal) {
            mergedFields[importedKey] = importedVal;
            hasChanges = true;
          }
        }

        if (hasChanges) {
          final updatedChem = existingChem.copyWith(customFields: mergedFields);
          await _repository.save(updatedChem);
          existingMap[key] = updatedChem; // Update map for subsequent checks if any
          updated++;
        } else {
          duplicatesSkipped++;
        }
      } else {
        // Brand new chemical
        await _repository.save(importedChem);
        existingMap[key] = importedChem;
        imported++;
      }
    }
    
    await _loadChemicals();

    if (!mounted) return;

    final parts = <String>[];
    if (imported > 0) parts.add('Imported $imported new chemical${imported == 1 ? '' : 's'}.');
    if (updated > 0) parts.add('Updated $updated chemical${updated == 1 ? '' : 's'}.');
    if (duplicatesSkipped > 0) parts.add('$duplicatesSkipped duplicate${duplicatesSkipped == 1 ? '' : 's'} skipped.');
    if (result.skippedRows > 0) parts.add('${result.skippedRows} invalid row${result.skippedRows == 1 ? '' : 's'} skipped.');

    if (parts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(parts.join(' ')),
          backgroundColor: (imported > 0 || updated > 0) ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showTxtStructureDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    
    final structureText = '''#CHEMICALC_NOTEBOOK_V1
Chemical Name|Formula|Molecular Weight
Example Water|H2O|18.01528
Example Salt|NaCl|58.44''';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Import File Structure',
                          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Want to manually create your own chemical list? Open a text editor on your phone or computer, paste the exact structure below, save it as a .txt file, and import it here!',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      structureText,
                      style: AppTextStyles.mono.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rules for text files:\n• Keep the #CHEMICALC_NOTEBOOK_V1 exactly as the first line.\n• The chemicals in the template are just examples. Replace them with your own!\n• Use the pipe symbol | to separate columns.\n• Do NOT put | inside chemical names or formulas.',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: structureText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Structure copied to clipboard!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('Copy Template'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'My Chemicals',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_snippet_outlined, color: AppColors.primary, size: 24),
                    tooltip: 'Text File Template Guide',
                    onPressed: _showTxtStructureDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.import_export, color: AppColors.primary, size: 24),
                    tooltip: 'Import / Export',
                    onPressed: _showImportExportSheet,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Personal Laboratory Chemical Notebook',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
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
                            onRowTap: _showChemicalDetails,
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
