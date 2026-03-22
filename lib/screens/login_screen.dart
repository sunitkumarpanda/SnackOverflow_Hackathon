import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/presentation/providers/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    showLoadingDialog(context);
    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Ensure user document exists
        await _firestoreService.createUserIfNotExists(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
        );

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

  Future<void> _handleGoogleSignIn() async {
    showLoadingDialog(context);
    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        await _firestoreService.createUserIfNotExists(
          uid: user.uid,
          name: user.displayName ?? 'Google User',
          email: user.email ?? '',
        );

        final profile = await ref.read(profileRepositoryProvider).getProfile(user.uid);

        if (!mounted) return;
        hideLoadingDialog(context);
        
        if (profile != null && profile.isProfileComplete) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/profileSetup', (route) => false);
        }
      } else {
        if (!mounted) return;
        hideLoadingDialog(context);
      }
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      final msg = e.toString().replaceAll('Exception: ', '');
      if (!msg.contains('cancelled')) {
        _showSnackbar(msg);
      }
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
                  onTap: () => Navigator.pushReplacementNamed(context, '/getStarted'),
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
                  'auth.welcomeBack'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'auth.signInContinue'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 36),

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
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'auth.password'.tr(),
                  hint: 'auth.passwordHint'.tr(),
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.passwordRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Login Button
                CustomButton(
                  label: 'auth.login'.tr(),
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'auth.or'.tr(),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign-In
                CustomButton(
                  label: 'auth.googleSignIn'.tr(),
                  onPressed: _handleGoogleSignIn,
                  isOutlined: true,
                  icon: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: const Icon(Icons.g_mobiledata_rounded,
                        color: Color(0xFF4285F4), size: 22),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.dontHaveAccount'.tr().split('?').first + '? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                        child: Text(
                          'auth.signup'.tr(),
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
