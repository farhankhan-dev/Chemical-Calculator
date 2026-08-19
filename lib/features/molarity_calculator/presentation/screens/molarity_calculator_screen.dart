import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/formula_parser.dart';
import '../../../my_chemicals/data/custom_chemical_repository.dart';
import '../../../library/data/library_pinned_repository.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';

class MolarityCalculatorScreen extends StatefulWidget {
  const MolarityCalculatorScreen({super.key});

  @override
  State<MolarityCalculatorScreen> createState() => _MolarityCalculatorScreenState();
}

class _MolarityCalculatorScreenState extends State<MolarityCalculatorScreen> {
  ChemicalModel? _selectedChemical;
  final FormulaParser _formulaParser = FormulaParser();
  
  final TextEditingController _formulaController = TextEditingController();
  final TextEditingController _massController = TextEditingController();
  final TextEditingController _volController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController();
  
  bool _isVolMl = true; // false = Liters

  double? _molarity;
  double? _displayedMolarity;
  String _displayedUnitLabel = 'mol/L';
  double? _normality;
  
  String _selectedOutputUnit = 'M (mol/L)';
  final List<String> _outputUnits = [
    'M (mol/L)',
    'mM (mmol/L)',
    'µM (µmol/L)',
    'nM (nmol/L)',
    'ppm (mg/L)',
    'ppb (µg/L)'
  ];
  String? _calculationString;
  String? _validationError;

