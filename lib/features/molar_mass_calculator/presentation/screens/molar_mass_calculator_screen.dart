import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
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
  
  double? _totalMass;
  List<Map<String, dynamic>> _breakdown = [];
  String? _error;
  List<ChemicalModel> _suggestions = [];
  ChemicalModel? _selectedChemical;

  static const Map<String, double> atomicWeights = {
    'H': 1.008, 'He': 4.0026, 'Li': 6.94, 'Be': 9.0122, 'B': 10.81, 'C': 12.011, 'N': 14.007, 'O': 15.999, 'F': 18.998, 'Ne': 20.180,
    'Na': 22.990, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.085, 'P': 30.974, 'S': 32.06, 'Cl': 35.45, 'Ar': 39.95, 'K': 39.098, 'Ca': 40.078,
    'Sc': 44.956, 'Ti': 47.867, 'V': 50.942, 'Cr': 51.996, 'Mn': 54.938, 'Fe': 55.845, 'Co': 58.933, 'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38,
    'Ga': 69.723, 'Ge': 72.630, 'As': 74.922, 'Se': 78.971, 'Br': 79.904, 'Kr': 83.798, 'Rb': 85.468, 'Sr': 87.62, 'Y': 88.906, 'Zr': 91.224,
    'Nb': 92.906, 'Mo': 95.95, 'Ru': 101.07, 'Rh': 102.91, 'Pd': 106.42, 'Ag': 107.87, 'Cd': 112.41, 'In': 114.82, 'Sn': 118.71, 'Sb': 121.76,
    'Te': 127.60, 'I': 126.90, 'Xe': 131.29, 'Cs': 132.91, 'Ba': 137.33, 'W': 183.84, 'Pt': 195.08, 'Au': 196.97, 'Hg': 200.59, 'Pb': 207.2,
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

    if (_selectedChemical != null && _selectedChemical!.formula != query.trim()) {
      setState(() => _selectedChemical = null);
    }

    final results = await _datasource.search(query);
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  void _calculate() {
    String formula = _formulaController.text.trim();
    if (formula.isEmpty) return;
    
    // Basic parser for flat formulas like H2SO4, C6H12O6
    final regex = RegExp(r'([A-Z][a-z]*)(\d*)');
    double total = 0.0;
    List<Map<String, dynamic>> breakdown = [];
    bool hasError = false;

    if (_selectedChemical != null && formula == _selectedChemical!.formula) {
      setState(() {
        _totalMass = _selectedChemical!.molecularWeight;
        _error = null;
        _breakdown = [];
      });
      FocusScope.of(context).unfocus();
      return;
    }

    // Check if there are unsupported characters like brackets
    if (formula.contains('(') || formula.contains(')')) {
      setState(() {
        _error = 'Brackets are not supported in this version. Please multiply out the elements (e.g., N2H8S1O4 instead of (NH4)2SO4).';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    final matches = regex.allMatches(formula);
    if (matches.isEmpty) {
      setState(() {
        _error = 'Invalid chemical formula format.';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    // Check if the whole string was matched
    String matchedString = matches.map((m) => m.group(0)).join('');
    if (matchedString != formula) {
      setState(() {
        _error = 'Formula contains invalid characters or elements.';
        _totalMass = null;
        _breakdown = [];
      });
      return;
    }

    for (final match in matches) {
      String element = match.group(1)!;
      String countStr = match.group(2)!;
      int count = countStr.isEmpty ? 1 : int.parse(countStr);

      if (!atomicWeights.containsKey(element)) {
        hasError = true;
        _error = 'Unknown element: $element';
        break;
      }

      double weight = atomicWeights[element]!;
      double contribution = weight * count;
      total += contribution;

      // Check if we already have this element in breakdown (e.g., CH3COOH -> C appears twice)
      int existingIndex = breakdown.indexWhere((b) => b['element'] == element);
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
        title: const Text('Molar Mass Calculator'),
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
