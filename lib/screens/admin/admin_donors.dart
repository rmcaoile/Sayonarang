import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donation_app/models/user_model.dart';
import 'package:donation_app/providers/admin_provider.dart';
import 'package:donation_app/screens/admin/admin_user_page.dart';
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:donation_app/storage_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewDonors extends StatefulWidget {
  const ViewDonors({Key? key}) : super(key: key);

  @override
  State<ViewDonors> createState() => _ViewDonorsState();
}

class _ViewDonorsState extends State<ViewDonors> {
  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    return (first.isNotEmpty ? first[0] : '') +
        (second.isNotEmpty ? second[0] : '');
  }

  ImageProvider? _getImageProvider(User donor) {
    if (donor.profileImageUrl == null || donor.profileImageUrl!.isEmpty) {
      return null;
    }
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(donor.profileImageUrl!);
    }
    return MemoryImage(base64Decode(donor.profileImageUrl!));
  }

  Widget _buildAvatar(BuildContext context, User donor) {
    final imageProvider = _getImageProvider(donor);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (donor.profileImageUrl == null || donor.profileImageUrl!.isEmpty) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShowFullImage(image: donor.profileImageUrl!),
          ),
        );
      },
      child: CircleAvatar(
        radius: 34,
        backgroundColor: colorScheme.primary,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                _getInitials(donor.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDonorCard(User donor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserPage(user: donor),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context, donor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '@${donor.username}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> donorsStream =
        context.watch<AdminProvider>().donorList;

    return Scaffold(
      body: StreamBuilder(
        stream: donorsStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error encountered! ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No donors yet!',
                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              User donor = User.fromJson(
                  snapshot.data!.docs[index].data() as Map<String, dynamic>);
              donor.id = snapshot.data!.docs[index].id;

              return _buildDonorCard(donor);
            },
          );
        },
      ),
    );
  }
}
