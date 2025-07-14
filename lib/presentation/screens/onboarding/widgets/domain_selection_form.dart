import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class DomainSelectionForm extends StatefulWidget {
  final AppSizes size;
  final Map<String, String> domainMap;
  final String? selectedDomain;
  final Function(String) onDomainChanged;

  const DomainSelectionForm({
    super.key,
    required this.size,
    required this.domainMap,
    required this.selectedDomain,
    required this.onDomainChanged,
  });

  @override
  State<DomainSelectionForm> createState() => _DomainSelectionFormState();
}

class _DomainSelectionFormState extends State<DomainSelectionForm> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _recentDomains = [];
  final List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  int _selectedIndex = -1;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadRecentDomains();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Set initial value if provided
    if (widget.selectedDomain != null && widget.selectedDomain!.isNotEmpty) {
      _controller.text = widget.selectedDomain!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentDomains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 🎯 Gerçek giriş geçmişinden oku
      final domains = prefs.getStringList('login_history') ?? [];
      debugPrint('[Domain Load] Loaded login history: $domains');

      if (mounted) {
        setState(() {
          _recentDomains = domains;
        });
      }
    } catch (e) {
      debugPrint('[Domain Load] Error loading domains: $e');
    }
  }

  Future<void> _saveRecentDomain(String domain) async {
    if (domain.trim().isEmpty) {
      debugPrint('[Domain Save] Empty domain, not saving');
      return;
    }

    debugPrint('[Domain Save] Attempting to save: $domain');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove if exists, then add to beginning
      _recentDomains.remove(domain);
      _recentDomains.insert(0, domain);

      // Keep only last 8 (mobile optimized)
      if (_recentDomains.length > 8) {
        _recentDomains = _recentDomains.take(8).toList();
      }

      await prefs.setStringList('recent_domains', _recentDomains);
      debugPrint('[Domain Save] Successfully saved. Recent domains: $_recentDomains');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[Domain Save] Error saving domain: $e');
    }
  }

  Future<void> _removeRecentDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    _recentDomains.remove(domain);
    await prefs.setStringList('login_history', _recentDomains);

    if (mounted) {
      setState(() {});
      _updateSuggestions();
    }
  }

  void _onTextChanged() {
    _updateSuggestions();
    widget.onDomainChanged(_controller.text);

    // Auto-save on valid domain (contains .veribiscrm.com)
    final text = _controller.text.trim();
    if (text.contains('.veribiscrm.com') && text.length > 15) {
      debugPrint('[Auto Save] Valid domain detected: $text');
      _saveRecentDomain(text);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
      _pulseController.forward();
    } else {
      // Save domain when losing focus
      final text = _controller.text.trim();
      if (text.isNotEmpty && text.contains('.')) {
        debugPrint('[Focus Lost] Auto-saving domain: $text');
        _saveRecentDomain(text);
      }

      _pulseController.reverse();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _updateSuggestions() {
    final query = _controller.text.toLowerCase();

    setState(() {
      _filteredSuggestions.clear();
      _selectedIndex = -1;

      if (query.isEmpty) {
        // Show recent domains when empty
        _filteredSuggestions.addAll(_recentDomains);
        _showSuggestions = _recentDomains.isNotEmpty;
      } else {
        // Filter recent domains only
        final recentMatches = _recentDomains.where((domain) => domain.toLowerCase().contains(query)).toList();

        _filteredSuggestions.addAll(recentMatches);
        _showSuggestions = _filteredSuggestions.isNotEmpty;
      }
    });
  }

  void _selectSuggestion(String domain) {
    debugPrint('[Domain Select] Selected: $domain');
    _controller.text = domain;
    _saveRecentDomain(domain);
    widget.onDomainChanged(domain);
    _focusNode.unfocus();
  }

  void _handleKeyPress(KeyEvent event) {
    if (!_showSuggestions || _filteredSuggestions.isEmpty) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = _selectedIndex <= 0 ? _filteredSuggestions.length - 1 : _selectedIndex - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedIndex >= 0 && _selectedIndex < _filteredSuggestions.length) {
          _selectSuggestion(_filteredSuggestions[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive calculations
        final isSmallScreen = constraints.maxWidth < 400;
        final horizontalPadding = isSmallScreen ? widget.size.padding : widget.size.padding * 1.5;
        final verticalPadding = isSmallScreen ? widget.size.padding * 1.2 : widget.size.padding * 1.5;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            border: Border.all(
              color: const Color(0xFF4B5563).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withValues(alpha: 0.8),
                          AppColors.primaryColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      "Domain Girişi",
                      style: TextStyle(
                        fontSize: isSmallScreen ? widget.size.mediumText * 0.9 : widget.size.mediumText,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_recentDomains.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_recentDomains.length}",
                        style: TextStyle(
                          fontSize: widget.size.smallText * 0.85,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: isSmallScreen ? widget.size.padding * 0.8 : widget.size.padding),

              Text(
                "Şirket domain'inizi yazın. Yazarken öneriler görünecek.",
                style: TextStyle(
                  fontSize: isSmallScreen ? widget.size.smallText * 0.9 : widget.size.smallText,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),

              SizedBox(height: isSmallScreen ? widget.size.padding * 1.5 : widget.size.padding * 2),

              // Google Style Search Input
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: _handleKeyPress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                          border: Border.all(
                            color: _focusNode.hasFocus ? AppColors.primaryColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
                            width: _focusNode.hasFocus ? 2 : 1,
                          ),
                          boxShadow: _focusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? widget.size.mediumText * 0.9 : widget.size.mediumText,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: isSmallScreen ? "domain.com" : "örn: mycompany.veribiscrm.com",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: isSmallScreen ? widget.size.mediumText * 0.85 : widget.size.mediumText * 0.9,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                              child: Icon(
                                Icons.search,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Save button
                                      IconButton(
                                        onPressed: () {
                                          final domain = _controller.text.trim();
                                          if (domain.isNotEmpty) {
                                            _saveRecentDomain(domain);
                                            _focusNode.unfocus();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: AppColors.primaryColor.withValues(alpha: 0.8),
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        tooltip: 'Kaydet',
                                      ),
                                      // Clear button
                                      IconButton(
                                        onPressed: () {
                                          _controller.clear();
                                          widget.onDomainChanged('');
                                        },
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white.withValues(alpha: 0.7),
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        tooltip: 'Temizle',
                                      ),
                                    ],
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? widget.size.padding : widget.size.padding * 1.5,
                              vertical: isSmallScreen ? widget.size.padding : widget.size.padding * 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Inline Suggestions with Animation
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showSuggestions && _focusNode.hasFocus ? _buildInlineSuggestions(isSmallScreen) : const SizedBox.shrink(),
              ),

              // Quick stats for non-focused state
              if (_recentDomains.isNotEmpty && !_focusNode.hasFocus) ...[
                SizedBox(height: isSmallScreen ? widget.size.padding : widget.size.padding * 1.5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? widget.size.padding * 0.8 : widget.size.padding,
                    vertical: isSmallScreen ? widget.size.padding * 0.5 : widget.size.padding * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.login,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          "Son giriş: ${_recentDomains.first}",
                          style: TextStyle(
                            fontSize: isSmallScreen ? widget.size.smallText * 0.85 : widget.size.smallText,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineSuggestions(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(top: isSmallScreen ? widget.size.padding * 0.8 : widget.size.padding),
      constraints: BoxConstraints(
        maxHeight: isSmallScreen ? 200 : 250,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF374151).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
        border: Border.all(
          color: const Color(0xFF4B5563).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header if showing recent
          if (_controller.text.isEmpty && _recentDomains.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? widget.size.padding * 0.8 : widget.size.padding),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Text(
                    "Son Kullanılanlar",
                    style: TextStyle(
                      fontSize: isSmallScreen ? widget.size.smallText * 0.85 : widget.size.smallText,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ],

          // Suggestions list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: isSmallScreen ? widget.size.padding * 0.5 : widget.size.padding * 0.8),
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final domain = _filteredSuggestions[index];
                final isSelected = index == _selectedIndex;

                return InkWell(
                  onTap: () => _selectSuggestion(domain),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? widget.size.padding * 0.8 : widget.size.padding,
                      vertical: isSmallScreen ? widget.size.padding * 0.6 : widget.size.padding * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? widget.size.padding * 0.4 : widget.size.padding * 0.5,
                      vertical: 1,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.login,
                          size: isSmallScreen ? 16 : 18,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                domain,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? widget.size.smallText : widget.size.smallText * 1.1,
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Giriş yapıldı",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? widget.size.smallText * 0.8 : widget.size.smallText * 0.85,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeRecentDomain(domain),
                          icon: Icon(
                            Icons.close,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 28 : 32,
                            minHeight: isSmallScreen ? 28 : 32,
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
    );
  }
}