class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.username,
    required this.role,
    this.email,
    this.area,
    this.profilePhotoUrl,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String phone;
  final String username;
  final String role;
  final String? email;
  final String? area;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        fullName: json['jina_kamili'] as String,
        phone: json['namba_ya_simu'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        email: json['email'] as String?,
        area: json['eneo'] as String?,
        profilePhotoUrl: json['profile_photo_url'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'] as String),
      );
}
