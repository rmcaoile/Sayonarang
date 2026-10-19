import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donate_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:donation_app/storage_config.dart';

class FirebaseDonorAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getDonor() {
    return db.collection("users").where("role", isEqualTo: "donor").snapshots();
  }

  Stream<QuerySnapshot> getAllOrgs() {
    return db
        .collection("users")
        .where("role", isEqualTo: "org")
        .where("status", isEqualTo: "approved")
        .snapshots();
  }

  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();
      return userDoc;
    } on FirebaseException catch (e) {
      throw Exception("Failed to retrieve user: ${e.message}");
    }
  }

  Future<void> addDonation(DonateData donation) async {
    try {
      await db.collection('donations').add(donation.toMap());
    } on FirebaseException catch (e) {
      throw Exception("Failed to add donation: ${e.message}");
    }
  }

  Future<QuerySnapshot> getDonationsByDonor(String donorId) async {
    try {
      return await db
          .collection('donations')
          .where('donorId', isEqualTo: donorId)
          .get();
    } on FirebaseException catch (e) {
      throw Exception("Failed to fetch donations: ${e.message}");
    }
  }

  Future<void> deleteDonation(String donationId) async {
    try {
      await db.collection('donations').doc(donationId).delete();
    } on FirebaseException catch (e) {
      throw Exception("Failed to delete donation: ${e.message}");
    }
  }

  // Instead of deleting update the status to cancelled
  Future<String> cancelDonation(String orgId, String status) async {
    try {
      await db.collection('donations').doc(orgId).update({
        'status': status,
      });

      return "Successfully updated donation status to $status!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<DocumentSnapshot> getOrgById(String orgId) async {
    try {
      return await db.collection('users').doc(orgId).get();
    } on FirebaseException catch (e) {
      throw Exception("Failed to retrieve organization: ${e.message}");
    }
  }

  Future<String?> getImageUrl(String photo) async {
    if (StorageConfig.useFirebaseStorage) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef.child("images/$photo");
        return await imageRef.getDownloadURL();
      } catch (e) {
        print("Failed to retrieve image: $e");
        return null;
      }
    }
    // base64 string stored in Firestore; return as-is
    return photo;
  }
}
