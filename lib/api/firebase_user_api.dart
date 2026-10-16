import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthAPI {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<User?> getUser() {
    return auth.authStateChanges();
  }

  Future<Map<String, dynamic>> signUp(
      String name,
      String username,
      String email,
      String password,
      String contactNum,
      List<String> addresses,
      String proof,
      String role) async {
    UserCredential credential;

    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // print(credential);

      // save user's other details to Firestore
      // specify own id by calling the set method
      await db.collection("users").doc(credential.user!.uid).set({
        'name': name,
        'username': username,
        'contactNum': contactNum,
        'addresses': addresses,
        'proof': proof,
        'role': role,
        'status': role == 'org' ? 'pending' : '',
        'isOpen': false,
        'description': '',
      });

      // print('Successfully signed up!');
      return {
        'success': true,
        'response': 'Successfully signed up!',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        // print('The password provided is too weak.');
        return {
          'success': false,
          'response': 'The password provided is too weak.',
        };
      } else if (e.code == 'email-already-in-use') {
        // print('The account already exists for that email.');
        return {
          'success': false,
          'response': 'The account already exists for that email.',
        };
      }
    } catch (e) {
      // print(e);
      return {
        'success': false,
        'response': e.toString(),
      };
    }
    return {
      'success': false,
      'response': 'An error occurred',
    };
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    // UserCredential credential;
    try {
      final credential = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      Map<String, dynamic> currentUser =
          await getUserDetails(credential.user!.uid);

      return {
        'success': true,
        'response': currentUser,
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // print('No user found for that email.');
        return {
          'success': false,
          'response': 'User not found',
        };
      } else if (e.code == 'wrong-password') {
        // print('Wrong password provided for that user.');
        return {
          'success': false,
          'response': 'Wrong password',
        };
      } else if (e.code == 'invalid-credential') {
        // print('Invalid credentials');
        return {
          'success': false,
          'response': 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'response': e.toString(),
      };
    }

    return {
      'success': false,
      'response': 'Invalid credentials',
    };
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<Map<String, dynamic>> getUserDetails(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('users').doc(uid).get();

    return userDoc.data()!;
  }

  Future<String> getUserRole(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('users').doc(uid).get();

    return userDoc.data()!['role'];
  }

  // for org use to update their status
  Future<String> editOrgIsOpen(
    String? orgId,
    bool isOpen,
  ) async {
    try {
      print("Is org open for donations: $isOpen");
      await db.collection("users").doc(orgId).update({
        "isOpen": isOpen,
      });

      return "Successfully edited org status to $isOpen!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}";
    }
  }

  Future<String> editOrgDetails(
    String? orgId,
    String description,
    List<String> addresses,
    String contactNum,
    bool isOpen,
    String? profileImageUrl,
  ) async {
    try {
      Map<String, dynamic> updateData = {
        "description": description,
        "addresses": addresses,
        "contactNum": contactNum,
        "isOpen": isOpen,
      };
      if (profileImageUrl != null) {
        updateData["profileImageUrl"] = profileImageUrl;
      }
      await db.collection("users").doc(orgId).update(updateData);

      return "Successfully edited org org details!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}'";
    }
  }

  Stream<QuerySnapshot> getOpenOrgs() {
    try {
      return db
          .collection("users")
          .where("isOpen", isEqualTo: true)
          .snapshots();
    } catch (e) {
      throw "Failed to get open orgs: $e";
    }
  }

  Future<DocumentSnapshot> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();
      return userDoc;
    } on FirebaseException catch (e) {
      throw Exception("Failed to retrieve user: ${e.message}");
    }
  }

  Future<String> updateDonorProfile(
    String? userId,
    String name,
    String username,
    String contactNum,
    List<String> addresses,
    String? profileImageUrl,
  ) async {
    try {
      Map<String, dynamic> updateData = {
        "name": name,
        "username": username,
        "contactNum": contactNum,
        "addresses": addresses,
      };
      if (profileImageUrl != null) {
        updateData["profileImageUrl"] = profileImageUrl;
      }
      await db.collection("users").doc(userId).update(updateData);
      return "Successfully updated donor profile!";
    } on FirebaseException catch (e) {
      return "Failed with error '${e.code}: ${e.message}'";
    }
  }
}
