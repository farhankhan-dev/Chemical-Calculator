import 'package:flutter/material.dart';
import '../../data/element_repository.dart';
import '../../models/element_category.dart';
import '../../models/element_model.dart';

class PeriodicTableController extends ChangeNotifier {
  final ElementRepository _repository = ElementRepository();

  String _searchQuery = '';
  ElementCategory? _selectedCategory;
  ElementModel? _selectedElement;

  String get searchQuery => _searchQuery;
  ElementCategory? get selectedCategory => _selectedCategory;
  ElementModel? get selectedElement => _selectedElement;

  List<ElementModel> get allElements => _repository.getAllElements();

  Set<int> get matchingAtomicNumbers {
    if (_searchQuery.trim().isEmpty && _selectedCategory == null) {
      return {};
    }
    
    return allElements.where((element) {
      bool matchesSearch = true;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final atomicMatch = int.tryParse(q);
        matchesSearch = (atomicMatch != null && element.atomicNumber == atomicMatch) ||
            element.name.toLowerCase().contains(q) ||
            element.symbol.toLowerCase().contains(q) ||
            element.atomicNumber.toString() == q;
      }

      bool matchesCategory = true;
      if (_selectedCategory != null) {
        matchesCategory = element.category == _selectedCategory;
      }

      return matchesSearch && matchesCategory;
    }).map((e) => e.atomicNumber).toSet();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleCategory(ElementCategory category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void selectElement(ElementModel? element) {
    _selectedElement = element;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }
}
