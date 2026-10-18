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
  final String? profileImageUrl;

  const DonationDetailScreen({
    Key? key,
    required this.donation,
    required this.userName,
    required this.userRole,
    this.profileImageUrl,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'scheduled for pick-up':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled for pick-up':
        return 'Scheduled';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    return ((first.isNotEmpty ? first[0] : '') +
            (second.isNotEmpty ? second[0] : ''))
        .toUpperCase();
  }

  ImageProvider? _getImageProvider() {
    final url = widget.profileImageUrl;
    if (url == null || url.isEmpty) return null;
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(url);
    }
    return MemoryImage(base64Decode(url));
  }

  Widget _buildAvatar(BuildContext context) {
    final imageProvider = _getImageProvider();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: imageProvider == null
          ? null
          : () {
              final url = widget.profileImageUrl!;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShowFullImage(image: url),
                ),
              );
            },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: colorScheme.primary,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _getInitials(widget.userName),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(64),
      ),
      child: Text(
        _getStatusLabel(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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

  Widget _buildValueRow(String value, IconData icon,
      {required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = value.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
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

  Widget _buildImageContainer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoadingImage) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_photoDownloadURL == null || _photoDownloadURL!.isEmpty) {
      return Center(
        child: Text(
          'No image available',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return InkWell(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final isOtherPartyDonor = widget.userRole == 'Donor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donation Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatar(context),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOtherPartyDonor ? 'Organization:' : 'Donor:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildStatusBadge(widget.donation.status),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSectionLabel('Donation Drive', context),
                const SizedBox(height: 4),
                FutureBuilder<String?>(
                  future: adminProvider.getTitleName(widget.donation.driveId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    } else if (snapshot.hasData &&
                        snapshot.data != null) {
                      return _buildValueRow(
                        snapshot.data!,
                        Icons.local_offer,
                        context: context,
                      );
                    } else {
                      return _buildValueRow(
                        'No Donation Drive',
                        Icons.local_offer,
                        context: context,
                      );
                    }
                  },
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('Categories', context),
                const SizedBox(height: 8),
                ...widget.donation.categories.map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildValueRow(
                        category,
                        Icons.category,
                        context: context,
                      ),
                    )),
                const SizedBox(height: 15),
                if (widget.donation.mode == 'Pick-up') ...[
                  _buildSectionLabel('Addresses', context),
                  const SizedBox(height: 8),
                  ...widget.donation.addresses.map((address) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildValueRow(
                          address,
                          Icons.location_on,
                          context: context,
                        ),
                      )),
                  const SizedBox(height: 15),
                ],
                _buildSectionLabel('Mode', context),
                const SizedBox(height: 4),
                _buildValueRow(
                  widget.donation.mode,
                  Icons.local_shipping,
                  context: context,
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('Weight', context),
                const SizedBox(height: 4),
                _buildValueRow(
                  '${widget.donation.weight} ${widget.donation.weightUnit}',
                  Icons.scale,
                  context: context,
                ),
                const SizedBox(height: 15),
                if (widget.donation.mode == 'Pick-up') ...[
                  _buildSectionLabel('Contact Number', context),
                  const SizedBox(height: 4),
                  _buildValueRow(
                    widget.donation.contactNum,
                    Icons.phone,
                    context: context,
                  ),
                  const SizedBox(height: 15),
                ],
                _buildSectionLabel('Date', context),
                const SizedBox(height: 4),
                _buildValueRow(
                  DateFormat('MMMM dd, yyyy').format(widget.donation.date),
                  Icons.calendar_today,
                  context: context,
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('Image', context),
                const SizedBox(height: 8),
                _buildImageContainer(context),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
