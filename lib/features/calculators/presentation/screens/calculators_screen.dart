import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

import '../../../dilution_calculator/presentation/screens/dilution_calculator_screen.dart';
import '../../../molarity_calculator/presentation/screens/molarity_calculator_screen.dart';
import '../../../mass_calculator/presentation/screens/mass_calculator_screen.dart';
import '../../../equivalent_weight_calculator/presentation/screens/equivalent_weight_calculator_screen.dart';
import '../../../molar_mass_calculator/presentation/screens/molar_mass_calculator_screen.dart';
import '../../../molality_calculator/presentation/screens/molality_calculator_screen.dart';
import '../../../molecular_weight_calculator/presentation/screens/molecular_weight_calculator_screen.dart';
import 'legal_document_screen.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculators',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a calculator or tool to get started',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.primary),
                    tooltip: 'About & Legal',
                    onPressed: () => _showLegalMenu(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    _buildCalculatorCard(
                      context,
                      title: 'Molarity Calculator',
                      subtitle: 'Calculate concentration or volume from known mass.',
                      icon: Icons.sync_outlined,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MolarityCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Molality Calculator',
                      subtitle: 'Calculate molality from moles and solvent mass.',
                      icon: Icons.functions,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MolalityCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Equivalent Weight Calculator',
                      subtitle: 'Calculate equivalent weight of compounds.',
                      imageAsset: 'assets/images/Equivalent_Calculator_icon.png',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EquivalentWeightCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Molecular Weight Calculator',
                      subtitle: 'Calculate molecular weight from chemical formula.',
                      icon: Icons.scale_outlined,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MolecularWeightCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Dilution Calculator',
                      subtitle: 'Solve N₁V₁ = N₂V₂ dilution problems.',
                      imageAsset: 'assets/images/Dilution_calculator_icon.png',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DilutionCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Molar Mass Calculator',
                      subtitle: 'Calculate molar mass of chemical compounds.',
                      imageAsset: 'assets/images/Molar_Mass_icon.png',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MolarMassCalculatorScreen()));
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: 'Mass Calculator',
                      subtitle: 'Calculate mass or volume requirements.',
                      imageAsset: 'assets/images/Mass_calculator _icon.png',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MassCalculatorScreen()));
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? imageAsset,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          width: 32,
                          height: 32,
                        )
                      : Icon(
                          icon,
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.primary),
                title: const Text('About Us'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(
                    title: 'About Us',
                    assetPath: 'assets/docs/about_us.txt',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(
                    title: 'Privacy Policy',
                    assetPath: 'assets/docs/privacy_policy.txt',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                title: const Text('Terms and Conditions'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(
                    title: 'Terms and Conditions',
                    assetPath: 'assets/docs/terms_and_conditions.txt',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, color: AppColors.primary),
                title: const Text('Terms of Use'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(
                    title: 'Terms of Use',
                    assetPath: 'assets/docs/terms_of_use.txt',
                  )));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Removed _showDocumentDialog as it is replaced by LegalDocumentScreen
}
