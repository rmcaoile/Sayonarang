import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/drive_provider.dart';
import 'package:donation_app/screens/donor_new/donor_donation_form.dart';
import 'package:donation_app/screens/shared/image_slider.dart';
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:donation_app/storage_config.dart';

class DonorDriveDetailsPage extends StatefulWidget {
  final Drive drive;
  final String userName;
  final String? profileImageUrl;
  final String status;
  final bool showDonateButton;

  const DonorDriveDetailsPage({
    Key? key,
    required this.drive,
    required this.userName,
    this.profileImageUrl,
    this.status = '',
    this.showDonateButton = false,
  }) : super(key: key);

  @override
  State<DonorDriveDetailsPage> createState() => _DonorDriveDetailsPageState();
}

class _DonorDriveDetailsPageState extends State<DonorDriveDetailsPage> {
  List<String> _photosDownloadURLs = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadURLs();
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

  String _orgInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    final initials =
        (first.isNotEmpty ? first[0] : '') + (second.isNotEmpty ? second[0] : '');
    return initials.toUpperCase();
  }

  ImageProvider? _getImageProvider() {
    if (widget.profileImageUrl == null ||
        widget.profileImageUrl!.isEmpty) {
      return null;
    }
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(widget.profileImageUrl!);
    }
    return MemoryImage(base64Decode(widget.profileImageUrl!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.drive.title,
          style: const TextStyle(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        if (widget.profileImageUrl == null ||
                            widget.profileImageUrl!.isEmpty) {
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShowFullImage(
                              image: widget.profileImageUrl!,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundImage: _getImageProvider(),
                            child: _getImageProvider() == null
                                ? Text(
                                    _orgInitials(widget.userName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          if (widget.status == 'approved')
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
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.drive.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'By: ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                widget.drive.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 15),
                            Text(
                              DateFormat('MMMM dd, yyyy')
                                  .format(widget.drive.endDate),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Images",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImageGrid(),
                      ],
                    ),
                   ],
                 ),
               ),
             ),

              if (widget.showDonateButton)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Donate Now'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
