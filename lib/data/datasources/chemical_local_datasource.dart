import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chemical_model.dart';

/// Loads the built-in chemical database from assets/data/chemicals.json
/// and also loads/saves custom user chemicals from local storage.
class ChemicalLocalDatasource {
  static final ChemicalLocalDatasource _instance = ChemicalLocalDatasource._internal();

  factory ChemicalLocalDatasource() {
    return _instance;
  }

  ChemicalLocalDatasource._internal();

  List<ChemicalModel>? _cache;

  bool get hasCache => _cache != null;

  @visibleForTesting
  void setCacheForTesting(List<ChemicalModel> chemicals) {
    _cache = chemicals;
  }

  /// Loads all chemicals from the JSON asset. Results are cached after
  /// the first call.
  Future<List<ChemicalModel>> getAllChemicals() async {
    if (_cache != null) return _cache!;

    // 1. Load built-in chemicals
    String jsonString;
    try {
      jsonString = await rootBundle
          .loadString('assets/data/chemicals.json')
          .timeout(const Duration(milliseconds: 1000));
    } catch (e) {
      jsonString = '[]';
    }
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    final baseChemicals = jsonList
        .map((e) => ChemicalModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2. Load user-added chemicals from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userChemicalsJson = prefs.getString('user_chemicals');
    
    List<ChemicalModel> userChemicals = [];
    if (userChemicalsJson != null) {
      final List<dynamic> userList = json.decode(userChemicalsJson);
      userChemicals = userList
          .map((e) => ChemicalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _cache = [...baseChemicals, ...userChemicals];
    return _cache!;
  }

  /// Adds a custom chemical to the user's local storage and updates the in-memory cache.
  Future<void> addChemical(ChemicalModel chemical) async {
    if (_cache == null) await getAllChemicals();

    // Assign a new ID to avoid collisions
    int maxId = 0;
    for (var c in _cache!) {
      if (c.id > maxId) maxId = c.id;
    }
    
    final newChemical = ChemicalModel(
      id: maxId + 1,
      name: chemical.name,
      formula: chemical.formula,
      molecularWeight: chemical.molecularWeight,
      equivalentWeight: chemical.equivalentWeight,
      density: chemical.density,
      meltingPoint: chemical.meltingPoint,
      boilingPoint: chemical.boilingPoint,
      casNumber: chemical.casNumber,
      category: chemical.category,
      atomicNumber: chemical.atomicNumber,
      atomicMass: chemical.atomicMass,
      note: chemical.note,
    );

    // Update in-memory cache
    _cache!.add(newChemical);

    // Save back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userChemicalsJson = prefs.getString('user_chemicals');
    List<dynamic> userList = [];
    if (userChemicalsJson != null) {
      userList = json.decode(userChemicalsJson);
    }
    userList.add(newChemical.toJson());
    await prefs.setString('user_chemicals', json.encode(userList));
  }

  /// Deletes a custom chemical from user's local storage and memory cache.
  /// Base chemicals (id <= 273) cannot be deleted.
  Future<void> deleteChemical(int id) async {
    if (id <= 273) return; // Safeguard

    if (_cache != null) {
      _cache!.removeWhere((c) => c.id == id);
    }

    final prefs = await SharedPreferences.getInstance();
    final userChemicalsJson = prefs.getString('user_chemicals');
    if (userChemicalsJson != null) {
      final List<dynamic> userList = json.decode(userChemicalsJson);
      userList.removeWhere((item) => item['id'] == id);
      await prefs.setString('user_chemicals', json.encode(userList));
    }
  }

  /// Search chemicals by name (case-insensitive).
  /// Returns chemicals whose name starts with or contains the query.
  /// Prefix matches are ranked first.
  Future<List<ChemicalModel>> searchByName(String query) async {
    final all = await getAllChemicals();
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final prefixMatches = <ChemicalModel>[];
    final containsMatches = <ChemicalModel>[];

    for (final chem in all) {
      final nameLower = chem.name.toLowerCase();
      if (nameLower.startsWith(q)) {
        prefixMatches.add(chem);
      } else if (nameLower.contains(q)) {
        containsMatches.add(chem);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }

  String _normalizeFormula(String formula) {
    return formula
        .replaceAll('₀', '0')
        .replaceAll('₁', '1')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('₄', '4')
        .replaceAll('₅', '5')
        .replaceAll('₆', '6')
        .replaceAll('₇', '7')
        .replaceAll('₈', '8')
        .replaceAll('₉', '9');
  }

  /// Search chemicals by name or formula.
  Future<List<ChemicalModel>> search(String query) async {
    final all = await getAllChemicals();
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final exactMatches = <ChemicalModel>[];
    final namePrefixMatches = <ChemicalModel>[];
    final formulaPrefixMatches = <ChemicalModel>[];
    final nameContainsMatches = <ChemicalModel>[];
    final formulaContainsMatches = <ChemicalModel>[];

    for (final chem in all) {
      final nameLower = chem.name.toLowerCase();
      final formulaLower = _normalizeFormula(chem.formula).toLowerCase();

      // 1. Exact matches
      if (nameLower == q || formulaLower == q) {
        exactMatches.add(chem);
        continue;
      }

      // 2. Prefix matches
      bool matchedPrefix = false;
      if (nameLower.startsWith(q)) {
        namePrefixMatches.add(chem);
        matchedPrefix = true;
      } else if (formulaLower.startsWith(q)) {
        formulaPrefixMatches.add(chem);
        matchedPrefix = true;
      }

      // 3. Contains matches (only if it wasn't a prefix match)
      if (!matchedPrefix) {
        if (nameLower.contains(q)) {
          nameContainsMatches.add(chem);
        } else if (formulaLower.contains(q)) {
          formulaContainsMatches.add(chem);
        }
      }
    }

    // Return prioritized list
    return [
      ...exactMatches,
      ...namePrefixMatches,
      ...formulaPrefixMatches,
      ...nameContainsMatches,
      ...formulaContainsMatches
    ];
  }

  /// Search chemicals exclusively by formula (case-insensitive).
  /// Prefix matches on formula are ranked first.
  Future<List<ChemicalModel>> searchByFormula(String query) async {
    final all = await getAllChemicals();
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final prefixMatches = <ChemicalModel>[];
    final containsMatches = <ChemicalModel>[];

    for (final chem in all) {
      final formulaLower = _normalizeFormula(chem.formula).toLowerCase();

      if (formulaLower.startsWith(q)) {
        prefixMatches.add(chem);
      } else if (formulaLower.contains(q)) {
        containsMatches.add(chem);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }
}
