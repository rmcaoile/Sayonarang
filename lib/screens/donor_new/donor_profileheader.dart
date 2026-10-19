import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:donation_app/storage_config.dart';

class ProfileHeader extends StatelessWidget {
  final String donorName;
  final String username;
  final String contactNum;
  final List<String> addresses;
  final String? profileImageUrl;
  final bool isEditing;
  final VoidCallback? onEditPressed;
  final VoidCallback? onImageTap;
  final VoidCallback? onImageViewTap;
  final VoidCallback? onAddAddress;
  final void Function(int)? onRemoveAddress;
  final TextEditingController? nameController;
  final TextEditingController? usernameController;
  final TextEditingController? contactController;
  final List<TextEditingController>? addressControllers;

  const ProfileHeader({
    super.key,
    required this.donorName,
    required this.username,
    required this.contactNum,
    required this.addresses,
    this.profileImageUrl,
    this.isEditing = false,
    this.onEditPressed,
    this.onImageTap,
    this.onImageViewTap,
    this.onAddAddress,
    this.onRemoveAddress,
    this.nameController,
    this.usernameController,
    this.contactController,
    this.addressControllers,
  });

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    final initials =
        (first.isNotEmpty ? first[0] : '') + (second.isNotEmpty ? second[0] : '');
    return initials.toUpperCase();
  }

  ImageProvider? _getImageProvider() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return null;
    }
    if (StorageConfig.useFirebaseStorage) {
      return NetworkImage(profileImageUrl!);
    }
    return MemoryImage(base64Decode(profileImageUrl!));
  }

  Widget _buildAvatar(BuildContext context) {
    final imageProvider = _getImageProvider();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isEditing ? onImageTap : onImageViewTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _getInitials(donorName),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  )
                : null,
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewField({
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Not set' : value,
          style: TextStyle(
            fontSize: 16,
            color: value.isEmpty
                ? colorScheme.onSurface.withValues(alpha: 0.4)
                : colorScheme.onSurface,
            fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(context),
                    const SizedBox(height: 8),
                    Text(
                      donorName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isEditing) ...[
                      // const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: isEditing
                    ? IconButton(
                        onPressed: onEditPressed,
                        icon: const Icon(Icons.check, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      )
                    : onEditPressed != null
                        ? IconButton(
                            onPressed: onEditPressed,
                            icon: const Icon(Icons.edit, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              foregroundColor: colorScheme.onSurface,
                            ),
                          )
                        : const SizedBox(width: 48, height: 48),
              ),
            ],
          ),

          if (isEditing) ...[
            const SizedBox(height: 18),
            _buildEditField(
              label: 'Name',
              controller: nameController!,
              context: context,
            ),
            _buildEditField(
              label: 'Username',
              controller: usernameController!,
              context: context,
            ),
            _buildEditField(
              label: 'Contact Number',
              controller: contactController!,
              context: context,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Text(
              'Addresses',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            ...addressControllers!.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintText: 'Address ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                      ),
                    ),
                    if (addressControllers!.length > 1)
                      IconButton(
                        onPressed: () => onRemoveAddress?.call(index),
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                      ),
                  ],
                ),
              );
            }),
            // const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Address'),
            ),
          ] else ...[
            if (contactNum.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Contact Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.phone,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contactNum,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 18),
              _buildViewField(
                label: 'Contact Number',
                value: '',
                context: context,
              ),
            ],
            if (addresses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Addresses',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...addresses.map((address) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                ],
              )
            ] else
              // const SizedBox(height: 12),
              _buildViewField(
                label: 'Addresses',
                value: '',
                context: context,
              ),
          ],
        ],
      ),
    );
  }
}
