import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/features/main/screens/profile_page.dart';

class UserSearchDelegate extends SearchDelegate {
  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: Colors.black87, fontSize: 16);

  @override
  String get searchFieldLabel => 'Cari pengguna...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.blue400),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.blue400),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          "Ketik username untuk mencari",
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return _buildSearchBody(context);
  }

  Widget _buildSearchBody(BuildContext context) {
    final request = context.read<CookieRequest>();

    return FutureBuilder(
      future: request.get("${Endpoints.searchProfiles}?q=$query"),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue400),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi kesalahan koneksi."));
        }

        final List<dynamic> data = snapshot.data['data'] ?? [];

        if (data.isEmpty) {
          return Center(
            child: Text(
              "Tidak ditemukan pengguna dengan nama \"$query\"",
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final user = data[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: _buildSmallProfileImage(user['profile_picture']),
              title: Text(
                user['username'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                (user['role'] ?? 'PENGGUNA').toString().toUpperCase(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: user['id']),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSmallProfileImage(String? url) {
    String finalUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        finalUrl = url;
      } else {
        finalUrl = "${Endpoints.baseUrl}${url.startsWith('/') ? '' : '/'}$url";
      }
    } else {
      finalUrl = "${Endpoints.baseUrl}/static/images/default_avatar.png";
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.black,
      ),
      child: ClipOval(
        child: Image.network(
          finalUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) =>
              const Icon(Icons.person, color: Colors.white),
        ),
      ),
    );
  }
}
