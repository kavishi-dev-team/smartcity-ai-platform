enum UserRole {
  superAdmin('SUPER_ADMIN', 'Super Admin'),
  cityManager('CITY_MANAGER', 'City Manager'),
  departmentOfficer('DEPARTMENT_OFFICER', 'Department Officer'),
  citizen('CITIZEN', 'Citizen');

  const UserRole(this.apiValue, this.displayName);

  final String apiValue;
  final String displayName;

  /// Unknown values fall back to the least-privileged role.
  static UserRole fromApi(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => UserRole.citizen,
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    this.phoneNumber,
    this.address,
    this.profilePhotoUrl,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final String? phoneNumber;
  final String? address;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  bool get isCitizen => role == UserRole.citizen;

  /// Super admin, city manager and department officer all use the officer side.
  bool get isStaff => !isCitizen;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: UserRole.fromApi(json['role'] as String?),
      isActive: (json['is_active'] as bool?) ?? true,
      isEmailVerified: (json['is_email_verified'] as bool?) ?? false,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }
}