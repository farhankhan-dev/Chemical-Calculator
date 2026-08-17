import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_chemical_model.dart';

/// Repository for persistent offline storage of user's custom chemical notebook entries.
///
/// Uses SharedPreferences (key: 'custom_chemicals_notebook') to store user-added chemicals locally.
/// Custom chemicals are kept strictly isolated from the built-in Periodic Table dataset.
class CustomChemicalRepository {
  static const String _storageKey = 'custom_chemicals_notebook';

  /// Fetches all custom chemicals stored locally on the device.
  Future<List<CustomChemicalModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      final chemicals = list
          .map((e) => CustomChemicalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Sort newest first
      chemicals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return chemicals;
    } catch (_) {
      return [];
    }
  }

  /// Saves a custom chemical entry (creates a new entry or updates existing by id).
  Future<void> save(CustomChemicalModel chemical) async {
    final list = await getAll();
    final index = list.indexWhere((c) => c.id == chemical.id);

    if (index >= 0) {
      list[index] = chemical;
    } else {
      list.insert(0, chemical);
    }

    await _persist(list);
  }

  /// Deletes a custom chemical by id.
  Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((c) => c.id == id);
    await _persist(list);
  }

  /// Searches custom chemicals matching query in name or formula (case-insensitive).
  Future<List<CustomChemicalModel>> search(String query) async {
    final all = await getAll();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.formula.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _persist(List<CustomChemicalModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
