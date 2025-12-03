import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  final String? url;
  final double radius;
  final double iconSize;

  const TeamLogo({
    super.key,
    required this.url,
    this.radius = 30,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Kalau URL kosong, pakai Icon Default
    if (url == null || url!.isEmpty) {
      return _buildDefaultIcon();
    }

    // 2. Kalau ada URL, coba load
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: NetworkImage(url!),
      onBackgroundImageError: (_, __) {}, // Supaya gak crash kalau error
      child: Image.network(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (ctx, error, stack) => _buildDefaultIcon(), // Fallback ke icon kalau link rusak
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.groups, size: iconSize, color: Colors.grey[600]), // Icon Orang
    );
  }
}