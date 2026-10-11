import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:donation_app/utils/image_compression.dart';

class PickImage extends StatefulWidget {
  final Function(String) onImagePicked;

  const PickImage({Key? key, required this.onImagePicked}) : super(key: key);

  @override
  State<PickImage> createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  File? _selectedImage;
  //String? _imageUrl;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _selectedImage != null
            ? Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: const Text("Gallery"),
            ),
            ElevatedButton(
              onPressed: _pickImageFromCamera,
              child: const Text("Camera"),
            ),
          ],
        ),
        if (_uploading) const CircularProgressIndicator(),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _uploading = true;
    });

    await _uploadImageToFirebaseStorage(_selectedImage!);
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _uploading = true;
    });

    await _uploadImageToFirebaseStorage(_selectedImage!);
  }

  Future<void> _uploadImageToFirebaseStorage(File imageFile) async {
    try {
      String result;
      if (StorageConfig.useFirebaseStorage) {
        String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        result = fileName;
      } else {
        // base64 in Firestore
        final compressedBytes = await ImageCompressionUtil.compressImage(imageFile);
        result = base64Encode(compressedBytes);
      }

      setState(() {
        _uploading = false;
      });

      widget.onImagePicked(result);
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      print('Error uploading image: $e');
    }
  }
}
