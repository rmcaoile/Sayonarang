import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../../storage_config.dart';

class SliderShowFullmages extends StatefulWidget {
  final List<dynamic> listImagesModel;
  final int current;

  const SliderShowFullmages({
    Key? key,
    required this.listImagesModel,
    required this.current,
  }) : super(key: key);

  @override
  _SliderShowFullmagesState createState() => _SliderShowFullmagesState();
}

class _SliderShowFullmagesState extends State<SliderShowFullmages> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        constraints: const BoxConstraints.expand(
          height: double.infinity,
          width: double.infinity,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            PhotoViewGallery.builder(
              itemCount: widget.listImagesModel.length,
              builder: (BuildContext context, int index) {
                final dynamic image = widget.listImagesModel[index];
                ImageProvider<Object>? imageProvider;
                if (image is String) {
                  if (StorageConfig.useFirebaseStorage) {
                    imageProvider = NetworkImage(image);
                  } else {
                    imageProvider = MemoryImage(base64Decode(image));
                  }
                } else if (image is File) {
                  imageProvider = FileImage(image);
                }
                return PhotoViewGalleryPageOptions(
                  imageProvider: imageProvider!,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: index),
                );
              },
              onPageChanged: (int index) {
                setState(() {
                  _current = index;
                });
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: PageController(initialPage: _current),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    "${_current + 1}/${widget.listImagesModel.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
