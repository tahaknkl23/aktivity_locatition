// lib/core/widgets/common/app_version_info_widget.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class AppVersionInfoWidget extends StatefulWidget {
  final bool showBackground;
  final bool showBuildDate;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool isFloating; // Sağ üst köşe için

  const AppVersionInfoWidget({
    super.key,
    this.showBackground = true,
    this.showBuildDate = true,
    this.textStyle,
    this.padding,
    this.isFloating = false,
  });

  @override
  State<AppVersionInfoWidget> createState() => _AppVersionInfoWidgetState();
}

class _AppVersionInfoWidgetState extends State<AppVersionInfoWidget> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = packageInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getBuildDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  String _getVersionText() {
    if (_packageInfo == null) return 'v1.0.0';

    final version = _packageInfo!.version;
    final buildNumber = _packageInfo!.buildNumber;

    if (buildNumber.isNotEmpty) {
      return 'v$version ($buildNumber)';
    }
    return 'v$version';
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    if (_isLoading) {
      return SizedBox(
        width: widget.isFloating ? 120 : null,
        height: widget.isFloating ? 60 : null,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    final defaultTextStyle = TextStyle(
      fontSize: widget.isFloating ? size.smallText * 0.8 : size.smallText,
      color: AppColors.white.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    );

    Widget content = Column(
      crossAxisAlignment: widget.isFloating ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Version
        Text(
          _getVersionText(),
          style: widget.textStyle ?? defaultTextStyle,
          textAlign: widget.isFloating ? TextAlign.right : TextAlign.center,
        ),

        // Build Date
        if (widget.showBuildDate) ...[
          SizedBox(height: widget.isFloating ? 2 : 4),
          Text(
            _getBuildDate(),
            style: (widget.textStyle ?? defaultTextStyle).copyWith(
              fontSize: (widget.isFloating ? size.smallText * 0.7 : size.smallText * 0.9),
              color: AppColors.white.withValues(alpha: 0.5),
            ),
            textAlign: widget.isFloating ? TextAlign.right : TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.isFloating) {
      return Positioned(
        top: 16,
        right: 16,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(size.cardBorderRadius),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.2),
            ),
          ),
          child: content,
        ),
      );
    }

    if (widget.showBackground) {
      return Container(
        padding: widget.padding ??
            EdgeInsets.symmetric(
              horizontal: size.mediumSpacing,
              vertical: size.smallSpacing,
            ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.2),
          ),
        ),
        child: content,
      );
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: content,
    );
  }
}
