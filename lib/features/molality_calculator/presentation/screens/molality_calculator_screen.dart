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
  String? _validationError;

  @override
  void dispose() {
    _molesController.dispose();
    _massSolventController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _validationError = null;
    });

    if (_molesController.text.isEmpty || _massSolventController.text.isEmpty) {
      setState(() {
        _validationError = 'Please fill all requirements';
      });
      return;
    }

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

  void _showMolalityNoteDialog(BuildContext context) {
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
                        'Molality Reference Notes',
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
                      _buildNoteCard(
                        title: 'What is Molality?',
                        content: 'm = moles of solute per kilogram of solvent',
                        icon: Icons.science_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Formula',
                        content: 'm = moles of solute ÷ Mass of solvent (kg)\n\nExpanded: m = mass of solute (g) ÷ [MW (g/mol) × mass of solvent (kg)]',
                        icon: Icons.functions,
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Based On',
                        content: 'MASS of solvent, NOT volume of solution',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Temperature Status',
                        content: 'Temperature INDEPENDENT — mass doesn\'t change with temperature',
                        icon: Icons.thermostat_outlined,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Used For',
                        content: 'Colligative properties:\n• Boiling point elevation\n• Freezing point depression',
                        icon: Icons.auto_awesome,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Unit',
                        content: 'mol/kg  or  m',
                        icon: Icons.straighten,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 16),
                      // Key Difference
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ Key Difference from Molarity',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Molarity (M) uses volume of solution (L) → Temperature dependent\n\nMolality (m) uses mass of solvent (kg) → Temperature independent',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
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

  Widget _buildNoteCard({
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
        title: const Text('Molality Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Molality Reference Notes',
            onPressed: () => _showMolalityNoteDialog(context),
          ),
        ],
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

            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _validationError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
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
