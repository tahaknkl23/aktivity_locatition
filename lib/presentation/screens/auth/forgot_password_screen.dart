import 'package:aktivity_location_app/core/constants/app_colors.dart';
import 'package:aktivity_location_app/core/constants/app_sizes.dart';
import 'package:aktivity_location_app/core/constants/app_strings.dart';
import 'package:aktivity_location_app/core/extensions/context_extensions.dart';
import 'package:aktivity_location_app/core/helpers/validators.dart';
import 'package:aktivity_location_app/presentation/screens/auth/widgets/login_background.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Başarılı"),
        content: const Text("Şifre sıfırlama bağlantısı e-postanıza gönderildi."),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Alert kapat
              context.pop(); // Login ekranına dön
            },
            child: const Text("Tamam"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    return Scaffold(
      body: LoginBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.padding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.forgotMyPassword,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: size.largeText * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: AppStrings.emailHint,
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.email),
                    ),
                    validator: Validators.validateEMAIL,
                  ),
                  SizedBox(
                    height: size.height * 0.04,
                  ),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueButtonColor,
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.ok,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: size.mediumText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blueButtonColor.withAlpha((0.4 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: size.largeText,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}