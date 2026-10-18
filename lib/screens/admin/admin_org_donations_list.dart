import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../models/drive_model.dart';
import '../../providers/donation_provider.dart';
import '../../providers/drive_provider.dart';
import '../../providers/admin_provider.dart';
import '../../screens/donor_new/donation_card.dart';
import '../../storage_config.dart';
import 'admin_donation_details.dart';
import 'admin_drive_details.dart';

class OrgDonationsList extends StatelessWidget {
  final String orgId;

  const OrgDonationsList({Key? key, required this.orgId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final donationProvider =
        Provider.of<DonationProvider>(context, listen: false);
    final driveProvider = Provider.of<DriveProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    donationProvider.fetchDonationsToOrg(orgId);
    driveProvider.fetchDrivesByOrg(orgId);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSection(context, driveProvider.drivesByOrg, adminProvider,
                'Donation Drives', false),
            const SizedBox(height: 30),
            _buildSection(context, donationProvider.donationsToOrg,
                adminProvider, 'All Donations', true),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, Stream<QuerySnapshot> stream,
      AdminProvider adminProvider, String title, bool isDonation) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error encountered! ${snapshot.error}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $title found!',
              style: const TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF54741)),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                if (isDonation) {
                  Donation donation = Donation.fromJson(
                      snapshot.data!.docs[index].data()
                          as Map<String, dynamic>);
                  donation.id = snapshot.data!.docs[index].id;
                  return _buildDonationListItem(
                      context, donation, adminProvider);
                } else {
                  Drive drive = Drive.fromJson(snapshot.data!.docs[index].data()
                      as Map<String, dynamic>);
                  drive.id = snapshot.data!.docs[index].id;
                  return _buildDriveListItem(context, drive, adminProvider);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDonationListItem(
      BuildContext context, Donation donation, AdminProvider adminProvider) {
    return FutureBuilder<DocumentSnapshot>(
      future: adminProvider.getDonorById(donation.donorId),
      builder: (context, donorSnapshot) {
        if (donorSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: const Text(
                  'Loading organization...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Status: ${donation.status}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        } else if (donorSnapshot.hasError) {
          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: const Text(
                  'Error loading organization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Status: ${donation.status}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        } else {
          var donorData = donorSnapshot.data!.data() as Map<String, dynamic>?;
          String donorName = donorData?['name'] ?? 'Unknown Organization';

          return DonationCard(
            donation: donation,
            orgName: donorName,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationDetailScreen(
                      donation: donation,
                      userName: donorName,
                      userRole: 'Organization',
                      profileImageUrl: donorData?['profileImageUrl']),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildDriveListItem(
      BuildContext context, Drive drive, AdminProvider adminProvider) {
    return FutureBuilder<DocumentSnapshot>(
      future: adminProvider.getOrgById(drive.orgId),
      builder: (context, orgSnapshot) {
        if (orgSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.handshake, color: Colors.blue),
                title: const Text(
                  'Loading organization...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Description: ${drive.description}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        } else if (orgSnapshot.hasError) {
          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.handshake, color: Colors.blue),
                title: const Text(
                  'Error loading organization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Description: ${drive.description}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        } else {
          var orgData = orgSnapshot.data!.data() as Map<String, dynamic>?;
          String orgName = orgData?['name'] ?? 'Unknown Organization';
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriveScreen(
                      drive: drive,
                      userName: orgName,
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
                    _buildDriveThumbnail(context, drive),
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
      },
    );
  }

  Widget _buildDriveThumbnail(BuildContext context, Drive drive) {
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
