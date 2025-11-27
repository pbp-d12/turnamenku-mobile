import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/main/screens/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final int? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final request = context.read<CookieRequest>();

    String url = Endpoints.userProfile;
    if (widget.userId != null) {
      url += '?id=${widget.userId}';
    }

    try {
      final response = await request.get(url);

      if (response['status'] == 'success') {
        setState(() {
          profileData = response['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? "Gagal mengambil data.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Terjadi kesalahan koneksi.";
        isLoading = false;
      });
    }
  }

  Widget _buildProfileImage(String? url, double radius) {
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
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue100, width: 4),
        color: Colors.black,
      ),
      child: ClipOval(
        child: Image.network(
          finalUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: Icon(Icons.person, size: radius, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyProfile = widget.userId == null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.blue400,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: isMyProfile ? LeftDrawer(userData: profileData) : null,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blue400),
            )
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 672),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(profileData!['profile_picture'], 64),

                      const SizedBox(height: 16),

                      Text(
                        profileData!['username'] ?? "",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue400,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (profileData!['role'] ?? "PENGGUNA").toString(),
                          style: const TextStyle(
                            color: AppColors.blue400,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        (profileData!['bio'] != null &&
                                profileData!['bio'].toString().isNotEmpty)
                            ? profileData!['bio']
                            : "User ini belum menulis bio.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),

                      const SizedBox(height: 24),

                      if (profileData!['can_edit'] == true)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfilePage(userData: profileData!),
                                ),
                              );
                              if (result == true) fetchProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Edit Profil",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 32),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Tim yang Diikuti",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Pengguna ini belum bergabung dengan tim manapun.",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Histori & Statistik Prediksi",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Total Poin: 0",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue400,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "Pengguna ini belum membuat prediksi apapun.",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
