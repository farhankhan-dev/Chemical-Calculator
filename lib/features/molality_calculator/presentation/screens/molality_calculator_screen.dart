import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';

class MolalityCalculatorScreen extends StatefulWidget {
  const MolalityCalculatorScreen({super.key});

  @override
  State<MolalityCalculatorScreen> createState() => _MolalityCalculatorScreenState();
}

class _MolalityCalculatorScreenState extends State<MolalityCalculatorScreen> {
  final TextEditingController _molesController = TextEditingController();
  final TextEditingController _massSolventController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double? _result;
  String? _calculationString;

  @override
  void dispose() {
    _molesController.dispose();
    _massSolventController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moles = double.tryParse(_molesController.text);
    final mass = double.tryParse(_massSolventController.text);
    
    if (moles == null || mass == null || mass == 0) return;

    setState(() {
      _result = moles / mass;
      _calculationString = 'Molality (m) = Moles of Solute / Mass of Solvent (kg)\n'
          '= ${FormatUtils.format(moles)} / ${FormatUtils.format(mass)} = ${FormatUtils.format(_result!)} mol/kg';
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
        title: const Text('Molality Calculator'),
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
            // Formula Card
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
                      'Molality (m) = Moles of Solute (mol) / Mass of Solvent (kg)',
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

            // Inputs
            Text('Moles of Solute', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _molesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter moles (mol)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                suffixText: 'mol',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Mass of Solvent', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _massSolventController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter mass (kg)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                suffixText: 'kg',
              ),
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
                      'Molality (m)',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${FormatUtils.format(_result!)} mol/kg',
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
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
