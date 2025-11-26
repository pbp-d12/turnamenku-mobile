import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart'; // DIPERLUKAN UNTUK IMAGE HELPER
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart'; // BARU: Custom Snackbar
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';

class ProfilePage extends StatefulWidget {
  // FINAL STRING USERNAME SUDAH DIHAPUS (Sesuai permintaan sebelumnya)
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage; // Tetap dipakai untuk tampilan error di body

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(Endpoints.userProfile);

      if (response['status'] == true) {
        setState(() {
          _profileData = response;
          _isLoading = false;
        });
      } else {
        final String message = response['message'] ?? "Gagal mengambil data";
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
        // BARU: Tampilkan Custom Snackbar Error
        if (context.mounted) {
          CustomSnackbar.show(context, message, SnackbarStatus.error);
        }
      }
    } catch (e) {
      const String message = "Terjadi kesalahan koneksi.";
      // BARU: Tampilkan Custom Snackbar Error
      if (context.mounted) {
        CustomSnackbar.show(context, message, SnackbarStatus.error);
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? drawerUserData;
    if (_profileData != null) {
      drawerUserData = {
        'username': _profileData!['username'],
        'email': _profileData!['email'],
        'role': _profileData!['role'],
        'profile_picture': _profileData!['profile_picture'],
      };
    }

    return Scaffold(
      backgroundColor: AppColors.blue50,
      appBar: AppBar(
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // ACTIONS (Tombol Refresh) DIHAPUS SESUAI PERMINTAAN
      ),
      drawer: LeftDrawer(userData: drawerUserData),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchProfile, // Tombol Coba Lagi tetap ada
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // CARD UTAMA (FOTO & NAMA)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Foto Profil (MENGGUNAKAN HELPER IMAGE YANG ROBUST)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.blue400,
                                width: 3,
                              ),
                            ),
                            // PENGGANTIAN DENGAN HELPER IMAGE
                            child: _buildProfileImage(
                              _profileData!['profile_picture'],
                              50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Username
                          Text(
                            _profileData!['username'] ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Role Badge
                          if (_profileData!['role'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _profileData!['role'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CARD DETAIL INFO
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildDetailTile(
                          Icons.email_outlined,
                          "Email",
                          _profileData!['email'] ?? '-',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildDetailTile(
                          Icons.info_outline,
                          "Bio",
                          _profileData!['bio'] ?? '-',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildDetailTile(
                          Icons.calendar_today_outlined,
                          "Bergabung Sejak",
                          _profileData!['date_joined'] ?? '-',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildDetailTile(
                          Icons.login_outlined,
                          "Login Terakhir",
                          _profileData!['last_login'] ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL EDIT (Placeholder)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profil"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.blue400),
                        foregroundColor: AppColors.blue400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // BARU: Menggunakan Custom Snackbar Info
                        CustomSnackbar.show(
                          context,
                          "Fitur Edit Profil segera hadir!",
                          SnackbarStatus.info,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGET HELPER PROFILE IMAGE (Disalin dari left_drawer.dart/home_page.dart) ---

  Widget _buildProfileImage(String? url, double radius) {
    bool hasUrl = url != null && url.isNotEmpty;

    String? fullUrl;
    if (hasUrl) {
      if (url.startsWith('http')) {
        fullUrl = url;
      } else {
        fullUrl = "${Endpoints.baseUrl}${url.startsWith('/') ? '' : '/'}$url";
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
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage(radius);
                },
              )
            : _buildFallbackImage(radius),
      ),
    );
  }

  Widget _buildFallbackImage(double radius) {
    const String defaultAvatarPath = '/static/images/default_avatar.png';
    final String defaultAvatarUrl = "${Endpoints.baseUrl}$defaultAvatarPath";

    return Image.network(
      defaultAvatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
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

  // --- WIDGET DETAIL BIASA ---

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.blue400, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
