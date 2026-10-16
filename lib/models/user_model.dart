//user_model.dart
import 'dart:convert';

class User {
  String? id;
  String name;
  String username;
  List<String> addresses;
  String contactNum; // Renamed this to be the same in firebase
  String proof;
  String role; // admin, donor, org
  String status; // pending, approved, rejected (for org)
  bool isOpen;
  String description;
  String? profileImageUrl;

  User({
    this.id,
    required this.name,
    required this.username,
    required this.addresses, // only for donor and org
    required this.contactNum, // only for donor and org
    required this.proof, // only for org
    required this.role,
    required this.status, // only for org
    required this.isOpen, // only for org (if accepting donations)
    required this.description, // only for org
    this.profileImageUrl,
  });

  // Factory constructor to instantiate object from json format
  factory User.fromJson(Map<String, dynamic> json) {
    // Convert dynamic list to list of strings
    List<String> parsedAddresses =
        json['addresses'] != null ? List<String>.from(json['addresses']) : [];

    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      addresses: parsedAddresses,
      contactNum: json['contactNum'],
      proof: json['proof'],
      role: json['role'],
      status: json['status'],
      isOpen: json['isOpen'],
      description: json['description'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  static List<User> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<User>((dynamic d) => User.fromJson(d)).toList();
  }

  static Map<String, dynamic> toJson(User user) {
    return {
      'name': user.name,
      'username': user.username,
      'addresses': user.addresses,
      'contactNum': user.contactNum,
      'proof': user.proof,
      'role': user.role,
      'status': user.status,
      'isOpen': user.isOpen,
      'description': user.description,
      'profileImageUrl': user.profileImageUrl,
    };
  }
}
