import 'package:chemi_calc/features/periodic_table/data/element_repository.dart';

void main() {
  final repo = ElementRepository();
  final cu = repo.getAllElements().firstWhere((e) => e.symbol == 'Cu');
  final s = repo.getAllElements().firstWhere((e) => e.symbol == 'S');
  final o = repo.getAllElements().firstWhere((e) => e.symbol == 'O');
  final h = repo.getAllElements().firstWhere((e) => e.symbol == 'H');
  
  print('Cu: ${cu.atomicMass}');
  print('S: ${s.atomicMass}');
  print('O: ${o.atomicMass}');
  print('H: ${h.atomicMass}');
  
  print('Total = ${cu.atomicMass + s.atomicMass + 4 * o.atomicMass + 5 * (2 * h.atomicMass + o.atomicMass)}');
}
