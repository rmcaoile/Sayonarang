import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:donation_app/screens/org/org_drive_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/providers/drive_provider.dart';

class OrgDrivesPage extends StatefulWidget {
  const OrgDrivesPage({super.key});
  @override
  _OrgDrivesPageState createState() => _OrgDrivesPageState();
}

class _OrgDrivesPageState extends State<OrgDrivesPage> {
  late User? _currentUser;
  late Future<Map<String, dynamic>> _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    // fetch user details
    _currentUser = FirebaseAuth.instance.currentUser;
    _userDetailsFuture =
        context.read<MyAuthProvider>().getUserDetails(_currentUser!.uid);
    if (_currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DriveProvider>().fetchDrivesByOrg(_currentUser!.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // access drives in the provider
    Stream<QuerySnapshot> drivesStream =
        context.watch<DriveProvider>().drivesByOrg;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Donation Drives",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          bottom: TabBar(
            dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Finished"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: drivesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error encountered! ${snapshot.error}"),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No donation drives yet!',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            // convert data from drives stream to a list
            List<Drive> drives = snapshot.data!.docs.map((doc) {
              Drive drive = Drive.fromJson(doc.data() as Map<String, dynamic>);
              drive.id = doc.id;
              return drive;
            }).toList();

            return TabBarView(
              children: [
                _buildDriveList(drives, true),
                _buildDriveList(drives, false),
              ],
            );
          },
        ),
        floatingActionButton: FutureBuilder<Map<String, dynamic>>(
          future: _userDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // disable FAB if user is not approved
              return const FloatingActionButton(
                onPressed: null,
                backgroundColor: Colors.grey,
                child: Icon(Icons.error, color: Colors.white, size: 28),
              );
            } else {
              final userDetails = snapshot.data;
              final isApproved = userDetails?['status'] == 'approved';
              return FloatingActionButton(
                tooltip: 'Create donation drive',
                onPressed: isApproved
                    ? () {
                        // navigate to the create drive details page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const OrgDriveFormPage(mode: "add"),
                          ),
                        );
                      }
                    : null,
                backgroundColor: isApproved
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDriveList(List<Drive> drives, bool isOngoing) {
    DateTime now = DateTime.now();
    List<Drive> filteredDrives = drives.where((drive) {
      return isOngoing
          ? now.isBefore(drive.endDate)
          : now.isAfter(drive.endDate);
    }).toList();

    if (filteredDrives.isEmpty) {
      return Center(
        child: Text(
          'No ${isOngoing ? "ongoing" : "finished"} drives yet!',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDrives.length,
      itemBuilder: (context, index) {
        Drive drive = filteredDrives[index];
        return _buildDriveCard(drive);
      },
    );
  }

  Widget _buildDriveCard(Drive drive) {
    bool isEnded = drive.endDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          // change selected drive
          context.read<DriveProvider>().changeSelectedDrive(drive);

          // navigate to the drive form page with view as mode
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrgDriveFormPage(mode: "view"),
            ),
          );
        },
        child: Card(
          surfaceTintColor: Colors.transparent,
          child: ListTile(
            title: Text(
              drive.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${isEnded ? 'Ended' : 'Ends'} on ${DateFormat('MMMM dd, yyyy').format(drive.endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drive.description,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
