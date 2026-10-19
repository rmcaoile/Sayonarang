import 'dart:convert';

import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:donation_app/screens/org/org_drive_form.dart';
import 'package:donation_app/storage_config.dart';
import 'package:flutter/material.dart';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'No ${isOngoing ? "ongoing" : "finished"} drives yet!',
              style: const TextStyle(fontSize: 18),
            ),
          ],
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
    final bool isEnded = drive.endDate.isBefore(DateTime.now());
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
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
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDriveThumbnail(drive),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drive.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (drive.photos.isNotEmpty) ...[
                            const Icon(
                              Icons.photo_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${drive.photos.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isEnded
                                  ? Colors.grey.shade200
                                  : colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isEnded ? 'Ended' : 'Ongoing',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isEnded
                                    ? Colors.grey.shade700
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildDriveThumbnail(Drive drive) {
    if (drive.photos.isEmpty) {
      return _driveThumbnailPlaceholder();
    }

    return FutureBuilder<List<String>>(
      future: context.read<DriveProvider>().fetchDownloadURLsForImages(
          drive.photos.take(1).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return _driveThumbnailPlaceholder();
        }

        final image = snapshot.data!.first;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: StorageConfig.useFirebaseStorage
                ? NetworkImage(image)
                : MemoryImage(base64Decode(image)) as ImageProvider,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _driveThumbnailPlaceholder() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
