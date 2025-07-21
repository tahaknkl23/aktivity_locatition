// lib/presentation/widgets/company/company_card_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/common/info_item_widget.dart';
import '../../../data/models/company/company_list_model.dart';

class CompanyCardWidget extends StatelessWidget {
  final CompanyListItem company;
  final VoidCallback onTap;

  const CompanyCardWidget({
    super.key,
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          child: Padding(
            padding: EdgeInsets.all(size.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(size),
                SizedBox(height: size.mediumSpacing),
                _buildContactInfo(size),
                SizedBox(height: size.smallSpacing),
                _buildWebAndRepresentative(size),
                SizedBox(height: size.mediumSpacing),
                _buildFooter(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        SizedBox(width: size.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.firma,
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (company.sektor != '-') ...[
                SizedBox(height: size.tinySpacing),
                Text(
                  company.sektor,
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ],
    );
  }

  Widget _buildContactInfo(AppSizes size) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.phone,
            label: 'Telefon',
            value: company.telefon,
            isEmpty: company.telefon == '-',
          ),
        ),
        SizedBox(width: size.mediumSpacing),
        Expanded(
          child: InfoItemWidget(
            icon: Icons.email,
            label: 'E-posta',
            value: company.mail,
            isEmpty: company.mail == '-',
          ),
        ),
      ],
    );
  }

  Widget _buildWebAndRepresentative(AppSizes size) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.language,
            label: 'Web',
            value: company.webAdres,
            isEmpty: company.webAdres == '-',
          ),
        ),
        SizedBox(width: size.mediumSpacing),
        Expanded(
          child: InfoItemWidget(
            icon: Icons.person,
            label: 'Temsilci',
            value: company.temsilci,
            isEmpty: company.temsilci == '-',
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppSizes size) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: size.tinySpacing),
        Text(
          _formatDate(company.kayitTarihi),
          style: TextStyle(
            fontSize: size.smallText * 0.9,
            color: AppColors.textTertiary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ID: ${company.id}',
            style: TextStyle(
              fontSize: size.smallText * 0.8,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
