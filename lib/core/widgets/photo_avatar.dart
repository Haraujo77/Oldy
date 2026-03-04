import 'dart:io';
import 'package:flutter/material.dart';

class PhotoAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? localPath;
  final String fallbackLetter;
  final double radius;
  final bool editable;
  final VoidCallback? onTap;

  const PhotoAvatar({
    super.key,
    this.photoUrl,
    this.localPath,
    required this.fallbackLetter,
    this.radius = 48,
    this.editable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar;
    if (localPath != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(localPath!)),
      );
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    } else {
      avatar = _fallbackAvatar(theme);
    }

    if (!editable) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: radius * 0.3,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        fallbackLetter.isNotEmpty ? fallbackLetter[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
