import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/predictions/models/prediction_match.dart';
import 'package:turnamenku_mobile/features/predictions/screens/leaderboard_page.dart';

class PredictionPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const PredictionPage({super.key, this.userData});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // Sesuaikan URL dengan environment Anda
  final String baseUrl = "http://127.0.0.1:8000";

  // Variabel future agar data tidak di-fetch ulang setiap kali tab berubah
  late Future<List<PredictionMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _matchesFuture = fetchMatches(request);
  }

  Future<List<PredictionMatch>> fetchMatches(CookieRequest request) async {
    final response = await request.get('$baseUrl/predictions/api/matches/');
    return predictionMatchFromJson(jsonEncode(response));
  }

  Future<void> voteTeam(CookieRequest request, int matchId, int teamId) async {
    final response = await request.postJson(
      '$baseUrl/predictions/api/submit/',
      jsonEncode({'match_id': matchId, 'team_id': teamId}),
    );

    if (context.mounted) {
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
        // Refresh data setelah vote berhasil
        setState(() {
          _matchesFuture = fetchMatches(request);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${response['message']}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // Menggunakan DefaultTabController untuk membuat Tab Bar
    return DefaultTabController(
      length: 2, // Jumlah tab (Aktif & Selesai)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prediksi Pertandingan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard),
              tooltip: 'Lihat Leaderboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardPage(),
                  ),
                );
              },
            ),
          ],
          // Menambahkan TabBar di bagian bawah AppBar
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: "Voting (Aktif)"),
              Tab(icon: Icon(Icons.history), text: "Riwayat (Selesai)"),
            ],
          ),
        ),
        drawer: LeftDrawer(userData: widget.userData),
        body: FutureBuilder(
          future: _matchesFuture,
          builder: (context, AsyncSnapshot<List<PredictionMatch>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Gagal memuat data.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _matchesFuture = fetchMatches(request);
                        });
                      },
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada data pertandingan."));
            } else {
              // Memisahkan data menjadi dua list berdasarkan status
              final ongoingMatches = snapshot.data!
                  .where((m) => !m.isFinished)
                  .toList();
              final finishedMatches = snapshot.data!
                  .where((m) => m.isFinished)
                  .toList();

              return TabBarView(
                children: [
                  // Tab 1: Pertandingan Aktif (Bisa Vote)
                  _buildMatchList(ongoingMatches, request, isVotingTab: true),

                  // Tab 2: Pertandingan Selesai (Hanya Lihat Skor)
                  _buildMatchList(finishedMatches, request, isVotingTab: false),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // Widget helper untuk membangun list pertandingan agar kode lebih rapi
  Widget _buildMatchList(
    List<PredictionMatch> matches,
    CookieRequest request, {
    required bool isVotingTab,
  }) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVotingTab ? Icons.event_busy : Icons.history_toggle_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isVotingTab
                  ? "Tidak ada pertandingan aktif saat ini."
                  : "Belum ada pertandingan yang selesai.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: matches.length,
      itemBuilder: (_, index) {
        final match = matches[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header: Nama Turnamen & Tanggal
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isVotingTab ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        match.tournament,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isVotingTab
                              ? Colors.blue[800]
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.matchDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content: Tim vs Tim
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Team
                    Expanded(
                      child: _buildTeamColumn(
                        match,
                        match.homeTeam,
                        match.homeTeamId,
                        request,
                      ),
                    ),

                    // VS / Skor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Text(
                            "VS",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Colors.grey[400],
                            ),
                          ),
                          if (!isVotingTab) // Tampilkan skor jika di tab riwayat
                            Container(
                              // --- PERBAIKAN DI SINI ---
                              margin: const EdgeInsets.only(
                                top: 8,
                              ), // Sebelumnya EdgeInsets.top(8)
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${match.homeScore} - ${match.awayScore}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Away Team
                    Expanded(
                      child: _buildTeamColumn(
                        match,
                        match.awayTeam,
                        match.awayTeamId,
                        request,
                      ),
                    ),
                  ],
                ),

                // Footer: Status Pemenang (Khusus Tab Riwayat)
                if (!isVotingTab)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      match.homeScore > match.awayScore
                          ? "${match.homeTeam} Menang!"
                          : match.awayScore > match.homeScore
                          ? "${match.awayTeam} Menang!"
                          : "Hasil Seri",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamColumn(
    PredictionMatch match,
    String teamName,
    int teamId,
    CookieRequest request,
  ) {
    bool isChosen = match.userPredictionTeamId == teamId;
    bool isFinished = match.isFinished;

    return Column(
      children: [
        // Nama Tim
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Tombol Vote atau Indikator Pilihan
        if (!isFinished)
          // Tampilan Tab Voting
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isChosen ? Colors.blue : Colors.white,
              foregroundColor: isChosen ? Colors.white : Colors.blue,
              side: BorderSide(color: Colors.blue.shade200),
              elevation: isChosen ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              if (!request.loggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Silakan login terlebih dahulu untuk melakukan voting!",
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                voteTeam(request, match.id, teamId);
              }
            },
            child: Text(isChosen ? "Dipilih" : "Vote"),
          )
        else
        // Tampilan Tab Riwayat
        if (isChosen && request.loggedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  "Pilihanmu",
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
