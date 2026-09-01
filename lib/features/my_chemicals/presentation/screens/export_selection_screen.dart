import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/chemical_io_service.dart';
import '../../models/custom_chemical_model.dart';

/// Screen for selecting chemicals to export and setting the file name.
class ExportSelectionScreen extends StatefulWidget {
  final List<CustomChemicalModel> chemicals;

  const ExportSelectionScreen({super.key, required this.chemicals});

  /// Navigates to this screen and returns true if export was successful.
  static Future<bool?> show(BuildContext context, List<CustomChemicalModel> chemicals) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExportSelectionScreen(chemicals: chemicals)),
    );
  }

  @override
  State<ExportSelectionScreen> createState() => _ExportSelectionScreenState();
}

class _ExportSelectionScreenState extends State<ExportSelectionScreen> {
  final Set<String> _selectedIds = {};
  bool _isExporting = false;

  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}_$h$min$s';
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _allSelected => _selectedIds.length == widget.chemicals.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(widget.chemicals.map((c) => c.id));
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _doExport() async {
    if (_selectedIds.isEmpty) return;

    final timestamp = _formatTimestamp(DateTime.now());
    final defaultName = 'ChemiCalc_Notebook_$timestamp';

    final fileName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: defaultName);
        return AlertDialog(
          title: const Text('Export File Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter file name',
              suffixText: '.txt',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Export'),
            ),
          ],
        );
      },
    );

    if (fileName == null || fileName.isEmpty) {
      return;
    }

    setState(() => _isExporting = true);

    final selected = widget.chemicals.where((c) => _selectedIds.contains(c.id)).toList();
    final path = await ChemicalIOService.exportChemicals(
      chemicals: selected,
      fileName: fileName,
    );

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${selected.length} chemicals to:\n$path'),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Chemicals'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Select All / Deselect All
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} of ${widget.chemicals.length} selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _toggleSelectAll,
                    icon: Icon(
                      _allSelected ? Icons.deselect : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(_allSelected ? 'Deselect All' : 'Select All'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            const Divider(height: 1),

            // Chemical list with checkboxes
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: widget.chemicals.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final chem = widget.chemicals[index];
                  final isSelected = _selectedIds.contains(chem.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleItem(chem.id),
                    activeColor: AppColors.primary,
                    title: Text(
                      chem.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      chem.formula,
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),

            // Export button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty || _isExporting ? null : _doExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_download_outlined, size: 20),
                  label: Text(
                    _isExporting
                        ? 'Exporting...'
                        : 'Export ${_selectedIds.length} Chemical${_selectedIds.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
