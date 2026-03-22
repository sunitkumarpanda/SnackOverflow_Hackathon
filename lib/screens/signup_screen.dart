import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/presentation/providers/profile_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    showLoadingDialog(context);
    try {
      final user = await _authService.signup(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Store in Firestore
        await _firestoreService.createUserIfNotExists(
          uid: user.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

        // Update display name
        await user.updateDisplayName(_nameController.text.trim());

        final profile = await ref.read(profileRepositoryProvider).getProfile(user.uid);

        if (!mounted) return;
        hideLoadingDialog(context);
        
        if (profile != null && profile.isProfileComplete) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/profileSetup', (route) => false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnackbar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild on language change
    final _ = context.locale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back button
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                ),
                const SizedBox(height: 32),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_dining_rounded,
                          color: Color(0xFF4CAF50), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'DietRAO',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  'auth.createAccount'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'auth.startJourney'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 32),

                // Name
                CustomTextField(
                  controller: _nameController,
                  label: 'auth.name'.tr(),
                  hint: 'auth.nameHint'.tr(),
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'auth.nameRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'auth.email'.tr(),
                  hint: 'auth.emailHint'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'auth.emailRequired'.tr();
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'auth.enterValidEmail'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'auth.password'.tr(),
                  hint: 'auth.passwordMinLength'.tr(),
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (value.length < 6) {
                      return 'auth.passwordLength'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'auth.confirmPassword'.tr(),
                  hint: 'auth.confirmPassword'.tr(),
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    if (value != _passwordController.text) {
                      return 'auth.passwordsDoNotMatch'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Signup Button
                CustomButton(
                  label: 'auth.signup'.tr(),
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 24),

                // Login link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.alreadyHaveAccount'.tr().split('?').first + '? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'auth.login'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
