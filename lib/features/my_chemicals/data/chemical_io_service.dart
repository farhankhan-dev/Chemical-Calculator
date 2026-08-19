import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/preferences_service.dart';
import '../models/custom_chemical_model.dart';

/// Service for importing/exporting custom chemical notebook data as `.txt` files.
///
/// Security measures:
/// - Only `.txt` files allowed for import.
/// - Magic header `#CHEMICALC_NOTEBOOK_V1` required.
/// - Only 3 pipe-delimited fields per row (name, formula, mol wt).
/// - Field sanitization: no HTML, scripts, or special characters.
/// - Max file size: 1 MB. Max rows: 500.
class ChemicalIOService {
  static const String _magicHeader = '#CHEMICALC_NOTEBOOK_V1';
  static const String _columnHeader = 'Chemical Name|Formula|Molecular Weight';
  static const int _maxFileSizeBytes = 1024 * 1024; // 1 MB
  static const int _maxRows = 500;

  // Allowed characters for chemical name: letters, digits, spaces, hyphens, parentheses, commas, dots, apostrophes
  static final RegExp _validNamePattern = RegExp(r"^[a-zA-Z0-9 \-\(\),\.\']+$");
  // Allowed characters for formula: letters, digits, parentheses, brackets, dots, subscript-like numbers
  static final RegExp _validFormulaPattern = RegExp(r'^[a-zA-Z0-9\(\)\[\]\.·]+$');

  /// Result class for import operations.
  static ImportResult _createResult({
    List<CustomChemicalModel> chemicals = const [],
    int skippedRows = 0,
    String? error,
  }) {
    return ImportResult(
      chemicals: chemicals,
      skippedRows: skippedRows,
      error: error,
    );
  }

  /// Export selected chemicals to a `.txt` file in the Downloads folder.
  ///
  /// Returns the file path on success, or null on failure.
  static Future<String?> exportChemicals({
    required List<CustomChemicalModel> chemicals,
    required String fileName,
  }) async {
    try {
      // Sanitize file name — remove any path separators or invalid chars
      final sanitizedName = fileName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      if (sanitizedName.isEmpty) return null;

      final customFieldsList = await PreferencesService.getCustomFields();

      // Build file content
      final buffer = StringBuffer();
      buffer.writeln(_magicHeader);
      
      String header = _columnHeader;
      for (final field in customFieldsList) {
        header += '|$field';
      }
      buffer.writeln(header);

      for (final chem in chemicals) {
        // Escape any pipe characters in data to prevent format corruption
        final name = chem.name.replaceAll('|', '-');
        final formula = chem.formula.replaceAll('|', '-');
        final weight = chem.molecularWeight.toString();
        
        String row = '$name|$formula|$weight';
        for (final field in customFieldsList) {
          final val = (chem.customFields[field] ?? '').replaceAll('|', '-').replaceAll('\n', ' ');
          row += '|$val';
        }
        buffer.writeln(row);
      }

      // Get Downloads directory
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) return null;

      final filePath = '${dir.path}/$sanitizedName.txt';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Opens a file picker for the user to select a `.txt` file for import.
  ///
  /// Returns an [ImportResult] with the parsed chemicals and any skipped rows.
  static Future<ImportResult> importChemicals() async {
    try {
      // Open file picker — restrict to .txt only
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return _createResult(error: 'No file selected.');
      }

      final pickedFile = result.files.first;

      // Security: double-check extension
      if (pickedFile.extension?.toLowerCase() != 'txt') {
        return _createResult(error: 'Only .txt files are allowed.');
      }

      final filePath = pickedFile.path;
      if (filePath == null) {
        return _createResult(error: 'Could not read the file.');
      }

      final file = File(filePath);

      // Security: check file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSizeBytes) {
        return _createResult(error: 'File too large. Maximum size is 1 MB.');
      }

      final content = await file.readAsString();
      return await _parseContent(content);
    } catch (e) {
      return _createResult(error: 'Failed to import: ${e.toString()}');
    }
  }

  /// Parses and validates the file content.
  static Future<ImportResult> _parseContent(String content) async {
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return _createResult(error: 'The file is empty.');
    }

    // Security: validate magic header
    if (lines.first != _magicHeader) {
      return _createResult(
        error: 'Invalid file format. This file was not exported from ChemiCalc.',
      );
    }

    // Skip header and column header line
    int dataStartIndex = 1;
    List<String> customFieldNames = [];

    if (lines.length > 1 && lines[1].startsWith('Chemical Name|Formula|Molecular Weight')) {
      final headerParts = lines[1].split('|');
      if (headerParts.length > 3) {
        customFieldNames = headerParts.sublist(3);
      }
      dataStartIndex = 2;
    }

    if (customFieldNames.isNotEmpty) {
      await PreferencesService.saveCustomFields(customFieldNames);
    }

    if (dataStartIndex >= lines.length) {
      return _createResult(error: 'The file contains no chemical data.');
    }

    final dataLines = lines.sublist(dataStartIndex);

    // Security: enforce row limit
    if (dataLines.length > _maxRows) {
      return _createResult(
        error: 'Too many entries. Maximum is $_maxRows chemicals per file.',
      );
    }

    final chemicals = <CustomChemicalModel>[];
    int skipped = 0;

    for (final line in dataLines) {
      final fields = line.split('|');

      // Security: must have at least 3 fields
      if (fields.length < 3) {
        skipped++;
        continue;
      }

      final name = fields[0].trim();
      final formula = fields[1].trim();
      final weightStr = fields[2].trim();

      // Validate name
      if (name.isEmpty || name.length > 100 || !_validNamePattern.hasMatch(name)) {
        skipped++;
        continue;
      }

      // Validate formula
      if (formula.isEmpty || formula.length > 50 || !_validFormulaPattern.hasMatch(formula)) {
        skipped++;
        continue;
      }

      // Validate molecular weight
      final weight = double.tryParse(weightStr);
      if (weight == null || weight <= 0 || weight >= 1000000) {
        skipped++;
        continue;
      }

      final customFields = <String, String>{};
      for (int i = 0; i < customFieldNames.length; i++) {
        if (i + 3 < fields.length) {
          final val = fields[i + 3].trim();
          if (val.isNotEmpty) customFields[customFieldNames[i]] = val;
        }
      }

      chemicals.add(CustomChemicalModel(
        id: '${DateTime.now().microsecondsSinceEpoch}_${chemicals.length}',
        name: name,
        formula: formula,
        molecularWeight: weight,
        createdAt: DateTime.now(),
        customFields: customFields,
      ));
    }

    if (chemicals.isEmpty && skipped > 0) {
      return _createResult(
        skippedRows: skipped,
        error: 'All $skipped rows were invalid and could not be imported.',
      );
    }

    return _createResult(chemicals: chemicals, skippedRows: skipped);
  }
}

/// Result of an import operation.
class ImportResult {
  final List<CustomChemicalModel> chemicals;
  final int skippedRows;
  final String? error;

  const ImportResult({
    this.chemicals = const [],
    this.skippedRows = 0,
    this.error,
  });

  bool get isSuccess => error == null && chemicals.isNotEmpty;
}
