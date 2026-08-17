import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../models/custom_chemical_model.dart';

/// Table widget displaying user's custom chemicals with 3 main columns:
/// Chemical Name | Chemical Formula | Molecular Weight
///
/// Supports multi-selection mode triggered by long-press on any row.
class CustomChemicalTable extends StatefulWidget {
  final List<CustomChemicalModel> chemicals;
  final ValueChanged<CustomChemicalModel> onEdit;
  final ValueChanged<CustomChemicalModel> onDelete;
  final void Function(Set<String> ids) onDeleteMultiple;
  final void Function(Set<String> ids, bool pinned) onTogglePin;

  const CustomChemicalTable({
    super.key,
    required this.chemicals,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteMultiple,
    required this.onTogglePin,
  });

  @override
  State<CustomChemicalTable> createState() => _CustomChemicalTableState();
}

class _CustomChemicalTableState extends State<CustomChemicalTable> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == widget.chemicals.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(widget.chemicals.map((c) => c.id));
      }
    });
  }

  void _confirmDeleteSelected() {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Flexible(child: Text('Delete $count Chemical${count == 1 ? '' : 's'}?')),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $count selected chemical${count == 1 ? '' : 's'} from your notebook?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteMultiple(Set.from(_selectedIds));
              _exitSelectionMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _pinSelected() {
    final selectedChemicals = widget.chemicals.where((c) => _selectedIds.contains(c.id));
    final allPinned = selectedChemicals.every((c) => c.isPinned);
    widget.onTogglePin(Set.from(_selectedIds), !allPinned);
    _exitSelectionMode();
  }

  void _editSelected() {
    if (_selectedIds.length == 1) {
      final chem = widget.chemicals.firstWhere((c) => c.id == _selectedIds.first);
      _exitSelectionMode();
      widget.onEdit(chem);
    }
  }

  bool _areAllSelectedPinned() {
    return widget.chemicals
        .where((c) => _selectedIds.contains(c.id))
        .every((c) => c.isPinned);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selection action bar
        if (_selectionMode)
          Container(
            color: AppColors.primarySurface,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                  onPressed: _exitSelectionMode,
                  tooltip: 'Cancel',
                  visualDensity: VisualDensity.compact,
                ),
                // Select All Checkbox
                Checkbox(
                  value: _selectedIds.length == widget.chemicals.length && widget.chemicals.isNotEmpty,
                  tristate: _selectedIds.isNotEmpty && _selectedIds.length < widget.chemicals.length,
                  onChanged: (_) => _toggleSelectAll(),
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                // Selected count
                Flexible(
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                // Pin button
                IconButton(
                  icon: Icon(
                    _areAllSelectedPinned() ? Icons.push_pin : Icons.push_pin_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: _pinSelected,
                  tooltip: _areAllSelectedPinned() ? 'Unpin' : 'Pin',
                  visualDensity: VisualDensity.compact,
                ),
                // Edit button (only when exactly 1 selected)
                if (_selectedIds.length == 1)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: _editSelected,
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: _confirmDeleteSelected,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

        // Table
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 16),
            children: [
              // Header Row
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                    left: BorderSide(color: AppColors.border),
                    right: BorderSide(color: AppColors.border),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text('Chemical Name', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text('Formula', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text('Mol Wt', textAlign: TextAlign.right, style: AppTextStyles.label.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Data Rows
              ...widget.chemicals.map((chem) {
                final isSelected = _selectedIds.contains(chem.id);
                return InkWell(
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(chem.id);
                    }
                  },
                  onLongPress: () {
                    if (!_selectionMode) {
                      _enterSelectionMode(chem.id);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySurface.withValues(alpha: 0.6) : null,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                        left: BorderSide(color: AppColors.border, width: 1),
                        right: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // First column: Chemical Name (with pin icon or checkbox inside)
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  if (_selectionMode)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleSelection(chem.id),
                                        activeColor: AppColors.primary,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                  else if (chem.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 2),
                                      child: Icon(Icons.push_pin, size: 12, color: AppColors.primary),
                                    ),
                                  if (_selectionMode || chem.isPinned)
                                    const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      chem.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                          // Second column: Formula
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chem.formula,
                                    style: AppTextStyles.mono.copyWith(
                                      fontSize: 12,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                          // Third column: Molecular Weight
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Text(
                                FormatUtils.format(chem.molecularWeight),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
