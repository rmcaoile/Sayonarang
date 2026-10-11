import "package:donation_app/models/drive_model.dart";
import "package:donation_app/providers/drive_provider.dart";
import "package:donation_app/screens/shared/image_slider.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import 'dart:io';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:image_picker/image_picker.dart';

// TODO: Add loading state for saving and loading images

class OrgDriveFormPage extends StatefulWidget {
  final String mode; // add, edit, view
  const OrgDriveFormPage({super.key, required this.mode});

  @override
  State<OrgDriveFormPage> createState() => OrgDriveFormPageState();
}

class OrgDriveFormPageState extends State<OrgDriveFormPage> {
  late User? _currentUser;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _endDateController;
  late List<String> _donationIds;
  late List<String> _photos;
  late List<String> _photosDownloadURLs;
  List<String> _deletedPhotos =
      []; // to keep track of the deleted photos deleted by the user when editing

  List<File> _selectedFiles = [];
  final _picker = ImagePicker();

  Drive? _selectedDrive;
  bool get isViewMode => widget.mode == "view";
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // fetch user details
    _currentUser = FirebaseAuth.instance.currentUser;

    if (widget.mode == "edit" || widget.mode == "view") {
      _selectedDrive = context.read<DriveProvider>().selected;

      _titleController = TextEditingController(text: _selectedDrive!.title);
      _descriptionController =
          TextEditingController(text: _selectedDrive?.description);
      _endDateController = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(_selectedDrive!.endDate));
      _donationIds = _selectedDrive!.donationIds;
      _photos = _selectedDrive!
          .photos; // filenames of the images from firebase storage
      _photosDownloadURLs = [];
      // fetch download URLs for images
      _loadDownloadURLs();
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _endDateController = TextEditingController();
      _donationIds = [];
      _photos = [];
      _photosDownloadURLs = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _endDateController.dispose();
    super.dispose();
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
            print('Invalid base64 image data in drive: $e');
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
              if (type == 'date') {
                _showDatePicker(context, controller);
              } else if (type == 'time') {
                _showTimePicker(context, controller);
              }
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

  void _showDatePicker(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  void _showTimePicker(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!context.mounted) return; // mounted check
    if (pickedTime != null) {
      controller.text = pickedTime.format(context);
    }
  }

  Future<bool?> _showBackDialog() {
    if (isViewMode) {
      // return true immediately if in view mode
      return Future.value(true);
    }
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          title: const Text('Are you sure you want to leave?'),
          content: const Text('Any unsaved changes will be lost.'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getImages() async {
    final pickedFile = await _picker.pickMultiImage(
        imageQuality: 100, maxHeight: 1000, maxWidth: 1000);
    List<XFile> xfilePick = pickedFile;

    setState(
      () {
        if (xfilePick.isNotEmpty) {
          for (var i = 0; i < xfilePick.length; i++) {
            _selectedFiles.add(File(xfilePick[i].path));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nothing is selected')));
        }
      },
    );
  }

  Widget _buildImageGrid() {
    List<dynamic> images = [..._photosDownloadURLs, ..._selectedFiles];

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
                                          image: image is File
                                            ? FileImage(image)
                                            : StorageConfig.useFirebaseStorage
                                                ? NetworkImage(image)
                                                : MemoryImage(
                                                    base64Decode(image))
                                                    as ImageProvider,
                                       fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isViewMode)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (image is File) {
                                          _selectedFiles.remove(image);
                                        } else if (image is String) {
                                          int deleteIndex = _photosDownloadURLs
                                              .indexOf(image);
                                          _photos.removeAt(deleteIndex);
                                          _deletedPhotos.add(
                                              _photosDownloadURLs[deleteIndex]);
                                          _photosDownloadURLs
                                              .removeAt(deleteIndex);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
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

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showBackDialog() ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                if (!isViewMode) ...[
                  _buildImageGrid(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              getImages();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            icon: const Icon(Icons.image_search),
                            label: const Text('Select Images From Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (widget.mode == "add") {
                              if (_selectedFiles.isNotEmpty) {
                                List<String> fileNames = await context
                                    .read<DriveProvider>()
                                    .uploadFiles(_selectedFiles);

                                Drive drive = Drive(
                                  orgId: _currentUser!.uid,
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  endDate: DateFormat('yyyy-MM-dd')
                                      .parse(_endDateController.text),
                                  donationIds: _donationIds,
                                  photos:
                                      fileNames, // convert File objects to paths
                                );

                                if (!context.mounted) return; // mounted check
                                context.read<DriveProvider>().addDrive(drive);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Successfully created a new donation drive!')),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please select at least one image'),
                                  ),
                                );
                              }
                            } else if (widget.mode == "edit") {
                              if (_selectedFiles.isNotEmpty ||
                                  _photos.isNotEmpty) {
                                List<String> fileNames = [];
                                if (_selectedFiles.isNotEmpty) {
                                  fileNames = await context
                                      .read<DriveProvider>()
                                      .uploadFiles(_selectedFiles);
                                }

                                // delete files only if there are photos to delete
                                if (_deletedPhotos.isNotEmpty) {
                                  if (!context.mounted) return; // mounted check

                                  context
                                      .read<DriveProvider>()
                                      .deleteFiles(_deletedPhotos);
                                }

                                // merge existing photos and newly uploaded files
                                List<String> updatedPhotos =
                                    _photos + fileNames;

                                if (!context.mounted) return; // mounted check
                                context.read<DriveProvider>().editDrive(
                                      _titleController.text,
                                      _descriptionController.text,
                                      DateFormat('yyyy-MM-dd')
                                          .parse(_endDateController.text),
                                      updatedPhotos,
                                    );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Successfully edited the donation drive!')),
                                );

                                // TODO: find fix for when going back to the view details page from edit, the details page is updated
                                // current solution is to pop twice to go back to the donation drives page
                                // https://stackoverflow.com/a/74316628
                                Navigator.of(context)
                                  ..pop()
                                  ..pop(); // kanta ni nayeon hahahaha
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select at least one image',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ),
                ],
                if (isViewMode) ...[
                  _buildImageGrid(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrgDriveFormPage(mode: "edit"),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // cannot delete donation drive if there are linked donations
                              if (_donationIds.isEmpty) {
                                context.read<DriveProvider>().deleteDrive();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Successfully deleted donation drive!')),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Cannot delete donation drive with donation!')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