  @override
  void dispose() {
    _formulaController.dispose();
    _massController.dispose();
    _volController.dispose();
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

    if (_massController.text.isEmpty || _volController.text.isEmpty) {
      setState(() {
        _validationError = 'Please fill all requirements';
      });
      return;
    }
    
    final mass = double.tryParse(_massController.text);
    final vol = double.tryParse(_volController.text);
    if (mass == null || vol == null) return;

    setState(() {
      final volLiters = _isVolMl ? vol / 1000 : vol;
      
      final moles = mass / molarMass!;
      _molarity = moles / volLiters;
      
      if (eqWeight != null) {
        final equivalents = mass / eqWeight;
        _normality = equivalents / volLiters;
        
        _calculationString = 'Moles = ${FormatUtils.format(mass)} g / ${FormatUtils.format(molarMass)} g/mol = ${FormatUtils.format(moles)}\n'
            'Molarity = ${FormatUtils.format(moles)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_molarity!)} M\n';
      } else {
        _normality = null;
        _calculationString = 'Moles = ${FormatUtils.format(mass)} g / ${FormatUtils.format(molarMass)} g/mol = ${FormatUtils.format(moles)}\n'
            'Molarity = ${FormatUtils.format(moles)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_molarity!)} M\n';
      }
      
      switch (_selectedOutputUnit) {
        case 'M (mol/L)':
          _displayedMolarity = _molarity;
          _displayedUnitLabel = 'mol/L';
          break;
        case 'mM (mmol/L)':
          _displayedMolarity = _molarity! * 1000;
          _displayedUnitLabel = 'mmol/L';
          _calculationString = '${_calculationString}Conversion: ${_molarity!} M × 1000 = ${_displayedMolarity!} mM\n';
          break;
        case 'µM (µmol/L)':
          _displayedMolarity = _molarity! * 1000000;
          _displayedUnitLabel = 'µmol/L';
          _calculationString = '${_calculationString}Conversion: ${_molarity!} M × 10⁶ = ${_displayedMolarity!} µM\n';
          break;
        case 'nM (nmol/L)':
          _displayedMolarity = _molarity! * 1000000000;
          _displayedUnitLabel = 'nmol/L';
          _calculationString = '${_calculationString}Conversion: ${_molarity!} M × 10⁹ = ${_displayedMolarity!} nM\n';
          break;
        case 'ppm (mg/L)':
          _displayedMolarity = _molarity! * molarMass * 1000;
          _displayedUnitLabel = 'mg/L (ppm)';
          _calculationString = '${_calculationString}Conversion: ${_molarity!} M × ${FormatUtils.format(molarMass)} g/mol × 1000 = ${_displayedMolarity!} ppm\n';
          break;
        case 'ppb (µg/L)':
          _displayedMolarity = _molarity! * molarMass * 1000000;
          _displayedUnitLabel = 'µg/L (ppb)';
          _calculationString = '${_calculationString}Conversion: ${_molarity!} M × ${FormatUtils.format(molarMass)} g/mol × 10⁶ = ${_displayedMolarity!} ppb\n';
          break;
      }
      
      if (eqWeight != null) {
        _calculationString = '$_calculationString\nEq = ${FormatUtils.format(mass)} g / ${FormatUtils.format(eqWeight)} g/eq = ${FormatUtils.format(mass/eqWeight)}\n'
            'Normality = ${FormatUtils.format(mass/eqWeight)} / ${FormatUtils.format(volLiters)} L = ${FormatUtils.format(_normality!)} N';
      } else {
        _calculationString = '$_calculationString\nNormality: N/A (Equivalent weight not available)';
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        // 0 = Menu, 1 = Library Pinned, 2 = My Chemicals Pinned
        int currentView = 0;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                                  searchQuery = '';
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
                            setModalState(() {
                              searchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: () {
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
                                    
                                    if (_massController.text.isNotEmpty && _volController.text.isNotEmpty) {
                                      _calculate();
                                    }
                                  },
                                );
                              },
                            );
                          } else {
                            return ListView.builder(
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
                                    
                                    if (_massController.text.isNotEmpty && _volController.text.isNotEmpty) {
                                      _calculate();
                                    }
                                  },
                                );
                              },
                            );
                          }
                        }(),
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

  void _showNormalityNoteDialog(BuildContext context) {
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
                        'Molarity Reference Notes',
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
                      // Molarity vs Normality
                      _buildNoteCard(
                        title: 'Molarity (M)',
                        content: 'Moles of solute per Liter of solution.\nStatus: FIXED value for a given solution. Does NOT depend on reaction type.',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        bgColor: Colors.green.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Normality (N)',
                        content: 'Equivalents of solute per Liter of solution.\nStatus: DEPENDS on reaction type because it uses n-factor.',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        title: 'Relation',
                        content: 'N = M × n-factor',
                        icon: Icons.link,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 16),
                      // n-factor table
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
                                '📐 n-factor Guide',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _buildNFactorRow('Acids', 'Number of replaceable H⁺ ions', 'H₂SO₄ → n = 2'),
                            _buildNFactorRow('Bases', 'Number of OH⁻ ions', 'NaOH → n = 1'),
                            _buildNFactorRow('Salts', 'Total ionic charge', 'Na₃PO₄ → n = 3'),
                            _buildNFactorRow('Redox', 'Electrons transferred', 'KMnO₄ (acid) → n = 5'),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Theory
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📖 Why Normality Matters',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Normality is used in titrations and acid-base/redox reactions because it accounts for the "reacting capacity" of a compound. Unlike molarity, which is fixed, normality changes based on what the compound does in a specific reaction. This makes it more practical for stoichiometric calculations in volumetric analysis.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Important + App Behavior
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
                              '⚠️ Important',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Some compounds (KMnO₄, K₂Cr₂O₇, Al(OH)₃) have variable normality.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'ℹ️ This app shows the value for the MOST COMMON condition (acid medium). For other conditions, recalculate using: N = M × n-factor',
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

  Widget _buildNFactorRow(String type, String description, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
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
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black87,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            example,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.black54,
              fontSize: 10,
              fontStyle: FontStyle.italic,
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
        title: const Text('Molarity Calculator'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Normality Reference Notes',
            onPressed: () => _showNormalityNoteDialog(context),
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
                  const Icon(Icons.sync_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Molarity (M) = Mass (g) / (Molar Mass (g/mol) × Volume (L))',
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
              'Calculate concentration from known mass.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Select Chemical
            Text('Select Chemical', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final chem = await ChemicalSelector.show(context);
                if (chem != null) {
                  setState(() {
                    _selectedChemical = chem;
                    _formulaController.clear();
                  });
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
            const SizedBox(height: 12),

            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 12),

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
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mass Added', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _massController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixText: 'g',
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
                      Text('Volume', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _volController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixIcon: DropdownButtonHideUnderline(
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Output Unit Selector
            Text('Desired Concentration Unit', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedOutputUnit,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  items: _outputUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: AppTextStyles.bodyMedium))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedOutputUnit = val;
                        if (_molarity != null) _calculate();
                      });
                    }
                  },
                ),
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
                  'Calculate Concentration',
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

            if (_molarity != null) ...[
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
                      'Concentration',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${FormatUtils.format(_displayedMolarity!)} $_displayedUnitLabel',
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 32),
                    ),
                    if (_normality != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Normality (N)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${FormatUtils.format(_normality!)} eq/L',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 24),
                      ),
                    ],
                    if (_selectedChemical?.density != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Density',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedChemical!.density} g/cm³',
                        style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 24),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Calculation Steps',
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _calculationString ?? '',
                      style: AppTextStyles.mono.copyWith(color: AppColors.primaryDark, fontSize: 12),
                    ),
                    if (_normality == null && _selectedChemical != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '⚠️ Note: ${_selectedChemical!.name} does not have a fixed Normality value.',
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Reason: This compound\'s n-factor depends on reaction conditions.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For standard textbook problems, use the value shown above.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade800,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'If your problem specifies a different condition, recalculate using: N = M × n-factor',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ],
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
