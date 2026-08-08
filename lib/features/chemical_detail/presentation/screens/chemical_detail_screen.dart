import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';

class ChemicalDetailScreen extends StatelessWidget {
  final ChemicalModel chemical;

  const ChemicalDetailScreen({super.key, required this.chemical});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(chemical.name),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
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
                    chemical.formula,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    chemical.name,
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
            Text(
              'Properties',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildDetailRow('Category', chemical.category, Icons.category_outlined),
            if (chemical.category == 'Element')
              _buildDetailRow('Atomic Number', '${chemical.displayAtomicNumber}', Icons.numbers_outlined),
            if (chemical.category == 'Element')
              _buildDetailRow('Atomic Mass', '${(chemical.atomicMass ?? chemical.molecularWeight).toStringAsFixed(4)} u', Icons.science_outlined),
            _buildDetailRow('Molecular Weight', '${chemical.molecularWeight.toStringAsFixed(4)} g/mol', Icons.monitor_weight_outlined),
            if (chemical.equivalentWeight != null)
              _buildDetailRow('Equivalent Weight', '${chemical.equivalentWeight!.toStringAsFixed(4)} g/eq', Icons.balance_outlined),
            if (chemical.density != null)
              _buildDetailRow('Density', '${chemical.density} g/cm³', Icons.water_drop_outlined),
            if (chemical.meltingPoint != null)
              _buildDetailRow('Melting Point', '${chemical.meltingPoint} °C', Icons.thermostat_outlined),
            if (chemical.boilingPoint != null)
              _buildDetailRow('Boiling Point', '${chemical.boilingPoint} °C', Icons.local_fire_department_outlined),
            if (chemical.casNumber != null)
              _buildDetailRow('CAS Number', chemical.casNumber!, Icons.tag),
              
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
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
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
        ],
      ),
    );
  }
}
