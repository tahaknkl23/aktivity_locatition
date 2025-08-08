// lib/presentation/widgets/home/quick_actions_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onFirmaEkle;
  final VoidCallback onAktiviteEkle;

  const QuickActionsWidget({
    super.key,
    required this.onFirmaEkle,
    required this.onAktiviteEkle,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: size.mediumText * 1.1,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.mediumSpacing),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_business_rounded,
                title: 'Firma Ekle',
                subtitle: 'Yeni müşteri',
                color: AppColors.primaryColor,
                onTap: onFirmaEkle,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: _ActionCard(
                icon: Icons.assignment_add,
                title: 'Aktivite Ekle',
                subtitle: 'Yeni görev',
                color: AppColors.secondoryColor,
                onTap: onAktiviteEkle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.2),
        child: Container(
          padding: EdgeInsets.all(size.cardPadding * 1.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              SizedBox(height: size.smallSpacing),
              Text(
                title,
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: size.smallText * 0.9,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}