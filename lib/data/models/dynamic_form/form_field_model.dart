import 'dart:convert';

import 'package:flutter/material.dart';

/// Dynamic form field model that handles all form field types
class DynamicFormField {
  final String key;
  final String label;
  final String? labelTooltip;
  final dynamic value;
  final bool isRequired;
  final bool isEnabled;
  final FormFieldType type;
  final int columnWidth;
  final int labelWidth;
  final int controlWidth;
  final FormFieldWidget widget;
  final String? mask;
  List<DropdownOption>? options;
  final bool isMasterControl;

  DynamicFormField({
    required this.key,
    required this.label,
    this.labelTooltip,
    this.value,
    required this.isRequired,
    required this.isEnabled,
    required this.type,
    required this.columnWidth,
    required this.labelWidth,
    required this.controlWidth,
    required this.widget,
    this.mask,
    this.options,
    required this.isMasterControl,
  });

  factory DynamicFormField.fromJson(Map<String, dynamic> json) {
    try {
      final widget = json['widget'] as Map<String, dynamic>? ?? {};
      final properties = widget['properties'] as Map<String, dynamic>? ?? {};
      final widgetName = widget['name'] as String? ?? 'TextBox';

      // Determine field type based on widget name and properties
      FormFieldType fieldType = _determineFieldType(widgetName, properties);

      // Parse dropdown options if exists
      List<DropdownOption>? options;
      if (fieldType == FormFieldType.dropdown || fieldType == FormFieldType.multiSelect) {
        options = _parseDropdownOptions(widget);
      }

      return DynamicFormField(
        key: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        labelTooltip: json['labelTooltip'] as String?,
        value: properties['value'],
        isRequired: properties['required'] as bool? ?? false,
        isEnabled: properties['enabled'] as bool? ?? true,
        type: fieldType,
        columnWidth: json['columnWidth'] as int? ?? 12,
        labelWidth: json['labelWidth'] as int? ?? 3,
        controlWidth: json['controlWidth'] as int? ?? 9,
        widget: FormFieldWidget.fromJson(widget),
        mask: properties['mask'] as String?,
        options: options,
        isMasterControl: json['IsMasterControl'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('[FormField] Parse error: $e');
      // Return default text field on error
      return DynamicFormField(
        key: json['value'] as String? ?? 'unknown',
        label: json['label'] as String? ?? 'Unknown Field',
        value: null,
        isRequired: false,
        isEnabled: true,
        type: FormFieldType.text,
        columnWidth: 12,
        labelWidth: 3,
        controlWidth: 9,
        widget: FormFieldWidget.textBox(),
        isMasterControl: false,
      );
    }
  }

  static FormFieldType _determineFieldType(String widgetName, Map<String, dynamic> properties) {
    switch (widgetName.toLowerCase()) {
      case 'textbox':
        return FormFieldType.text;
      case 'textarea':
        return FormFieldType.textarea;
      case 'datepicker':
        return FormFieldType.date;
      case 'datetimepicker':
        return FormFieldType.date;
      case 'dropdownlist':
        return FormFieldType.dropdown;
      case 'multiselectbox': // 🔥 MultiSelectBox'ı multiSelect olarak işle
        return FormFieldType.multiSelect;
      case 'checkbox':
        return FormFieldType.checkbox;
      case 'hiddenbox':
        return FormFieldType.hidden;
      case 'sqllabel':
        return FormFieldType.label;
      case 'map':
        return FormFieldType.map;
      case 'empty':
        return FormFieldType.empty;
      default:
        return FormFieldType.text;
    }
  }

  static List<DropdownOption>? _parseDropdownOptions(Map<String, dynamic> widget) {
    try {
      // This would need to be populated from API calls
      // For now, return null - will be populated when data loads
      return null;
    } catch (e) {
      debugPrint('[FormField] Dropdown options parse error: $e');
      return null;
    }
  }

  /// Get responsive column span based on screen width
  int getResponsiveColumnSpan(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile: Full width for most fields
      return columnWidth >= 6 ? 12 : columnWidth;
    } else if (screenWidth < 900) {
      // Tablet: Adjust for medium screens
      return columnWidth >= 8 ? 12 : (columnWidth * 1.5).round().clamp(1, 12);
    } else {
      // Desktop: Use original column width
      return columnWidth;
    }
  }

  bool get isVisible => true;
}

/// Form field types supported by the dynamic form
enum FormFieldType {
  text,
  textarea,
  date,
  dropdown,
  multiSelect,
  checkbox,
  hidden,
  label,
  map,
  empty,
}

/// Form field widget configuration
class FormFieldWidget {
  final String name;
  final Map<String, dynamic> properties;
  final String? sourceType;
  final dynamic sourceValue;
  final String? dataTextField;
  final String? dataValueField;

  FormFieldWidget({
    required this.name,
    required this.properties,
    this.sourceType,
    this.sourceValue,
    this.dataTextField,
    this.dataValueField,
  });

