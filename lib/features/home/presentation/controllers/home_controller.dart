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
  ChemicalModel? _selectedChemical;
  bool _isLoading = false;
  String _query = '';

  List<ChemicalModel> get suggestions => _suggestions;
  List<ChemicalModel> get recentSearches => _recentSearches;
  ChemicalModel? get selectedChemical => _selectedChemical;
  bool get isLoading => _isLoading;
  String get query => _query;

  /// Initialize — preload the chemical database and load recent searches.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Preload cache so first search is fast
    await _datasource.getAllChemicals();
    await _loadRecentSearches();

    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadRecentSearches() async {
    final recentNames = await PreferencesService.getRecentSearches();
    final all = await _datasource.getAllChemicals();
    _recentSearches = recentNames
        .map((name) => all.where((c) => c.name == name).firstOrNull)
        .whereType<ChemicalModel>()
        .toList();
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
}

