import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../../core/utils/format_utils.dart';

class EquivalentWeightCalculatorScreen extends StatefulWidget {
  const EquivalentWeightCalculatorScreen({super.key});

  @override
  State<EquivalentWeightCalculatorScreen> createState() => _EquivalentWeightCalculatorScreenState();
}

class _EquivalentWeightCalculatorScreenState extends State<EquivalentWeightCalculatorScreen> {
  ChemicalModel? _selectedChemical;

  final TextEditingController _molarMassController = TextEditingController();
  final TextEditingController _nFactorController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double? _result;
  String? _calculationString;

  @override
  void dispose() {
    _molarMassController.dispose();
    _nFactorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateManual() {
    final molarMass = double.tryParse(_molarMassController.text);
    final nFactor = double.tryParse(_nFactorController.text);
    if (molarMass == null || nFactor == null || nFactor == 0) return;

    setState(() {
      _selectedChemical = null; // Clear chemical if manually calculating
      _result = molarMass / nFactor;
      _calculationString = 'Eq. Weight = Molar Mass / n-factor\n'
          '= ${FormatUtils.format(molarMass)} / ${FormatUtils.format(nFactor)} = ${FormatUtils.format(_result!)} g/eq';
    });
    
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectChemical(ChemicalModel chem) {
    setState(() {
      _selectedChemical = chem;
      _molarMassController.clear();
      _nFactorController.clear();
      
      if (chem.equivalentWeight != null) {
        _result = chem.equivalentWeight;
        final nFactor = chem.molecularWeight / chem.equivalentWeight!;
        _calculationString = 'Eq. Weight = Molar Mass / n-factor\n'
            '= ${FormatUtils.format(chem.molecularWeight)} / ${FormatUtils.format(nFactor)} = ${FormatUtils.format(_result!)} g/eq';
      } else {
        _result = null;
        _calculationString = 'Equivalent weight data not available for this chemical.\nPlease use manual entry.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eq. Weight Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.functions, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eq. Weight = Molar Mass / Valency',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Select Chemical
            Text('Lookup from Database', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final chem = await ChemicalSelector.show(context);
                if (chem != null) {
                  _selectChemical(chem);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedChemical?.name ?? 'Choose a chemical',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ],
                    ),
                    const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: AppTextStyles.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Manual Entry
            Text('Manual Calculation', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Molar Mass', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _molarMassController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: 'g/mol',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('n-factor', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nFactorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text('Calculate Manually', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
              ),
            ),

            if (_result != null || _calculationString != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_result != null) ...[
                      Text(
                        'Equivalent Weight',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${FormatUtils.format(_result!)} g/eq',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Calculation',
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _calculationString ?? '',
                      style: AppTextStyles.mono.copyWith(color: AppColors.primaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
