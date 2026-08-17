import 'package:flutter/material.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../core/services/preferences_service.dart';

/// State management for the home screen.
///
/// Manages search query, filtered suggestions, selected chemical, and recent searches.
class HomeController extends ChangeNotifier {
  final ChemicalLocalDatasource _datasource = ChemicalLocalDatasource();

  List<ChemicalModel> _suggestions = [];
  List<ChemicalModel> _recentSearches = [];
  List<ChemicalModel> _clearedRecentSearches = [];
  ChemicalModel? _selectedChemical;
  bool _isLoading = false;
  String _query = '';

  List<ChemicalModel> get suggestions => _suggestions;
  List<ChemicalModel> get recentSearches => _recentSearches;
  ChemicalModel? get selectedChemical => _selectedChemical;
  bool get isLoading => _isLoading;
  String get query => _query;
  
  bool get canUndoClear => _clearedRecentSearches.isNotEmpty && _recentSearches.isEmpty;

  /// Initialize — preload the chemical database and load recent searches.
  Future<void> init() async {
    if (_datasource.hasCache) {
      _isLoading = false;
      _loadRecentSearches();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _datasource.getAllChemicals(),
        _loadRecentSearches(),
      ]).timeout(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('Error initializing HomeController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadRecentSearches() async {
    try {
      final recentNames = await PreferencesService.getRecentSearches();
      final all = await _datasource.getAllChemicals();
      _recentSearches = recentNames
          .map((name) => all.where((c) => c.name == name).firstOrNull)
          .whereType<ChemicalModel>()
          .toList();
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
      _recentSearches = [];
    }
    notifyListeners();
  }

  /// Called when user types in the search field.
  Future<void> onQueryChanged(String query) async {
    _query = query;

    if (query.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    final results = await _datasource.search(query);
    _suggestions = results.take(8).toList(); // Limit to 8 suggestions
    notifyListeners();
  }

  /// Called when user selects a chemical from the suggestion list.
  void selectChemical(ChemicalModel chemical) async {
    _selectedChemical = chemical;
    _suggestions = [];
    _query = chemical.name;
    _clearedRecentSearches = []; // Clear undo state when adding new
    notifyListeners();
    
    // Save to recent searches
    await PreferencesService.saveRecentSearch(chemical.name);
    await _loadRecentSearches();
  }

  /// Clear selection and reset search.
  void clearSelection() {
    _selectedChemical = null;
    _suggestions = [];
    _query = '';
    notifyListeners();
  }

  /// Clear all recent searches.
  Future<void> clearRecentSearches() async {
    _clearedRecentSearches = List.from(_recentSearches);
    await PreferencesService.clearRecentSearches();
    _recentSearches = [];
    notifyListeners();
  }

  /// Undo clear all recent searches.
  Future<void> undoClearRecentSearches() async {
    if (_clearedRecentSearches.isEmpty) return;
    
    _recentSearches = List.from(_clearedRecentSearches);
    _clearedRecentSearches = [];
    
    // Restore to preferences
    // Because saveRecentSearch appends to the top, we should restore them in reverse
    // but preferences service might not have a set list method.
    // Let's assume we can just re-add them or if PreferencesService doesn't have a batch set,
    // we can save them one by one in reverse order to keep the same order.
    await PreferencesService.clearRecentSearches();
    for (var chemical in _recentSearches.reversed) {
      await PreferencesService.saveRecentSearch(chemical.name);
    }
    
    notifyListeners();
  }
}

