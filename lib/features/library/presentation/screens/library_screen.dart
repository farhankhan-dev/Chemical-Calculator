import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../chemical_detail/presentation/screens/chemical_detail_screen.dart';
import '../../data/library_pinned_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _sidebarKey = GlobalKey();

  List<ChemicalModel> _allChemicals = [];
  List<ChemicalModel> _filteredChemicals = [];
  bool _isLoading = true;
  String? _activeLetter;
  
  final LibraryPinnedRepository _pinnedRepo = LibraryPinnedRepository();
  Set<int> _pinnedIds = {};


  
  final List<_LibraryItem> _flattenedList = [];
  List<String> _sortedKeys = [];

  @override
  void initState() {
    super.initState();
    _loadPinnedIds();
    _loadChemicals();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadPinnedIds() async {
    final ids = await _pinnedRepo.getPinnedIds();
    if (mounted) {
      setState(() {
        _pinnedIds = ids;
      });
    }
  }

  void _onScroll() {
    if (!mounted || _flattenedList.isEmpty) return;

    final offset = _scrollController.offset;
    
    // With a fixed itemExtent of 84.0, we can find the top visible item instantly
    int activeIndex = ((offset + 42.0) / 84.0).floor(); // 42.0 is half item buffer
    activeIndex = activeIndex.clamp(0, _flattenedList.length - 1);

    final currentLetter = _flattenedList[activeIndex].letter;

    if (currentLetter != _activeLetter) {
      setState(() {
        _activeLetter = currentLetter;
      });
    }
  }

  void _processFlattenedData() {
    _flattenedList.clear();
    
    final Map<String, List<ChemicalModel>> grouped = {};
    for (var c in _filteredChemicals) {
      final letter = c.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    _sortedKeys = grouped.keys.toList()..sort();

    for (var letter in _sortedKeys) {
      _flattenedList.add(_LibraryItem(isHeader: true, letter: letter));

      for (var c in grouped[letter]!) {
        _flattenedList.add(_LibraryItem(isHeader: false, letter: letter, chemical: c));
      }
    }
    
    if (_sortedKeys.isNotEmpty) {
      _activeLetter = _sortedKeys.first;
    }
  }

  Future<void> _loadChemicals() async {
    final chemicals = await _datasource.getAllChemicals();
    chemicals.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      _filteredChemicals = chemicals;
      _processFlattenedData();
      setState(() {
        _allChemicals = chemicals;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      _filteredChemicals = _allChemicals;
      _processFlattenedData();
      setState(() {});
      return;
    }
    
    final results = await _datasource.search(query);
    if (mounted) {
      _filteredChemicals = results;
      _processFlattenedData();
      setState(() {});
    }
  }

  void _scrollToLetter(String letter) {
    if (_activeLetter == letter) return; // Prevent animation spam on drag
    
    final index = _flattenedList.indexWhere((item) => item.isHeader && item.letter == letter);
    if (index != -1) {
      setState(() => _activeLetter = letter);
      // Use jumpTo instead of animateTo to prevent massive jank/lag during rapid drag gestures
      _scrollController.jumpTo(index * 84.0);
    }
  }

  /// Called by both drag and tap on the side index bar.
  /// Calculates which letter corresponds to the local Y position.
  void _handleSidePosition(Offset localPosition, List<String> presentLetters) {
    if (presentLetters.isEmpty) return;

    // Get the actual rendered height of the sidebar container
    final RenderBox? box =
        _sidebarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final totalHeight = box.size.height;
    if (totalHeight <= 0) return;

    final dy = localPosition.dy.clamp(0.0, totalHeight);
    final index = ((dy / totalHeight) * presentLetters.length)
        .floor()
        .clamp(0, presentLetters.length - 1);

    _scrollToLetter(presentLetters[index]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPinOptions(ChemicalModel chemical) {
    final isPinned = _pinnedIds.contains(chemical.id);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                chemical.name,
                style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  isPinned ? 'Unpin Chemical' : 'Pin Chemical',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pinnedRepo.togglePin(chemical.id, !isPinned);
                  _loadPinnedIds();
                  if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text(isPinned ? '${chemical.name} unpinned' : '${chemical.name} pinned', style: const TextStyle(color: Colors.white)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPinnedLibraryBottomSheet() {
    final pinnedChemicals = _allChemicals.where((c) => _pinnedIds.contains(c.id)).toList();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredChemicals = pinnedChemicals.where((c) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) || c.formula.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      'Library Pinned Chemicals',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                    ),
                    if (pinnedChemicals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search pinned...',
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
                    if (pinnedChemicals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No pinned chemicals found.\n\nLong press a chemical in the library to pin it!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else if (filteredChemicals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No matching chemicals found.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredChemicals.length,
                          itemBuilder: (context, index) {
                            final chem = filteredChemicals[index];
                            return ListTile(
                              leading: const Icon(Icons.science_outlined, color: AppColors.primary),
                              title: Text(chem.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(chem.formula, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.primaryDark)),
                              trailing: Text(chem.category, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                              onTap: () async {
                                Navigator.pop(ctx);
                                FocusManager.instance.primaryFocus?.unfocus();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChemicalDetailScreen(chemical: chem),
                                  ),
                                );
                                if (result == true && mounted) {
                                  _loadChemicals();
                                }
                              },
                              onLongPress: () {
                                Navigator.pop(ctx);
                                _showPinOptions(chem);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chemical Library',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Browse all chemicals alphabetically',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.push_pin_outlined, color: AppColors.primary),
                    onPressed: _showPinnedLibraryBottomSheet,
                    tooltip: 'View Pinned Chemicals',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search chemical name or formula...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredChemicals.isEmpty
                        ? Center(
                            child: Text(
                              'No chemicals found',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? _buildSearchResults()
                            : _buildGroupedList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _filteredChemicals.length,
      itemBuilder: (context, index) =>
          _buildChemicalTile(_filteredChemicals[index]),
    );
  }

  Widget _buildGroupedList() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main scrollable list ──────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _flattenedList.length,
            itemExtent: 84.0, // Fixed height makes ListView insanely fast and math perfect
            itemBuilder: (context, index) {
              final item = _flattenedList[index];
              if (item.isHeader) {
                return SizedBox(
                  height: 84.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 46, bottom: 4, left: 4),
                    child: Text(
                      item.letter,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              } else {
                return _buildChemicalTile(item.chemical!);
              }
            },
          ),
        ),

        const SizedBox(width: 4),

        // ── Contacts-style side index bar ─────────────────────────────────
        GestureDetector(
          onTapDown: (d) => _handleSidePosition(d.localPosition, _sortedKeys),
          onVerticalDragUpdate: (d) =>
              _handleSidePosition(d.localPosition, _sortedKeys),
          behavior: HitTestBehavior.opaque,
          child: Container(
            key: _sidebarKey,
            width: 26,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: _sortedKeys.map((letter) {
                final isSelected = _activeLetter == letter;
                return Flexible(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                      decoration: isSelected
                          ? const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Text(
                        letter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChemicalTile(ChemicalModel chemical) {
    return SizedBox(
      height: 84.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.science_outlined,
                  color: AppColors.primary, size: 20),
            ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chemical.name,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_pinnedIds.contains(chemical.id))
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                ),
            ],
          ),
          subtitle: Text(
            chemical.formula,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textTertiary, size: 20),
          onLongPress: () => _showPinOptions(chemical),
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChemicalDetailScreen(chemical: chemical),
              ),
            );
            if (result == true && mounted) {
              _loadChemicals();
            }
          },
        ),
      ),
      ),
    );
  }
}

class _LibraryItem {
  final bool isHeader;
  final String letter;
  final ChemicalModel? chemical;

  _LibraryItem({required this.isHeader, required this.letter, this.chemical});
}
