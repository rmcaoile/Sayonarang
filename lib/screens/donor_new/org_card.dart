import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:donation_app/models/user_model.dart' as user_model;
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:donation_app/storage_config.dart';

class OrgCard extends StatelessWidget {
  final user_model.User org;
  final VoidCallback? onTap;

  const OrgCard({
    super.key,
    required this.org,
    this.onTap,
  });

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    return (first.isNotEmpty ? first[0] : '') +
        (second.isNotEmpty ? second[0] : '');
  }

  ImageProvider? _getImageProvider() {
    if (org.profileImageUrl == null || org.profileImageUrl!.isEmpty) {
      return null;
    }
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(org.profileImageUrl!);
    }
    return MemoryImage(base64Decode(org.profileImageUrl!));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Widget _buildAvatar(BuildContext context) {
    final imageProvider = _getImageProvider();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (org.profileImageUrl == null || org.profileImageUrl!.isEmpty) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShowFullImage(image: org.profileImageUrl!),
          ),
        );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: colorScheme.primary,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _getInitials(org.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (org.status == 'approved')
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                spreadRadius: 0,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (org.status != 'approved' && org.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(org.status),
                              borderRadius: BorderRadius.circular(64),
                            ),
                            child: Text(
                              org.status[0].toUpperCase() +
                                  org.status.substring(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (org.status == 'approved')
                      const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '@${org.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      org.description.isEmpty
                          ? 'No description yet.'
                          : org.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                   ],
                  ),
               ),
             ],
           ),
         ),
       ),
     ),
   ),
 );
  }
}
