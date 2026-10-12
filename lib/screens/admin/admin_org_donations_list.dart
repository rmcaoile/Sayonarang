import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../models/drive_model.dart';
import '../../providers/donation_provider.dart';
import '../../providers/drive_provider.dart';
import '../../providers/admin_provider.dart';
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
    IconData leadingIcon;
    Color statusColor;

    switch (donation.status) {
      case 'pending':
        leadingIcon = Icons.remove_circle;
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        leadingIcon = Icons.check_circle;
        statusColor = Colors.blue;
        break;
      case 'scheduled for pick-up':
        leadingIcon = Icons.check_circle;
        statusColor = Colors.blue;
        break;
      case 'completed':
        leadingIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        leadingIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        leadingIcon = Icons.error;
        statusColor = Colors.black;
    }

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

          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(
                leadingIcon,
                color: statusColor,
              ),
              title: Text(
                donorName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    'Status: ${donation.status}',
                    style: TextStyle(color: statusColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: donation.categories
                        .take(3) // Limit to three categories
                        .map(
                          (category) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonationDetailScreen(
                        donation: donation,
                        userName: donorName,
                        userRole: 'Organization'),
                  ),
                );
              },
            ),
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
            margin: const EdgeInsets.all(8.0),
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
            margin: const EdgeInsets.all(8.0),
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

          return Card(
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.handshake, color: Colors.blue),
              title: Text(
                drive.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              subtitle: Text(
                'Description: ${drive.description}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
            ),
          );
        }
      },
    );
  }
}
