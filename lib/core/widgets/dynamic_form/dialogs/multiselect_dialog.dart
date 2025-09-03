// lib/core/widgets/dynamic_form/dialogs/multiselect_dialog.dart - GENERIC VERSION
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

class MultiselectDialog extends StatefulWidget {
  final String title;
  final List<DropdownOption> options;
  final List<dynamic> selectedValues;
  final AppSizes size;

  const MultiselectDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.size,
  });

  @override
  State<MultiselectDialog> createState() => _MultiselectDialogState();
}

class _MultiselectDialogState extends State<MultiselectDialog> {
  late List<dynamic> _selectedValues;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedValues = List<dynamic>.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _getFilteredOptions();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.size.cardBorderRadius),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title, // ✅ GENERIC: API'den gelen title kullan
            style: TextStyle(
              fontSize: widget.size.mediumText,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: widget.size.smallSpacing),
          _buildSearchField(),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            _buildSelectAllOption(filteredOptions),
            Divider(color: AppColors.border),
            Expanded(
              child: _buildOptionsList(filteredOptions),
            ),
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        // ✅ GENERIC: Dinamik arama
        hintText: '${widget.title} içinde ara...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildSelectAllOption(List<DropdownOption> filteredOptions) {
    final allSelected = filteredOptions.every((option) => _selectedValues.contains(option.value));

    return CheckboxListTile(
      title: Text(
        // ✅ GENERIC: Dinamik "Tümünü Seç"
        'Tümünü Seç',
        style: TextStyle(
          fontSize: widget.size.textSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: allSelected,
      tristate: true,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            for (final option in filteredOptions) {
              if (!_selectedValues.contains(option.value)) {
                _selectedValues.add(option.value);
              }
            }
          } else {
            for (final option in filteredOptions) {
              _selectedValues.remove(option.value);
            }
          }
        });
      },
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildOptionsList(List<DropdownOption> filteredOptions) {
    return ListView.builder(
      itemCount: filteredOptions.length,
      itemBuilder: (context, index) {
        final option = filteredOptions[index];
        final isSelected = _selectedValues.contains(option.value);

        return CheckboxListTile(
          title: Text(
            option.text,
            style: TextStyle(fontSize: widget.size.textSize),
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
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'İptal',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: widget.size.textSize,
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
          // ✅ GENERIC: Dinamik sayım
          'Tamam (${_selectedValues.length})',
          style: TextStyle(fontSize: widget.size.textSize),
        ),
      ),
    ];
  }

  List<DropdownOption> _getFilteredOptions() {
    if (_searchQuery.isEmpty) {
      return widget.options;
    }

    return widget.options.where((option) {
      return option.text.toLowerCase().contains(_searchQuery);
    }).toList();
  }
}
