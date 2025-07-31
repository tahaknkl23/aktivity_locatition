import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';

/// Arama özellikli dropdown widget
class SearchableDropdownWidget extends StatefulWidget {
  final String label;
  final String? hint;
  final List<DropdownOption> options;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final bool isEnabled;
  final String? Function(dynamic)? validator;

  const SearchableDropdownWidget({
    super.key,
    required this.label,
    this.hint,
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
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<DropdownOption> _filteredOptions = [];
  bool _isOpen = false;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
    _updateDisplayText();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options || oldWidget.value != widget.value) {
      _filteredOptions = List.from(widget.options);
      _updateDisplayText();
    }
  }

  void _updateDisplayText() {
    if (widget.value != null) {
      final selectedOption = widget.options.firstWhere(
        (option) => option.value == widget.value,
        orElse: () => DropdownOption(value: widget.value, text: widget.value.toString()),
      );
      _displayText = selectedOption.text;
    } else {
      _displayText = '';
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOpen) {
      _openDropdown();
    } else if (!_focusNode.hasFocus && _isOpen) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && _isOpen) {
          _closeDropdown();
        }
      });
    }
  }

  void _openDropdown() {
    if (!widget.isEnabled || _isOpen) return;

    setState(() {
      _isOpen = true;
    });

    _searchController.clear();
    _filteredOptions = List.from(widget.options);

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isOpen) return;

    setState(() {
      _isOpen = false;
    });

    _removeOverlay();
    _searchController.clear();
    _focusNode.unfocus();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        _filteredOptions = widget.options.where((option) => option.text.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _selectOption(DropdownOption option) {
    widget.onChanged(option.value);
    _updateDisplayText();
    _closeDropdown();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size2 = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    final spaceBelow = screenHeight - position.dy - size2.height;
    final spaceAbove = position.dy;
    final openUpwards = spaceBelow < 300 && spaceAbove > spaceBelow;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier
          GestureDetector(
            onTap: _closeDropdown,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.transparent,
            ),
          ),

          // Dropdown menu
          Positioned(
            left: position.dx,
            top: openUpwards ? position.dy - 300 : position.dy + size2.height + 4,
            width: size2.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 300,
                  minHeight: 0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: false,
                              decoration: InputDecoration(
                                hintText: 'Ara...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              onChanged: _filterOptions,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _filterOptions('');
                              },
                              child: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Options list
                    Flexible(
                      child: _filteredOptions.isEmpty
                          ? Container(
                              padding: EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                'Sonuç bulunamadı',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filteredOptions.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: AppColors.border.withValues(alpha: 0.1),
                              ),
                              itemBuilder: (context, index) {
                                final option = _filteredOptions[index];
                                final isSelected = option.value == widget.value;

                                return InkWell(
                                  onTap: () => _selectOption(option),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        if (isSelected) ...[
                                          Icon(
                                            Icons.check,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                        ] else ...[
                                          SizedBox(width: 30),
                                        ],
                                        Expanded(
                                          child: Text(
                                            option.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event.logicalKey.keyLabel == 'Escape' && _isOpen) {
            _closeDropdown();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.isEnabled ? _openDropdown : null,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isEnabled ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
              border: Border.all(
                color: _isOpen ? AppColors.primary : AppColors.border,
                width: _isOpen ? 2 : 1,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: size.cardPadding,
              vertical: size.cardPadding * 0.8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText.isEmpty ? (widget.hint ?? 'Seçiniz...') : _displayText,
                    style: TextStyle(
                      fontSize: size.textSize,
                      color: _displayText.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: size.smallSpacing),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: widget.isEnabled ? (_isOpen ? AppColors.primary : AppColors.textSecondary) : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
