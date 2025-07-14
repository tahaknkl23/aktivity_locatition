import 'package:aktivity_location_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

class LoginBackground extends StatelessWidget {
  final Widget child;
  const LoginBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.background),
          fit: BoxFit.cover, // 🔄 tüm yönlerde ekranı doldur
          alignment: Alignment.center,
        ),
      ),
      child: child,
    );
  }
}
