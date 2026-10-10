import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class QrCodeScreen extends StatelessWidget {
  final String donationId;
  final String status;
  final DateTime timestamp;
  final ScreenshotController screenshotController = ScreenshotController();

  QrCodeScreen({
    Key? key,
    required this.donationId,
    required this.status,
    required this.timestamp,
  }) : super(key: key);

  Future<void> saveImage() async {
    final Uint8List? uint8list = await screenshotController.capture();
    if (uint8list != null) {
      final PermissionStatus status;
      if (await Permission.manageExternalStorage.request().isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        final result = await ImageGallerySaverPlus.saveImage(uint8list);
        if (result['isSuccess']) {
          print('Image Saved to Gallery');
        } else {
          print('Failed to save image: ${result['error']}');
        }
      } else {
        print('Permission to access storage denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> qrData = {
      'donationId': donationId,
      'status': status,
      'timestamp': timestamp.toString(),
    };

    final String finalQrData = jsonEncode(qrData);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF54741),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFF54741)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Screenshot(
              controller: screenshotController,
              child: QrImageView(
                data: finalQrData,
                version: QrVersions.auto,
                gapless: false,
                size: 320,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20.0),
            const Text('Scan QR code'),
            ElevatedButton(
              onPressed: () async {
                await saveImage();
              },
              child: const Text('Save as Image'),
            ),
          ],
        ),
      ),
    );
  }
}
