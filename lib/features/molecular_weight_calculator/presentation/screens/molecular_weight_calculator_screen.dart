import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/utils/formula_parser.dart';
import '../../../../features/periodic_table/data/element_repository.dart';
import '../../../home/presentation/widgets/chemical_search_bar.dart';

class MolecularWeightCalculatorScreen extends StatefulWidget {
  const MolecularWeightCalculatorScreen({super.key});

  @override
  State<MolecularWeightCalculatorScreen> createState() =>
      _MolecularWeightCalculatorScreenState();
}

class _MolecularWeightCalculatorScreenState
    extends State<MolecularWeightCalculatorScreen> {
  final TextEditingController _formulaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();

  final FormulaParser _formulaParser = FormulaParser();

  double? _totalMass;
  List<Map<String, dynamic>> _breakdown = [];
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
    
    // If they start typing something else, clear the selected chemical
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
          _breakdown = [];
          _error = null;
        });
      }
      return;
    }

    if (_selectedChemical != null && formula == _selectedChemical!.formula) {
      setState(() {
        _totalMass = _selectedChemical!.molecularWeight;
        _error = null;
        _breakdown = []; // Database items bypass breakdown parsing
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
        _breakdown = [];
      });
      return;
    }

    final repo = ElementRepository();
    final allElements = repo.getAllElements();
    final breakdown = <Map<String, dynamic>>[];
    
    for (final entry in result.elementCounts.entries) {
      final symbol = entry.key;
      final count = entry.value;
      final element = allElements.firstWhere((e) => e.symbol == symbol);
      final weight = element.atomicMass;
      final contribution = weight * count;
      
      breakdown.add({
        'element': symbol,
        'count': count,
        'weight': weight,
        'contribution': contribution,
      });
    }

    setState(() {
      _totalMass = result.molarMass;
      _breakdown = breakdown;
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

  void _showMWNoteDialog(BuildContext context) {
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
                        'Molecular Weight Reference Notes',
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
                      _buildMWNoteCard(
                        title: 'What is Molecular Weight?',
                        content: 'Mass of 1 mole of molecules',
                        icon: Icons.scale_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildMWNoteCard(
                        title: 'Formula',
                        content: 'MW = Σ (Atomic Weight × Number of atoms)\n\nMW = Sum of (Atomic Weightᵢ × Number of Atomsᵢ)',
                        icon: Icons.functions,
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildMWNoteCard(
                        title: 'Calculated From',
                        content: 'Chemical formula using atomic weights from Periodic Table',
                        icon: Icons.table_chart_outlined,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildMWNoteCard(
                        title: 'Unit',
                        content: 'g/mol',
                        icon: Icons.straighten,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildMWNoteCard(
                        title: 'Status',
                        content: 'FIXED value for a given compound (does not change)',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildMWNoteCard(
                        title: 'Required For',
                        content: 'Molarity, molality, normality, stoichiometry calculations',
                        icon: Icons.auto_awesome,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 16),
                      // Key Points
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Text(
                                '📌 Key Points',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.orange.shade800,
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
                                    '• MW is the SUM of all atomic weights in the formula',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Used to convert grams ↔ moles',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• For elements (O₂, F₂, Cl₂, Br₂, I₂), use molecular formula (not atomic weight)',
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
                      const SizedBox(height: 12),
                      // Relationship note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'ℹ️ Molecular Weight is numerically the same as Molar Mass — but they are different concepts. MW refers to a single molecule; Molar Mass refers to 1 mole of substance.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
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

  Widget _buildMWNoteCard({
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
        title: const Text('Molecular Weight Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Molecular Weight Reference Notes',
            onPressed: () => _showMWNoteDialog(context),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.scale_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Molecular Weight Formula',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MW = Σ (nᵢ × Aᵢ)',
                          style: AppTextStyles.monoLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Where:\n  nᵢ = number of atoms of element i\n  Aᵢ = atomic weight of element i (g/mol)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            ChemicalSearchBar(
              controller: _formulaController,
              suggestions: _suggestions,
              hintText: 'e.g. NaCl or H2O',
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Calculate Molecular Weight',
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
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                ),
              ),
            ],

            if (_totalMass != null) ...[
              const SizedBox(height: AppSpacing.xl),

              // Result Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.headerStart, AppColors.headerEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Molecular Weight',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${FormatUtils.format(_totalMass!)} g/mol',
                      style: AppTextStyles.h1.copyWith(
                          color: Colors.white, fontSize: 36),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedChemical != null
                          ? 'for: ${_selectedChemical!.name} (${_selectedChemical!.formula})'
                          : 'for: ${_formulaController.text.trim()}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Step-by-step calculation
              Text('Step-by-Step Calculation', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MW = Σ (Number of Atoms × Atomic Weight)',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._breakdown.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${item['element']}: ${item['weight']} × ${item['count']} = ${FormatUtils.format(item['contribution'])}',
                          style: AppTextStyles.mono.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(
                      'Total = ${FormatUtils.format(_totalMass!)} g/mol',
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),




            ],
          ],
        ),
      ),
    );
  }
}
