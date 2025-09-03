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

      _recentDomains.remove(domain);
      _recentDomains.insert(0, domain);

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

    // ENHANCED AUTO-SAVE - More flexible validation
    final text = _controller.text.trim();
    if (_isValidDomain(text)) {
      debugPrint('[Auto Save] Valid domain detected: $text');
      _saveRecentDomain(text);
    }
  }

  // ENHANCED DOMAIN VALIDATION
  bool _isValidDomain(String domain) {
    if (domain.isEmpty || domain.length < 3) return false;

    // 1. Full URL (http/https)
    if (domain.startsWith('http://') || domain.startsWith('https://')) {
      return domain.length > 10;
    }

    // 2. Domain with port (localhost:8080, 192.168.1.100:3000)
    if (domain.contains(':')) {
      final parts = domain.split(':');
      if (parts.length == 2) {
        final port = int.tryParse(parts[1]);
        return port != null && port > 0 && port < 65536;
      }
    }

    // 3. IP Address (192.168.1.100)
    if (_isValidIpAddress(domain)) {
      return true;
    }

    // 4. Domain with dots (destekcrm.com, demo.veribiscrm.com)
    if (domain.contains('.')) {
      final parts = domain.split('.');
      return parts.length >= 2 && parts.every((part) => part.isNotEmpty);
    }

    // 5. Plain subdomain (demo, destek) - at least 3 characters
    return domain.length >= 3 && !domain.contains(' ');
  }

  bool _isValidIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
      _pulseController.forward();
    } else {
      final text = _controller.text.trim();
      if (_isValidDomain(text)) {
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
        _filteredSuggestions.addAll(_recentDomains);
        _showSuggestions = _recentDomains.isNotEmpty;
      } else {
        // Filter recent domains
        final recentMatches = _recentDomains.where((domain) => domain.toLowerCase().contains(query)).toList();

        // Add common suggestions if not in recent
        final commonSuggestions = _getCommonSuggestions(query);

        _filteredSuggestions.addAll(recentMatches);
        for (final suggestion in commonSuggestions) {
          if (!_filteredSuggestions.contains(suggestion)) {
            _filteredSuggestions.add(suggestion);
          }
        }

        _showSuggestions = _filteredSuggestions.isNotEmpty;
      }
    });
  }

  // ENHANCED COMMON SUGGESTIONS
  List<String> _getCommonSuggestions(String query) {
    final suggestions = <String>[];

    if (query.isEmpty) return suggestions;

    // 1. Veribis domain suggestions
    if (!query.contains('.')) {
      suggestions.add('$query.veribiscrm.com');
    }

    // 2. Common TLD suggestions
    if (!query.contains('.') && query.length >= 3) {
      suggestions.addAll([
        '$query.com',
        '$query.com.tr',
        '$query.net',
      ]);
    }

    // 3. Development suggestions
    if (query.contains('local') || query.contains('dev') || query.contains('test')) {
      if (!query.contains(':')) {
        suggestions.addAll([
          '$query:8080',
          '$query:3000',
          '$query:5000',
        ]);
      }
    }

    // 4. HTTPS variations for custom domains
    if (query.contains('.') && !query.startsWith('http')) {
      suggestions.add('https://$query');
    }

    return suggestions.take(3).toList(); // Limit suggestions
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
              // Header with enhanced info
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
                      Icons.language,
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

              SizedBox(height: isSmallScreen ? widget.size.padding * 1.5 : widget.size.padding * 2),

              // Enhanced input with validation feedback
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isValid = _isValidDomain(_controller.text);
                  final borderColor = _focusNode.hasFocus
                      ? (isValid ? Colors.green.withValues(alpha: 0.6) : AppColors.primaryColor.withValues(alpha: 0.6))
                      : Colors.white.withValues(alpha: 0.2);

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
                            color: borderColor,
                            width: _focusNode.hasFocus ? 2 : 1,
                          ),
                          boxShadow: _focusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: (isValid ? Colors.green : AppColors.primaryColor).withValues(alpha: 0.2),
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
                            filled: true,
                            fillColor: const Color(0xFF1F2937).withValues(alpha: 0.3),
                            hintText: isSmallScreen ? "domain veya IP" : "destekcrm.com, localhost:8080",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: isSmallScreen ? widget.size.mediumText * 0.85 : widget.size.mediumText * 0.9,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                              child: Icon(
                                isValid && _controller.text.isNotEmpty ? Icons.check_circle : Icons.language,
                                color: isValid && _controller.text.isNotEmpty
                                    ? Colors.green.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.7),
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            suffixIcon: _controller.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isValid)
                                        IconButton(
                                          onPressed: () {
                                            final domain = _controller.text.trim();
                                            if (domain.isNotEmpty) {
                                              _saveRecentDomain(domain);
                                              _focusNode.unfocus();
                                            }
                                          },
                                          icon: Icon(
                                            Icons.bookmark_add,
                                            color: Colors.green.withValues(alpha: 0.8),
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                          tooltip: 'Kaydet',
                                        ),
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

              // Enhanced suggestions
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showSuggestions && _focusNode.hasFocus ? _buildEnhancedSuggestions(isSmallScreen) : const SizedBox.shrink(),
              ),

              // Enhanced stats for non-focused state
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
                        Icons.history,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          "Son: ${_recentDomains.first}",
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

  Widget _buildEnhancedSuggestions(bool isSmallScreen) {
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
                    "Önerileri Seç",
                    style: TextStyle(
                      fontSize: isSmallScreen ? widget.size.smallText * 0.85 : widget.size.smallText,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ],
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: isSmallScreen ? widget.size.padding * 0.5 : widget.size.padding * 0.8),
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final domain = _filteredSuggestions[index];
                final isSelected = index == _selectedIndex;
                final isRecent = _recentDomains.contains(domain);

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
                          isRecent ? Icons.history : Icons.auto_awesome,
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
                                isRecent ? "Daha önce kullanıldı" : "Öneri",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? widget.size.smallText * 0.8 : widget.size.smallText * 0.85,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isRecent)
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
