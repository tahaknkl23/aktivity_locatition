// lib/presentation/widgets/home/welcome_card_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class WelcomeCardWidget extends StatelessWidget {
  final String userName;
  final String userDomain;

  const WelcomeCardWidget({
    super.key,
    required this.userName,
    required this.userDomain,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.cardPadding * 1.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(
                Icons.account_circle,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: size.mediumSpacing * 1.2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: size.smallText * 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.mediumText * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userDomain.isNotEmpty) ...[
                  SizedBox(height: size.tinySpacing),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      userDomain,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.smallText * 0.9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
