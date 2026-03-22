import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final double? height;
  final double? weight;
  final int? age;
  final String? gender;
  final List<String> conditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.conditions = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isProfileComplete =>
      height != null && weight != null && age != null && gender != null;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'conditions': conditions,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfileModel(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      age: json['age'] as int?,
      gender: json['gender'],
      conditions: List<String>.from(json['conditions'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // AI-Ready Data payload
  Map<String, dynamic> buildProfilePayload({String languageCode = 'en'}) {
    return {
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'conditions': conditions,
      'language': languageCode,
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? email,
    double? height,
    double? weight,
    int? age,
    String? gender,
    List<String>? conditions,
  }) {
    return UserProfileModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
