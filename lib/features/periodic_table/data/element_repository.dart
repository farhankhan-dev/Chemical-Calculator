import '../models/element_category.dart';
import '../models/element_model.dart';
import 'element_dataset.dart';

class ElementRepository {
  List<ElementModel> getAllElements() {
    return ElementDataset.elements;
  }

  ElementModel? getByAtomicNumber(int number) {
    try {
      return ElementDataset.elements.firstWhere((e) => e.atomicNumber == number);
    } catch (_) {
      return null;
    }
  }

  List<ElementModel> search(String query) {
    if (query.trim().isEmpty) {
      return ElementDataset.elements;
    }

    final q = query.trim().toLowerCase();
    final atomicMatch = int.tryParse(q);

    return ElementDataset.elements.where((element) {
      if (atomicMatch != null && element.atomicNumber == atomicMatch) {
        return true;
      }
      return element.name.toLowerCase().contains(q) ||
          element.symbol.toLowerCase().contains(q) ||
          element.atomicNumber.toString() == q;
    }).toList();
  }

  List<ElementModel> getByCategory(ElementCategory category) {
    return ElementDataset.elements
        .where((e) => e.category == category)
        .toList();
  }
}
