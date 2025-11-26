import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart'; // Import Endpoints diperlukan untuk helper image
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/auth/screens/login_page.dart';
import 'package:turnamenku_mobile/features/auth/screens/register_page.dart';
import 'package:turnamenku_mobile/features/auth/services/auth_service.dart';
import 'package:turnamenku_mobile/features/main/screens/home_page.dart';
import 'package:turnamenku_mobile/features/main/screens/profile_page.dart';
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_list_page.dart';

class LeftDrawer extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const LeftDrawer({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isLoggedIn = userData != null;

    // Setup data tampilan
    String displayName = isLoggedIn
        ? (userData!['username'] ?? "User")
        : "Tamu";
    String displayEmail = isLoggedIn
        ? (userData!['email'] ?? "Member")
        : "Silakan Login";
    String displayRole = isLoggedIn ? (userData!['role'] ?? "") : "";
    String? profilePicUrl = isLoggedIn ? userData!['profile_picture'] : null;

    return Drawer(
      backgroundColor: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.blue400),
            accountName: Row(
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (displayRole.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayRole.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            accountEmail: Text(
              displayEmail,
              style: const TextStyle(color: Colors.white70),
            ),
            // PENGGANTIAN LOGIKA IMAGE LAMA DENGAN HELPER BARU
            currentAccountPicture: _buildProfileImage(profilePicUrl, 36),
          ),

          // MENU ITEMS
          _buildDrawerItem(
            icon: Icons.home_rounded,
            title: "Home",
            onTap: () {
              // Navigasi ke Home dengan membawa userData yang ada
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(userData: userData),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.emoji_events_rounded,
            title: "Tournaments",
            onTap: () {
              // Replace the current screen with the Tournament List
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentListPage(userData: userData),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.groups_rounded,
            title: "Teams",
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigasi Teams
            },
          ),

          const Divider(),

          if (isLoggedIn) ...[
            _buildDrawerItem(
              icon: Icons.person_rounded,
              title: "Profile",
              onTap: () {
                // FIX: ProfilePage sekarang tidak membutuhkan argumen username
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfilePage(), // DIUBAH MENJADI const ProfilePage()
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: "Logout",
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: () async {
                final response = await AuthService(request).logout();
                if (context.mounted) {
                  if (response['status'] == true) {
                    CustomSnackbar.show(
                      context,
                      "Berhasil logout!",
                      SnackbarStatus.success,
                    );
                    // Logout -> Ke Home sebagai Guest (userData: null)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(userData: null),
                      ),
                    );
                  }
                }
              },
            ),
          ],

          if (!isLoggedIn) ...[
            _buildDrawerItem(
              icon: Icons.login,
              title: "Login",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.app_registration,
              title: "Register",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.blue400),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // --- WIDGET HELPER PROFILE IMAGE (DISALIN DARI home_page.dart) ---

  Widget _buildProfileImage(String? url, double radius) {
    bool hasUrl = url != null && url.isNotEmpty;

    // 2. Konstruksi URL Lengkap (Tambahkan Base URL jika URL relatif)
    String? fullUrl;
    if (hasUrl) {
      if (url.startsWith('http')) {
        fullUrl = url;
      } else {
        // Handle slash di awal (jika URL dimulai dengan /media/...)
        fullUrl = "${Endpoints.baseUrl}${url.startsWith('/') ? '' : '/'}$url";
      }
    }

    // 3. Menggunakan Image.network dengan ErrorBuilder
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
                // KALAU ERROR, TAMPILKAN GAMBAR DEFAULT DARI SERVER
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage(radius);
                },
              )
            : _buildFallbackImage(radius), // Fallback jika URL null/kosong
      ),
    );
  }

  // WIDGET BARU: Menggunakan NetworkImage untuk gambar default
  Widget _buildFallbackImage(double radius) {
    // Path gambar default dari Django (sesuai permintaan user)
    const String defaultAvatarPath = '/static/images/default_avatar.png';
    // Konstruksi URL lengkap
    final String defaultAvatarUrl = "${Endpoints.baseUrl}$defaultAvatarPath";

    // NetworkImage untuk gambar default
    return Image.network(
      defaultAvatarUrl,
      fit: BoxFit.cover,
      // Fallback terakhir: jika NetworkImage default pun gagal (server down)
      errorBuilder: (context, error, stackTrace) {
        // Kembali ke Icon sederhana
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
