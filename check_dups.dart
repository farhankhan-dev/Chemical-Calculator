import 'dart:convert';
import 'dart:io';

void main() {
  final f = File('assets/data/chemicals.json');
  final str = f.readAsStringSync();
  final List<dynamic> data = json.decode(str);
  
  final casMap = <String, List<String>>{};
  final nameMap = <String, List<String>>{};
  
  for (var item in data) {
    final cas = item['casNumber']?.toString();
    final name = item['name'].toString().toLowerCase();
    
    if (cas != null && cas.isNotEmpty) {
      casMap.putIfAbsent(cas, () => []).add(item['name']);
    }
    nameMap.putIfAbsent(name, () => []).add(item['name']);
  }
  
  print('Duplicate CAS:');
  casMap.forEach((k, v) {
    if (v.length > 1) print('$k : $v');
  });
  
  print('Duplicate Names:');
  nameMap.forEach((k, v) {
    if (v.length > 1) print('$k : $v');
  });
}
