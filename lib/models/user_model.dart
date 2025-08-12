class UserModel {
  final String id;
  String name;
  String email;
  String phone;
  String? profileImageUrl;
  String? address;
  String? preferredPaymentMethod;
  List<String> favoriteRoutes;
  Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.address,
    this.preferredPaymentMethod,
    this.favoriteRoutes = const [],
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      address: json['address'],
      preferredPaymentMethod: json['preferredPaymentMethod'],
      favoriteRoutes:
          json['favoriteRoutes'] != null
              ? List<String>.from(json['favoriteRoutes'])
              : [],
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'preferredPaymentMethod': preferredPaymentMethod,
      'favoriteRoutes': favoriteRoutes,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? address,
    String? preferredPaymentMethod,
    List<String>? favoriteRoutes,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      preferences: preferences ?? this.preferences,
    );
  }
}
