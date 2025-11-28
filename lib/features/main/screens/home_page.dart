import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/core/widgets/profile_avatar.dart';
import 'package:turnamenku_mobile/features/auth/screens/login_page.dart';
import 'package:turnamenku_mobile/features/auth/screens/register_page.dart';
import 'package:turnamenku_mobile/features/main/models/home_data.dart';
import 'package:turnamenku_mobile/features/main/screens/user_search_delegate.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeData? _homeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final request = context.read<CookieRequest>();
    try {
      final homeResponse = await request.get(Endpoints.homeData);
      var fetchedHomeData = HomeData.fromJson(homeResponse);

      try {
        final profileResponse = await request.get(Endpoints.userProfile);

        if (profileResponse['status'] == true) {
          final Map<String, dynamic> mergedUserData = {
            ...(fetchedHomeData.userData ?? {}),
            ...profileResponse,
          };

          fetchedHomeData = HomeData(
            status: fetchedHomeData.status,
            ongoingTournaments: fetchedHomeData.ongoingTournaments,
            upcomingMatches: fetchedHomeData.upcomingMatches,
            recentThreads: fetchedHomeData.recentThreads,
            topPredictors: fetchedHomeData.topPredictors,
            stats: fetchedHomeData.stats,
            userData: mergedUserData,
          );
        }
      } catch (e) {
        // heh, ignore profile fetch errors
      }

      if (mounted) {
        setState(() {
          _homeData = fetchedHomeData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ignore errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUserData = _homeData?.userData ?? widget.userData;
    final bool isLoggedIn = displayUserData != null;

    return Scaffold(
      backgroundColor: AppColors.blue50,
      appBar: AppBar(
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Turnamenku",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: UserSearchDelegate());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: LeftDrawer(userData: displayUserData),
      body: _isLoading && _homeData == null
          ? const Center(child: CircularProgressIndicator())
          : _homeData == null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroSection(isLoggedIn, displayUserData),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle("Sekilas Komunitas"),
                    ),
                    _buildCommunityStats(_homeData!.stats),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle("Live Turnamen"),
                    ),
                    _buildOngoingList(_homeData!.ongoingTournaments),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle("Prediksi Berikutnya"),
                    ),
                    _buildUpcomingMatches(_homeData!.upcomingMatches),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle("Diskusi Terbaru"),
                    ),
                    _buildRecentThreads(_homeData!.recentThreads),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionTitle("Top Predictors"),
                    ),
                    _buildTopPredictors(_homeData!.topPredictors),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Gagal memuat data.\nCek koneksi internet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isLoggedIn, Map<String, dynamic>? userData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue400, AppColors.blue300],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLoggedIn && userData != null) ...[
            ProfileAvatar(imageUrl: userData['profile_picture'], radius: 40),

            const SizedBox(height: 16),
            Text(
              "Halo, ${userData['username']}!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (userData['role'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  userData['role'].toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Peringkat #${userData['rank'] ?? '-'}  |  ${userData['total_points'] ?? 0} Poin",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const Text(
              "Selamat Datang di\nTURNAMENKU!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Platform terpusat untuk mengelola, mengikuti, dan berdiskusi seputar turnamen olahraga favorit Anda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.blue400,
                  ),
                  child: const Text("Login"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text("Daftar"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCommunityStats(Map<String, dynamic> stats) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildStatCard(
            "Turnamen",
            stats['tournaments_count'].toString(),
            Icons.emoji_events,
          ),
          _buildStatCard(
            "Laga",
            stats['matches_count'].toString(),
            Icons.sports_soccer,
          ),
          _buildStatCard(
            "Diskusi",
            stats['threads_count'].toString(),
            Icons.forum,
          ),
          _buildStatCard(
            "Prediktor",
            stats['predictors_count'].toString(),
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blue300, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blue400,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingList(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState("Tidak ada turnamen live.");
    return Column(
      children: list
          .map(
            (t) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  t['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  "Berakhir: ${t['end_date']}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  // TODO: Ke Detail Turnamen
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUpcomingMatches(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState("Belum ada match mendatang.");
    return SizedBox(
      height: 150,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final m = list[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m['tournament_name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          m['home_team'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "VS",
                          style: TextStyle(
                            color: AppColors.blue300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m['away_team'],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.blue400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentThreads(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState("Belum ada diskusi.");
    return Column(
      children: list
          .map(
            (th) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.forum_rounded,
                  color: AppColors.blue300,
                  size: 32,
                ),
                title: Text(
                  th['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(th['author'], style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${th['reply_count']} Balasan",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  // TODO: Ke Detail Thread
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopPredictors(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState("Belum ada data.");
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: list.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final p = entry.value;
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: idx == 1
                      ? Colors.amber
                      : (idx == 2
                            ? Colors.grey.shade400
                            : Colors.brown.shade300),
                  foregroundColor: Colors.white,
                  child: Text(
                    "#$idx",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  p['user__username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "${p['total_points']} Poin",
                  style: const TextStyle(
                    color: AppColors.blue400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (idx != list.length)
                const Divider(height: 1, indent: 70, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
