import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import '../../models/element_model.dart';
class ElementDetailScreen extends StatelessWidget {
  final ElementModel element;

  const ElementDetailScreen({super.key, required this.element});

  static Future<void> show(BuildContext context, ElementModel element) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ElementDetailScreen(element: element),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final catColor = element.category.color;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),

              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor),
                      ),
                      child: Text(
                        element.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Header Banner Card
                    _buildHeaderCard(catColor),

                    const SizedBox(height: AppSpacing.md),

                    // Quick Specs Bar
                    _buildQuickSpecsBar(),

                    const SizedBox(height: AppSpacing.md),

                    // Overview / Description
                    _buildSectionHeader('Overview', Icons.info_outline),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        element.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Basic Information
                    _buildSectionHeader('Basic Information', Icons.science_outlined),
                    const SizedBox(height: 6),
                    _buildGridProps([
                      _PropItem('Atomic Number', '${element.atomicNumber}'),
                      _PropItem('Symbol', element.symbol),
                      _PropItem('Atomic Mass', '${element.atomicMass} u'),
                      _PropItem('Group', element.group == 0 ? 'N/A' : '${element.group}'),
                      _PropItem('Period', '${element.period}'),
                      _PropItem('Block', '${element.block}-block'),
                      _PropItem('State (STP)', element.stateAtRoomTemp),
                    ]),

                    const SizedBox(height: AppSpacing.md),

                    // Physical Properties
                    _buildSectionHeader('Physical Properties', Icons.thermostat_outlined),
                    const SizedBox(height: 6),
                    _buildGridProps([
                      _PropItem('Melting Point', element.meltingPoint != null ? '${element.meltingPoint} °C' : 'N/A'),
                      _PropItem('Boiling Point', element.boilingPoint != null ? '${element.boilingPoint} °C' : 'N/A'),
                      _PropItem('Density', element.density != null ? '${element.density} g/cm³' : 'N/A'),
                    ]),

                    const SizedBox(height: AppSpacing.md),

                    // Chemical Properties
                    _buildSectionHeader('Chemical Properties', Icons.bolt_outlined),
                    const SizedBox(height: 6),
                    _buildGridProps([
                      _PropItem('Electron Config', element.electronConfiguration),
                      _PropItem('Electronegativity', element.electronegativity != null ? '${element.electronegativity}' : 'N/A'),
                      _PropItem('Oxidation States', element.oxidationStates),
                    ]),

                    const SizedBox(height: AppSpacing.md),

                    // Discovery Details
                    _buildSectionHeader('Discovery', Icons.history_edu_outlined),
                    const SizedBox(height: 6),
                    _buildGridProps([
                      _PropItem('Discovery Year', element.discoveryYear),
                      _PropItem('Discoverer', element.discoverer),
                    ]),

                    if (element.keyFacts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSectionHeader('Key Facts', Icons.lightbulb_outline),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: element.keyFacts.map((fact) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      fact,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(Color catColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [catColor, catColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Symbol box
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${element.atomicNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  element.symbol,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: catColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Name & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.name,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Atomic Mass: ${element.atomicMass} u',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSpecsBar() {
    return Row(
      children: [
        _buildSpecChip('Group', element.group == 0 ? '-' : '${element.group}'),
        const SizedBox(width: 8),
        _buildSpecChip('Period', '${element.period}'),
        const SizedBox(width: 8),
        _buildSpecChip('Block', element.block.toUpperCase()),
        const SizedBox(width: 8),
        _buildSpecChip('State', element.stateAtRoomTemp),
      ],
    );
  }

  Widget _buildSpecChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGridProps(List<_PropItem> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  item.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PropItem {
  final String label;
  final String value;
  _PropItem(this.label, this.value);
}
