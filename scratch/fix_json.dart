import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/chemicals.json');
  final jsonString = file.readAsStringSync();
  final List<dynamic> jsonList = json.decode(jsonString);

  for (var item in jsonList) {
    int id = item['id'];
    switch (id) {
      case 8:
        item['molecularWeight'] = 163.94;
        break;
      case 25:
        item['molecularWeight'] = 46.005;
        break;
      case 31:
        item['molecularWeight'] = 149.087;
        break;
      case 45:
        item['molecularWeight'] = 79.055;
        break;
      case 81:
        item['molecularWeight'] = 115.992;
        break;
      case 94:
        item['molecularWeight'] = 79.865;
        break;
      case 100:
        item['molecularWeight'] = 219.50;
        break;
      case 189:
        item['molecularWeight'] = 126.904;
        break;
      case 221:
        item['molecularWeight'] = 79.904;
        break;
      case 223:
        item['molecularWeight'] = 314.02;
        break;
      case 246:
        item['molecularWeight'] = 108.01;
        break;
      case 257:
        item['molecularWeight'] = 381.37;
        break;
      case 263:
        item['molecularWeight'] = 150.71;
        break;
      case 224:
        item['molecularWeight'] = 176.78;
        break;
    }
  }

  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(jsonList));
  print('Updated JSON successfully');
}
