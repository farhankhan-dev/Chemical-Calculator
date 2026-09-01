import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/formula_parser.dart';
import '../../../../core/utils/formula_formatter.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../chemical_detail/presentation/screens/chemical_detail_screen.dart';
import '../../data/custom_chemical_repository.dart';
import '../../models/custom_chemical_model.dart';

/// Modal dialog / sheet for adding a new custom chemical or editing an existing one.
class AddEditChemicalDialog extends StatefulWidget {
  final CustomChemicalModel? existingChemical;

  const AddEditChemicalDialog({
    super.key,
    this.existingChemical,
  });

  /// Shows the dialog and returns the saved [CustomChemicalModel] or `null` if cancelled.
  static Future<CustomChemicalModel?> show(
    BuildContext context, {
    CustomChemicalModel? existingChemical,
  }) {
    return showDialog<CustomChemicalModel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddEditChemicalDialog(existingChemical: existingChemical),
    );
  }

  @override
  State<AddEditChemicalDialog> createState() => _AddEditChemicalDialogState();
}

class _AddEditChemicalDialogState extends State<AddEditChemicalDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _formulaController;
  late final TextEditingController _mwController;

  final FormulaParser _formulaParser = FormulaParser();

  bool _isManualMwOverride = false;
  String? _validationError;
  ChemicalModel? _duplicateLibraryChemical;
  String _lastAutoFormula = '';
  Timer? _debounce;

  List<String> _customFieldNames = [];
  final Map<String, TextEditingController> _customFieldControllers = {};

  bool get _isEditing => widget.existingChemical != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingChemical;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _formulaController = TextEditingController(text: existing?.formula ?? '');
    _mwController = TextEditingController(
      text: existing != null ? FormatUtils.format(existing.molecularWeight) : '',
    );
    if (existing != null) {
      _lastAutoFormula = existing.formula;
      _isManualMwOverride = true;
    }
    _loadCustomFields();
  }

  Future<void> _loadCustomFields() async {
    final fields = await PreferencesService.getCustomFields();
    if (!mounted) return;
    
    setState(() {
      _customFieldNames = fields;
      for (final field in fields) {
        _customFieldControllers[field] = TextEditingController(
          text: widget.existingChemical?.customFields[field] ?? '',
        );
      }
    });
  }

  void _addNewCustomField() async {
    final newField = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Custom Field'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. Purity, State, Color',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newField != null && newField.isNotEmpty && !_customFieldNames.contains(newField)) {
      await PreferencesService.saveCustomField(newField);
      setState(() {
        _customFieldNames.add(newField);
        _customFieldControllers[newField] = TextEditingController();
      });
    }
  }

  void _deleteCustomField(String fieldName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Field?'),
        content: Text('Are you sure you want to delete the column "$fieldName" and all its data from all saved chemicals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Remove from preferences
      await PreferencesService.deleteCustomField(fieldName);
      // 2. Remove from all existing chemicals
      await CustomChemicalRepository().removeCustomField(fieldName);
      
      // 3. Remove from current UI state
      if (!mounted) return;
      setState(() {
        _customFieldNames.remove(fieldName);
        _customFieldControllers[fieldName]?.dispose();
        _customFieldControllers.remove(fieldName);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formulaController.dispose();
    _mwController.dispose();
    for (final controller in _customFieldControllers.values) {
      controller.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _onFormulaChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _processFormulaChange(val);
    });
  }

  void _processFormulaChange(String val) {
    final formula = val.trim();
    if (formula.isEmpty) {
      setState(() {
        _lastAutoFormula = '';
        _isManualMwOverride = false;
        _validationError = null;
      });
      return;
    }

    // If the user changes the formula again, reset manual override for new formula
    if (formula != _lastAutoFormula) {
      _isManualMwOverride = false;
      _lastAutoFormula = formula;
    }

    if (!_isManualMwOverride) {
      final parseResult = _formulaParser.parse(formula);
      if (parseResult.isValid) {
        _mwController.text = FormatUtils.format(parseResult.molarMass);
        setState(() {
          _validationError = null;
        });
      } else {
        setState(() {
          _validationError = parseResult.error ?? 'Please enter a valid chemical formula.';
        });
      }
    }
  }

  void _onMwChanged(String val) {
    // Mark as manually overridden when user directly types into MW field
    if (!_isManualMwOverride) {
      setState(() {
        _isManualMwOverride = true;
      });
    }
  }

  void _save() async {
    setState(() {
      _validationError = null;
      _duplicateLibraryChemical = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError = 'Please enter a chemical name.';
      });
      return;
    }

    final rawFormula = _formulaController.text.trim();
    if (rawFormula.isEmpty) {
      setState(() {
        _validationError = 'Please enter a chemical formula.';
      });
      return;
    }
    
    // Auto format the formula properly (e.g. nacl -> NaCl)
    final formula = FormulaFormatter.format(rawFormula);
    _formulaController.text = formula; // Update the UI so they see the caps when it dismisses

    final parseResult = _formulaParser.parse(formula);
    if (!parseResult.isValid) {
      setState(() {
        _validationError = parseResult.error ?? 'Please enter a valid chemical formula.';
      });
      return;
    }

    final mwText = _mwController.text.trim();
    final mw = double.tryParse(mwText);
    if (mw == null || mw <= 0) {
      setState(() {
        _validationError = 'Please enter a valid molecular weight.';
      });
      return;
    }

    final now = DateTime.now();
    final isNew = widget.existingChemical == null;

    if (isNew) {
      final localSource = ChemicalLocalDatasource();
      final all = await localSource.getAllChemicals();
      final nLower = name.toLowerCase();
      final fLower = formula.toLowerCase();

      ChemicalModel? dup;
      for (final c in all) {
        if (c.name.toLowerCase() == nLower || c.formula.toLowerCase() == fLower) {
          dup = c;
          break;
        }
      }

      if (dup != null) {
        setState(() {
          _duplicateLibraryChemical = dup;
        });
        return;
      }
    }

    final customFields = <String, String>{};
    for (final entry in _customFieldControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) {
        customFields[entry.key] = val;
      }
    }

    final chemical = CustomChemicalModel(
      id: widget.existingChemical?.id ?? now.millisecondsSinceEpoch.toString(),
      name: name,
      formula: formula,
      molecularWeight: mw,
      createdAt: widget.existingChemical?.createdAt ?? now,
      customFields: customFields,
    );

    if (!mounted) return;
    Navigator.of(context).pop(chemical);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            _isEditing ? 'Edit Chemical' : 'Add Chemical',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),

                  // Chemical Name Field
                  Text('Chemical Name', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Sodium Chloride',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Chemical Formula Field
                  Text('Chemical Formula', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _formulaController,
                    onChanged: _onFormulaChanged,
                    decoration: InputDecoration(
                      hintText: 'e.g. NaCl, H2SO4, Ca(OH)2',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      suffixIcon: _formulaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _formulaController.clear();
                                _onFormulaChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Molecular Weight Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Molecular Weight (g/mol)', style: AppTextStyles.label),
                      if (_isManualMwOverride)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Manual Override',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mwController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onMwChanged,
                    decoration: InputDecoration(
                      hintText: 'e.g. 58.44',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      suffixText: 'g/mol',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Error Display
                  if (_validationError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Duplicate Error Display
                  if (_duplicateLibraryChemical != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This chemical is already available in the app library!',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChemicalDetailScreen(chemical: _duplicateLibraryChemical!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.science, size: 16),
                              label: Text('View ${_duplicateLibraryChemical!.name}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Custom Fields
                  if (_customFieldNames.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Custom Fields', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    const SizedBox(height: AppSpacing.sm),
                    ..._customFieldNames.map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(field, style: AppTextStyles.label),
                                InkWell(
                                  onTap: () => _deleteCustomField(field),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _customFieldControllers[field],
                              decoration: InputDecoration(
                                hintText: 'Enter value',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Add Custom Field Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addNewCustomField,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Custom Field'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isEditing ? 'Save Changes' : 'Add Chemical',
                            style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
