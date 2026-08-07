import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../../core/utils/format_utils.dart';

class MassCalculatorScreen extends StatefulWidget {
  const MassCalculatorScreen({super.key});

  @override
  State<MassCalculatorScreen> createState() => _MassCalculatorScreenState();
}

class _MassCalculatorScreenState extends State<MassCalculatorScreen> {
  bool _isMassNeeded = true; // false = Volume Needed
  ChemicalModel? _selectedChemical;
  bool _isMolarity = true; // false = Normality
  bool _isVolMl = true; // false = Liters
  
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _volMassController = TextEditingController(); // Volume if Mass Needed, Mass if Volume Needed
  final ScrollController _scrollController = ScrollController();

  double? _result;
  String? _calculationString;

  @override
  void dispose() {
    _targetController.dispose();
    _volMassController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_selectedChemical == null) return;
    
    final target = double.tryParse(_targetController.text);
    final volMass = double.tryParse(_volMassController.text);
    if (target == null || volMass == null) return;

    setState(() {
      if (_isMassNeeded) {
        // Mass = Concentration * Volume(L) * Weight
        final volLiters = _isVolMl ? volMass / 1000 : volMass;
        if (_isMolarity) {
          _result = target * volLiters * _selectedChemical!.molecularWeight;
          _calculationString = 'Mass = Molarity × Molar Mass × Volume (L)\n'
              '= ${FormatUtils.format(target)} × ${FormatUtils.format(_selectedChemical!.molecularWeight)} × ${FormatUtils.format(volLiters)} = ${FormatUtils.format(_result!)} g';
        } else {
          final eqWeight = _selectedChemical!.equivalentWeight;
          if (eqWeight == null) {
            _result = null;
            _calculationString = 'Cannot calculate using Normality:\nEquivalent weight data is missing for this chemical.';
            return;
          }
          _result = target * volLiters * eqWeight;
          _calculationString = 'Mass = Normality × Eq. Weight × Volume (L)\n'
              '= ${FormatUtils.format(target)} × ${FormatUtils.format(eqWeight)} × ${FormatUtils.format(volLiters)} = ${FormatUtils.format(_result!)} g';
        }
      } else {
        // Volume Needed (L) = Mass / (Concentration * Weight)
        // Here volMass input is actually Mass (g)
        if (_isMolarity) {
          final volL = volMass / (target * _selectedChemical!.molecularWeight);
          _result = _isVolMl ? volL * 1000 : volL;
          _calculationString = 'Volume (L) = Mass / (Molarity × Molar Mass)\n'
              '= ${FormatUtils.format(volMass)} / (${FormatUtils.format(target)} × ${FormatUtils.format(_selectedChemical!.molecularWeight)}) = ${FormatUtils.format(volL)} L';
        } else {
          final eqWeight = _selectedChemical!.equivalentWeight;
          if (eqWeight == null) {
            _result = null;
            _calculationString = 'Cannot calculate using Normality:\nEquivalent weight data is missing for this chemical.';
            return;
          }
          final volL = volMass / (target * eqWeight);
          _result = _isVolMl ? volL * 1000 : volL;
          _calculationString = 'Volume (L) = Mass / (Normality × Eq. Weight)\n'
              '= ${FormatUtils.format(volMass)} / (${FormatUtils.format(target)} × ${FormatUtils.format(eqWeight)}) = ${FormatUtils.format(volL)} L';
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mass Calculator'),
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
            // Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMassNeeded = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isMassNeeded ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mass Needed',
                          style: TextStyle(
                            color: _isMassNeeded ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMassNeeded = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isMassNeeded ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Volume Needed',
                          style: TextStyle(
                            color: !_isMassNeeded ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Select Chemical
            Text('Select Chemical', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final chem = await ChemicalSelector.show(context);
                if (chem != null) {
                  setState(() => _selectedChemical = chem);
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
            const SizedBox(height: AppSpacing.lg),

            // Target
            Text('Target', style: AppTextStyles.label),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isMolarity,
                  onChanged: (val) => setState(() => _isMolarity = true),
                  activeColor: AppColors.primary,
                ),
                Text('Molarity (M)', style: AppTextStyles.bodyMedium),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _isMolarity,
                  onChanged: (val) => setState(() => _isMolarity = false),
                  activeColor: AppColors.primary,
                ),
                Text('Normality (N)', style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Value', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: _isMolarity ? 'M' : 'N',
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
                      Text(_isMassNeeded ? 'Volume' : 'Mass', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _volMassController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixIcon: _isMassNeeded ? DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: _isVolMl,
                              items: const [
                                DropdownMenuItem(value: true, child: Text('mL')),
                                DropdownMenuItem(value: false, child: Text('L')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _isVolMl = val);
                              },
                            ),
                          ) : Padding(
                            padding: const EdgeInsets.only(top: 14.0, right: 12.0),
                            child: Text('g', style: AppTextStyles.bodyMedium, textAlign: TextAlign.right),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Calculate',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
              ),
            ),

            if (_result != null) ...[
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
                    Text(
                      _isMassNeeded ? 'Mass Needed' : 'Volume Needed',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMassNeeded 
                          ? '${FormatUtils.format(_result!)} g'
                          : '${FormatUtils.format(_result!)} ${_isVolMl ? 'mL' : 'L'}',
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Pure substance)',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white),
                    const SizedBox(height: 16),
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
