import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';

class DilutionCalculatorScreen extends StatefulWidget {
  const DilutionCalculatorScreen({super.key});

  @override
  State<DilutionCalculatorScreen> createState() => _DilutionCalculatorScreenState();
}

class _DilutionCalculatorScreenState extends State<DilutionCalculatorScreen> {
  final _c1Controller = TextEditingController();
  final _v1Controller = TextEditingController();
  final _c2Controller = TextEditingController();
  final _v2Controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _resultMessage;

  @override
  void dispose() {
    _c1Controller.dispose();
    _v1Controller.dispose();
    _c2Controller.dispose();
    _v2Controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    final c1 = double.tryParse(_c1Controller.text);
    final v1 = double.tryParse(_v1Controller.text);
    final c2 = double.tryParse(_c2Controller.text);
    final v2 = double.tryParse(_v2Controller.text);

    int emptyCount = 0;
    if (c1 == null) emptyCount++;
    if (v1 == null) emptyCount++;
    if (c2 == null) emptyCount++;
    if (v2 == null) emptyCount++;

    if (emptyCount != 1) {
      setState(() {
        _resultMessage = 'Please leave exactly one field empty to calculate it.';
      });
      return;
    }

    setState(() {
      if (c1 == null) {
        final result = (c2! * v2!) / v1!;
        _c1Controller.text = FormatUtils.format(result);
        _resultMessage = 'Calculated C₁: ${FormatUtils.format(result)}';
      } else if (v1 == null) {
        final result = (c2! * v2!) / c1;
        _v1Controller.text = FormatUtils.format(result);
        _resultMessage = 'Calculated V₁: ${FormatUtils.format(result)}';
      } else if (c2 == null) {
        final result = (c1 * v1) / v2!;
        _c2Controller.text = FormatUtils.format(result);
        _resultMessage = 'Calculated C₂: ${FormatUtils.format(result)}';
      } else if (v2 == null) {
        final result = (c1 * v1) / c2;
        _v2Controller.text = FormatUtils.format(result);
        _resultMessage = 'Calculated V₂: ${FormatUtils.format(result)}';
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

  void _clear() {
    _c1Controller.clear();
    _v1Controller.clear();
    _c2Controller.clear();
    _v2Controller.clear();
    setState(() {
      _resultMessage = null;
    });
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dilution Calculator'),
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
            Text(
              'C₁V₁ = C₂V₂',
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter three values and leave the one you want to calculate empty.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(child: _buildInputField('Initial Concentration (C₁)', 'e.g. 1.0 M', _c1Controller)),
                const SizedBox(width: 16),
                Expanded(child: _buildInputField('Initial Volume (V₁)', 'e.g. 100 mL', _v1Controller)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildInputField('Final Concentration (C₂)', 'e.g. 0.5 M', _c2Controller)),
                const SizedBox(width: 16),
                Expanded(child: _buildInputField('Final Volume (V₂)', 'e.g. 200 mL', _v2Controller)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Clear', style: AppTextStyles.h3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
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
              ],
            ),

            if (_resultMessage != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _resultMessage!,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
