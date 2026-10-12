import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDonationAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<String> addDonation(Map<String, dynamic> donation) async {
    try {
      await db.collection("donations").add(donation);

      return "Successfully added donation!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Stream<QuerySnapshot> getAllDonations() {
    return db.collection("donations").snapshots();
  }

  Stream<QuerySnapshot> getDonationsByDonor(String donorId) {
    try {
      return db
          .collection("donations")
          .where("donorId", isEqualTo: donorId)
          .snapshots();
    } catch (e) {
      throw "Failed to get donations by donor: $e";
    }
  }

  Stream<QuerySnapshot> getDonationsToOrg(String orgId) {
    try {
      return db
          .collection("donations")
          .where("orgId", isEqualTo: orgId)
          .snapshots();
    } catch (e) {
      throw "Failed to get donations to org: $e";
    }
  }

  Stream<QuerySnapshot> getDonationsByDrive(String driveId) {
    try {
      return db
          .collection("donations")
          .where("driveId", isEqualTo: driveId)
          .snapshots();
    } catch (e) {
      throw "Failed to get donations by drive: $e";
    }
  }

  // for donor, can edit all fields except the status
  Future<String> editDonationDetails(
      String? id,
      List<String> categories,
      List<String> addresses,
      String mode,
      double weight,
      String weightUnit,
      String contactNum,
      DateTime date,
      String time,
      String photo) async {
    try {
      await db.collection("donations").doc(id).update({
        'categories': categories,
        'addresses': addresses,
        'mode': mode,
        'weight': weight,
        'weightUnit': weightUnit,
        'contactNum': contactNum,
        'date': date,
        'time': time,
        'photo': photo,
      });

      return "Successfully edited donation details!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<String> editDonationStatus(
    String? id,
    String status,
  ) async {
    try {
      print("Status: $status");
      await db.collection("donations").doc(id).update({
        "status": status,
      });

      return "Successfully edited donation status to $status!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<String> linkToDrive(
    String? id,
    String driveId,
  ) async {
    if (id == null) {
      return "Donation ID is null and cannot be linked to the drive.";
    }
    try {
      print("Drive ID: $driveId");
      print("id: $id");
      final batch = db.batch();
      batch.update(
        db.collection("donations").doc(id),
        {"driveId": driveId},
      );
      // add donation id to drive's list of donation ids
      batch.update(
        db.collection("drives").doc(driveId),
        {"donationIds": FieldValue.arrayUnion([id])},
      );
      await batch.commit();

      return "Successfully linked donation to $driveId!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<String> editAndLink(
    String? id,
    String status,
    String driveId,
  ) async {
    if (id == null) {
      return "Donation ID is null and cannot be linked to the drive.";
    }
    try {
      print(">> Status: $status");
      print(">> Drive id: $driveId");
      print(">> Donation id: $id");

      final batch = db.batch();
      batch.update(
        db.collection("donations").doc(id),
        {"status": status, "driveId": driveId},
      );
      batch.update(
        db.collection("drives").doc(driveId),
        {"donationIds": FieldValue.arrayUnion([id])},
      );
      await batch.commit();

      return "Successfully linked donation status to $driveId!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<String> deleteDonation(String? id) async {
    try {
      await db.collection("donations").doc(id).delete();

      return "Successfully deleted donation!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }
}
