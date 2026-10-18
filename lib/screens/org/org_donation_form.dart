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
import 'dart:async';
import 'package:donation_app/storage_config.dart';
import 'package:donation_app/providers/user_provider.dart';

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

  StreamSubscription? _drivesSubscription;

  Donation? _selectedDonation;
  String? _driveTitle;
  String _donorName = 'Donor';
  String? _donorProfileImageUrl;
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

    _loadDownloadURLs();
    _loadDriveTitle();
    _loadDonorDetails();
  }

  Future<void> _loadDonorDetails() async {
    try {
      final details = await context
          .read<MyAuthProvider>()
          .getUserDetails(_selectedDonation!.donorId);
      if (!mounted) return;
      setState(() {
        _donorName = details['name'] as String? ?? 'Donor';
        _donorProfileImageUrl = details['profileImageUrl'] as String?;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _drivesSubscription?.cancel();
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
    // cancel any existing subscription before creating a new one
    _drivesSubscription?.cancel();

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
    _drivesSubscription = drivesStream.listen((QuerySnapshot snapshot) {
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

                      // cancel subscription to prevent further stream events
                      _drivesSubscription?.cancel();

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
    final url = _donorProfileImageUrl;
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
              final url = _donorProfileImageUrl!;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShowFullImage(image: url),
                ),
              );
            },
      child: CircleAvatar(
        radius: 52,
        backgroundColor: colorScheme.primary,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                _getInitials(_donorName),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
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
        Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
    if (_photoDownloadURL == '') {
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
            builder: (context) => ShowFullImage(image: _photoDownloadURL),
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
                : MemoryImage(base64Decode(_photoDownloadURL)) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
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

    final colorScheme = Theme.of(context).colorScheme;
    final donation = _selectedDonation!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Donation Details",
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
                                'Donor:',
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
                                  _donorName,
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
                      child: _buildStatusBadge(donation.status),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSectionLabel('Donation Drive', context),
                const SizedBox(height: 4),
                FutureBuilder<String?>(
                  future: context.read<DriveProvider>().getDriveTitle(donation.driveId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return _buildValueRow(snapshot.data!, Icons.local_offer,
                          context: context);
                    } else {
                      return _buildValueRow('No Donation Drive', Icons.local_offer,
                          context: context);
                    }
                  },
                ),
                const SizedBox(height: 15),
                _buildSectionLabel('Categories', context),
                const SizedBox(height: 8),
                ...donation.categories.map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildValueRow(category, Icons.category,
                          context: context),
                    )),
                const SizedBox(height: 15),
                if (donation.mode == 'Pick-up') ...[
                  _buildSectionLabel('Addresses', context),
                  const SizedBox(height: 8),
                  ...donation.addresses.map((address) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildValueRow(address, Icons.location_on,
                            context: context),
                      )),
                  const SizedBox(height: 15),
                ],
                _buildSectionLabel('Mode', context),
                const SizedBox(height: 4),
                _buildValueRow(donation.mode, Icons.local_shipping,
                    context: context),
                const SizedBox(height: 15),
                _buildSectionLabel('Weight', context),
                const SizedBox(height: 4),
                _buildValueRow('${donation.weight} ${donation.weightUnit}',
                    Icons.scale, context: context),
                const SizedBox(height: 15),
                if (donation.mode == 'Pick-up') ...[
                  _buildSectionLabel('Contact Number', context),
                  const SizedBox(height: 4),
                  _buildValueRow(donation.contactNum, Icons.phone,
                      context: context),
                  const SizedBox(height: 15),
                ],
                _buildSectionLabel('Date', context),
                const SizedBox(height: 4),
                _buildValueRow(
                    DateFormat('MMMM dd, yyyy').format(donation.date),
                    Icons.calendar_today,
                    context: context),
                const SizedBox(height: 15),
                _buildSectionLabel('Image', context),
                const SizedBox(height: 8),
                _buildImageContainer(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_status != 'completed' && _status != 'cancelled')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    backgroundColor: colorScheme.primary,
                  ),
                  child: Text(buttonText),
                ),
              ),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
