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
  String? _validationError;

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
    setState(() {
      _validationError = null;
    });

    int emptyCount = 0;
    if (_c1Controller.text.isEmpty) emptyCount++;
    if (_v1Controller.text.isEmpty) emptyCount++;
    if (_c2Controller.text.isEmpty) emptyCount++;
    if (_v2Controller.text.isEmpty) emptyCount++;

    if (emptyCount != 1) {
      setState(() {
        _validationError = 'Please fill all requirements (leave exactly 1 empty)';
      });
      return;
    }

    final c1 = double.tryParse(_c1Controller.text);
    final v1 = double.tryParse(_v1Controller.text);
    final c2 = double.tryParse(_c2Controller.text);
    final v2 = double.tryParse(_v2Controller.text);

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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
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
      _validationError = null;
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

  void _showDilutionNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dilution Reference Notes',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(Icons.close, color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDilutionNoteCard(
                        title: 'What is Dilution?',
                        content: 'Process of making a solution less concentrated by adding solvent',
                        icon: Icons.water_drop_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildDilutionNoteCard(
                        title: 'Formula',
                        content: 'C₁V₁ = C₂V₂\n\nWhere:\n  C₁ = Initial concentration\n  V₁ = Initial volume\n  C₂ = Final concentration\n  V₂ = Final volume',
                        icon: Icons.functions,
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildDilutionNoteCard(
                        title: 'Main Point',
                        content: 'The number of moles of solute REMAINS CONSTANT during dilution. Only the volume changes (solvent is added).',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildDilutionNoteCard(
                        title: 'Temperature Status',
                        content: 'Temperature dependent — volume changes with temperature',
                        icon: Icons.thermostat_outlined,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildDilutionNoteCard(
                        title: 'Used For',
                        content: 'Preparing solutions from stock solutions',
                        icon: Icons.science_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 16),
                      // Key Rules
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Text(
                                '⚠️ Key Rules',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• C₁V₁ = C₂V₂ — Moles of solute before = Moles after',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• V₂ must be > V₁ — dilution means more volume',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Units must be consistent — both in L or both in mL',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Common Applications
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🧪 Common Applications',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Preparing dilute solutions from concentrated stock\n• Serial dilutions in labs\n• Adjusting concentration for experiments',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.black87,
                                height: 1.5,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDilutionNoteCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black87,
                    height: 1.5,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Dilution Reference Notes',
            onPressed: () => _showDilutionNoteDialog(context),
          ),
        ],
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
                  Image.asset('assets/images/Dilution_calculator_icon.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'C₁V₁ = C₂V₂',
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
                      backgroundColor: Colors.purple.shade50,
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Clear', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
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

            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _validationError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_resultMessage != null && _validationError == null) ...[
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
                      _resultMessage!,
                      style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                      textAlign: TextAlign.center,
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
