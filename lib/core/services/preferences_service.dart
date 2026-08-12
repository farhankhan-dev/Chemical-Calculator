import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _recentSearchesKey = 'recent_searches';

  /// Saves a chemical name to recent searches (keeps only the latest 10)
  static Future<void> saveRecentSearch(String chemicalName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentSearchesKey) ?? [];
    
    // Remove if already exists to put it at the top
    recent.remove(chemicalName);
    recent.insert(0, chemicalName);
    
    // Keep only last 10
    if (recent.length > 10) {
      recent = recent.sublist(0, 10);
    }
    
    await prefs.setStringList(_recentSearchesKey, recent);
  }

  /// Gets the list of recently searched chemical names
  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }
  
  /// Clears recent searches
  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
