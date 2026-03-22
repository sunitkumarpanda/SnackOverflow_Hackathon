import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/user_profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveProfile(UserProfileModel profile) async {
    await _db
        .collection('users')
        .doc(profile.uid)
        .collection('profile')
        .doc('data')
        .set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfileModel?> getProfile(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('data')
        .get();

    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromJson(doc.data()!, uid);
    }
    return null;
  }
}
