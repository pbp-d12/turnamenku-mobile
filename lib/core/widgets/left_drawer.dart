import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/auth/screens/login_page.dart';
import 'package:turnamenku_mobile/features/auth/screens/register_page.dart';
import 'package:turnamenku_mobile/features/auth/services/auth_service.dart';
import 'package:turnamenku_mobile/features/main/screens/home_page.dart';
import 'package:turnamenku_mobile/features/main/screens/profile_page.dart';
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_list_page.dart';
import 'package:turnamenku_mobile/features/predictions/screens/prediction_page.dart';
import 'package:turnamenku_mobile/features/teams/screens/team_list_screen.dart';

class LeftDrawer extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const LeftDrawer({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isLoggedIn = userData != null;

    String displayName = isLoggedIn
        ? (userData!['username'] ?? "User")
        : "Tamu";
    String displayEmail = isLoggedIn
        ? (userData!['email'] ?? "")
        : "Silakan Login";
    String displayRole = isLoggedIn ? (userData!['role'] ?? "") : "";
    String? profilePicUrl = isLoggedIn ? userData!['profile_picture'] : null;

    final double topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.blue400,
            padding: EdgeInsets.only(
              top: topPadding + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TurnamenKu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildProfileImage(profilePicUrl, 24),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isLoggedIn && displayRole.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayRole.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                displayEmail,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          _buildDrawerItem(
            icon: Icons.home_rounded,
            title: "Home",
            onTap: () {
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
              Navigator.pushReplacement(
                context, MaterialPageRoute(
                  builder: (context) => TeamListScreen(userData: userData),
                )
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.forum_rounded,
            title: "Forums",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumHomePage(userData: userData),
                ),
              );
            },
          ),
           _buildDrawerItem(
            icon: Icons.sports_soccer_rounded, 
            title: "Predictions",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PredictionPage(userData: userData),
                ),
              );
            },
          ),
        
          const Divider(height: 32, thickness: 1),

          if (isLoggedIn) ...[
            _buildDrawerItem(
              icon: Icons.person_rounded,
              title: "Profile",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
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
          ] else ...[
            _buildDrawerItem(
              icon: Icons.login_rounded,
              title: "Login",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.app_registration_rounded,
              title: "Register",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              ),
            ),
          ],

          const SizedBox(height: 24),
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
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
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
        border: Border.all(color: Colors.white, width: 2),
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
