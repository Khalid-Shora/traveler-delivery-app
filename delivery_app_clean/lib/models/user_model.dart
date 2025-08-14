import 'address_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String phone;
  final List<String> roles; // ['buyer', 'traveler']
  final double earnings; // total traveler earnings (quick access)
  final String? name;
  final List<Address>? addresses;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final bool? verified;

  UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.roles,
    required this.earnings,
    this.name,
    this.addresses,
    this.createdAt,
    this.lastActive,
    this.verified,
  });

  // copyWith
  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    List<String>? roles,
    double? earnings,
    List<Address>? addresses,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? verified,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      earnings: earnings ?? this.earnings,
      name: name ?? this.name,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      verified: verified ?? this.verified,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
    uid: uid,
    email: map['email'],
    phone: map['phone'],
    roles: List<String>.from(map['roles'] ?? []),
    earnings: (map['earnings'] ?? 0).toDouble(),
    name: map['name'],
    addresses: map['addresses'] != null
        ? List<Address>.from(
        (map['addresses'] as List).map((x) => Address.fromMap(x)))
        : null,
    createdAt: map['createdAt']?.toDate(),
    lastActive: map['lastActive']?.toDate(),
    verified: map['verified'] ?? false,
  );


  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'phone': phone,
    'roles': roles,
    'earnings': earnings,
    'name': name,
    'addresses': addresses?.map((e) => e.toMap()).toList(),
    'createdAt': createdAt,
    'lastActive': lastActive,
    'verified': verified,
  };
}

