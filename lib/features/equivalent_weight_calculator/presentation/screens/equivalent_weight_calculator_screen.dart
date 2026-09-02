import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/utils/formula_parser.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../my_chemicals/data/custom_chemical_repository.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../library/data/library_pinned_repository.dart';
class EquivalentWeightCalculatorScreen extends StatefulWidget {
  const EquivalentWeightCalculatorScreen({super.key});

  @override
  State<EquivalentWeightCalculatorScreen> createState() => _EquivalentWeightCalculatorScreenState();
}

class _EquivalentWeightCalculatorScreenState extends State<EquivalentWeightCalculatorScreen> {
  ChemicalModel? _selectedChemical;
  final FormulaParser _formulaParser = FormulaParser();
  final TextEditingController _formulaController = TextEditingController();

  final TextEditingController _molarMassController = TextEditingController();
  final TextEditingController _nFactorController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double? _result;
  String? _calculationString;

  @override
  void dispose() {
    _formulaController.dispose();
    _molarMassController.dispose();
    _nFactorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _validationError;

  void _calculateManual() {
    setState(() {
      _validationError = null;
    });

    final molarMassText = _molarMassController.text.trim();
    final nFactorText = _nFactorController.text.trim();

    if (molarMassText.isEmpty || nFactorText.isEmpty) {
      setState(() {
        _validationError = 'Please fill all requirements';
      });
      return;
    }

    final molarMass = double.tryParse(molarMassText);
    final nFactor = double.tryParse(nFactorText);
    
    if (molarMass == null || nFactor == null) {
      setState(() {
        _validationError = 'Please enter valid numbers.';
      });
      return;
    }

    if (nFactor == 0) {
      setState(() {
        _validationError = 'n-factor cannot be zero.';
      });
      return;
    }

    setState(() {
      _selectedChemical = null; // Clear chemical if manually calculating
      _result = molarMass / nFactor;
      
      String header = '';
      if (_formulaController.text.trim().isNotEmpty) {
        header = 'Equivalent weight of ${_formulaController.text.trim()}:\n';
      } else {
        header = 'Manual equivalent weight calculation:\n';
      }
      
      _calculationString = '${header}Eq. Weight = Molar Mass / n-factor\n'
          '= ${FormatUtils.format(molarMass)} / ${FormatUtils.format(nFactor)} = ${FormatUtils.format(_result!)} g/eq';
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

  void _selectChemical(ChemicalModel chem) {
    setState(() {
      _selectedChemical = chem;
      _formulaController.clear();
      _molarMassController.clear();
      _nFactorController.clear();
      
      if (chem.equivalentWeight != null) {
        _result = chem.equivalentWeight;
        final nFactor = chem.molecularWeight / chem.equivalentWeight!;
        _calculationString = 'Equivalent weight of ${chem.name} (${chem.formula}):\n'
            'Eq. Weight = Molar Mass / n-factor\n'
            '= ${FormatUtils.format(chem.molecularWeight)} / ${FormatUtils.format(nFactor)} = ${FormatUtils.format(_result!)} g/eq';
      } else {
        _result = null;
        _calculationString = 'Equivalent weight value N/A\nPlease use manual entry.';
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

  void _showPinnedChemicalsBottomSheet(BuildContext context) async {
    final customRepo = CustomChemicalRepository();
    final allCustom = await customRepo.getAll();
    final customPinnedChemicals = allCustom.where((c) => c.isPinned).toList();
    
    final libraryRepo = LibraryPinnedRepository();
    final libraryPinnedIds = await libraryRepo.getPinnedIds();
    final allLibrary = await ChemicalLocalDatasource().getAllChemicals();
    final libraryPinnedChemicals = allLibrary.where((c) => libraryPinnedIds.contains(c.id)).toList();
    
    if (!mounted) return;
    if (!context.mounted) return;
    final searchQueryNotifier = ValueNotifier<String>('');
    int currentView = 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (currentView != 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                              onPressed: () {
                                setModalState(() {
                                  currentView = 0;
                                  searchQueryNotifier.value = '';
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (currentView != 0) const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              currentView == 0 ? 'Pinned Chemicals' : currentView == 1 ? 'Library Pinned' : 'My Chemicals Pinned',
                              style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentView == 0) ...[
                      ListTile(
                        leading: const Icon(Icons.library_books, color: AppColors.primary),
                        title: const Text('Library Pinned Chemicals'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setModalState(() => currentView = 1),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.science, color: AppColors.primary),
                        title: const Text('My Chemical Pinned Chemicals'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setModalState(() => currentView = 2),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                          onChanged: (val) => searchQueryNotifier.value = val.trim(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: searchQueryNotifier,
                          builder: (context, searchQuery, child) {
                            final filteredCustom = customPinnedChemicals.where((c) {
                              if (searchQuery.isEmpty) return true;
                              return c.name.toLowerCase().contains(searchQuery.toLowerCase()) || c.formula.toLowerCase().contains(searchQuery.toLowerCase());
                            }).toList();
                            
                            final filteredLibrary = libraryPinnedChemicals.where((c) {
                              if (searchQuery.isEmpty) return true;
                              return c.name.toLowerCase().contains(searchQuery.toLowerCase()) || c.formula.toLowerCase().contains(searchQuery.toLowerCase());
                            }).toList();

                            if ((currentView == 1 && libraryPinnedChemicals.isEmpty) || (currentView == 2 && customPinnedChemicals.isEmpty)) {
                              return Center(child: Text('No pinned chemicals found in this section.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)));
                            } else if ((currentView == 1 && filteredLibrary.isEmpty) || (currentView == 2 && filteredCustom.isEmpty)) {
                              return Center(child: Text('No matching chemicals found.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)));
                            }

                            final list = currentView == 1 ? filteredLibrary : filteredCustom;
                            final trailingText = currentView == 1 ? (chem) => chem.category : (chem) => 'Custom';
                            
                            return ListView.builder(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final dynamic chem = list[index];
                                return ListTile(
                                  leading: const Icon(Icons.push_pin, color: AppColors.primary),
                                  title: Text(chem.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                  subtitle: Text(chem.formula, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.primaryDark)),
                                  trailing: Text(trailingText(chem), style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _formulaController.text = chem.formula;
                                      _molarMassController.text = chem.molecularWeight.toStringAsFixed(4);
                                      _selectedChemical = null;
                                      _result = null;
                                      _calculationString = null;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showEwNoteDialog(BuildContext context) {
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
                        'Equivalent Weight Reference Notes',
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
                        title: 'What is Equivalent Weight?',
                        content: 'Mass of a substance that reacts with or displaces 1 gram of hydrogen, 8 grams of oxygen, or 35.5 grams of chlorine.',
                        icon: Icons.scale_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 What to Remember',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Equivalent weight = Molar Mass ÷ n-factor\n'
                              '• It is used mainly in titrations and volumetric analysis.\n'
                              '• For some compounds, it changes depending on the reaction type (acid-base vs redox).',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEwNoteSection(
                        title: '✅ Fixed EW — Single, definite EW value',
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                        rows: const [
                          ['Acetic Acid', 'CH₃COOH', '60.052 g/eq', 'Acid (1H⁺)'],
                          ['Sulfuric Acid', 'H₂SO₄', '49.036 g/eq', 'Acid (2H⁺)'],
                          ['Sodium Hydroxide', 'NaOH', '39.997 g/eq', 'Base (1OH⁻)'],
                          ['Calcium Hydroxide', 'Ca(OH)₂', '37.046 g/eq', 'Base (2OH⁻)'],
                          ['Sodium Chloride', 'NaCl', '58.44 g/eq', 'Salt (1 charge)'],
                          ['Sodium Phosphate', 'Na₃PO₄', '54.647 g/eq', 'Salt (3 charge)'],
                          ['Sulfate Ion', 'SO₄²⁻', '48.03 g/eq', 'Ion (2 charge)'],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildEwNoteSection(
                        title: '⚠️ Variable EW — EW depends on reaction/pH',
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                        rows: const [
                          ['KMnO₄', 'Acid (5e⁻)', '31.61 g/eq', 'Neutral/Base (3e⁻) → 52.68 g/eq'],
                          ['KMnO₄', 'Strong Base (1e⁻)', '158.03 g/eq', 'Redox varies by pH'],
                          ['K₂Cr₂O₇', 'Acid (6e⁻)', '49.03 g/eq', 'Neutral/Base (3e⁻) → 98.06 g/eq'],
                          ['KIO₃', 'Acid (6e⁻)', '35.67 g/eq', 'Neutral/Base (4e⁻) → 53.50 g/eq'],
                          ['KClO₃', 'Acid (6e⁻)', '20.42 g/eq', 'Varies for other reactions'],
                          ['Fe₂O₃', 'Salt (charge)', '26.62 g/eq', 'Redox varies'],
                          ['H₂CrO₄', 'Acid (2H⁺)', '59.01 g/eq', 'Redox varies'],
                          ['Cr₂O₃', 'Salt (charge)', '25.33 g/eq', 'Redox varies'],
                          ['PbO₂', 'Salt (charge)', '59.80 g/eq', 'Redox varies'],
                          ['K₄Fe(CN)₆', 'Salt (charge)', '92.09 g/eq', 'Redox varies'],
                          ['Al(OH)₃', 'As base (3OH⁻)', '26.00 g/eq', 'As acid (1H⁺) → 78.00 / (2H⁺) → 39.00'],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildEwNoteSection(
                        title: '🔶 Special Cases',
                        color: Colors.deepOrange.shade800,
                        bgColor: Colors.deepOrange.shade50,
                        rows: const [
                          ['NH₄Cl', 'Salt (charge)', '53.49 g/eq', 'Sublimes/decomposes — no liquid phase'],
                          ['HClO₄', 'Acid (1H⁺)', '100.46 g/eq', 'Unstable pure compound'],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildEwNoteSection(
                        title: '❌ No Fixed EW — Polymers / Unstable species',
                        color: Colors.red.shade800,
                        bgColor: Colors.red.shade50,
                        rows: const [
                          ['Cellulose', '(C₆H₁₀O₅)ₙ', 'N/A', 'Chain length varies'],
                          ['Polystyrene', '(C₈H₈)ₙ', 'N/A', 'Chain length varies'],
                          ['Polyurethane Foam', 'C₂₇H₃₆N₂O₁₀', 'N/A', 'Complex variable structure'],
                          ['Phenyl Radical', 'C₆H₅', 'N/A', 'Unstable radical — not a stable compound'],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'ℹ️ The app displays the most commonly used EW value with a valid reason. For variable EW compounds, the condition/context is shown alongside the value.',
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

  Widget _buildEwNoteSection({
    required String title,
    required Color color,
    required Color bgColor,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const Divider(height: 1),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row[0],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${row[2]}  •  ${row[1]}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black87,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        row[3],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black54,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eq. Weight Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'EW Reference Notes',
            onPressed: () => _showEwNoteDialog(context),
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
                  Image.asset('assets/images/Equivalent_Calculator_icon.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eq. Weight = Molar Mass / Valency',
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

            // Select Chemical
            Text('Select Chemical', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final chem = await ChemicalSelector.show(context);
                if (chem != null) {
                  _selectChemical(chem);
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
            
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: AppTextStyles.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Write Formula', style: AppTextStyles.label),
                InkWell(
                  onTap: () => _showPinnedChemicalsBottomSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.push_pin_outlined, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Pinned',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _formulaController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Enter chemical formula (e.g. H2O, NaCl)...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.edit_note_outlined, color: AppColors.primary),
                suffixIcon: _formulaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                        onPressed: () {
                          _formulaController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  final parseResult = _formulaParser.parse(val);
                  if (parseResult.isValid) {
                    _molarMassController.text = parseResult.molarMass.toStringAsFixed(4);
                  }
                  if (_selectedChemical != null) {
                    _selectedChemical = null;
                    _result = null;
                    _calculationString = null;
                  }
                }
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: AppTextStyles.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Manual Entry
            Text('Manual Calculation', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Molar Mass', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _molarMassController,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: 'g/mol',
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
                      Text('n-factor', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nFactorController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _calculateManual(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Calculate Manually', style: AppTextStyles.h3.copyWith(color: Colors.white)),
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

            if (_validationError == null && (_result != null || _calculationString != null)) ...[
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
                    if (_result != null) ...[
                      Text(
                        'Equivalent Weight',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${FormatUtils.format(_result!)} g/eq',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Calculation',
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _calculationString ?? '',
                      style: AppTextStyles.mono.copyWith(color: AppColors.primaryDark, fontSize: 12),
                    ),
                    if (_result == null && _selectedChemical != null) ...[ 
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Equivalent Weight is N/A — Why?',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"${_selectedChemical!.name}" does not have Equivalent weight fixed value.\n\n'
                        'Equivalent Weight = Molar Mass ÷ n-factor\n\n'
                        'The n-factor (valency factor) tells how many H⁺ or OH⁻ ions a compound donates or accepts in a reaction. For some chemicals — like pure elements, organic solvents, or compounds with variable valency — no single fixed n-factor can be assigned.\n\n'
                        'You can still calculate manually using the fields above if you know the n-factor for your specific reaction.',
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
