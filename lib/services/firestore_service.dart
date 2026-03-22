import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Create user document if not exists ───────────────────────────────────
  Future<void> createUserIfNotExists({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      final docRef = _db.collection('users').doc(uid).collection('profile').doc('data');
      final snapshot = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Network is slow, please try again.'),
      );

      if (!snapshot.exists) {
        await docRef.set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Don't crash the app if Firestore fails — just log
      // In production, consider sending to Crashlytics
    }
  }

  // ─── Get user profile data ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('data')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
