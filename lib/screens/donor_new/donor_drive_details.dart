import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/drive_provider.dart';
import 'package:donation_app/screens/donor_new/donor_donation_form.dart';
import 'package:donation_app/screens/shared/image_slider.dart';
import 'package:donation_app/storage_config.dart';

class DonorDriveDetailsPage extends StatefulWidget {
  final Drive drive;
  final String userName;

  const DonorDriveDetailsPage({
    Key? key,
    required this.drive,
    required this.userName,
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_photosDownloadURLs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            'No images available',
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
          "Images",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.grey[200],
          ),
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _photosDownloadURLs.length,
              itemBuilder: (context, index) {
                final image = _photosDownloadURLs[index];
                return InkWell(
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: StorageConfig.useFirebaseStorage
                            ? NetworkImage(image)
                            : MemoryImage(base64Decode(image))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
        backgroundColor:
            const Color(0xFFF54741).withValues(alpha: 0.12),
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
                  children: [
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: Text(
                        _orgInitials(widget.userName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
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
                        _buildImageGrid(),
                      ],
                    ),
                   ],
                 ),
               ),
             ),
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
