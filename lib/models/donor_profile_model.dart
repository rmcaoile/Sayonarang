class DonorProfileModel {
  final String name;
  final String username;
  final String contactNum;
  final List<String> addresses;
  final String? profileImageUrl;

  DonorProfileModel({
    required this.name,
    required this.username,
    required this.contactNum,
    required this.addresses,
    this.profileImageUrl,
  });

  factory DonorProfileModel.fromMap(Map<String, dynamic> map) {
    return DonorProfileModel(
      name: map['name'],
      username: map['username'],
      contactNum: map['contactNum'],
      addresses: List<String>.from(map['addresses']),
      profileImageUrl: map['profileImageUrl'],
    );
  }

  DonorProfileModel copyWith({
    String? name,
    String? username,
    String? contactNum,
    List<String>? addresses,
    String? profileImageUrl,
  }) {
    return DonorProfileModel(
      name: name ?? this.name,
      username: username ?? this.username,
      contactNum: contactNum ?? this.contactNum,
      addresses: addresses ?? this.addresses,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
