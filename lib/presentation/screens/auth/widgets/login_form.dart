import 'package:aktivity_location_app/core/constants/app_colors.dart';
import 'package:aktivity_location_app/core/constants/app_sizes.dart';
import 'package:aktivity_location_app/core/constants/app_strings.dart';
import 'package:aktivity_location_app/core/helpers/validators.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    widget.emailController.addListener(_validateEmail);
    widget.passwordController.addListener(_validatePassword);
  }

  void _validateEmail() {
    setState(() {
      _emailError = Validators.validateUsername(widget.emailController.text);
    });
  }

  void _validatePassword() {
    setState(() {
      _passwordError = Validators.validatePassword(widget.passwordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    return Column(
      children: [
        // E-posta alanı
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          controller: widget.emailController,
          decoration: InputDecoration(
            hintStyle: TextStyle(fontSize: size.mediumText),
            hintText: AppStrings.userNameandEmail,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Icon(
              Icons.email,
              color: widget.emailController.text.isEmpty
                  ? AppColors.iconInactive // Boşsa normal renk
                  : (_emailError != null ? AppColors.redColor : AppColors.iconInactive), // Hatalıysa kırmızı, geçerliyse normal renk
            ),
            errorText: _emailError,
            errorStyle: TextStyle(color: Colors.red, fontSize: size.smallText),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: Validators.validateUsername,
        ),
        SizedBox(height: size.height * 0.05),

        // Şifre alanı
        TextFormField(
          obscureText: _obscurePassword,
          controller: widget.passwordController,
          decoration: InputDecoration(
            hintStyle: TextStyle(fontSize: size.mediumText),
            hintText: AppStrings.passwordHint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: widget.passwordController.text.isEmpty
                    ? AppColors.iconInactive
                    : widget.passwordController.text.length < 4
                        ? AppColors.redColor // Hatalıysa kırmızı
                        : AppColors.iconInactive, // Geçerli ise normal renk
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            errorText: _passwordError,
            errorStyle: TextStyle(color: Colors.red, fontSize: size.smallText),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }
}
