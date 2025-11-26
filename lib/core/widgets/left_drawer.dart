import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/auth/screens/login_page.dart';
import 'package:turnamenku_mobile/features/auth/screens/register_page.dart';
import 'package:turnamenku_mobile/features/auth/services/auth_service.dart';
import 'package:turnamenku_mobile/features/main/screens/home_page.dart';
import 'package:turnamenku_mobile/features/main/screens/profile_page.dart'; // Import ini sekarang aman

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
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.white,
              backgroundImage:
                  (profilePicUrl != null && profilePicUrl.isNotEmpty)
                  ? NetworkImage(profilePicUrl)
                  : null,
              child: (profilePicUrl == null || profilePicUrl.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: AppColors.blue300)
                  : null,
            ),
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
              Navigator.pop(context);
              // TODO: Navigasi Tournament
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(username: displayName),
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
}
