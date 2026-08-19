import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryPinnedRepository {
  static const String _storageKey = 'library_pinned_chemicals';

  Future<Set<int>> getPinnedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> togglePin(int chemicalId, bool isPinned) async {
    final pinnedIds = await getPinnedIds();
    if (isPinned) {
      pinnedIds.add(chemicalId);
    } else {
      pinnedIds.remove(chemicalId);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(pinnedIds.toList()));
  }
}
