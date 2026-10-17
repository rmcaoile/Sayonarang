import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:donation_app/models/donation_model.dart';
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:donation_app/storage_config.dart';

class DonationCard extends StatelessWidget {
  final Donation donation;
  final String orgName;
  final VoidCallback? onTap;

  const DonationCard({
    super.key,
    required this.donation,
    required this.orgName,
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
    if (donation.photo.isEmpty) {
      return null;
    }
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(donation.photo);
    }
    return MemoryImage(base64Decode(donation.photo));
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

  Widget _buildAvatar(BuildContext context) {
    final imageProvider = _getImageProvider();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (donation.photo.isEmpty) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShowFullImage(image: donation.photo),
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
                    _getInitials(orgName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
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
                                orgName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(donation.status),
                                borderRadius: BorderRadius.circular(64),
                              ),
                              child: Text(
                                donation.status[0].toUpperCase() +
                                    donation.status.substring(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Donated on ${_formatDate(donation.timestamp)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              donation.mode,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 25),
                            // const Spacer(),
                            const Icon(
                              Icons.scale,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${donation.weight} ${donation.weightUnit}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        // const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: donation.categories.take(3).map((category) {
                            return _buildTruncatedChip(context, category);
                          }).toList(),
                        ),
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

  Widget _buildTruncatedChip(BuildContext context, String text) {
    const maxLength = 20;
    final truncatedText =
        text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;

    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      label: Text(truncatedText),
      backgroundColor: Theme.of(context).colorScheme.primary,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
