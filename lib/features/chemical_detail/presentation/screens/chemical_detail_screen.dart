import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';
import '../../../../data/datasources/chemical_local_datasource.dart';
import '../../../library/data/library_pinned_repository.dart';

class ChemicalDetailScreen extends StatefulWidget {
  final ChemicalModel chemical;

  const ChemicalDetailScreen({super.key, required this.chemical});

  @override
  State<ChemicalDetailScreen> createState() => _ChemicalDetailScreenState();
}

class _ChemicalDetailScreenState extends State<ChemicalDetailScreen> {
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinned();
  }

  Future<void> _checkIfPinned() async {
    final repo = LibraryPinnedRepository();
    final ids = await repo.getPinnedIds();
    if (mounted) {
      setState(() {
        _isPinned = ids.contains(widget.chemical.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.chemical.name),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              if (widget.chemical.id <= 273) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Built-in library chemicals cannot be deleted.')),
                );
                return;
              }
              
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Chemical'),
                  content: const Text('Are you sure you want to delete this chemical?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final datasource = ChemicalLocalDatasource();
                await datasource.deleteChemical(widget.chemical.id);
                if (context.mounted) {
                  Navigator.pop(context, true); 
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.headerStart, AppColors.headerEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.chemical.formula,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.chemical.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Details Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Properties',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_isPinned)
                  const Icon(Icons.push_pin, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildDetailRow('Category', widget.chemical.category, Icons.category_outlined),
            if (widget.chemical.category == 'Element')
              _buildDetailRow('Atomic Number', '${widget.chemical.displayAtomicNumber}', Icons.numbers_outlined),
            if (widget.chemical.category == 'Element')
              _buildDetailRow('Atomic Mass', '${(widget.chemical.atomicMass ?? widget.chemical.molecularWeight).toStringAsFixed(4)} u', Icons.science_outlined),
            _buildDetailRow('Molecular Weight', '${widget.chemical.molecularWeight.toStringAsFixed(4)} g/mol', Icons.monitor_weight_outlined),
            if (widget.chemical.equivalentWeight != null)
              _buildDetailRow('Equivalent Weight', '${widget.chemical.equivalentWeight!.toStringAsFixed(4)} g/eq', Icons.balance_outlined)
            else if (_noEwChemicalIds.contains(widget.chemical.id))
              _buildDetailRow(
                'Equivalent Weight',
                'N/A',
                Icons.balance_outlined,
                labelTrailing: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.purple.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'EQUIVALENT WEIGHT (EW) IS NOT APPLICABLE',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          'This compound does not have a fixed EW because it is not a classic acid, base, or redox agent.\n\n'
                          'It falls into one of these categories:\n'
                          '• Non-reactive solvent or organic compound\n'
                          '• Ion that exists only in solution\n'
                          '• Polymer with a variable chain length\n\n'
                          'For these substances, EW has no standard chemical meaning. Use Molecular Weight (MW) for all stoichiometric calculations.',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (widget.chemical.density != null)
              _buildDetailRow('Density', '${widget.chemical.density} g/cm³', Icons.water_drop_outlined),
            if (widget.chemical.meltingPoint != null)
              _buildDetailRow('Melting Point', '${widget.chemical.meltingPoint} °C', Icons.thermostat_outlined),
            if (widget.chemical.boilingPoint != null)
              _buildDetailRow('Boiling Point', '${widget.chemical.boilingPoint} °C', Icons.local_fire_department_outlined),
            if (widget.chemical.casNumber != null)
              _buildDetailRow(
                'CAS Number', 
                widget.chemical.casNumber!, 
                Icons.tag,
                labelTrailing: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.purple.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        title: const Text('CAS Number', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        content: const Text(
                          'A CAS Registry Number is a unique numerical identifier assigned by the Chemical Abstracts Service to every chemical substance. It ensures accurate identification regardless of the various names an element or compound might have.',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
            if (widget.chemical.note != null && widget.chemical.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  'Note : ${widget.chemical.note!}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Widget? trailing, Widget? labelTrailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (labelTrailing != null) ...[
                      const SizedBox(width: 6),
                      labelTrailing,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static const Set<int> _noEwChemicalIds = {
    1, 2, 5, 6, 7, 10, 30, 41, 47, 49, 61, 62, 63, 65, 66, 67, 79, 80, 81, 86, 90,
    92, 93, 95, 96, 98, 99, 100, 101, 103, 112, 114, 117, 118, 142, 144, 146, 147,
    148, 149, 157, 161, 163, 165, 170, 171, 172, 178, 179, 180, 201, 211, 245, 246,
    248, 254, 258, 260, 261, 264, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283,
    284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299,
    300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 312, 313, 314, 315, 316,
    317, 318, 319, 320, 330, 331, 332, 333, 334, 336, 337, 338, 341, 342, 343, 344,
    345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360,
    361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 379, 380, 381, 382,
    383, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 403, 404, 405,
    406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421,
    422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
  };
}