  factory FormFieldWidget.fromJson(Map<String, dynamic> json) {
    return FormFieldWidget(
      name: json['name'] as String? ?? 'TextBox',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      sourceType: json['sourceType'] as String?,
      sourceValue: json['sourceValue'],
      dataTextField: json['dataTextField'] as String?,
      dataValueField: json['dataValueField'] as String?,
    );
  }

  factory FormFieldWidget.textBox() {
    return FormFieldWidget(
      name: 'TextBox',
      properties: {
        'enabled': true,
        'required': false,
        'value': null,
      },
    );
  }
}

/// Dropdown option model
class DropdownOption {
  final dynamic value;
  final String text;
  final bool isSelected;

  DropdownOption({
    required this.value,
    required this.text,
    this.isSelected = false,
  });

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      value: json['Value'] ?? json['value'],
      text: json['Text'] ?? json['text'] ?? json['Value']?.toString() ?? '',
    );
  }
}

/// Dynamic form section model
class DynamicFormSection {
  final String label;
  final int width;
  final List<DynamicFormField> fields;
  final int orderIndex;

  DynamicFormSection({
    required this.label,
    required this.width,
    required this.fields,
    required this.orderIndex,
  });

  factory DynamicFormSection.fromJson(Map<String, dynamic> json) {
    try {
      // 🔍 DEBUG: Raw JSON kontrolü
      debugPrint('[FORM_SECTION] 🔍 Raw JSON keys: ${json.keys.toList()}');
      debugPrint('[FORM_SECTION] 🔍 Fields key exists: ${json.containsKey('Fields')}');

      final fieldsJson = json['Fields'] as List? ?? [];
      debugPrint('[FORM_SECTION] 🔍 Fields count in JSON: ${fieldsJson.length}');

      // Parse fields
      final fields = fieldsJson.whereType<Map<String, dynamic>>().map((field) {
        debugPrint('[FORM_SECTION] 🔍 Parsing field: ${field.keys.toList()}');
        return DynamicFormField.fromJson(field);
      }).where((field) {
        debugPrint('[FORM_SECTION] 🔍 Field visible check: ${field.label} -> ${field.isVisible}');
        return field.isVisible;
      }).toList();

      debugPrint('[FORM_SECTION] 🔍 Final fields count: ${fields.length}');

      return DynamicFormSection(
        label: json['label'] as String? ?? '',
        width: json['width'] as int? ?? 12,
        fields: fields,
        orderIndex: json['OrderIndex'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('[FORM_SECTION] ❌ Parse error: $e');
      return DynamicFormSection(
        label: 'Parse Error',
        width: 12,
        fields: [],
        orderIndex: 0,
      );
    }
  }
}

/// Complete dynamic form model
class DynamicFormModel {
  final String formName;
  final String description;
  final int formId;
  final int tableId;
  final String routeName;
  final List<DynamicFormSection> sections;
  final Map<String, dynamic> data;
  final Map<String, dynamic> pristineData;

  DynamicFormModel({
    required this.formName,
    required this.description,
    required this.formId,
    required this.tableId,
    required this.routeName,
    required this.sections,
    required this.data,
    required this.pristineData,
  });

  factory DynamicFormModel.fromJson(Map<String, dynamic> json) {
    try {
      final formData = json['Data']?['Form'] as Map<String, dynamic>? ?? {};
      final sectionsJson = formData['Sections'] as String? ?? '[]';

      // Parse sections JSON string
      List<dynamic> sectionsList = [];
      try {
        sectionsList = jsonDecode(sectionsJson) as List? ?? [];
      } catch (e) {
        debugPrint('[DynamicForm] Sections parse error: $e');
      }

      final sections = sectionsList.whereType<Map<String, dynamic>>().map((section) => DynamicFormSection.fromJson(section)).toList();

      return DynamicFormModel(
        formName: formData['FormName'] as String? ?? '',
        description: formData['Description'] as String? ?? '',
        formId: formData['Id'] as int? ?? 0,
        tableId: formData['TableId'] as int? ?? 0,
        routeName: formData['RouteName'] as String? ?? '',
        sections: sections,
        data: json['Data']?['Data'] as Map<String, dynamic>? ?? {},
        pristineData: json['Data']?['PristineData'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      debugPrint('[DynamicForm] Parse error: $e');
      return DynamicFormModel(
        formName: 'Unknown Form',
        description: '',
        formId: 0,
        tableId: 0,
        routeName: '',
        sections: [],
        data: {},
        pristineData: {},
      );
    }
  }

  /// Get all visible fields from all sections
  List<DynamicFormField> get allFields {
    return sections.expand((section) => section.fields).toList();
  }

  /// Get field by key
  DynamicFormField? getFieldByKey(String key) {
    for (final section in sections) {
      for (final field in section.fields) {
        if (field.key == key) {
          return field;
        }
      }
    }
    return null;
  }
}

/// Helper to decode JSON string safely
dynamic jsonDecode(String source) {
  try {
    return json.decode(source);
  } catch (e) {
    debugPrint('[JSON] Decode error: $e');
    return null;
  }
}
