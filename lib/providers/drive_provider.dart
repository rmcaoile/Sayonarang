import 'package:flutter/material.dart';
import 'package:donation_app/api/firebase_drive_api.dart';
import 'package:donation_app/models/drive_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:donation_app/utils/image_compression.dart';

class DriveProvider with ChangeNotifier {
  late FirebaseDriveAPI firebaseService;
  late Stream<QuerySnapshot> _drivesStream;
  late Stream<QuerySnapshot> _drivesByOrgStream;
  Drive? _selectedDrive;

  DriveProvider() {
    firebaseService = FirebaseDriveAPI();
    fetchDrives();
    _drivesStream = const Stream
        .empty(); // initialize with an empty stream to prevent LateInitializationError
    _drivesByOrgStream = const Stream.empty();
  }

  // getter
  Stream<QuerySnapshot> get drives => _drivesStream;
  Stream<QuerySnapshot> get drivesByOrg => _drivesByOrgStream;
  Drive get selected => _selectedDrive!;

  changeSelectedDrive(Drive drive) {
    _selectedDrive = drive;
  }

  void fetchDrives() {
    _drivesStream = firebaseService.getAllDrives();
    notifyListeners();
  }

  void fetchDrivesByOrg(String orgId) {
    _drivesByOrgStream = firebaseService.getDrivesByOrg(orgId);
    notifyListeners();
  }

  void addDrive(Drive drive) async {
    String message = await firebaseService.addDrive(drive.toJson());
    print(message);
    notifyListeners();
  }

  void editDrive(String title, String description, DateTime endDate,
      List<String> photos) async {
    String message = await firebaseService.editDrive(
        _selectedDrive!.id, title, description, endDate, photos);
    print(message);
    notifyListeners();
  }

  void deleteDrive() async {
    String message = await firebaseService.deleteDrive(_selectedDrive!.id);
    print(message);
    notifyListeners();
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
        final uploadRef = storageRef.child("drive/$timestamp-$fileName");
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

  Future<List<String>> uploadFiles(List<File> files) async {
    List<String> uploadedPaths = [];

    try {
      if (StorageConfig.useFirebaseStorage) {
        // Get reference to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref();

        // Upload each file in the list
        for (File file in files) {
          // Get filename of the image
          final fileName = file.path.split("/").last;
          final timestamp = DateTime.now().microsecondsSinceEpoch;

          // Define the path in the storage
          final uploadRef = storageRef.child("drives/$timestamp-$fileName");

          // Upload file to Firebase Storage
          await uploadRef.putFile(file);

          // Add uploaded file path to the list
          uploadedPaths.add('$timestamp-$fileName');
          print('Successfully uploaded file: $fileName');
        }

        return uploadedPaths;
      }

      // base64 in Firestore
      for (File file in files) {
        final compressedBytes = await ImageCompressionUtil.compressImage(file);
        final base64Image = base64Encode(compressedBytes);
        uploadedPaths.add(base64Image);
        print('Successfully compressed and converted file to base64');
      }

      return uploadedPaths;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> deleteFiles(List<String> fileUrls) async {
    if (StorageConfig.useFirebaseStorage) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        for (String fileUrl in fileUrls) {
          final fileRef = storageRef.storage.refFromURL(fileUrl);
          await fileRef.delete();
          print('Successfully deleted file: $fileUrl');
        }
      } catch (e) {
        print(e);
      }
      return;
    }
    // 
  }

  Future<List<String>> fetchDownloadURLsForImages(
      List<String> photos) async {
    List<String> downloadURLs = [];
    if (StorageConfig.useFirebaseStorage) {
      for (String photo in photos) {
        String downloadURL = await FirebaseStorage.instance
            .ref()
            .child('drives/$photo')
            .getDownloadURL();
        downloadURLs.add(downloadURL);
      }
      return downloadURLs;
    }
    // base64 strings stored in Firestore; return as-is
    for (String photo in photos) {
      downloadURLs.add(photo);
    }
    return downloadURLs;
  }

  Future<DocumentSnapshot> getDriveById(String orgId) async {
    try {
      return await firebaseService.getDriveById(orgId);
    } catch (e) {
      throw Exception("Failed to retrieve drive: ${e.toString()}");
    }
  }

  Future<String?> getDriveTitle(String driveId) async {
    return firebaseService.getDriveTitleById(driveId);
  }
}