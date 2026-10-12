import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/drive_provider.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:donation_app/screens/donor_new/donor_donation_form.dart';
import 'package:donation_app/screens/donor_new/donor_drive_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/storage_config.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class DonorOrgPage extends StatefulWidget {
  const DonorOrgPage({super.key});
  @override
  _DonorOrgPageState createState() => _DonorOrgPageState();
}

class _DonorOrgPageState extends State<DonorOrgPage> {
  User? _selectedOrg;
  @override
  void initState() {
    super.initState();
    _selectedOrg = context.read<MyAuthProvider>().selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId = _selectedOrg?.id;
      if (orgId != null) {
        context.read<DriveProvider>().fetchDrivesByOrg(orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Organization Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF54741),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF54741)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                surfaceTintColor: Colors.transparent,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              _orgInitials(_selectedOrg!.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedOrg!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedOrg!.username,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF666666),
                                      fontStyle: FontStyle.italic),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedOrg!.description == ''
                                      ? "No description yet."
                                      : _selectedOrg!.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Number:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Addresses:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedOrg!.contactNum,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    _selectedOrg!.addresses.map((address) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
                _buildDrivesSection(),
                const SizedBox(height: 8),
             ],
           ),
          ],
        ),
       bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // navigate to the create donation form page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DonorDonationFormPage(mode: 'add'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Donate Now'),
            ),
          ),
        ),
      ),
     );
   }

  Widget _buildDrivesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: context.watch<DriveProvider>().drivesByOrg,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error encountered!"),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text(
                  'No donation drives yet!',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        // convert data from drives stream to a list
        List<Drive> drives = snapshot.data!.docs.map((doc) {
          Drive drive = Drive.fromJson(doc.data() as Map<String, dynamic>);
          drive.id = doc.id;
          return drive;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'Donation Drives',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            ...drives.map((drive) => _buildDriveCard(drive)),
          ],
        );
      },
    );
  }

  Widget _buildDriveCard(Drive drive) {
    final bool isEnded = drive.endDate.isBefore(DateTime.now());
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // change selected drive
            context.read<DriveProvider>().changeSelectedDrive(drive);

            // navigate to the drive details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DonorDriveDetailsPage(
                  drive: drive,
                  userName: _selectedOrg!.name,
                ),
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
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _driveThumbnailPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  String _orgInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    final initials =
        (first.isNotEmpty ? first[0] : '') + (second.isNotEmpty ? second[0] : '');
    return initials.toUpperCase();
  }
 }
