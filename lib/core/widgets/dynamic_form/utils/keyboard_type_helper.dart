import 'package:flutter/material.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

class KeyboardTypeHelper {
  static TextInputType getKeyboardType(DynamicFormField field) {
    if (field.mask != null && field.mask!.contains('@')) {
      return TextInputType.emailAddress;
    }

    final keyLower = field.key.toLowerCase();

    if (keyLower.contains('phone') || keyLower.contains('tel')) {
      return TextInputType.phone;
    }
    if (keyLower.contains('mail') || keyLower.contains('email')) {
      return TextInputType.emailAddress;
    }
    if (keyLower.contains('number') || keyLower.contains('amount')) {
      return TextInputType.number;
    }
    if (keyLower.contains('url') || keyLower.contains('website')) {
      return TextInputType.url;
    }

    return TextInputType.text;
  }
}
