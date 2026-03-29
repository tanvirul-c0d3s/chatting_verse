import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl.isEmpty
            ? const LinearGradient(
          colors: [Color(0xFF6A5AE0), Color(0xFF8F94FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: radius,
        )
            : CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A5AE0), Color(0xFF8F94FB)],
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: radius,
            ),
          ),
        ),
      ),
    );
  }
}