import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/validators.dart';
import '../../../core/widgets/real_map_location_picker.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../core/widgets/common/searchable_dropdown_widget.dart'; // 🆕 Import

/// Dynamic form field widget that renders different field types
class DynamicFormFieldWidget extends StatefulWidget {
  final DynamicFormField field;
  final Function(String key, dynamic value) onValueChanged;
  final Map<String, dynamic> formData;

  const DynamicFormFieldWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
    required this.formData,
  });

  @override
  State<DynamicFormFieldWidget> createState() => _DynamicFormFieldWidgetState();
}

class _DynamicFormFieldWidgetState extends State<DynamicFormFieldWidget> {
  late TextEditingController _textController;
  dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.formData[widget.field.key] ?? widget.field.value;
    _textController = TextEditingController(
      text: _currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicFormFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.key != widget.field.key) {
      _currentValue = widget.formData[widget.field.key] ?? widget.field.value;
      _textController.text = _currentValue?.toString() ?? '';
    }

    // If options changed, validate current value
    if (widget.field.type == FormFieldType.dropdown && widget.field.options != oldWidget.field.options) {
      if (widget.field.options != null && _currentValue != null) {
        final hasValue = widget.field.options!.any((option) => option.value == _currentValue);
        if (!hasValue) {
          _currentValue = null;
          debugPrint('[DynamicFormField] Value reset due to options change: ${widget.field.key}');
        }
      }
    }

