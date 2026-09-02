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

class MassCalculatorScreen extends StatefulWidget {
  const MassCalculatorScreen({super.key});

  @override
  State<MassCalculatorScreen> createState() => _MassCalculatorScreenState();
}

class _MassCalculatorScreenState extends State<MassCalculatorScreen> {
  bool _isMassNeeded = true; // false = Volume Needed
  ChemicalModel? _selectedChemical;
  final FormulaParser _formulaParser = FormulaParser();
  final TextEditingController _formulaController = TextEditingController();
  
  bool _isMolarity = true; // false = Normality
  bool _isVolMl = true; // false = Liters
  
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _volMassController = TextEditingController(); // Volume if Mass Needed, Mass if Volume Needed
  final ScrollController _scrollController = ScrollController();

  double? _result;
  String? _calculationString;
  String? _validationError;

  @override
  void dispose() {
    _formulaController.dispose();
    _targetController.dispose();
    _volMassController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _validationError = null;
    });

    final manualFormulaText = _formulaController.text.trim();
    double? molarMass;
    double? eqWeight;

    if (manualFormulaText.isNotEmpty) {
      final parseResult = _formulaParser.parse(manualFormulaText);
      if (!parseResult.isValid) {
        setState(() {
          _validationError = parseResult.error ?? 'Please enter a valid chemical formula.';
        });
        return;
      }
      molarMass = parseResult.molarMass;
    } else if (_selectedChemical != null) {
      molarMass = _selectedChemical!.molecularWeight;
      eqWeight = _selectedChemical!.equivalentWeight;
    } else {
      setState(() {
        _validationError = 'Please fill all requirements';
      });
      return;
    }

    final targetText = _targetController.text.trim();
    final volMassText = _volMassController.text.trim();

    if (targetText.isEmpty || volMassText.isEmpty) {
      setState(() {
        _validationError = 'Please fill all requirements';
      });
      return;
    }
    
    final target = double.tryParse(targetText);
    final volMass = double.tryParse(volMassText);
    
    if (target == null || volMass == null) {
      setState(() {
        _validationError = 'Please enter valid numbers.';
      });
      return;
    }

    if (!_isMassNeeded && target == 0) {
      setState(() {
        _validationError = 'Concentration cannot be zero when calculating volume.';
      });
      return;
    }

    setState(() {
      if (_isMassNeeded) {
        // Mass = Concentration * Volume(L) * Weight
        final volLiters = _isVolMl ? volMass / 1000 : volMass;
        if (_isMolarity) {
          _result = target * volLiters * molarMass!;
          _calculationString = 'Mass = Molarity × Molar Mass × Volume (L)\n'
              '= ${FormatUtils.format(target)} × ${FormatUtils.format(molarMass)} × ${FormatUtils.format(volLiters)} = ${FormatUtils.format(_result!)} g';
        } else {
          if (eqWeight == null) {
            _result = null;
            _calculationString = 'Cannot calculate using Normality:\nEquivalent weight data is missing for this chemical.';
            return;
          }
          _result = target * volLiters * eqWeight;
          _calculationString = 'Mass = Normality × Eq. Weight × Volume (L)\n'
              '= ${FormatUtils.format(target)} × ${FormatUtils.format(eqWeight)} × ${FormatUtils.format(volLiters)} = ${FormatUtils.format(_result!)} g';
        }
      } else {
        // Volume Needed (L) = Mass / (Concentration * Weight)
        // Here volMass input is actually Mass (g)
        if (_isMolarity) {
          final volL = volMass / (target * molarMass!);
          _result = _isVolMl ? volL * 1000 : volL;
          _calculationString = 'Volume (L) = Mass / (Molarity × Molar Mass)\n'
              '= ${FormatUtils.format(volMass)} / (${FormatUtils.format(target)} × ${FormatUtils.format(molarMass)}) = ${FormatUtils.format(volL)} L';
        } else {
          if (eqWeight == null) {
            _result = null;
            _calculationString = 'Cannot calculate using Normality:\nEquivalent weight data is missing for this chemical.';
            return;
          }
          final volL = volMass / (target * eqWeight);
          _result = _isVolMl ? volL * 1000 : volL;
          _calculationString = 'Volume (L) = Mass / (Normality × Eq. Weight)\n'
              '= ${FormatUtils.format(volMass)} / (${FormatUtils.format(target)} × ${FormatUtils.format(eqWeight)}) = ${FormatUtils.format(volL)} L';
        }
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
    // 0 = Menu, 1 = Library Pinned, 2 = My Chemicals Pinned
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
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header row with optional backtrack button
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
                              currentView == 0
                                  ? 'Pinned Chemicals'
                                  : currentView == 1
                                      ? 'Library Pinned'
                                      : 'My Chemicals Pinned',
                              style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (currentView == 0) ...[
                      // Menu View
                      ListTile(
                        leading: const Icon(Icons.library_books, color: AppColors.primary),
                        title: const Text('Library Pinned Chemicals'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setModalState(() {
                            currentView = 1;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.science, color: AppColors.primary),
                        title: const Text('My Chemical Pinned Chemicals'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setModalState(() {
                            currentView = 2;
                          });
                        },
                      ),
                    ] else ...[
                      // List View
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
                            searchQueryNotifier.value = val.trim();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: searchQueryNotifier,
                          builder: (context, searchQuery, child) {
                            final filteredCustom = customPinnedChemicals.where((c) {
                              if (searchQuery.isEmpty) return true;
                              final q = searchQuery.toLowerCase();
                              return c.name.toLowerCase().contains(q) || c.formula.toLowerCase().contains(q);
                            }).toList();
                            
                            final filteredLibrary = libraryPinnedChemicals.where((c) {
                              if (searchQuery.isEmpty) return true;
                              final q = searchQuery.toLowerCase();
                              return c.name.toLowerCase().contains(q) || c.formula.toLowerCase().contains(q);
                            }).toList();

                            final isLibraryEmpty = currentView == 1 && libraryPinnedChemicals.isEmpty;
                            final isCustomEmpty = currentView == 2 && customPinnedChemicals.isEmpty;

                            if (isLibraryEmpty || isCustomEmpty) {
                              return Center(
                                child: Text(
                                  'No pinned chemicals found in this section.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              );
                            } else if (currentView == 1 && filteredLibrary.isEmpty) {
                              return Center(
                                child: Text(
                                  'No matching chemicals found.',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              );
                            } else if (currentView == 2 && filteredCustom.isEmpty) {
                              return Center(
                                child: Text(
                                  'No matching chemicals found.',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              );
                            }

                            if (currentView == 1) {
                              return ListView.builder(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                itemCount: filteredLibrary.length,
                                itemBuilder: (context, index) {
                                  final chem = filteredLibrary[index];
                                  return ListTile(
                                    leading: const Icon(Icons.push_pin, color: AppColors.primary),
                                    title: Text(chem.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    subtitle: Text(chem.formula, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.primaryDark)),
                                    trailing: Text(chem.category, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _formulaController.text = chem.formula;
                                      _selectedChemical = null;
                                      setState(() {});
                                      
                                      if (_targetController.text.isNotEmpty && _volMassController.text.isNotEmpty) {
                                        _calculate();
                                      }
                                    },
                                  );
                                },
                              );
                            } else {
                              return ListView.builder(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                itemCount: filteredCustom.length,
                                itemBuilder: (context, index) {
                                  final chem = filteredCustom[index];
                                  return ListTile(
                                    leading: const Icon(Icons.push_pin, color: AppColors.primary),
                                    title: Text(chem.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    subtitle: Text(chem.formula, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.primaryDark)),
                                    trailing: Text('Custom', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _formulaController.text = chem.formula;
                                      _selectedChemical = null;
                                      setState(() {});
                                      
                                      if (_targetController.text.isNotEmpty && _volMassController.text.isNotEmpty) {
                                        _calculate();
                                      }
                                    },
                                  );
                                },
                              );
                            }
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

  void _showMassNoteDialog(BuildContext context) {
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
                        'Mass Reference Notes',
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
                        title: 'What is Mass?',
                        content: 'Amount of substance measured in grams',
                        icon: Icons.scale_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Formulas',
                        content: '1. Mass = Moles × Molecular Weight (MW)\n2. Mass = Molarity × Volume (L) × MW',
                        icon: Icons.functions,
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Unit',
                        content: 'grams (g) or kilograms (kg)',
                        icon: Icons.straighten,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Used For',
                        content: 'Preparing solutions, stoichiometry, reactions',
                        icon: Icons.science_outlined,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 16),
                      // Conversion Table
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
                                '📐 Conversions',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _buildNFactorRow('Mass from Moles', 'mass = moles × MW'),
                            _buildNFactorRow('Mass from Molarity', 'mass = M × Volume (L) × MW'),
                            _buildNFactorRow('Mass from Density', 'mass = Volume × Density'),
                            _buildNFactorRow('Volume from Mass', 'Volume (L) = mass ÷ (M × MW)'),
                            _buildNFactorRow('Volume from Moles', 'Volume (L) = moles ÷ M'),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Key Concepts
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Key Concepts',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Mass is conserved in chemical reactions (Law of Conservation of Mass)\n'
                              '• Mass depends on the amount of substance, not on temperature or pressure\n'
                              '• Always convert mL to L when using molarity: 1 L = 1000 mL',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Examples
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
                              '📝 Examples',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Example 1 - Mass needed\nHow many grams of NaCl are needed to make 500 mL of 0.5 M solution?\n'
                              'mass = M × V(L) × MW = 0.5 × 0.5 × 58.44 = 14.61 g\n\n'
                              'Example 2 - Volume needed\nWhat volume of solution can be made with 10 g of NaOH at 0.1 M?\n'
                              'V(L) = mass ÷ (M × MW) = 10 ÷ (0.1 × 40) = 2.5 L = 2500 mL',
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

  Widget _buildNFactorRow(String type, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black87,
                fontSize: 11,
              ),
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
        title: const Text('Mass Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Mass Reference Notes',
            onPressed: () => _showMassNoteDialog(context),
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
                  Image.asset('assets/images/Mass_calculator _icon.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mass (g) = Concentration (M/N) × Volume (L) × Molar/Eq. Mass',
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

            // Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMassNeeded = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isMassNeeded ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mass Needed',
                          style: TextStyle(
                            color: _isMassNeeded ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMassNeeded = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isMassNeeded ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Volume Needed',
                          style: TextStyle(
                            color: !_isMassNeeded ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                if (val.isNotEmpty && _selectedChemical != null) {
                  _selectedChemical = null;
                }
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Target
            Text('Target', style: AppTextStyles.label),
            Row(
              children: [
                _buildCustomRadio(
                  selected: _isMolarity,
                  onTap: () => setState(() => _isMolarity = true),
                  label: 'Molarity (M)',
                ),
                const SizedBox(width: 20),
                _buildCustomRadio(
                  selected: !_isMolarity,
                  onTap: () => setState(() => _isMolarity = false),
                  label: 'Normality (N)',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Value', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _targetController,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: _isMolarity ? 'M' : 'N',
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
                      Text(_isMassNeeded ? 'Volume' : 'Mass', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _volMassController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _calculate(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixIcon: _isMassNeeded ? DropdownButtonHideUnderline(
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
                          ) : Padding(
                            padding: const EdgeInsets.only(top: 14.0, right: 12.0),
                            child: Text('g', style: AppTextStyles.bodyMedium, textAlign: TextAlign.right),
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

            if (_result != null || (_calculationString != null && _calculationString!.contains('Cannot calculate'))) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _result == null
                      ? Colors.orange.withValues(alpha: 0.1)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: _result == null
                      ? Border.all(color: Colors.orange.withValues(alpha: 0.4))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_result != null) ...[
                      Text(
                        _isMassNeeded ? 'Mass Needed' : 'Volume Needed',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMassNeeded
                            ? '${FormatUtils.format(_result!)} g'
                            : '${FormatUtils.format(_result!)} ${_isVolMl ? 'mL' : 'L'}',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Pure substance)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
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
                    if (_result == null && _calculationString != null) ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Result is N/A — Why?',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Normality cannot be calculated for this chemical because its Equivalent Weight is not available in the database.\n\n'
                        'Equivalent Weight = Molar Mass ÷ n-factor\n\n'
                        'The n-factor depends on how many H⁺ or OH⁻ ions a compound donates/accepts in a reaction. For some chemicals (e.g., pure elements, organic solvents), this value is not defined or not stored.\n\n'
                        'To use Normality mode, either:\n'
                        '  • Select a chemical that has Equivalent Weight data (e.g., HCl, H₂SO₄, NaOH), or\n'
                        '  • Switch to Molarity mode instead.',
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

  Widget _buildCustomRadio({required bool selected, required VoidCallback onTap, required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.textTertiary,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
