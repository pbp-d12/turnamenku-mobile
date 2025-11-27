import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart'; 

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  Future<List<dynamic>> fetchLeaderboard(CookieRequest request) async {
    final response = await request.get(Endpoints.predictionLeaderboard);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.blue50, // Background konsisten
      appBar: AppBar(
        title: const Text(
          "Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: fetchLeaderboard(request),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue400),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data leaderboard."));
          } else {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = snapshot.data![index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index < 3
                          ? Colors.amber
                          : Colors.grey[300],
                      foregroundColor: index < 3
                          ? Colors.white
                          : Colors.grey[800],
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      data['user__username'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      "${data['total_points'] ?? 0} Pts",
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.blue400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
