import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../chemical_detail/presentation/screens/chemical_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChemicalModel> _allChemicals = [];
  List<ChemicalModel> _filteredChemicals = [];
  bool _isLoading = true;
  
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void initState() {
    super.initState();
    _loadChemicals();
  }

  Future<void> _loadChemicals() async {
    final chemicals = await _datasource.getAllChemicals();
    // Sort alphabetically
    chemicals.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        _allChemicals = chemicals;
        _filteredChemicals = chemicals;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChemicals = _allChemicals;
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      final matches = _allChemicals.where((c) {
        return c.name.toLowerCase().contains(q) || 
               c.formula.toLowerCase().contains(q);
      }).toList();

      matches.sort((a, b) {
        int getScore(ChemicalModel c) {
          final nameLower = c.name.toLowerCase();
          final formulaLower = c.formula.toLowerCase();
          
          if (nameLower.startsWith(q)) return 1;
          if (formulaLower.startsWith(q)) return 2;
          if (nameLower.contains(q)) return 3;
          if (formulaLower.contains(q)) return 4;
          return 5;
        }

        final scoreA = getScore(a);
        final scoreB = getScore(b);

        if (scoreA != scoreB) {
          return scoreA.compareTo(scoreB);
        }
        
        return a.name.compareTo(b.name);
      });
      
      _filteredChemicals = matches;
    });
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              Text(
                'Chemical Library',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse all chemicals',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
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
                    hintText: 'Search in library...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : _searchController.text.isEmpty
                        ? _buildGroupedList()
                        : _buildSearchResults(),
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
      itemBuilder: (context, index) {
        return _buildChemicalTile(_filteredChemicals[index]);
      },
    );
  }

  Widget _buildGroupedList() {
    // Group by first letter
    Map<String, List<ChemicalModel>> grouped = {};
    for (var c in _filteredChemicals) {
      String firstLetter = c.name[0].toUpperCase();
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
        if (!_letterKeys.containsKey(firstLetter)) {
          _letterKeys[firstLetter] = GlobalKey();
        }
      }
      grouped[firstLetter]!.add(c);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main List
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedKeys.map((letter) {
                final items = grouped[letter]!;
                return Column(
                  key: _letterKeys[letter],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        letter,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((chem) => _buildChemicalTile(chem)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        // A-Z Index
        if (_searchController.text.isEmpty)
          Container(
            width: 24,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                  final hasItems = grouped.containsKey(letter);
                  return GestureDetector(
                    onTap: hasItems ? () => _scrollToLetter(letter) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 10,
                          color: hasItems ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.5),
                          fontWeight: hasItems ? FontWeight.bold : FontWeight.w500,
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
    return Container(
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
            child: const Icon(
              Icons.science_outlined, // Fallback icon
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            chemical.name,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            chemical.formula,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
            size: 20,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChemicalDetailScreen(chemical: chemical),
              ),
            );
          },
        ),
      ),
    );
  }
}
