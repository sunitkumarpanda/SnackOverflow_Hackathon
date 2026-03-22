import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile_model.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileModel?>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel?>> {
  final ProfileRepository _repository;
  UserProfileModel? _cachedProfile;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchProfile(user.uid);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> fetchProfile(String uid) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(uid);
      _cachedProfile = profile;
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveProfile(profile);
      _cachedProfile = profile;
      state = AsyncValue.data(profile);
    } catch (e, st) {
      // Revert to cache if fails
      state = AsyncValue.data(_cachedProfile);
      rethrow;
    }
  }

  void clearProfile() {
    _cachedProfile = null;
    state = const AsyncValue.data(null);
  }
}
