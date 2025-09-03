// lib/core/widgets/common/searchable_dropdown_widget.dart - YENİ DOSYA
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';

class SearchableDropdownWidget extends StatefulWidget {
  final String? label;
  final String hint;
  final List<DropdownOption> options;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final bool isEnabled;
  final String? Function(dynamic)? validator;

  const SearchableDropdownWidget({
    super.key,
    this.label,
    this.hint = 'Seçiniz...',
    required this.options,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isEnabled = true,
    this.validator,
  });

  @override
  State<SearchableDropdownWidget> createState() => _SearchableDropdownWidgetState();
}

class _SearchableDropdownWidgetState extends State<SearchableDropdownWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isOpen = false;
  List<DropdownOption> _filteredOptions = [];
  DropdownOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    _initializeValue();
    _filteredOptions = List.from(widget.options);
  }

  @override
  void didUpdateWidget(SearchableDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      _filteredOptions = List.from(widget.options);
      _filterOptions(_searchController.text);
    }

    if (oldWidget.value != widget.value) {
      _initializeValue();
    }
  }

  void _initializeValue() {
    _selectedOption = null;

    if (widget.value != null) {
      // Value'dan option bulma
      _selectedOption = widget.options.where((option) {
        return option.value == widget.value || option.text == widget.value || option.value.toString() == widget.value.toString();
      }).firstOrNull;
    }

    _updateSearchText();
  }

  void _updateSearchText() {
    if (_selectedOption != null) {
      _searchController.text = _selectedOption!.text;
    } else {
      _searchController.text = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterOptions(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        _filteredOptions = widget.options.where((option) {
          return option.text.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleDropdown() {
    if (!widget.isEnabled) return;

    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _focusNode.requestFocus();
      _filterOptions(_searchController.text);
    } else {
      _focusNode.unfocus();
    }
  }

  void _selectOption(DropdownOption? option) {
    setState(() {
      _selectedOption = option;
      _isOpen = false;
      _updateSearchText();
    });

    _focusNode.unfocus();
    widget.onChanged(option?.value);
  }

  void _clearSelection() {
    _selectOption(null);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (sadece widget.label varsa)
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(bottom: size.smallSpacing),
            child: RichText(
              text: TextSpan(
                text: widget.label!,
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.w600,
                  color: widget.isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                children: [
                  if (widget.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontSize: size.textSize,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        // Dropdown Field
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
              border: Border.all(
                color: _isOpen ? AppColors.primary : AppColors.border,
                width: _isOpen ? 2 : 1,
              ),
              color: widget.isEnabled ? AppColors.surface : AppColors.surfaceVariant,
            ),
            child: Column(
              children: [
                // Search/Display Field
                TextFormField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled && _isOpen,
                  readOnly: !_isOpen,
                  onChanged: _filterOptions,
                  onTap: _toggleDropdown,
                  style: TextStyle(fontSize: size.textSize),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: size.textSize,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clear button
                        if (_selectedOption != null && widget.isEnabled)
                          IconButton(
                            onPressed: _clearSelection,
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        // Dropdown arrow
                        Icon(
                          _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: widget.isEnabled ? AppColors.primary : AppColors.textTertiary,
                        ),
                        SizedBox(width: size.smallSpacing),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.cardPadding,
                      vertical: size.cardPadding * 0.8,
                    ),
                  ),
                ),

                // Dropdown List
                if (_isOpen) ...[
                  Divider(height: 1, color: AppColors.border),
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: _buildDropdownList(size),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownList(AppSizes size) {
    if (widget.options.isEmpty) {
      return Container(
        padding: EdgeInsets.all(size.cardPadding),
        child: Text(
          'Seçenek bulunamadı',
          style: TextStyle(
            fontSize: size.textSize,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_filteredOptions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(size.cardPadding),
        child: Text(
          'Arama sonucu bulunamadı',
          style: TextStyle(
            fontSize: size.textSize,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filteredOptions.length,
      itemBuilder: (context, index) {
        final option = _filteredOptions[index];
        final isSelected = _selectedOption?.value == option.value;

        return InkWell(
          onTap: () => _selectOption(option),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.cardPadding,
              vertical: size.cardPadding * 0.7,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Text(
              option.text,
              style: TextStyle(
                fontSize: size.textSize,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
