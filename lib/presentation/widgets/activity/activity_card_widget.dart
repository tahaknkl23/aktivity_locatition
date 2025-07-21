// lib/presentation/widgets/activity/activity_card_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/common/info_item_widget.dart';
import '../../../data/models/activity/activity_list_model.dart';

class ActivityCardWidget extends StatelessWidget {
  final ActivityListItem activity;
  final bool isOpen;
  final VoidCallback onTap;

  const ActivityCardWidget({
    super.key,
    required this.activity,
    required this.isOpen,
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
              border: Border(
                left: BorderSide(
                  color: isOpen ? AppColors.success : AppColors.error,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(size.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(size),
                  SizedBox(height: size.mediumSpacing),
                  _buildCompanyAndContact(size),
                  SizedBox(height: size.smallSpacing),
                  if (activity.hasAddress) ...[
                    _buildAddressSection(size),
                    SizedBox(height: size.smallSpacing),
                  ],
                  _buildDateAndRepresentative(size),
                  if (activity.detay != null && activity.detay!.isNotEmpty) ...[
                    SizedBox(height: size.smallSpacing),
                    _buildDetailSection(size),
                  ],
                  SizedBox(height: size.mediumSpacing),
                  _buildFooter(size),
                ],
              ),
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
            color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isOpen ? Icons.assignment_outlined : Icons.assignment_turned_in,
            color: isOpen ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ),
        SizedBox(width: size.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activity.displayAktiviteTipi != 'Belirtilmemiş') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.displayAktiviteTipi,
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: size.tinySpacing),
              ],
              Text(
                activity.konu ?? 'Konu belirtilmemiş',
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontStyle: activity.konu == null ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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

  Widget _buildCompanyAndContact(AppSizes size) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.business,
            label: 'Firma',
            value: activity.firma ?? 'Belirtilmemiş',
            isEmpty: activity.firma == null,
          ),
        ),
        SizedBox(width: size.mediumSpacing),
        Expanded(
          child: InfoItemWidget(
            icon: Icons.person,
            label: 'Kişi',
            value: activity.kisi ?? 'Belirtilmemiş',
            isEmpty: activity.kisi == null,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding * 0.75),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.75),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: size.smallSpacing),
              Text(
                'Ziyaret Adresi',
                style: TextStyle(
                  fontSize: size.smallText,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (activity.adresTipi != null && activity.adresTipi!.isNotEmpty) ...[
                SizedBox(width: size.smallSpacing),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.adresTipi!,
                    style: TextStyle(
                      fontSize: size.smallText * 0.8,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            activity.displayAddress,
            style: TextStyle(
              fontSize: size.textSize * 0.95,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (activity.hasLocation) ...[
            SizedBox(height: size.tinySpacing),
            Row(
              children: [
                Icon(
                  Icons.place,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: size.tinySpacing),
                Text(
                  '${activity.ilce}, ${activity.il}',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateAndRepresentative(AppSizes size) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.access_time,
            label: 'Başlangıç',
            value: activity.baslangic ?? 'Belirtilmemiş',
            isEmpty: activity.baslangic == null,
          ),
        ),
        SizedBox(width: size.mediumSpacing),
        Expanded(
          child: InfoItemWidget(
            icon: Icons.account_circle,
            label: 'Temsilci',
            value: activity.temsilci ?? 'Belirtilmemiş',
            isEmpty: activity.temsilci == null,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.smallSpacing),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note,
            size: 16,
            color: AppColors.info,
          ),
          SizedBox(width: size.smallSpacing),
          Expanded(
            child: Text(
              activity.detay!,
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.info,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppSizes size) {
    return Column(
      children: [
        // 🆕 YENİ: Kayıt tarihi ve oluşturan kişi
        if (activity.tarih != null || activity.olusturan != null) ...[
          Row(
            children: [
              if (activity.tarih != null) ...[
                Expanded(
                  child: InfoItemWidget(
                    icon: Icons.calendar_today,
                    label: 'Kayıt Tarihi',
                    value: activity.tarih!,
                    isEmpty: false,
                  ),
                ),
                if (activity.olusturan != null) SizedBox(width: size.mediumSpacing),
              ],
              if (activity.olusturan != null)
                Expanded(
                  child: InfoItemWidget(
                    icon: Icons.person_add,
                    label: 'Oluşturan',
                    value: activity.olusturan!,
                    isEmpty: false,
                  ),
                ),
            ],
          ),
          SizedBox(height: size.mediumSpacing),
        ],

        // Status ve ID row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOpen ? 'AÇIK' : 'KAPALI',
                style: TextStyle(
                  fontSize: size.smallText * 0.8,
                  color: isOpen ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ID: ${activity.id}',
                style: TextStyle(
                  fontSize: size.smallText * 0.8,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
