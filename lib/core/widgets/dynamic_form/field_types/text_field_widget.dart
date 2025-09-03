// lib/core/widgets/dynamic_form/field_types/text_field_widget.dart - GENERIC VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/helpers/validators.dart';
import '../dynamic_form_field_widget.dart';
import '../utils/input_decoration_builder.dart';
import '../utils/keyboard_type_helper.dart';

class TextFieldWidget extends StatelessWidget {
  final FieldCommonProps props;
  final bool isMultiline;

  const TextFieldWidget({
    super.key,
    required this.props,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Min/Max lines kontrolü
    final maxLines = isMultiline ? _getMaxLines() : 1;
    final minLines = isMultiline ? _getMinLines(maxLines) : 1;

    return TextFormField(
      controller: props.textController,
      enabled: props.field.isEnabled,
      decoration: InputDecorationBuilder.build(
        size: props.size,
        isEnabled: props.field.isEnabled,
        hintText: _getHintText(),
      ),
      keyboardType: isMultiline ? TextInputType.multiline : KeyboardTypeHelper.getKeyboardType(props.field),
      inputFormatters: _getInputFormatters(),
      maxLines: maxLines,
      minLines: minLines,
      validator: props.field.isRequired
          ? (value) => Validators.validateRequired(
                value,
                fieldName: props.field.label,
              )
          : null,
      onChanged: props.onValueChanged,
      style: TextStyle(
        fontSize: props.size.textSize,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  String _getHintText() {
    if (isMultiline) {
      // ✅ GENERIC: API'den gelen label kullan
      return '${props.field.label} yazınız...';
    }

    // ✅ GENERIC: Field type'a göre dinamik hint ama API label'ı kullan
    final keyLower = props.field.key.toLowerCase();
    final labelLower = props.field.label.toLowerCase();

    if (keyLower.contains('email') ||
        keyLower.contains('mail') ||
        labelLower.contains('email') ||
        labelLower.contains('mail') ||
        labelLower.contains('e-posta')) {
      return 'ornek@email.com';
    }
    if (keyLower.contains('phone') || keyLower.contains('tel') || labelLower.contains('telefon') || labelLower.contains('phone')) {
      return '0555 123 45 67';
    }
    if (keyLower.contains('web') || keyLower.contains('url') || labelLower.contains('web') || labelLower.contains('site')) {
      return 'https://ornek.com';
    }
    if (keyLower.contains('tax') || keyLower.contains('vergi')) {
      return '1234567890';
    }
    if (keyLower.contains('iban')) {
      return 'TR00 0000 0000 0000 0000 0000 00';
    }

    // ✅ GENERIC: Varsayılan - API label'ı kullan
    return '${props.field.label} giriniz';
  }

  int _getMaxLines() {
    if (!isMultiline) return 1;

    final rowProperty = props.field.widget.properties['row']?.toString();
    final maxLines = int.tryParse(rowProperty ?? '5') ?? 5;

    // ✅ FIX: Minimum 1 satır garanti et
    return maxLines.clamp(1, 20); // Max 20 satır limiti
  }

  /// ✅ FIX: MinLines hesapla (MaxLines'dan küçük olmalı)
  int _getMinLines(int maxLines) {
    if (!isMultiline) return 1;

    // MinLines, MaxLines'dan küçük veya eşit olmalı
    final defaultMinLines = 3;
    return defaultMinLines.clamp(1, maxLines);
  }

  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[];

    final keyLower = props.field.key.toLowerCase();
    final labelLower = props.field.label.toLowerCase();

    // Phone formatters - dynamic detection
    if (keyLower.contains('phone') || keyLower.contains('tel') || labelLower.contains('telefon') || labelLower.contains('phone')) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    // Email formatters - dynamic detection
    if (keyLower.contains('email') ||
        keyLower.contains('mail') ||
        labelLower.contains('email') ||
        labelLower.contains('mail') ||
        labelLower.contains('e-posta')) {
      formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
    }

    return formatters;
  }
}
