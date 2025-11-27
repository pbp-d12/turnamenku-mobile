import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/predictions/models/prediction_match.dart';
import 'package:turnamenku_mobile/features/predictions/screens/leaderboard_page.dart';
import 'package:turnamenku_mobile/features/predictions/screens/add_match_page.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart'; 

class PredictionPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const PredictionPage({super.key, this.userData});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // Variabel future agar data tidak di-fetch ulang setiap kali tab berubah
  late Future<List<PredictionMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _matchesFuture = fetchMatches(request);
  }

  Future<List<PredictionMatch>> fetchMatches(CookieRequest request) async {
    final response = await request.get(Endpoints.predictionMatches);
    return predictionMatchFromJson(jsonEncode(response));
  }

  Future<void> voteTeam(CookieRequest request, int matchId, int teamId) async {
    final response = await request.postJson(
      Endpoints.predictionSubmit,
      jsonEncode({'match_id': matchId, 'team_id': teamId}),
    );

    if (context.mounted) {
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
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

 // --- FUNGSI: EDIT SKOR---
  Future<void> _editMatchScore(CookieRequest request, int matchId, int currentHome, int currentAway) async {
    final homeController = TextEditingController(text: currentHome.toString());
    final awayController = TextEditingController(text: currentAway.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Skor Pertandingan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: homeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Skor Home Team"),
            ),
            TextField(
              controller: awayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Skor Away Team"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (homeController.text.isEmpty || awayController.text.isEmpty) return;

              final response = await request.postJson(
                Endpoints.predictionEditScore, 
                jsonEncode({
                  'match_id': matchId, 
                  'home_score': int.parse(homeController.text), 
                  'away_score': int.parse(awayController.text),
                }),
              );

              if (context.mounted) {
                // [PERUBAHAN 2] Cek 'status' == 'success'
                if (response['status'] == 'success') {
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message'])),
                  );
                  setState(() {
                    _matchesFuture = fetchMatches(request); // Refresh data
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal: ${response['message']}")),
                  );
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI: HAPUS PREDIKSI ---
  Future<void> _deletePredictions(CookieRequest request, int matchId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Prediksi"),
        content: const Text(
            "Apakah Anda yakin ingin menghapus semua prediksi user untuk pertandingan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Batal")
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final response = await request.postJson(
        Endpoints.predictionDelete, 
        jsonEncode({
          'match_id': matchId,
        }),
      );

      if (context.mounted) {
        if (response['status'] == 'success') {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(response['message'])),
           );
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
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // --- LOGIKA CEK ROLE ---
    bool canAddMatch = false;
    if (widget.userData != null && widget.userData!.containsKey('role')) {
      final String userRole = widget.userData!['role'].toString().toLowerCase();
      // Izinkan akses jika role adalah 'admin' atau 'penyelenggara'
      if (userRole == 'admin' || userRole == 'penyelenggara') {
        canAddMatch = true;
      }
    }

    return DefaultTabController(
      length: 2, 
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: "Voting (Aktif)"),
              Tab(icon: Icon(Icons.history), text: "Riwayat (Selesai)"),
            ],
          ),
        ),
        drawer: LeftDrawer(userData: widget.userData),
        
        // Tombol hanya muncul jika canAddMatch bernilai true
        floatingActionButton: canAddMatch
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final bool? shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMatchPage(),
                    ),
                  );

                  if (shouldRefresh == true) {
                     setState(() {
                        _matchesFuture = fetchMatches(request);
                     });
                  }
                },
                label: const Text('Add Match'),
                icon: const Icon(Icons.add),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                tooltip: 'Tambah Pertandingan Baru',
              )
            : null, 

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
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
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
              final ongoingMatches = snapshot.data!
                  .where((m) => !m.isFinished)
                  .toList();
              final finishedMatches = snapshot.data!
                  .where((m) => m.isFinished)
                  .toList();

              return TabBarView(
                children: [
                  _buildMatchList(ongoingMatches, request, isVotingTab: true, isAdmin: canAddMatch),
                  _buildMatchList(finishedMatches, request, isVotingTab: false, isAdmin: canAddMatch),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMatchList(
    List<PredictionMatch> matches,
    CookieRequest request, {
    required bool isVotingTab,
    required bool isAdmin, // Menerima parameter status admin
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
      padding: const EdgeInsets.only(
        top: 8, left: 8, right: 8, bottom: 80
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          color: isVotingTab ? Colors.blue[800] : Colors.grey[700],
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
                    Expanded(
                      child: _buildTeamColumn(match, match.homeTeam, match.homeTeamId, request),
                    ),

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
                          if (!isVotingTab)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${match.homeScore} - ${match.awayScore}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _buildTeamColumn(match, match.awayTeam, match.awayTeamId, request),
                    ),
                  ],
                ),

                // --- ADMIN ACTIONS (EDIT/DELETE) ---
                if (isAdmin && !match.isFinished) ...[
                  const Divider(height: 32),
                  const Text(
                    "Admin Actions",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol Edit Skor
                      OutlinedButton.icon(
                        onPressed: () => _editMatchScore(
                          request, match.id, match.homeScore, match.awayScore
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit Skor"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue[800]),
                      ),
                      // Tombol Hapus Prediksi
                      OutlinedButton.icon(
                        onPressed: () => _deletePredictions(request, match.id),
                        icon: const Icon(Icons.delete_forever, size: 16),
                        label: const Text("Reset Prediksi"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red[800]),
                      ),
                    ],
                  ),
                ],

                if (!isVotingTab)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      match.homeScore > match.awayScore
                          ? "${match.homeTeam} Menang!"
                          : match.awayScore > match.homeScore
                          ? "${match.awayTeam} Menang!"
                          : "Hasil Seri",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        if (!isFinished)
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