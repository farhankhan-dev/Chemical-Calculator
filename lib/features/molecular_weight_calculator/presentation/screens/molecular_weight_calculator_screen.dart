import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
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

  double? _totalMass;
  List<Map<String, dynamic>> _breakdown = [];
  String? _error;
  List<ChemicalModel> _suggestions = [];
  ChemicalModel? _selectedChemical;

  static const Map<String, double> atomicWeights = {
    'H': 1.008, 'He': 4.0026, 'Li': 6.94, 'Be': 9.0122, 'B': 10.81,
    'C': 12.011, 'N': 14.007, 'O': 15.999, 'F': 18.998, 'Ne': 20.180,
    'Na': 22.990, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.085, 'P': 30.974,
    'S': 32.06, 'Cl': 35.45, 'Ar': 39.95, 'K': 39.098, 'Ca': 40.078,
    'Sc': 44.956, 'Ti': 47.867, 'V': 50.942, 'Cr': 51.996, 'Mn': 54.938,
    'Fe': 55.845, 'Co': 58.933, 'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38,
    'Ga': 69.723, 'Ge': 72.630, 'As': 74.922, 'Se': 78.971, 'Br': 79.904,
    'Kr': 83.798, 'Rb': 85.468, 'Sr': 87.62, 'Y': 88.906, 'Zr': 91.224,
    'Nb': 92.906, 'Mo': 95.95, 'Ru': 101.07, 'Rh': 102.91, 'Pd': 106.42,
    'Ag': 107.87, 'Cd': 112.41, 'In': 114.82, 'Sn': 118.71, 'Sb': 121.76,
    'Te': 127.60, 'I': 126.90, 'Xe': 131.29, 'Cs': 132.91, 'Ba': 137.33,
    'W': 183.84, 'Pt': 195.08, 'Au': 196.97, 'Hg': 200.59, 'Pb': 207.2,
    'Bi': 208.98, 'U': 238.03,
  };

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
    if (formula.isEmpty) return;

    if (_selectedChemical != null && formula == _selectedChemical!.formula) {
      setState(() {
        _totalMass = _selectedChemical!.molecularWeight;
        _error = null;
        _breakdown = []; // Database items bypass breakdown parsing
      });
      FocusScope.of(context).unfocus();
      return;
    }

    if (formula.contains('(') || formula.contains(')')) {
      setState(() {
        _error =
            'Brackets not supported yet. Please expand manually (e.g., N2H8SO4 instead of (NH4)2SO4).';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    final regex = RegExp(r'([A-Z][a-z]*)(\d*)');
    double total = 0.0;
    List<Map<String, dynamic>> breakdown = [];
    bool hasError = false;

    final matches = regex.allMatches(formula);
    if (matches.isEmpty) {
      setState(() {
        _error = 'Invalid chemical formula.';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    final matchedString = matches.map((m) => m.group(0)).join('');
    if (matchedString != formula) {
      setState(() {
        _error = 'Formula contains invalid characters or elements.';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    for (final match in matches) {
      final element = match.group(1)!;
      final countStr = match.group(2)!;
      final count = countStr.isEmpty ? 1 : int.parse(countStr);

      if (!atomicWeights.containsKey(element)) {
        hasError = true;
        _error = 'Unknown element: $element';
        break;
      }

      final weight = atomicWeights[element]!;
      final contribution = weight * count;
      total += contribution;

      final existingIndex =
          breakdown.indexWhere((b) => b['element'] == element);
      if (existingIndex != -1) {
        breakdown[existingIndex]['count'] += count;
        breakdown[existingIndex]['contribution'] += contribution;
      } else {
        breakdown.add({
          'element': element,
          'count': count,
          'weight': weight,
          'contribution': contribution,
        });
      }
    }

    if (hasError) {
      setState(() {
        _totalMass = null;
        _breakdown = [];
      });
    } else {
      setState(() {
        _error = null;
        _totalMass = total;
        _breakdown = breakdown;
      });
    }

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
        title: const Text('Molecular Weight Calculator'),
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
