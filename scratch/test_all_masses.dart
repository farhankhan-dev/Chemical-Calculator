import 'package:chemi_calc/features/periodic_table/data/element_repository.dart';

void main() {
  final repo = ElementRepository();
  for (final e in repo.getAllElements()) {
    print('${e.symbol}: ${e.atomicMass}');
  }
}
