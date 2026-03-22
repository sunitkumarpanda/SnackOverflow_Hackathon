import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/loading_dialog.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final UserProfileModel? existingProfile;

  const ProfileSetupScreen({super.key, this.existingProfile});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  String? _selectedGender;
  List<String> _selectedConditions = [];

  final List<String> _conditionOptions = [
    'Diabetes',
    'Thyroid',
    'PCOS',
    'Hypertension',
    'None'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _heightController = TextEditingController(text: p?.height != null ? p!.height.toString() : '');
    _weightController = TextEditingController(text: p?.weight != null ? p!.weight.toString() : '');
    _ageController = TextEditingController(text: p?.age != null ? p!.age.toString() : '');
    _selectedGender = p?.gender;
    _selectedConditions = List.from(p?.conditions ?? []);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (condition == 'None') {
        _selectedConditions.clear();
        _selectedConditions.add('None');
      } else {
        _selectedConditions.remove('None');
        if (_selectedConditions.contains(condition)) {
          _selectedConditions.remove(condition);
        } else {
          _selectedConditions.add(condition);
        }
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showSnackbar('Please select your gender');
      return;
    }

    showLoadingDialog(context);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final double height = double.parse(_heightController.text.trim());
      final double weight = double.parse(_weightController.text.trim());
      final int age = int.parse(_ageController.text.trim());

      final updatedProfile = UserProfileModel(
        uid: user.uid,
        name: widget.existingProfile?.name ?? user.displayName ?? 'User',
        email: widget.existingProfile?.email ?? user.email ?? '',
        height: height,
        weight: weight,
        age: age,
        gender: _selectedGender,
        conditions: _selectedConditions,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
      );

      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

      if (!mounted) return;
      hideLoadingDialog(context);

      // If it's first setup
      if (widget.existingProfile == null || !widget.existingProfile!.isProfileComplete) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pop(context); // just pop back to Profile screen if edit
      }
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnackbar('Failed to save profile: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild on language change
    final _ = context.locale;

    final isEditMode = widget.existingProfile != null && widget.existingProfile!.isProfileComplete;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: Text(isEditMode ? 'profile.editProfile'.tr() : 'profile.setupProfile'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditMode) ...[
                Text(
                  'profile.letsBuild'.tr(),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'profile.fewDetails'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
              ],

              // Basic Info Container
              _SectionContainer(
                title: 'profile.basicInfo'.tr(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _heightController,
                            label: 'profile.height'.tr(),
                            hint: '170',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _weightController,
                            label: 'profile.weight'.tr(),
                            hint: '70',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _ageController,
                            label: 'profile.age'.tr(),
                            hint: '25',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'profile.gender'.tr(),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedGender = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Medical Conditions Section
              _SectionContainer(
                title: 'profile.conditionsOptional'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.conditionsDesc'.tr(),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _conditionOptions.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return GestureDetector(
                          onTap: () => _toggleCondition(condition),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check, size: 16, color: Colors.white),
                                  ),
                                Text(
                                  condition,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[800],
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              CustomButton(
                label: isEditMode ? 'profile.updateProfile'.tr() : 'profile.saveContinue'.tr(),
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
