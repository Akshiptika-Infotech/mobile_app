import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Round avatar for dashboard headers. Renders the user's profile image when
/// [imageUrl] is non-null, otherwise the [fallback] (typically an icon or
/// initial letter). Falls back gracefully if the image fails to load.
class DashboardAvatar extends StatelessWidget {
  const DashboardAvatar({
    super.key,
    required this.imageUrl,
    required this.fallback,
    required this.backgroundColor,
    this.radius = 20,
    this.onTap,
  });

  final String? imageUrl;
  final Widget fallback;
  final Color backgroundColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: imageUrl == null
          ? fallback
          : ClipOval(
              child: SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(child: fallback),
                  errorWidget: (_, __, ___) => Center(child: fallback),
                ),
              ),
            ),
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }

    return avatar;
  }
}
