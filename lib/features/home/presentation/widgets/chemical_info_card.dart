import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/chemical_model.dart';

/// Card showing selected chemical's details.
///
/// Displays: Name, Formula header card, then a list of properties
/// (Molecular Weight, Equivalent Weight, Density, Melting Point,
/// Boiling Point, CAS Number, Category).
class ChemicalInfoCard extends StatelessWidget {
  final ChemicalModel chemical;

  const ChemicalInfoCard({super.key, required this.chemical});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card with gradient background
        _buildHeaderCard(),

        const SizedBox(height: AppSpacing.md),

        // Properties list
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPropertyRow(
                icon: Icons.science_outlined,
                label: 'Molecular Weight',
                value: '${chemical.molecularWeight} g/mol',
              ),
              const Divider(height: 1),
              _buildPropertyRow(
                icon: Icons.balance_outlined,
                label: 'Equivalent Weight',
                value: chemical.equivalentWeight != null
                    ? '${chemical.equivalentWeight} g/eq'
                    : 'N/A',
              ),
              const Divider(height: 1),
              _buildPropertyRow(
                icon: Icons.fitness_center_outlined,
                label: 'Molar Mass',
                value: '${chemical.molecularWeight} g/mol',
              ),
              if (chemical.density != null) ...[
                const Divider(height: 1),
                _buildPropertyRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Density',
                  value: '${chemical.density} g/mL',
                ),
              ],
              if (chemical.meltingPoint != null) ...[
                const Divider(height: 1),
                _buildPropertyRow(
                  icon: Icons.ac_unit_outlined,
                  label: 'Melting Point',
                  value: '${chemical.meltingPoint} °C',
                ),
              ],
              if (chemical.boilingPoint != null) ...[
                const Divider(height: 1),
                _buildPropertyRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Boiling Point',
                  value: '${chemical.boilingPoint} °C',
                ),
              ],
              if (chemical.casNumber != null) ...[
                const Divider(height: 1),
                _buildPropertyRow(
                  icon: Icons.tag_outlined,
                  label: 'CAS Number',
                  value: chemical.casNumber!,
                ),
              ],
              const Divider(height: 1),
              _buildPropertyRow(
                icon: Icons.text_fields_outlined,
                label: 'Formula',
                value: chemical.formula,
              ),
              const Divider(height: 1),
              _buildPropertyRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: chemical.category,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerStart, AppColors.headerEnd],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chemical.name,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            chemical.formula,
            style: AppTextStyles.monoLarge.copyWith(
              color: Colors.white70,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chemical.category,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.mono.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
