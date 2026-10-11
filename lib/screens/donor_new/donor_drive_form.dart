import "package:donation_app/models/donation_model.dart";
import "package:donation_app/models/drive_model.dart";
import "package:donation_app/providers/donation_provider.dart";
import "package:donation_app/providers/drive_provider.dart";
import "package:donation_app/screens/shared/image_slider.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "package:cloud_firestore/cloud_firestore.dart";

// TODO: Add loading state for saving and loading images
import 'dart:convert';
import '../../storage_config.dart';
// TODO: Add snackbar to show successfully edited or successfully saved

class DonorDriveFormPage extends StatefulWidget {
  final String mode; // add, edit, view
  const DonorDriveFormPage({super.key, required this.mode});

  @override
  State<DonorDriveFormPage> createState() => DonorDriveFormPageState();
}

class DonorDriveFormPageState extends State<DonorDriveFormPage> {
  late User? _currentUser;
  late DocumentSnapshot? _driveDoc;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _endDateController;
  // late List<String> _donationIds;
  late List<String> _photos = [];
  late List<String> _photosDownloadURLs = [];

  Donation? _selectedDonation;
  bool get isViewMode => widget.mode == "view";
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    _selectedDonation = context.read<DonationProvider>().selected;

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _endDateController = TextEditingController();
    // _donationIds = [];
    _photos = [];
    _photosDownloadURLs = [];

    if (_currentUser != null) {
      // fetch drive using driveId of selected donation
      _fetchDrive(_selectedDonation!.driveId);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchDrive(String driveId) async {
    _driveDoc = await context.read<DriveProvider>().getDriveById(driveId);
    setState(() {
      _initializeFormFields();
      _loadDownloadURLs();
    });
  }

  void _initializeFormFields() {
    final driveData = Drive.fromJson(_driveDoc!.data() as Map<String, dynamic>);

    _titleController = TextEditingController(text: driveData.title);
    _descriptionController = TextEditingController(text: driveData.description);
    _endDateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(driveData.endDate));
    _photos = driveData.photos;
    _loadDownloadURLs();
  }

  Future<void> _loadDownloadURLs() async {
    if (widget.mode == "edit" || widget.mode == "view") {
      if (StorageConfig.useFirebaseStorage) {
        List<String> downloadURLs = await context
            .read<DriveProvider>()
            .fetchDownloadURLsForImages(_photos);
        setState(() {
          _photosDownloadURLs = downloadURLs;
        });
      } else {
        List<String> validPhotos = [];
        for (String photo in _photos) {
          try {
            base64Decode(photo);
            validPhotos.add(photo);
          } catch (e) {
            print('Invalid base64 image data: $e');
          }
        }
        setState(() {
          _photosDownloadURLs = validPhotos;
        });
      }
    }
  }

  Widget _buildFormField({
    required BuildContext context,
    required type, // text, date, time
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required String? Function(String?) validator,
    int minLines = 1,
    int? maxLines,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            minLines: minLines,
            maxLines: maxLines,
            onTap: () {
              // not needed for donor view
              // if (type == 'date') {
              //   _showDatePicker(context, controller);
              // } else if (type == 'time') {
              //   _showTimePicker(context, controller);
              // }
            },
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              alignLabelWithHint: true,
              suffixIcon: suffixIcon,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1.0,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    List<dynamic> images = [..._photosDownloadURLs];

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
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
              child: images.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return Stack(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SliderShowFullmages(
                                        listImagesModel: images,
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
                                              as ImageProvider
                                          : MemoryImage(
                                              base64Decode(image))
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: Text(
        "${widget.mode == "add" ? "Add" : widget.mode == "edit" ? "Edit" : "View"} Donation Drive ${widget.mode == "view" ? "Details" : ""}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      )),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormField(
                context: context,
                type: 'text',
                label: 'Title',
                controller: _titleController,
                enabled: !isViewMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              _buildFormField(
                context: context,
                type: 'text',
                label: 'Description',
                controller: _descriptionController,
                enabled: !isViewMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                minLines: 5,
                maxLines: null,
              ),
              _buildFormField(
                  context: context,
                  type: 'date',
                  label: 'End Date',
                  controller: _endDateController,
                  enabled: !isViewMode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an end date';
                    }
                    return null;
                  },
                  minLines: 1,
                  suffixIcon: const Icon(Icons.calendar_today)),
              const SizedBox(height: 8),
              _buildImageGrid(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
