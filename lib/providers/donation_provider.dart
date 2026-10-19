import 'package:flutter/material.dart';
import 'package:donation_app/api/firebase_donation_api.dart';
import 'package:donation_app/models/donation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:donation_app/utils/image_compression.dart';

class DonationProvider with ChangeNotifier {
  late FirebaseDonationAPI firebaseService;
  late Stream<QuerySnapshot> _donationsStream;
  late Stream<QuerySnapshot> _donationsByDonorStream;
  late Stream<QuerySnapshot> _donationsToOrgStream;
  late Stream<QuerySnapshot> _donationsByDriveStream;
  Donation? _selectedDonation;

  DonationProvider() {
    firebaseService = FirebaseDonationAPI();
    fetchDonations();
    _donationsByDonorStream = const Stream
        .empty(); // initialize with an empty stream to prevent LateInitializationError
    _donationsToOrgStream = const Stream
        .empty(); // initialize with an empty stream to prevent LateInitializationError
  }

  // getter
  Stream<QuerySnapshot> get donations => _donationsStream;
  Stream<QuerySnapshot> get donationsByDonor => _donationsByDonorStream;
  Stream<QuerySnapshot> get donationsToOrg => _donationsToOrgStream;
  Stream<QuerySnapshot> get donationsByDrive => _donationsByDriveStream;
  Donation get selected => _selectedDonation!;

  changeSelectedDonation(Donation donation) {
    _selectedDonation = donation;
  }

  void fetchDonations() {
    _donationsStream = firebaseService.getAllDonations();
    notifyListeners();
  }

  void fetchDonationsByDonor(String donorId) {
    _donationsByDonorStream = firebaseService.getDonationsByDonor(donorId);
    notifyListeners();
  }

  void fetchDonationsToOrg(String orgId) {
    _donationsToOrgStream = firebaseService.getDonationsToOrg(orgId);
    notifyListeners();
  }

  void fetchDonationsByDrive(String driveId) {
    _donationsByDriveStream = firebaseService.getDonationsByDrive(driveId);
    notifyListeners();
  }

  void addDonation(Donation donation) async {
    String message =
        await firebaseService.addDonation(donation.toJson(donation));
    print(message);
    notifyListeners();
  }

  void editDonationDetails(
      List<String> categories,
      List<String> addresses,
      String mode,
      double weight,
      String weightUnit,
      String contactNum,
      DateTime date,
      String time,
      String photo) async {
    String message = await firebaseService.editDonationDetails(
      _selectedDonation!.id,
      categories,
      addresses,
      mode,
      weight,
      weightUnit,
      contactNum,
      date,
      time,
      photo,
    );
    print(message);
    notifyListeners();
  }

  void editDonationStatus(String status) async {
    String message =
        await firebaseService.editDonationStatus(_selectedDonation!.id, status);
    print(message);
    notifyListeners();
  }

  void linkToDrive(String driveId) async {
    String message =
        await firebaseService.linkToDrive(_selectedDonation!.id, driveId);
    print(message);
    notifyListeners();
  }

  void editAndLink(String status, String driveId) async {
    String message =
        await firebaseService.editAndLink(_selectedDonation!.id, status, driveId);
    print(message);
    notifyListeners();
  }

  void deleteDonation() async {
    String message =
        await firebaseService.deleteDonation(_selectedDonation!.id);
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
        final uploadRef = storageRef.child("images/$timestamp-$fileName");
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

  Future<void> deleteFile(String fileUrl) async {
    if (StorageConfig.useFirebaseStorage) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final fileRef = storageRef.storage.refFromURL(fileUrl);
        await fileRef.delete();
        print('Successfully deleted file: $fileUrl');
      } catch (e) {
        print(e);
      }
      return;
    }
    // 
  }

  Future<String> fetchDownloadURLForImage(String photo) async {
    if (StorageConfig.useFirebaseStorage) {
      String downloadURL = await FirebaseStorage.instance
          .ref()
          .child('images/${photo}')
          .getDownloadURL();
      return downloadURL;
    }
    // base64 string stored in Firestore; return as-is
    return photo;
  }
}