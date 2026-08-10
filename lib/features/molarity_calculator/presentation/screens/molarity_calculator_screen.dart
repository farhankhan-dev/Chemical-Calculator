import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../../core/utils/format_utils.dart';

class MolarityCalculatorScreen extends StatefulWidget {
  const MolarityCalculatorScreen({super.key});

  @override
  State<MolarityCalculatorScreen> createState() => _MolarityCalculatorScreenState();
}

class _MolarityCalculatorScreenState extends State<MolarityCalculatorScreen> {
  ChemicalModel? _selectedChemical;
  
  final TextEditingController _massController = TextEditingController();
  final TextEditingController _volController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController();
  
  bool _isVolMl = true; // false = Liters

  double? _molarity;
  double? _normality;
  String? _calculationString;

  @override
  void dispose() {
    _massController.dispose();
    _volController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_selectedChemical == null) return;
    
    final mass = double.tryParse(_massController.text);
    final vol = double.tryParse(_volController.text);
    if (mass == null || vol == null) return;

    setState(() {
      final volLiters = _isVolMl ? vol / 1000 : vol;
      
      final moles = mass / _selectedChemical!.molecularWeight;
      _molarity = moles / volLiters;
      
      final eqWeight = _selectedChemical!.equivalentWeight;
      if (eqWeight != null) {
        final equivalents = mass / eqWeight;
        _normality = equivalents / volLiters;
        
        _calculationString = 'Moles = ${FormatUtils.format(mass)} g / ${FormatUtils.format(_selectedChemical!.molecularWeight)} g/mol = ${FormatUtils.format(moles)}\n'
            'Molarity = ${FormatUtils.format(moles)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_molarity!)} M\n\n'
            'Eq = ${FormatUtils.format(mass)} g / ${FormatUtils.format(eqWeight)} g/eq = ${FormatUtils.format(equivalents)}\n'
            'Normality = ${FormatUtils.format(equivalents)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_normality!)} N';
      } else {
        _normality = null;
        _calculationString = 'Moles = ${FormatUtils.format(mass)} g / ${FormatUtils.format(_selectedChemical!.molecularWeight)} g/mol = ${FormatUtils.format(moles)}\n'
            'Molarity = ${FormatUtils.format(moles)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_molarity!)} M\n\n'
            'Normality: N/A (Equivalent weight not available)';
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
        title: const Text('Molarity Calculator'),
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
                  const Icon(Icons.sync_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Molarity (M) = Mass (g) / (Molar Mass (g/mol) × Volume (L))',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Calculate concentration from known mass.',
              style: AppTextStyles.bodyMedium,
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedChemical != null
                                  ? '${_selectedChemical!.name} (${_selectedChemical!.formula})'
                                  : 'Choose a chemical',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: _selectedChemical != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mass Added', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _massController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: 'g',
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
                      Text('Volume', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _volController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixIcon: DropdownButtonHideUnderline(
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
                  'Calculate Concentration',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
              ),
            ),

            if (_molarity != null) ...[
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
                      'Molarity (M)',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${FormatUtils.format(_molarity!)} mol/L',
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                    ),
                    if (_normality != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Normality (N)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${FormatUtils.format(_normality!)} eq/L',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 24),
                      ),
                    ],
                    if (_selectedChemical?.density != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Density',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedChemical!.density} g/cm³',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 24),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Calculation Steps',
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _calculationString ?? '',
                      style: AppTextStyles.mono.copyWith(color: AppColors.primaryDark, fontSize: 12),
                    ),
                    if (_normality == null) ...[ 
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Normality is N/A — Why?',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Normality could not be calculated for "${_selectedChemical?.name ?? 'this chemical'}" because its Equivalent Weight is not stored in the database.\n\n'
                        'Normality (N) = (Mass ÷ Eq. Weight) ÷ Volume (L)\n\n'
                        'Equivalent Weight requires knowing the n-factor — the number of H⁺ or OH⁻ ions the compound can donate or accept. For some chemicals (elements, organic compounds, salts with complex reactions), this is not defined.\n\n'
                        'Molarity is still valid and has been calculated above.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.orange.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
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
