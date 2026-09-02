import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/utils/formula_parser.dart';
import '../../../../features/periodic_table/data/element_repository.dart';
import '../../../../core/widgets/chemical_selector.dart';
import '../../../my_chemicals/data/custom_chemical_repository.dart';
import '../../../library/data/library_pinned_repository.dart';

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


  final FormulaParser _formulaParser = FormulaParser();

  double? _totalMass;
  List<Map<String, dynamic>> _breakdown = [];
  String? _error;
  ChemicalModel? _selectedChemical;

  @override
  void dispose() {
    _formulaController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                                      _calculate();
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
                                      _calculate();
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

  void _calculate() {
    final formula = _formulaController.text.trim();
    
    // If neither a chemical is selected nor a formula is typed, do nothing
    if (formula.isEmpty && _selectedChemical == null) {
      if (mounted) {
        setState(() {
          _totalMass = null;
          _breakdown = [];
          _error = null;
        });
      }
      return;
    }

    if (_selectedChemical != null) {
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
        _error = 'No chemical found';
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
                  _calculate();
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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _calculate(),
              onChanged: (_) {
                if (_selectedChemical != null) {
                  setState(() => _selectedChemical = null);
                }
              },
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
