import 'package:donation_app/models/donation_model.dart';
import 'package:donation_app/models/drive_model.dart';
import 'package:donation_app/providers/donation_provider.dart';
import 'package:donation_app/providers/drive_provider.dart';
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import "package:firebase_auth/firebase_auth.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';

// TODO: Add loading state for saving and loading image

class OrgDonationFormPage extends StatefulWidget {
  const OrgDonationFormPage({super.key});

  @override
  State<OrgDonationFormPage> createState() => OrgDonationFormPageState();
}

class OrgDonationFormPageState extends State<OrgDonationFormPage> {
  late User? _currentUser;

  late List<String> _categories;
  late TextEditingController _otherCategoriesController;
  late TextEditingController _weightController;
  late String _weightUnit;
  late String _mode;
  late List<TextEditingController> _addressControllers;
  late TextEditingController _contactNumController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late String _photo;
  late String _photoDownloadURL;
  late String _status;
  // late DateTime _timestamp;

  Donation? _selectedDonation;
  String? _driveTitle;
  bool get isViewMode => true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // fetch user details
    _currentUser = FirebaseAuth.instance.currentUser;

    _selectedDonation = context.read<DonationProvider>().selected;

    _categories = _selectedDonation!.categories;
    _otherCategoriesController = TextEditingController();
    _weightController =
        TextEditingController(text: _selectedDonation!.weight.toString());
    _weightUnit = _selectedDonation!.weightUnit;
    _mode = _selectedDonation!.mode;
    _addressControllers = _selectedDonation!.addresses
        .map((address) => TextEditingController(text: address))
        .toList();
    _contactNumController =
        TextEditingController(text: _selectedDonation!.contactNum);
    _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(_selectedDonation!.date));
    _timeController = TextEditingController(text: _selectedDonation!.time);
    _photo = _selectedDonation!.photo;
    _photoDownloadURL = '';
    _status = _selectedDonation!.status;
    // _timestamp = _selectedDonation!.timestamp;

    _loadDownloadURLs();
    _loadDriveTitle();
  }

  @override
  void dispose() {
    _otherCategoriesController.dispose();
    _weightController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _contactNumController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadURLs() async {
    if (_photo != '') {
      if (StorageConfig.useFirebaseStorage) {
        final downloadURL = await context
            .read<DonationProvider>()
            .fetchDownloadURLForImage(_photo);
        setState(() {
          _photoDownloadURL = downloadURL;
        });
      } else {
        try {
          base64Decode(_photo);
          setState(() {
            _photoDownloadURL = _photo;
          });
        } catch (e) {
          print('Invalid base64 image data in donation: $e');
        }
      }
    }
  }

  Future<void> _loadDriveTitle() async {
    String? driveTitle = await context
        .read<DriveProvider>()
        .getDriveTitle(_selectedDonation!.driveId);
    setState(() {
      _driveTitle = driveTitle;
    });
  }

  Future<void> _showDonationDrivesModal(BuildContext context) async {
    // fetch drives
    context.read<DriveProvider>().fetchDrivesByOrg(_currentUser!.uid);

    // access drives in the provider
    final DriveProvider driveProvider =
        Provider.of<DriveProvider>(context, listen: false);

    // get the stream of drives
    Stream<QuerySnapshot> drivesStream = driveProvider.drivesByOrg;

    // show loading indicator while fetching drives
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return const Center(
    //       child: CircularProgressIndicator(),
    //     );
    //   },
    // );

    // listen to the stream for changes
    drivesStream.listen((QuerySnapshot snapshot) {
      // convert data from drives stream to a list
      List<Drive> drives = snapshot.docs.map((doc) {
        Drive drive = Drive.fromJson(doc.data() as Map<String, dynamic>);
        drive.id = doc.id;
        return drive;
      }).toList();

      // filter open drives
      DateTime now = DateTime.now();
      List<Drive> openDrives =
          drives.where((drive) => now.isBefore(drive.endDate)).toList();

      // close loading dialog
      // Navigator.pop(context);

      // show modal only if there are open drives
      if (openDrives.isNotEmpty) {
        showModalBottomSheet<String>(
          context: context,
          builder: (BuildContext context) {
            return ListView.builder(
              itemCount: openDrives.length,
              itemBuilder: (BuildContext context, int index) {
                Drive drive = openDrives[index];
                return ListTile(
                  title: Text(drive.title),
                  onTap: () async {
                    // show confirmation modal
                    bool confirm = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Donation Drive Link'),
                          content: Text(
                              'Are you sure you want to link this donation to ${drive.title}?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(false); // return false on cancel
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(true); // return true on confirm
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        );
                      },
                    );

                    // proceed if confirmed
                    if (confirm == true) {
                      // edit donation status to confirmed and link to drive
                      if (!context.mounted) return; // mounted check
                      // context
                      //     .read<DonationProvider>()
                      //     .editDonationStatus("confirmed");
                      // context.read<DonationProvider>().linkToDrive(drive.id!);
                      context
                          .read<DonationProvider>()
                          .editAndLink("confirmed", drive.id!);

                      Navigator.of(context)
                        ..pop()
                        ..pop();
                    }
                  },
                );
              },
            );
          },
        );
      } else {
        //  no open drives
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No open donation drives!'),
          ),
        );
      }
    });
  }

  void _showDonationStatusModal(String newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          title: const Text('Change Donation Status'),
          content:
              Text('Are you sure you want to change the status to $newStatus?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                context.read<DonationProvider>().editDonationStatus(newStatus);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Successfully edited the donation status!')),
                );

                // TODO: if new status is completed, send notification to donor of donation
                if (newStatus == "confirmed") {
                  await _sendCompletionNotification();
                }

                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendCompletionNotification() async {
    final String donorContactNum = _contactNumController.text;
    final String message =
        "Your donation has been sent to Donation Drive: $_driveTitle. Thank you for your contribution!";

    final Uri smsUri = Uri.parse('smsto:$donorContactNum');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app')),
      );
    }
  }

  void _startQrScan() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: double.infinity,
            height: 300,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                final String code =
                    capture.barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  Navigator.of(context).pop();
                  _handleQRScan(code);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _handleQRScan(String data) {
    // parse the JSON data from the QR code
    Map<String, dynamic> qrData = json.decode(data);

    // check if the 'donationId' key exists in qrData
    if (!qrData.containsKey('donationId')) {
      // if 'donationId' is not present, invalid qr
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code: Donation ID not found.'),
        ),
      );
      return;
    }

    String donationId = qrData['donationId'];

    // check if the donationId matches the selected donation
    if (donationId == _selectedDonation!.id) {
      //ask the user if they want to update the status
      _showDonationStatusModal("completed");
    } else {
      // donationId doesn't match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('The scanned QR code does not match the selected donation.'),
        ),
      );
    }
  }

  Widget _buildImageContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Image (optional)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          if (_photoDownloadURL != '')
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShowFullImage(
                      image: _photoDownloadURL,
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
                        ? NetworkImage(_photoDownloadURL)
                        : MemoryImage(base64Decode(_photoDownloadURL))
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (_photoDownloadURL == '')
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey[200],
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: Colors.grey[400],
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required BuildContext context,
    required String type, // text, date, time
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
              // not needed for org view
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

  @override
  Widget build(BuildContext context) {
    String buttonText = "";
    VoidCallback? onPressed;

    if (_status == "pending") {
      buttonText = "Link to a Donation Drive";
      onPressed = () => _showDonationDrivesModal(context);
    } else if (_status == "confirmed" && _mode == "Pick-up") {
      buttonText = "Schedule for Pick-up";
      onPressed = () => _showDonationStatusModal("scheduled for pick-up");
    } else if (_status == "scheduled for pick-up") {
      buttonText = "Complete";
      onPressed = () => _showDonationStatusModal("completed");
    } else if (_status == "confirmed" && _mode == "Drop-off") {
      buttonText = "Complete";
      onPressed = () => _startQrScan();
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
        "View Donation Details",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      )),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      ..._categories.map((option) {
                        return CheckboxListTile(
                          enabled: !isViewMode,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(option),
                          value: _categories.contains(option),
                          onChanged: (newValue) {
                            setState(() {
                              if (newValue!) {
                                _categories.add(option);
                              } else {
                                _categories.remove(option);
                              }
                            });
                          },
                        );
                      }).toList()
                    ])),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFormField(
                    context: context,
                    type: 'number',
                    label: 'Weight',
                    controller: _weightController,
                    enabled: !isViewMode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter weight';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _weightUnit,
                    onChanged: isViewMode
                        ? null
                        : (newValue) {
                            setState(() {
                              _weightUnit = newValue!;
                            });
                          },
                    items: <String>['kg', 'lbs'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode of Transfer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text('Pick-up'),
                    value: 'Pick-up',
                    groupValue: _mode,
                    onChanged: isViewMode
                        ? null
                        : (value) {
                            setState(() {
                              _mode = value as String;
                            });
                          },
                  ),
                  RadioListTile<String>(
                    title: const Text('Drop-off'),
                    value: 'Drop-off',
                    groupValue: _mode,
                    onChanged: isViewMode
                        ? null
                        : (value) {
                            setState(() {
                              _mode = value as String;
                            });
                          },
                  ),
                ],
              ),
            ),
            if (_mode == 'Pick-up') ...[
              ..._addressControllers.map((controller) {
                final int index = _addressControllers.indexOf(controller);
                return Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        context: context,
                        type: 'text',
                        label: 'Address ${index + 1}',
                        controller: controller,
                        enabled: !isViewMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an address';
                          }
                          return null;
                        },
                        minLines: 1,
                        maxLines: null,
                      ),
                    ),
                  ],
                );
              }).toList(),
              _buildFormField(
                context: context,
                type: 'text',
                label: 'Contact Number',
                controller: _contactNumController,
                enabled: !isViewMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
            ],
            _buildFormField(
              context: context,
              type: 'date',
              label: 'Date of Pick-up/Drop-off',
              controller: _dateController,
              enabled: !isViewMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter date of pick-up/drop-off';
                }
                return null;
              },
              minLines: 1,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            const SizedBox(height: 8),
            _buildFormField(
              context: context,
              type: 'time',
              label: 'Time of Pick-up/Drop-off',
              controller: _timeController,
              enabled: !isViewMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter time of pick-up/drop-off';
                }
                return null;
              },
              minLines: 1,
              suffixIcon: const Icon(Icons.access_time),
            ),
            const SizedBox(height: 8),
            _buildImageContainer(),
            const SizedBox(height: 8),
            if (_status != 'completed' && _status != 'cancelled')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
