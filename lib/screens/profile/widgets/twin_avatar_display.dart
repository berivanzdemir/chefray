import 'package:flutter/material.dart';

/// Avatar PNG display with responsive height.
/// Uses LayoutBuilder to scale the avatar proportionally.
class TwinAvatarDisplay extends StatelessWidget {
  final String avatarPath;
  final double height;

  const TwinAvatarDisplay({
    super.key,
    required this.avatarPath,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      avatarPath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
