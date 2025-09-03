import 'dart:convert';
import 'package:aktivity_location_app/core/helpers/dynamic_cascade_helper.dart';
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
      debugPrint('[FormField] 🔍 Parsing field: ${json.keys.toList()}');
      debugPrint('[FormField] 🔍 Label: ${json['label']}');
      debugPrint('[FormField] 🔍 Value: ${json['value']}');

      final widget = json['widget'] as Map<String, dynamic>? ?? {};
      final properties = widget['properties'] as Map<String, dynamic>? ?? {};
      final widgetName = widget['name'] as String? ?? 'TextBox';

      debugPrint('[FormField] 🔍 Widget name: $widgetName');
      debugPrint('[FormField] 🔍 Properties: ${properties.keys.toList()}');

      // Determine field type based on widget name and properties
      FormFieldType fieldType = _determineFieldType(widgetName, properties);
      debugPrint('[FormField] 🔍 Determined type: $fieldType');

      // Parse dropdown options if exists
      List<DropdownOption>? options;
      if (fieldType == FormFieldType.dropdown || fieldType == FormFieldType.multiSelect) {
        options = _parseDropdownOptions(widget);
      }

      // 🔧 SAFE INTEGER PARSING - String'leri int'e çevir
      int safeParseInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String) {
          return int.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      final columnWidth = safeParseInt(json['columnWidth'], 12);
      final labelWidth = safeParseInt(json['labelWidth'], 3);
      final controlWidth = safeParseInt(json['controlWidth'], 9);

      debugPrint('[FormField] 🔍 Column width: $columnWidth');
      debugPrint('[FormField] 🔍 Label width: $labelWidth');
      debugPrint('[FormField] 🔍 Control width: $controlWidth');

      final field = DynamicFormField(
        key: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        labelTooltip: json['labelTooltip'] as String?,
        value: properties['value'],
        isRequired: properties['required'] as bool? ?? false,
        isEnabled: properties['enabled'] as bool? ?? true,
        type: fieldType,
        columnWidth: columnWidth,
        labelWidth: labelWidth,
        controlWidth: controlWidth,
        widget: FormFieldWidget.fromJson(widget),
        mask: properties['mask'] as String?,
        options: options,
        isMasterControl: json['IsMasterControl'] as bool? ?? false,
      );

      debugPrint('[FormField] ✅ Field parsed: ${field.label} (${field.type})');
      return field;
    } catch (e, stackTrace) {
      debugPrint('[FormField] ❌ Parse error: $e');
      debugPrint('[FormField] ❌ StackTrace: $stackTrace');
      debugPrint('[FormField] ❌ JSON: $json');

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
    debugPrint('[FIELD_TYPE] 🔍 Determining type for widget: $widgetName');
    debugPrint('[FIELD_TYPE] 🔍 Widget properties: $properties');

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
      case 'multiselectbox':
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
        debugPrint('[FIELD_TYPE] ⚠️ Unknown widget type: $widgetName, defaulting to text');
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
      debugPrint('[FORM_SECTION] 🔍 Raw JSON keys: ${json.keys.toList()}');
      debugPrint('[FORM_SECTION] 🔍 Section label: ${json['label']}');
      debugPrint('[FORM_SECTION] 🔍 Fields key exists: ${json.containsKey('Fields')}');

      final fieldsJson = json['Fields'] as List? ?? [];
      debugPrint('[FORM_SECTION] 🔍 Fields count in JSON: ${fieldsJson.length}');

      // Parse fields
      final fields = <DynamicFormField>[];

      for (int i = 0; i < fieldsJson.length; i++) {
        try {
          final fieldData = fieldsJson[i];
          debugPrint('[FORM_SECTION] 🔍 Parsing field $i: ${fieldData.keys.toList()}');

          if (fieldData is Map<String, dynamic>) {
            final field = DynamicFormField.fromJson(fieldData);
            if (field.isVisible) {
              fields.add(field);
              debugPrint('[FORM_SECTION] ✅ Field $i added: ${field.label}');
            } else {
              debugPrint('[FORM_SECTION] 🔍 Field $i hidden: ${field.label}');
            }
          } else {
            debugPrint('[FORM_SECTION] ❌ Field $i is not a Map: ${fieldData.runtimeType}');
          }
        } catch (e) {
          debugPrint('[FORM_SECTION] ❌ Failed to parse field $i: $e');
        }
      }

      debugPrint('[FORM_SECTION] ✅ Section parsed: ${json['label']} with ${fields.length} fields');

      return DynamicFormSection(
        label: json['label'] as String? ?? '',
        width: int.tryParse(json['width']?.toString() ?? '12') ?? 12,
        fields: fields,
        orderIndex: json['OrderIndex'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      debugPrint('[FORM_SECTION] ❌ Parse error: $e');
      debugPrint('[FORM_SECTION] ❌ StackTrace: $stackTrace');
      debugPrint('[FORM_SECTION] ❌ JSON: $json');

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
      debugPrint('[DynamicForm] 🔍 Parsing form model...');

      final formData = json['Data']?['Form'] as Map<String, dynamic>? ?? {};
      final sectionsJson = formData['Sections'] as String? ?? '[]';

      debugPrint('[DynamicForm] 🔍 Form name: ${formData['FormName']}');
      debugPrint('[DynamicForm] 🔍 Sections JSON length: ${sectionsJson.length}');

      // Parse sections JSON string
      List<dynamic> sectionsList = [];
      try {
        sectionsList = jsonDecode(sectionsJson) as List? ?? [];
        debugPrint('[DynamicForm] ✅ Sections parsed: ${sectionsList.length} sections');
      } catch (e) {
        debugPrint('[DynamicForm] ❌ Sections parse error: $e');
      }

      final sections = <DynamicFormSection>[];
      for (int i = 0; i < sectionsList.length; i++) {
        try {
          final sectionData = sectionsList[i];
          if (sectionData is Map<String, dynamic>) {
            final section = DynamicFormSection.fromJson(sectionData);
            sections.add(section);
            debugPrint('[DynamicForm] ✅ Section $i parsed: ${section.label} (${section.fields.length} fields)');
          } else {
            debugPrint('[DynamicForm] ❌ Section $i is not a Map: ${sectionData.runtimeType}');
          }
        } catch (e) {
          debugPrint('[DynamicForm] ❌ Failed to parse section $i: $e');
        }
      }

      final model = DynamicFormModel(
        formName: formData['FormName'] as String? ?? '',
        description: formData['Description'] as String? ?? '',
        formId: formData['Id'] as int? ?? 0,
        tableId: formData['TableId'] as int? ?? 0,
        routeName: formData['RouteName'] as String? ?? '',
        sections: sections,
        data: json['Data']?['Data'] as Map<String, dynamic>? ?? {},
        pristineData: json['Data']?['PristineData'] as Map<String, dynamic>? ?? {},
      );

      debugPrint('[DynamicForm] ✅ Form model created: ${model.formName}');
      debugPrint('[DynamicForm] ✅ Total sections: ${model.sections.length}');
      debugPrint('[DynamicForm] ✅ Total fields: ${model.allFields.length}');

      return model;
    } catch (e, stackTrace) {
      debugPrint('[DynamicForm] ❌ Parse error: $e');
      debugPrint('[DynamicForm] ❌ StackTrace: $stackTrace');

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

  List<DynamicFormField> get cascadeFields {
    return allFields.where((field) => field.isCascadeField).toList();
  }

  /// Debug cascade info for all fields
  void debugCascadeFields() {
    debugPrint('[FORM_MODEL] ===== CASCADE FIELDS DEBUG =====');

    final cascadeFields = this.cascadeFields;
    debugPrint('[FORM_MODEL] Total cascade fields: ${cascadeFields.length}');

    for (final field in cascadeFields) {
      field.debugCascadeInfo();
    }

    debugPrint('[FORM_MODEL] =====================================');
  }
}
