// lib/core/widgets/dynamic_form/field_types/label_field_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

/// Label/Read-only field widget'ı - İYİLEŞTİRİLMİŞ VERSİYON
class LabelFieldWidget extends StatelessWidget {
  final DynamicFormField field;
  final dynamic currentValue;
  final AppSizes size;
  final bool isDisabled;

  const LabelFieldWidget({
    super.key,
    required this.field,
    required this.currentValue,
    required this.size,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = _getDisplayValue();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getFieldColor().withValues(alpha: 0.05),
            _getFieldColor().withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        border: Border.all(
          color: _getFieldColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getFieldColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getFieldIcon(),
                size: 16,
                color: _getFieldColor(),
              ),
            ),

            SizedBox(width: size.smallSpacing),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // API label'ı
                  Text(
                    field.label, // ✅ API'den gelen gerçek isim
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: _getFieldColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 2),

                  // Value
                  Text(
                    displayValue.isNotEmpty ? displayValue : '—',
                    style: TextStyle(
                      fontSize: size.textSize,
                      fontWeight: FontWeight.w600,
                      color: displayValue.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getFieldColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: size.smallText * 0.8,
                  color: _getFieldColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayValue() {
    if (currentValue == null) return '';

    // Boş veya sadece whitespace kontrolü
    final stringValue = currentValue.toString().trim();
    if (stringValue.isEmpty || stringValue == 'null') return '';

    return stringValue;
  }

  IconData _getFieldIcon() {
    final labelLower = field.label.toLowerCase();

    if (labelLower.contains('ticari') && labelLower.contains('kod')) {
      return Icons.qr_code; // Kod için
    } else if (labelLower.contains('bakiye')) {
      return Icons.account_balance_wallet; // Bakiye için
    } else if (labelLower.contains('toplam') || labelLower.contains('total')) {
      return Icons.calculate; // Toplam için
    } else if (labelLower.contains('durum') || labelLower.contains('status')) {
      return Icons.info_outline; // Durum için
    } else if (labelLower.contains('sayı') || labelLower.contains('adet')) {
      return Icons.numbers; // Sayaç için
    }

    return Icons.label; // Varsayılan
  }

  Color _getFieldColor() {
    final labelLower = field.label.toLowerCase();

    if (labelLower.contains('ticari') && labelLower.contains('kod')) {
      return Colors.blue; // Mavi - Kod
    } else if (labelLower.contains('bakiye')) {
      return Colors.green; // Yeşil - Para
    } else if (labelLower.contains('toplam') || labelLower.contains('total')) {
      return Colors.orange; // Turuncu - Toplam
    } else if (labelLower.contains('durum') || labelLower.contains('status')) {
      return Colors.purple; // Mor - Durum
    } else if (labelLower.contains('sayı') || labelLower.contains('adet')) {
      return Colors.teal; // Deniz mavisi - Sayaç
    }

    return Colors.grey; // Varsayılan
  }

  String _getStatusText() {
    final hasValue = _getDisplayValue().isNotEmpty;

    if (field.label.toLowerCase().contains('ticari') && field.label.toLowerCase().contains('kod')) {
      return hasValue ? 'KOD' : 'YENİ';
    } else if (field.label.toLowerCase().contains('bakiye')) {
      return hasValue ? 'BAKİYE' : 'YOK';
    }

    return hasValue ? 'VAR' : 'YOK';
  }
}

// =======================================================================
