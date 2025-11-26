import 'package:flutter/material.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cek validitas URL
    bool hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    String? fullUrl;

    if (hasUrl) {
      if (imageUrl!.startsWith('http')) {
        fullUrl = imageUrl;
      } else {
        // Tambahkan Base URL jika relative path (misal: /media/...)
        fullUrl =
            "${Endpoints.baseUrl}${imageUrl!.startsWith('/') ? '' : '/'}$imageUrl";
      }
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                fullUrl!,
                fit: BoxFit.cover,
                // Loading Builder (Spinner saat gambar loading)
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius,
                      height: radius,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                // Error Builder -> Fallback ke Default Image
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage();
                },
              )
            : _buildFallbackImage(), // Null URL -> Fallback
      ),
    );
  }

  // Helper internal untuk fallback image
  Widget _buildFallbackImage() {
    // Path gambar default dari Django
    const String defaultAvatarPath = '/static/images/default_avatar.png';
    final String defaultAvatarUrl = "${Endpoints.baseUrl}$defaultAvatarPath";

    return Image.network(
      defaultAvatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback terakhir: Icon Lokal (Jika server down/gambar default hilang)
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            size: radius * 1.2,
            color: AppColors.blue400,
          ),
        );
      },
    );
  }
}
