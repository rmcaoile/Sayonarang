import 'package:donation_app/screens/shared/image_viewer.dart';
import 'dart:convert';
import 'package:donation_app/storage_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class UserAccountDetails extends StatelessWidget {
  final User user;

  const UserAccountDetails({Key? key, required this.user}) : super(key: key);

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    return ((first.isNotEmpty ? first[0] : '') +
            (second.isNotEmpty ? second[0] : ''))
        .toUpperCase();
  }

  ImageProvider? _getImageProvider() {
    final url = user.profileImageUrl;
    if (url == null || url.isEmpty) return null;
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(url);
    }
    return MemoryImage(base64Decode(url));
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

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDonor = user.role == 'donor';
    final imageProvider = _getImageProvider();

    return Scaffold(
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
                if (!isDonor && user.status != 'approved') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(user.status),
                      borderRadius: BorderRadius.circular(64.0),
                    ),
                    child: Text(
                      'Status: ${user.status}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: imageProvider == null
                            ? null
                            : () {
                                final url = user.profileImageUrl!;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShowFullImage(image: url),
                                  ),
                                );
                              },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  colorScheme.primary,
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? Text(
                                      _getInitials(user.name),
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                      ),
                                    )
                                  : null,
                            ),
                            if (!isDonor && user.status == 'approved')
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (!isDonor) ...[
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.description.isEmpty ? 'Not set' : user.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: user.description.isEmpty
                          ? colorScheme.onSurface.withValues(alpha: 0.4)
                          : colorScheme.onSurface,
                      fontStyle: user.description.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 18),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.phone,
                                size: 18,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user.contactNum.isEmpty
                                      ? 'Not set'
                                      : user.contactNum,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: user.contactNum.isEmpty
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.4)
                                        : colorScheme.onSurface,
                                    fontStyle: user.contactNum.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...user.addresses.map((address) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (user.addresses.isEmpty)
                            Text(
                              'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                if (!isDonor) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Accepting donations:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isOpen ? 'Yes' : 'No',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Proof:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: adminProvider.getProofImageUrl(user.proof),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        final imageUrl = snapshot.data;
                        if (imageUrl != null) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ShowFullImage(image: imageUrl),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: StorageConfig.useFirebaseStorage
                                  ? Image.network(
                                      imageUrl,
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.memory(
                                      base64Decode(imageUrl),
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          );
                        } else {
                          return const Text('Image not found');
                        }
                      }
                    },
                  ),
                ],
                if (!isDonor && user.status == 'pending') ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          adminProvider.updateOrgStatus(user.id!, 'approved');
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          adminProvider.updateOrgStatus(user.id!, 'rejected');
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFE53935),
                        ),
                        child: const Text('Disapprove'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 15),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
