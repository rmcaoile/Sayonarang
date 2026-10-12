import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Drive {
  String? id;
  final String orgId; // id of org who created the donation drive
  String title;
  String description;
  List<String>
      donationIds; // list of donation ids for when the org links donations to donation drives
  DateTime endDate;
  List<String> photos;

  Drive({
    this.id,
    required this.orgId,
    required this.title,
    required this.description,
    required this.donationIds,
    required this.endDate,
    required this.photos,
  });

  // Factory constructor to instantiate object from json format
  factory Drive.fromJson(Map<String, dynamic> json) {
    return Drive(
      id: json['id'],
      orgId: json['orgId'],
      title: json['title'],
      description: json['description'],
      donationIds: ((json['donationIds'] as List?) ?? <String>[]).cast<String>(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      photos: ((json['photos'] as List?) ?? <String>[]).cast<String>(),
    );
  }

  static List<Drive> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<Drive>((dynamic d) => Drive.fromJson(d)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'orgId': orgId,
      'title': title,
      'description': description,
      'donationIds': donationIds,
      'endDate': endDate,
      'photos': photos,
    };
  }
}
