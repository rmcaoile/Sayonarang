import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/donation_provider.dart';
import '../../screens/shared/image_viewer.dart';
import '../../storage_config.dart';

class DonationDetailScreen extends StatefulWidget {
  final Donation donation;
  final String userName;
  final String userRole;

  const DonationDetailScreen({
    Key? key,
    required this.donation,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  String? _photoDownloadURL;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadURL();
  }

  Future<void> _loadDownloadURL() async {
    if (widget.donation.photo != '' && widget.donation.photo.isNotEmpty) {
      final downloadURL = await context
          .read<DonationProvider>()
          .fetchDownloadURLForImage(widget.donation.photo);
      if (mounted) {
        setState(() {
          _photoDownloadURL = downloadURL;
          _isLoadingImage = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  Widget _buildImageContainer() {
    if (_isLoadingImage) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_photoDownloadURL == null || _photoDownloadURL!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            'No image available',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Image",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ShowFullImage(
                  image: _photoDownloadURL!,
                ),
              ),
            );
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: StorageConfig.useFirebaseStorage
                    ? NetworkImage(_photoDownloadURL!)
                    : MemoryImage(base64Decode(_photoDownloadURL!))
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donation Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF54741),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF54741)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              surfaceTintColor: Colors.transparent,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        widget.userRole == 'Donor'
                            ? 'Organization: ${widget.userName}'
                            : 'Donor: ${widget.userName}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildStatusText(widget.donation.status),
                    const SizedBox(height: 15),
                    const Text(
                      'Donation Drive:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 25),
                        FutureBuilder<String?>(
                          future: adminProvider.getTitleName(widget.donation.driveId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data != null) {
                              return Text(
                                snapshot.data!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              );
                            } else {
                              return const Text(
                                'No Donation Drive',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Categories:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.donation.categories.map((category) {
                        return Row(
                          children: [
                            const SizedBox(width: 25),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    if (widget.donation.mode == 'Pick-up') ...[
                      const Text(
                        'Addresses:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.donation.addresses.map((address) {
                          return Row(
                            children: [
                              const SizedBox(width: 25),
                              Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                    const Text(
                      'Mode:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 25),
                        Text(
                          widget.donation.mode,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Weight:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 25),
                        Text(
                          widget.donation.weight.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (widget.donation.mode == 'Pick-up') ...[
                      const Text(
                        'Contact Number:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 25),
                          Text(
                            widget.donation.contactNum,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                    const Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 25),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(widget.donation.date),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildImageContainer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(String status) {
    Color statusColor = Colors.black;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.black;
        break;
    }

    return Text(
      'Status: $status',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: statusColor,
      ),
    );
  }
}
