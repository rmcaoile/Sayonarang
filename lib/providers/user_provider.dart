import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:donation_app/api/firebase_user_api.dart';
import 'dart:io';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:donation_app/utils/image_compression.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/models/user_model.dart' as user_model;

class MyAuthProvider with ChangeNotifier {
  late FirebaseAuthAPI authService;
  late Stream<User?> uStream;
  User? userObj;
  String? role;
  late Stream<QuerySnapshot> _openOrgsStream;
  user_model.User? _selectedOrg;

  Map<String, dynamic> signupStatus = {};
  Map<String, dynamic> userDetails =
      {}; // {success: true/false, response: map/string}
  Stream<QuerySnapshot> get openOrgs => _openOrgsStream;
  user_model.User get selected => _selectedOrg!;

  changeSelectedOrg(user_model.User org) {
    _selectedOrg = org;
  }

  MyAuthProvider() {
    authService = FirebaseAuthAPI();
    fetchAuthentication();
    _openOrgsStream = const Stream
        .empty(); // initialize with an empty stream to prevent LateInitializationError
  }

  Stream<User?> get userStream => uStream;

  void fetchAuthentication() {
    uStream = authService.getUser();

    // get user role based on id
    uStream.first.then((user) async {
      if (user != null) {
        print('## User ID: ${user.uid}');

        role = await authService.getUserRole(user.uid);
        print('## Role: $role');
        notifyListeners();
      }
    });

    notifyListeners();
  }

  Future<void> signUp(
      String name,
      String username,
      String email,
      String password,
      String contactNum,
      List<String> addresses,
      String proof,
      String role) async {
    signupStatus = await authService.signUp(
        name, username, email, password, contactNum, addresses, proof, role);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    userDetails = await authService.signIn(email, password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await authService.signOut();
    notifyListeners();
  }

  Future<File?> getImageFromGallery(BuildContext context) async {
    try {
      final returnImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (returnImage == null) return null;
      // print(returnImage.path);
      return File(returnImage.path);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      if (StorageConfig.useFirebaseStorage) {
        // get reference to firebase storage
        final storageRef = FirebaseStorage.instance.ref();

        // get filename of the image
        final fileName = file.path.split("/").last;
        final timestamp = DateTime.now().microsecondsSinceEpoch;

        // define the path in the storage
        final uploadRef = storageRef.child("proof/$timestamp-$fileName");
        await uploadRef.putFile(file);
        print('Successfully uploaded file');
        return '$timestamp-$fileName';
      }

      // base64 in Firestore
      final compressedBytes = await ImageCompressionUtil.compressImage(file);
      final base64Image = base64Encode(compressedBytes);
      print('Successfully compressed and converted file to base64');
      return base64Image;
    } catch (e) {
      print(e);
      return '';
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      Map<String, dynamic> userDoc = await authService.getUserDetails(userId);
      return userDoc;
    } catch (e) {
      throw Exception("Failed to retrieve details of user: ${e.toString()}");
    }
  }

  Future<String> getUserRole(String userId) async {
    try {
      role = await authService.getUserRole(userId);
      notifyListeners();
      return role ?? '';
    } catch (e) {
      throw Exception("Failed to retrieve role of user: ${e.toString()}");
    }
  }

  void editOrgIsOpen(
    String userId,
    bool isOpen,
  ) async {
    String message = await authService.editOrgIsOpen(userId, isOpen);
    print(message);
    notifyListeners();
  }

  void editOrgDetails(
    String userId,
    String description,
    List<String> addresses,
    String contactNum,
    bool isOpen,
    String? profileImageUrl,
  ) async {
    String message = await authService.editOrgDetails(
        userId, description, addresses, contactNum, isOpen, profileImageUrl);
    print(message);
    notifyListeners();
  }

  void fetchOpenOrgs() {
    _openOrgsStream = authService.getOpenOrgs();
    notifyListeners();
  }

  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      return await authService.getUserById(userId);
    } catch (e) {
      throw Exception("Failed to retrieve user: ${e.toString()}");
    }
  }

  Future<String> updateDonorProfile(
    String userId,
    String name,
    String username,
    String contactNum,
    List<String> addresses,
    String? profileImageUrl,
  ) async {
    try {
      String message = await authService.updateDonorProfile(
          userId, name, username, contactNum, addresses, profileImageUrl);
      notifyListeners();
      return message;
    } catch (e) {
      throw Exception("Failed to update donor profile: ${e.toString()}");
    }
  }
}