    // MultiSelect için options validation
    if (widget.field.type == FormFieldType.multiSelect && widget.field.options != oldWidget.field.options) {
      if (widget.field.options != null && _currentValue != null) {
        List<dynamic> selectedValues = [];
        if (_currentValue is List) {
          selectedValues = List<dynamic>.from(_currentValue);
        } else if (_currentValue is String && _currentValue.toString().isNotEmpty) {
          selectedValues = _currentValue.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }

        // Geçersiz değerleri temizle
        final validValues = selectedValues.where((value) => widget.field.options!.any((option) => option.value == value)).toList();

        if (validValues.length != selectedValues.length) {
          _currentValue = validValues;
          debugPrint('[DynamicFormField] MultiSelect value cleaned: ${widget.field.key}');
        }
      }
    }
  }

  void _onValueChanged(dynamic value) {
    setState(() {
      _currentValue = value;
    });
    widget.onValueChanged(widget.field.key, value);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(size),
          SizedBox(height: size.smallSpacing),
          _buildField(size),
        ],
      ),
    );
  }

  Widget _buildLabel(AppSizes size) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.field.label,
            style: TextStyle(
              fontSize: size.textSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // 🔧 Dropdown için zorunlu işareti gösterme - kullanıcı deneyimi için
        if (widget.field.isRequired && widget.field.type != FormFieldType.dropdown)
          Text(
            ' *',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (widget.field.labelTooltip != null)
          Padding(
            padding: EdgeInsets.only(left: size.smallSpacing),
            child: Tooltip(
              message: widget.field.labelTooltip!,
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField(AppSizes size) {
    if (!widget.field.isEnabled) {
      return _buildDisabledField(size);
    }

    switch (widget.field.type) {
      case FormFieldType.text:
        return _buildTextField(size);
      case FormFieldType.textarea:
        return _buildTextAreaField(size);
      case FormFieldType.date:
        return _buildDateField(size);
      case FormFieldType.dropdown:
        return _buildDropdownField(size);
      case FormFieldType.multiSelect:
        return _buildMultiSelectField(size);
      case FormFieldType.checkbox:
        return _buildCheckboxField(size);
      case FormFieldType.label:
        return _buildLabelField(size);
      case FormFieldType.map:
        return _buildMapField(size);
      case FormFieldType.empty:
        return _buildEmptyField(size);
      case FormFieldType.hidden:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(AppSizes size) {
    return TextFormField(
      controller: _textController,
      enabled: widget.field.isEnabled,
      decoration: _buildInputDecoration(size),
      keyboardType: _getKeyboardType(),
      inputFormatters: _getInputFormatters(),
      validator: widget.field.isRequired ? (value) => Validators.validateRequired(value, fieldName: widget.field.label) : null,
      onChanged: _onValueChanged,
      style: TextStyle(fontSize: size.textSize),
    );
  }

  Widget _buildTextAreaField(AppSizes size) {
    return TextFormField(
      controller: _textController,
      enabled: widget.field.isEnabled,
      decoration: _buildInputDecoration(size),
      maxLines: int.tryParse(widget.field.widget.properties['row']?.toString() ?? '3') ?? 3,
      validator: widget.field.isRequired ? (value) => Validators.validateRequired(value, fieldName: widget.field.label) : null,
      onChanged: _onValueChanged,
      style: TextStyle(fontSize: size.textSize),
    );
  }

  Widget _buildDateField(AppSizes size) {
    return InkWell(
      onTap: widget.field.isEnabled ? () => _selectDate(context) : null,
      child: InputDecorator(
        decoration: _buildInputDecoration(size),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(_currentValue) ?? 'Tarih seçiniz',
              style: TextStyle(
                fontSize: size.textSize,
                color: _currentValue != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: widget.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 YENİ SEARCHABLE DROPDOWN - Eski dropdown yerine
  Widget _buildDropdownField(AppSizes size) {
    // Ensure current value exists in options or set to null
    dynamic validValue = _currentValue;
    if (widget.field.options != null && _currentValue != null) {
      final hasValue = widget.field.options!.any((option) => option.value == _currentValue);
      if (!hasValue) {
        validValue = null;
        debugPrint('[DynamicFormField] Current value $_currentValue not found in options, setting to null');
      }
    }

    // 🆕 Searchable dropdown kullan - zorunluluk kaldırıldı
    return SearchableDropdownWidget(
      label: widget.field.label,
      hint: 'Seçiniz...',
      options: widget.field.options ?? [],
      value: validValue,
      onChanged: widget.field.isEnabled
          ? (value) {
              debugPrint('[DynamicFormField] Searchable dropdown changed: ${widget.field.key} = $value');
              _onValueChanged(value);
            }
          : (value) {},
      isRequired: false, // 🔧 Zorunlu olmaktan çıkardık
      isEnabled: widget.field.isEnabled,
      validator: null, // 🔧 Validasyon kaldırıldı
    );
  }

  Widget _buildMultiSelectField(AppSizes size) {
    // Current value kontrolü - List olmalı
    List<dynamic> selectedValues = [];
    if (_currentValue != null) {
      if (_currentValue is List) {
        selectedValues = List<dynamic>.from(_currentValue);
      } else if (_currentValue is String && _currentValue.toString().isNotEmpty) {
        // String ise virgülle ayrılmış olabilir
        selectedValues = _currentValue.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        // Tek değer ise list'e çevir
        selectedValues = [_currentValue];
      }
    }

    return InkWell(
      onTap: widget.field.isEnabled ? () => _showMultiSelectDialog(context) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
          color: widget.field.isEnabled ? AppColors.surface : AppColors.surfaceVariant,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size.cardPadding,
          vertical: size.cardPadding * 0.8,
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedValues.isEmpty
                  ? Text(
                      'Seçiniz...',
                      style: TextStyle(
                        fontSize: size.textSize,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedValues.map((value) {
                        final option = widget.field.options?.firstWhere(
                          (opt) => opt.value == value,
                          orElse: () => DropdownOption(value: value, text: value.toString()),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            option?.text ?? value.toString(),
                            style: TextStyle(
                              fontSize: size.textSize * 0.9,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: widget.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxField(AppSizes size) {
    return CheckboxListTile(
      value: _currentValue == true,
      onChanged: widget.field.isEnabled ? (value) => _onValueChanged(value) : null,
      title: Text(
        widget.field.label,
        style: TextStyle(fontSize: size.textSize),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildLabelField(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _currentValue?.toString() ?? '-',
        style: TextStyle(
          fontSize: size.textSize,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMapField(AppSizes size) {
    // Mevcut konum verisi varsa parse et
    MapLocationData? currentLocation;
    if (_currentValue != null && _currentValue.toString().isNotEmpty) {
      try {
        final parts = _currentValue.toString().split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          currentLocation = MapLocationData(
            latitude: lat,
            longitude: lng,
            address: 'Seçilen konum',
            coordinates: _currentValue.toString(),
          );
        }
      } catch (e) {
        debugPrint('[DynamicFormField] Invalid location format: $_currentValue');
      }
    }

    return InkWell(
      onTap: widget.field.isEnabled ? () => _openMapSelector(context) : null,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: currentLocation != null ? _buildSelectedLocationDisplay(currentLocation, size) : _buildEmptyLocationDisplay(size),
      ),
    );
  }

  Widget _buildSelectedLocationDisplay(MapLocationData location, AppSizes size) {
    return Padding(
      padding: EdgeInsets.all(size.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: size.mediumIcon,
              ),
              SizedBox(width: size.smallSpacing),
              Expanded(
                child: Text(
                  'Konum Seçildi',
                  style: TextStyle(
                    fontSize: size.textSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.field.isEnabled ? () => _clearLocation() : null,
                icon: Icon(
                  Icons.clear,
                  size: 20,
                  color: AppColors.error,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: size.tinySpacing),
          Flexible(
            child: Text(
              location.address,
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: size.tinySpacing),
          Text(
            location.coordinates,
            style: TextStyle(
              fontSize: size.smallText * 0.9,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationDisplay(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 32,
            color: widget.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            widget.field.isEnabled ? 'Konum seçiniz' : 'Konum seçimi devre dışı',
            style: TextStyle(
              fontSize: size.textSize,
              color: widget.field.isEnabled ? AppColors.textSecondary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _clearLocation() {
    _onValueChanged(null);
  }

  Widget _buildEmptyField(AppSizes size) {
    final content = widget.field.widget.properties['value']?.toString() ?? '';
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          SizedBox(width: size.smallSpacing),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledField(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _currentValue?.toString() ?? '-',
        style: TextStyle(
          fontSize: size.textSize,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(AppSizes size) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.cardPadding,
        vertical: size.cardPadding * 0.8,
      ),
      filled: true,
      fillColor: widget.field.isEnabled ? AppColors.surface : AppColors.surfaceVariant,
    );
  }

  TextInputType _getKeyboardType() {
    if (widget.field.mask != null && widget.field.mask!.contains('@')) {
      return TextInputType.emailAddress;
    }
    if (widget.field.key.toLowerCase().contains('phone') || widget.field.key.toLowerCase().contains('tel')) {
      return TextInputType.phone;
    }
    if (widget.field.key.toLowerCase().contains('mail')) {
      return TextInputType.emailAddress;
    }
    return TextInputType.text;
  }

  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (widget.field.mask != null && widget.field.mask!.isNotEmpty) {
      // Add mask formatters if needed
    }

    return formatters;
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        String dateStr = value.trim();

        // Zaten doğru formatta ise direkt döndür
        if (dateStr.contains('.') && (dateStr.contains(':') || dateStr.contains(' '))) {
          return dateStr;
        }

        // ISO format ise parse et
        if (dateStr.contains('-') || dateStr.contains('T')) {
          final date = DateTime.parse(dateStr);
          return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }

        // Başka bir format varsa olduğu gibi döndür
        return dateStr;
      }
    } catch (e) {
      debugPrint('[DynamicFormField] Date format error for value: $value - Error: $e');
      // Hata durumunda value'yu string olarak döndür
      return value.toString();
    }

    return value.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      DateTime initialDate = DateTime.now();
      TimeOfDay initialTime = TimeOfDay.now();

      // Parse current value if exists
      if (_currentValue != null) {
        try {
          String dateStr = _currentValue.toString().trim();

          if (dateStr.contains('.') && dateStr.contains(' ') && dateStr.contains(':')) {
            // Format: "dd.MM.yyyy HH:mm"
            List<String> mainParts = dateStr.split(' ');
            if (mainParts.length >= 2) {
              List<String> dateParts = mainParts[0].split('.');
              List<String> timeParts = mainParts[1].split(':');

              if (dateParts.length == 3 && timeParts.length >= 2) {
                initialDate = DateTime(
                  int.parse(dateParts[2]), // year
                  int.parse(dateParts[1]), // month
                  int.parse(dateParts[0]), // day
                );
                initialTime = TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                );
              }
            }
          } else if (dateStr.contains('.')) {
            // Format: "dd.MM.yyyy"
            List<String> dateParts = dateStr.split('.');
            if (dateParts.length == 3) {
              initialDate = DateTime(
                int.parse(dateParts[2]), // year
                int.parse(dateParts[1]), // month
                int.parse(dateParts[0]), // day
              );
            }
          } else {
            // Try ISO format
            initialDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            initialTime = TimeOfDay.fromDateTime(initialDate);
          }
        } catch (e) {
          debugPrint('[DynamicFormField] Date parse error: $e');
          initialDate = DateTime.now();
          initialTime = TimeOfDay.now();
        }
      }

      // Show date picker
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (selectedDate != null && mounted) {
        // Check if widget is DateTimePicker (has time component)
        final hasTime = widget.field.widget.name.toLowerCase() == 'datetimepicker' ||
            widget.field.widget.properties['format']?.toString().contains('HH:mm') == true;

        if (hasTime) {
          // Show time picker
          final selectedTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.primary,
                      ),
                ),
                child: child!,
              );
            },
          );

          if (selectedTime != null && mounted) {
            // Format as "dd.MM.yyyy HH:mm"
            final formattedDateTime =
                '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
            _onValueChanged(formattedDateTime);
          }
        } else {
          // Format as "dd.MM.yyyy"
          final formattedDate =
              '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}';
          _onValueChanged(formattedDate);
        }
      }
    } catch (e) {
      debugPrint('[DynamicFormField] Date selection error: $e');
    }
  }

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    if (widget.field.options == null || widget.field.options!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçenekler yükleniyor, lütfen bekleyin'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    // Mevcut seçimleri hazırla
    List<dynamic> selectedValues = [];
    if (_currentValue != null) {
      if (_currentValue is List) {
        selectedValues = List<dynamic>.from(_currentValue);
      } else if (_currentValue is String && _currentValue.toString().isNotEmpty) {
        selectedValues = _currentValue.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        selectedValues = [_currentValue];
      }
    }

    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          title: widget.field.label,
          options: widget.field.options!,
          selectedValues: selectedValues,
        );
      },
    );

    if (result != null) {
      _onValueChanged(result);
    }
  }

  Future<void> _openMapSelector(BuildContext context) async {
    try {
      // Map selector dialog'unu aç
      final result = await showDialog<MapLocationData>(
        context: context,
        builder: (context) => RealMapLocationPicker(
          title: widget.field.label,
          initialCoordinates: _currentValue?.toString(),
        ),
      );

      // Sonucu işle
      if (result != null) {
        // Koordinatları string olarak kaydet (web formatına uygun)
        _onValueChanged(result.coordinates);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Konum seçildi: ${result.address}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[DynamicFormField] Map selector error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konum seçiminde hata: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// MultiSelect Dialog Widget
class MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<DropdownOption> options;
  final List<dynamic> selectedValues;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List<dynamic>.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: size.mediumText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: size.height * 0.5, // Maksimum yükseklik
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.options.length,
          itemBuilder: (context, index) {
            final option = widget.options[index];
            final isSelected = _selectedValues.contains(option.value);

            return CheckboxListTile(
              title: Text(
                option.text,
                style: TextStyle(fontSize: size.textSize),
              ),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedValues.contains(option.value)) {
                      _selectedValues.add(option.value);
                    }
                  } else {
                    _selectedValues.remove(option.value);
                  }
                });
              },
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'İptal',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size.textSize,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedValues),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: Text(
            'Tamam (${_selectedValues.length})',
            style: TextStyle(fontSize: size.textSize),
          ),
        ),
      ],
    );
  }
}
