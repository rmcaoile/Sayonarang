import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../models/drive_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/drive_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/donor_new/donation_card.dart';
import '../../screens/shared/image_slider.dart';
import '../../storage_config.dart';
import 'admin_donation_details.dart';

class DriveScreen extends StatefulWidget {
  final Drive drive;
  final String userName;

  const DriveScreen({
    Key? key,
    required this.drive,
    required this.userName,
  }) : super(key: key);

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  @override
  Widget build(BuildContext context) {
    final driveId = widget.drive.id ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.drive.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF54741),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF54741)),
          bottom: TabBar(
            dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            tabs: const [
              Tab(text: 'Donations'),
              Tab(text: 'Drive Details'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DriveDonationsList(driveId: driveId),
            DriveDetailScreen(
              drive: widget.drive,
              userName: widget.userName,
            ),
          ],
        ),
      ),
    );
  }
}

// Details screen of drive
class DriveDetailScreen extends StatefulWidget {
  final Drive drive;
  final String userName;

  const DriveDetailScreen({
    Key? key,
    required this.drive,
    required this.userName,
  }) : super(key: key);

  @override
  State<DriveDetailScreen> createState() => _DriveDetailScreenState();
}

class _DriveDetailScreenState extends State<DriveDetailScreen> {
  List<String> _photosDownloadURLs = [];
  bool _isLoadingImages = true;
  String? _orgProfileImageUrl;
  String _orgName = '';
  String _orgStatus = '';

  @override
  void initState() {
    super.initState();
    _loadDownloadURLs();
    _loadOrgDetails();
  }

  Future<void> _loadOrgDetails() async {
    try {
      final details = await context
          .read<MyAuthProvider>()
          .getUserDetails(widget.drive.orgId);
      if (!mounted) return;
      setState(() {
        _orgName = details['name'] as String? ?? widget.userName;
        _orgProfileImageUrl = details['profileImageUrl'] as String?;
        _orgStatus = details['status'] as String? ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _orgName = widget.userName);
    }
  }

  Future<void> _loadDownloadURLs() async {
    if (widget.drive.photos.isNotEmpty) {
      final downloadURLs = await context
          .read<DriveProvider>()
          .fetchDownloadURLsForImages(widget.drive.photos);
      if (mounted) {
        setState(() {
          _photosDownloadURLs = downloadURLs;
          _isLoadingImages = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  Widget _buildImageGrid() {
    if (_isLoadingImages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photosDownloadURLs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No images available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = _photosDownloadURLs.length <= 3 ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 4 / 3,
      ),
      itemCount: _photosDownloadURLs.length,
      itemBuilder: (context, index) {
        final image = _photosDownloadURLs[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SliderShowFullmages(
                        listImagesModel: _photosDownloadURLs,
                        current: index,
                      ),
                    ),
                  );
                },
                child: StorageConfig.useFirebaseStorage
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.memory(
                        base64Decode(image),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _getOrgImageProvider() {
    final url = _orgProfileImageUrl;
    if (url == null || url.isEmpty) return null;
    if (StorageConfig.useFirebaseStorage) return NetworkImage(url);
    return MemoryImage(base64Decode(url));
  }

  Widget _buildSectionLabel(String label, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildValueRow(String value, {required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = value.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isEmpty ? 'Not set' : value,
            style: TextStyle(
              fontSize: 16,
              color: isEmpty
                  ? colorScheme.onSurface.withValues(alpha: 0.4)
                  : colorScheme.onSurface,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: colorScheme.primary,
                        backgroundImage: _getOrgImageProvider(),
                        child: _getOrgImageProvider() == null
                            ? Text(
                                (_orgName.isNotEmpty
                                        ? _orgName
                                        : widget.userName)
                                    .trim()
                                    .split(RegExp(r'\s+'))
                                    .where((w) => w.isNotEmpty)
                                    .take(2)
                                    .map((w) => w[0])
                                    .join()
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      if (_orgStatus == 'approved')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.drive.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'By: ${_orgName.isEmpty ? (widget.userName.isEmpty ? 'Unknown' : widget.userName) : _orgName}',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionLabel('Description', context),
                const SizedBox(height: 4),
                _buildValueRow(
                  widget.drive.description,
                  context: context,
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('End Date', context),
                const SizedBox(height: 4),
                _buildValueRow(
                  DateFormat('MMMM dd, yyyy').format(widget.drive.endDate),
                  context: context,
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('Images', context),
                const SizedBox(height: 8),
                _buildImageGrid(),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class DriveDonationsList extends StatelessWidget {
  final String driveId;

  const DriveDonationsList({Key? key, required this.driveId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final donationProvider =
        Provider.of<DonationProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    donationProvider.fetchDonationsByDrive(driveId);

    return StreamBuilder(
      stream: donationProvider.donationsByDrive,
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
          return const Center(
            child: Text(
              'No donations found!',
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            Donation donation = Donation.fromJson(
                snapshot.data!.docs[index].data() as Map<String, dynamic>);
            donation.id = snapshot.data!.docs[index].id;

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
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Icon(
                        leadingIcon,
                        color: statusColor,
                      ),
                      title: const Text('Loading organization...'),
                      subtitle: Text('Status: ${donation.status}'),
                    ),
                  );
                } else if (donorSnapshot.hasError) {
                  return Card(
                    surfaceTintColor: Colors.transparent,
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Icon(
                        leadingIcon,
                        color: statusColor,
                      ),
                      title: const Text('Error loading organization'),
                      subtitle: Text('Status: ${donation.status}'),
                    ),
                  );
                } else {
                  var donorData =
                      donorSnapshot.data!.data() as Map<String, dynamic>?;
                  String donorName =
                      donorData?['name'] ?? 'Unknown Organization';

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
                            userRole: 'org',
                            profileImageUrl: donorData?['profileImageUrl'],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
