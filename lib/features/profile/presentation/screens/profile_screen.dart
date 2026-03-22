import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';
import '../providers/profile_provider.dart';
import 'profile_setup_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  TimeOfDay _testTime = TimeOfDay.now();

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('profile.logout'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text('profile.logoutConfirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('profile.cancel'.tr(),
                  style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text('profile.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      ref.read(profileProvider.notifier).clearProfile();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _testTime,
    );
    if (picked != null && picked != _testTime) {
      setState(() {
        _testTime = picked;
      });
    }
  }

  void _scheduleTestNotification() {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _testTime.hour,
      _testTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    NotificationService().scheduleNotification(
      id: 999,
      title: "Test Notification 🔔",
      body: "This is your scheduled test notification from DietRAO!",
      scheduledDate: scheduledDate,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Notification scheduled for ${_testTime.format(context)}"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: Text('profile.title'.tr(),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                fontSize: 18)),
        centerTitle: true,
        actions: [
          if (profileState is AsyncData && profileState.value != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4CAF50)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProfileSetupScreen(existingProfile: profileState.value)),
                );
              },
            ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
        error: (err, st) => Center(child: Text("${'common.error'.tr()}: $err")),
        data: (profile) {
          final displayName = profile?.name ?? user?.displayName ?? 'User';
          final email = profile?.email ?? user?.email ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFF4CAF50),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                (displayName.isNotEmpty ? displayName[0] : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text(email,
                          style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGoogleUser
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                isGoogleUser
                                    ? Icons.g_mobiledata_rounded
                                    : Icons.email_rounded,
                                size: 16,
                                color: isGoogleUser
                                    ? const Color(0xFF4285F4)
                                    : const Color(0xFF4CAF50)),
                            const SizedBox(width: 6),
                            Text(
                                isGoogleUser
                                    ? 'profile.googleAccount'.tr()
                                    : 'profile.emailAccount'.tr(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isGoogleUser
                                        ? const Color(0xFF4285F4)
                                        : const Color(0xFF4CAF50))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info Cards
                if (profile != null) ...[
                  Row(
                    children: [
                      Expanded(
                          child: _InfoRow(
                              icon: Icons.height,
                              label: 'profile.height'.tr().split(' ').first,
                              value: "${profile.height ?? '-'} cm")),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _InfoRow(
                              icon: Icons.monitor_weight_outlined,
                              label: 'profile.weight'.tr().split(' ').first,
                              value: "${profile.weight ?? '-'} kg")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'profile.age'.tr(),
                              value: "${profile.age ?? '-'} yrs")),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _InfoRow(
                              icon: Icons.transgender,
                              label: 'profile.gender'.tr(),
                              value: profile.gender ?? '-')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notification Test Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.notifications_active_rounded,
                                  color: Colors.orange, size: 16),
                            ),
                            const SizedBox(width: 10),
                            const Text('Notification Test',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Schedule a test alert for ${_testTime.format(context)}",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: _pickTime,
                              child: const Text("Change Time"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _scheduleTestNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Schedule Now"),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              NotificationService().showNotification(
                                id: 888,
                                title: "Instant Notification 🚀",
                                body: "This is a quick test for the notification system!",
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              foregroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Test Instant Notification"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Language Switcher
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.language_rounded,
                              color: Color(0xFF1976D2), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('profile.changeLanguage'.tr(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<Locale>(
                            value: context.locale,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey),
                            items: const [
                              DropdownMenuItem(
                                  value: Locale('en'),
                                  child: Text('English',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600))),
                              DropdownMenuItem(
                                  value: Locale('hi'),
                                  child: Text('हिंदी',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600))),
                              DropdownMenuItem(
                                  value: Locale('or'),
                                  child: Text('ଓଡ଼ିଆ',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600))),
                            ],
                            onChanged: (Locale? newLocale) {
                              if (newLocale != null) {
                                context.setLocale(newLocale);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('profile.logout'.tr(),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }
}
