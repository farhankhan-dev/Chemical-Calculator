import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';

class AddChemicalScreen extends StatefulWidget {
  const AddChemicalScreen({super.key});

  @override
  State<AddChemicalScreen> createState() => _AddChemicalScreenState();
}

class _AddChemicalScreenState extends State<AddChemicalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = ChemicalLocalDatasource();

  String _name = '';
  String _formula = '';
  double _molecularWeight = 0.0;
  String _category = '';
  double? _density;
  double? _meltingPoint;
  double? _boilingPoint;
  String _casNumber = 'N/A';

  bool _isSaving = false;

  String _toSubscript(String formula) {
    return formula
        .replaceAll('0', '₀')
        .replaceAll('1', '₁')
        .replaceAll('2', '₂')
        .replaceAll('3', '₃')
        .replaceAll('4', '₄')
        .replaceAll('5', '₅')
        .replaceAll('6', '₆')
        .replaceAll('7', '₇')
        .replaceAll('8', '₈')
        .replaceAll('9', '₉');
  }

  void _saveChemical() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final formattedFormula = _toSubscript(_formula);

      final newChemical = ChemicalModel(
        id: 0, // Assigned correctly in datasource
        name: _name,
        formula: formattedFormula,
        molecularWeight: _molecularWeight,
        category: _category,
        density: _density,
        meltingPoint: _meltingPoint,
        boilingPoint: _boilingPoint,
        casNumber: _casNumber,
      );

      await _datasource.addChemical(newChemical);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Chemical'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Chemical Details',
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                label: 'Name *',
                hint: 'e.g., Sodium Chloride',
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Formula *',
                hint: 'e.g., NaCl',
                validator: (v) => v == null || v.isEmpty ? 'Formula is required' : null,
                onSaved: (v) => _formula = v!,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Molecular Weight *',
                hint: 'e.g., 58.44',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Molecular Weight is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
                onSaved: (v) => _molecularWeight = double.parse(v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'CAS Number',
                hint: 'e.g., 58-08-2',
                onSaved: (v) => _casNumber = v?.isNotEmpty == true ? v! : 'N/A',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Category *',
                hint: 'e.g., Organic Compound',
                validator: (v) => v == null || v.isEmpty ? 'Category is required' : null,
                onSaved: (v) => _category = v!,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Density (g/cm³)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSaved: (v) => _density = v != null && v.isNotEmpty ? double.tryParse(v) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Melting Point (°C)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onSaved: (v) => _meltingPoint = v != null && v.isNotEmpty ? double.tryParse(v) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(
                label: 'Boiling Point (°C)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onSaved: (v) => _boilingPoint = v != null && v.isNotEmpty ? double.tryParse(v) : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChemical,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Chemical',
                          style: AppTextStyles.label.copyWith(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? hint,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }
}
