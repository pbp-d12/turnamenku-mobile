import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<dynamic>> fetchLeaderboard(CookieRequest request) async {
    final response = await request.get('$baseUrl/predictions/api/leaderboard/');
    return response; // response sudah berupa List json
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard")),
      body: FutureBuilder(
        future: fetchLeaderboard(request),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data leaderboard."));
          } else {
            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final data = snapshot.data![index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < 3 ? Colors.amber : Colors.grey[300],
                    child: Text("${index + 1}"),
                  ),
                  title: Text(data['user__username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    "${data['total_points'] ?? 0} Pts",
                    style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
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