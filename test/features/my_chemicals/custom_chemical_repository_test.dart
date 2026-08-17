import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemi_calc/features/my_chemicals/data/custom_chemical_repository.dart';
import 'package:chemi_calc/features/my_chemicals/models/custom_chemical_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CustomChemicalRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = CustomChemicalRepository();
  });

  group('CustomChemicalRepository CRUD Operations', () {
    test('getAll returns empty list initially', () async {
      final items = await repository.getAll();
      expect(items, isEmpty);
    });

    test('save adds a custom chemical entry', () async {
      final chem = CustomChemicalModel(
        id: '1',
        name: 'Lab Sodium Chloride',
        formula: 'NaCl',
        molecularWeight: 58.44,
        createdAt: DateTime.now(),
      );

      await repository.save(chem);
      final items = await repository.getAll();

      expect(items.length, equals(1));
      expect(items.first.name, equals('Lab Sodium Chloride'));
      expect(items.first.formula, equals('NaCl'));
      expect(items.first.molecularWeight, equals(58.44));
    });

    test('save allows duplicate formulas with different names', () async {
      final chem1 = CustomChemicalModel(
        id: '1',
        name: 'Lab Water',
        formula: 'H2O',
        molecularWeight: 18.015,
        createdAt: DateTime.now(),
      );

      final chem2 = CustomChemicalModel(
        id: '2',
        name: 'Purified Water',
        formula: 'H2O',
        molecularWeight: 18.015,
        createdAt: DateTime.now(),
      );

      await repository.save(chem1);
      await repository.save(chem2);

      final items = await repository.getAll();
      expect(items.length, equals(2));
      expect(items.map((e) => e.name), containsAll(['Lab Water', 'Purified Water']));
    });

    test('save updates an existing chemical by id', () async {
      final chem = CustomChemicalModel(
        id: '1',
        name: 'Sulfuric Acid',
        formula: 'H2SO4',
        molecularWeight: 98.079,
        createdAt: DateTime.now(),
      );

      await repository.save(chem);

      final updatedChem = chem.copyWith(
        name: 'Sulfuric Acid 98%',
        molecularWeight: 98.08,
      );

      await repository.save(updatedChem);
      final items = await repository.getAll();

      expect(items.length, equals(1));
      expect(items.first.name, equals('Sulfuric Acid 98%'));
      expect(items.first.molecularWeight, equals(98.08));
    });

    test('delete removes a chemical by id', () async {
      final chem = CustomChemicalModel(
        id: '1',
        name: 'Calcium Hydroxide',
        formula: 'Ca(OH)2',
        molecularWeight: 74.092,
        createdAt: DateTime.now(),
      );

      await repository.save(chem);
      expect((await repository.getAll()).length, equals(1));

      await repository.delete('1');
      expect((await repository.getAll()), isEmpty);
    });

    test('search filters by name or formula case-insensitively', () async {
      final chem1 = CustomChemicalModel(
        id: '1',
        name: 'Sodium Chloride',
        formula: 'NaCl',
        molecularWeight: 58.44,
        createdAt: DateTime.now(),
      );
      final chem2 = CustomChemicalModel(
        id: '2',
        name: 'Sulfuric Acid',
        formula: 'H2SO4',
        molecularWeight: 98.079,
        createdAt: DateTime.now(),
      );

      await repository.save(chem1);
      await repository.save(chem2);

      final byName = await repository.search('sodium');
      expect(byName.length, equals(1));
      expect(byName.first.name, equals('Sodium Chloride'));

      final byFormula = await repository.search('h2so4');
      expect(byFormula.length, equals(1));
      expect(byFormula.first.name, equals('Sulfuric Acid'));
    });
  });
}
