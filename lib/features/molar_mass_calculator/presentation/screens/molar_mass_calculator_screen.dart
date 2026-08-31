import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/utils/formula_parser.dart';

import '../../../home/presentation/widgets/chemical_search_bar.dart';

class MolarMassCalculatorScreen extends StatefulWidget {
  const MolarMassCalculatorScreen({super.key});

  @override
  State<MolarMassCalculatorScreen> createState() => _MolarMassCalculatorScreenState();
}

class _MolarMassCalculatorScreenState extends State<MolarMassCalculatorScreen> {
  final TextEditingController _formulaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();
  final FormulaParser _formulaParser = FormulaParser();

  double? _totalMass;

  String? _error;
  List<ChemicalModel> _suggestions = [];
  ChemicalModel? _selectedChemical;

  @override
  void dispose() {
    _formulaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _selectedChemical = null;
        });
      }
      return;
    }

    if (_selectedChemical != null && _selectedChemical!.formula != query.trim()) {
      setState(() => _selectedChemical = null);
    }

    final results = await _datasource.search(query);
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  void _calculate() {
    final formula = _formulaController.text.trim();
    if (formula.isEmpty) {
      if (mounted) {
        setState(() {
          _totalMass = null;
          _error = null;
        });
      }
      return;
    }

    if (_selectedChemical != null && formula == _selectedChemical!.formula) {
      setState(() {
        _totalMass = _selectedChemical!.molecularWeight;
        _error = null;
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
      return;
    }

    final result = _formulaParser.parse(formula);
    if (!result.isValid) {
      setState(() {
        _error = result.error;
        _totalMass = null;
      });
      return;
    }

    setState(() {
      _totalMass = result.molarMass;
      _error = null;
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

  void _showMolarMassNoteDialog(BuildContext context) {
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
                        'Molar Mass Reference Notes',
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
                        title: 'What is Molar Mass?',
                        content: 'Mass of 1 mole of a substance',
                        icon: Icons.scale_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Formula',
                        content: 'Molar Mass = mass of substance ÷ number of moles',
                        icon: Icons.functions,
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Numeric Relationship',
                        content: 'Numerically EQUAL to Molecular Weight (MW)',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Unit',
                        content: 'g/mol',
                        icon: Icons.straighten,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Used For',
                        content: 'Converting mass to moles and moles to mass',
                        icon: Icons.science_outlined,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 16),
                      // Concept Difference
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
                              '⚠️ Concept Difference',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MW is mass of 1 molecule; Molar Mass is mass of 1 mole',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Key Points
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Text(
                                '📌 Key Points',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.blue.shade800,
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
                                    '1. Molar Mass (g/mol) = Mass (g) ÷ Moles (mol)',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '2. Same numeric value as MW (Molecular Weight)',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '3. Concept difference: MW is per molecule, Molar Mass is per mole',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '4. Used in stoichiometry to calculate mass from moles or moles from mass',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
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
        title: const Text('Molar Mass Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Molar Mass Reference Notes',
            onPressed: () => _showMolarMassNoteDialog(context),
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
                  Image.asset('assets/images/Molar_Mass_icon.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Molar Mass = ∑ (Number of Atoms × Atomic Weight)',
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
              'Calculate precise molar mass from chemical formula.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            ChemicalSearchBar(
              controller: _formulaController,
              suggestions: _suggestions,
              hintText: 'e.g. H2SO4 or C6H12O6',
              showSearchIcon: false,
              onChanged: _onSearchChanged,
              onSelected: (chem) {
                _formulaController.text = chem.formula;
                setState(() {
                  _suggestions = [];
                  _selectedChemical = chem;
                });
                FocusManager.instance.primaryFocus?.unfocus();
                _calculate();
              },
              onClear: () {
                _formulaController.clear();
                setState(() {
                  _suggestions = [];
                  _selectedChemical = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),

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
                  'Calculate Molar Mass',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                ),
              ),
            ],

            if (_totalMass != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Molar Mass',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${FormatUtils.format(_totalMass!)} g/mol',
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
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
