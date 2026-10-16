import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:donation_app/storage_config.dart';

class OrgProfileHeader extends StatelessWidget {
  final String orgName;
  final String username;
  final String contactNum;
  final String description;
  final List<String> addresses;
  final String status;
  final bool isOpen;
  final String? profileImageUrl;
  final bool isEditing;
  final VoidCallback? onEditPressed;
  final VoidCallback? onImageTap;
  final VoidCallback? onImageViewTap;
  final VoidCallback? onAddAddress;
  final void Function(int)? onRemoveAddress;
  final TextEditingController? nameController;
  final TextEditingController? usernameController;
  final TextEditingController? descriptionController;
  final TextEditingController? contactController;
  final List<TextEditingController>? addressControllers;
  final void Function(bool)? onIsOpenChanged;

  const OrgProfileHeader({
    super.key,
    required this.orgName,
    required this.username,
    required this.contactNum,
    required this.description,
    required this.addresses,
    required this.status,
    required this.isOpen,
    this.profileImageUrl,
    this.isEditing = false,
    this.onEditPressed,
    this.onImageTap,
    this.onImageViewTap,
    this.onAddAddress,
    this.onRemoveAddress,
    this.nameController,
    this.usernameController,
    this.descriptionController,
    this.contactController,
    this.addressControllers,
    this.onIsOpenChanged,
  });

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final second = words.length > 1 ? words[1] : '';
    return (first.isNotEmpty ? first[0] : '') +
        (second.isNotEmpty ? second[0] : '');
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

  Widget _buildAvatar(BuildContext context, String status) {
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
                    _getInitials(orgName),
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
            )
          else if (status == 'approved')
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
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
    );
  }

  Widget _buildViewField({
    required String label,
    required String value,
    required BuildContext context,
    IconData? icon,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? 'Not set' : value,
                style: TextStyle(
                  fontSize: 16,
                  color: value.isEmpty
                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                      : colorScheme.onSurface,
                  fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabledLabelColor = colorScheme.onSurface.withValues(alpha: 0.4);
    final disabledTextColor = colorScheme.onSurface.withValues(alpha: 0.5);
    final disabledFillColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.15);
    final disabledBorderColor = colorScheme.outline.withValues(alpha: 0.3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? colorScheme.onSurface.withValues(alpha: 0.6) : disabledLabelColor,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: enabled ? colorScheme.outline : disabledBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: enabled ? colorScheme.outline.withValues(alpha: 0.5) : disabledBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: disabledBorderColor),
            ),
            filled: true,
            fillColor: enabled ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : disabledFillColor,
          ),
          style: TextStyle(fontSize: 16, color: enabled ? colorScheme.onSurface : disabledTextColor),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color getStatusColor(String status) {
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
          if (!isEditing && status != 'approved') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(status),
                borderRadius: BorderRadius.circular(64.0),
              ),
              child: Text(
                'Status: $status',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(context, status),
                    const SizedBox(height: 8),
                    Text(
                      orgName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isEditing) ...[
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
                    : status == 'approved' && onEditPressed != null
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
              enabled: false,
            ),
            _buildEditField(
              label: 'Username',
              controller: usernameController!,
              context: context,
              enabled: false,
            ),
            _buildEditField(
              label: 'Description',
              controller: descriptionController!,
              context: context,
              enabled: true,
              maxLines: 5,
            ),
            _buildEditField(
              label: 'Contact Number',
              controller: contactController!,
              context: context,
              enabled: true,
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
            }).toList(),
            // const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Address'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you accepting donations?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(children: [
                    const Text("No"),
                    const SizedBox(width: 4),
                    Switch(
                        value: isOpen,
                        onChanged: onIsOpenChanged,
                        activeColor: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    const Text("Yes"),
                  ]),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            _buildViewField(
              context: context,
              label: 'Description',
              value: description,
              icon: null,
            ),
            if (contactNum.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildViewField(
                context: context,
                label: 'Contact Number',
                value: contactNum,
                icon: Icons.phone,
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
              _buildViewField(
                context: context,
                label: 'Addresses',
                value: '',
                icon: null,
              ),
          ],
        ],
      ),
    );
  }
}
