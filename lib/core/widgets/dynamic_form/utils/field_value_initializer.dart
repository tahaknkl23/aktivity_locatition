import 'package:flutter/material.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

class FieldValueInitializer {
  final DynamicFormField field;
  final Map<String, dynamic> formData;

  const FieldValueInitializer({
    required this.field,
    required this.formData,
  });

  InitializationResult initialize() {
    dynamic initialValue = _getInitialValue();
    String textValue = _convertToText(initialValue);
    
    debugPrint('[FIELD_INIT] ✅ ${field.key} initialized: $initialValue');

    return InitializationResult(
      value: initialValue,
      textController: TextEditingController(text: textValue),
    );
  }

  dynamic _getInitialValue() {
    if (formData.containsKey(field.key)) {
      return formData[field.key];
    }
    if (field.value != null) {
      return field.value;
    }
    if (field.widget.properties.containsKey('value')) {
      return field.widget.properties['value'];
    }
    return null;
  }

  String _convertToText(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value['Text']?.toString() ?? 
             value['Adi']?.toString() ?? 
             value.toString();
    }
    return value.toString();
  }
}

class InitializationResult {
  final dynamic value;
  final TextEditingController textController;

  const InitializationResult({
    required this.value,
    required this.textController,
  });
}