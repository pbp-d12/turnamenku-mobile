import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament_detail.dart';

class TournamentDetailPage extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  Future<TournamentDetail> fetchDetail(CookieRequest request) async {
    final response = await request.get(Endpoints.tournamentDetail(widget.tournamentId));
    return TournamentDetail.fromJson(response);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournament Detail"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<TournamentDetail>(
        future: fetchDetail(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Tournament not found"));
          }

          final detail = snapshot.data!;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // 1. Header Section (Banner & Title)
                if (detail.bannerUrl != null && detail.bannerUrl!.isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(detail.bannerUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Container(
                  color: Theme.of(context).primaryColor,
                  child: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: "Overview"),
                      Tab(text: "Matches"),
                      Tab(text: "Standings"),
                    ],
                  ),
                ),
                
                // 2. Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: OVERVIEW
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (detail.winnerName != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.emoji_events, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Winner: ${detail.winnerName}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.calendar_today, "${detail.startDate} - ${detail.endDate}"),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.person, "Organizer: ${detail.organizer}"),
                            const SizedBox(height: 16),
                            const Text(
                              "Description",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(detail.description),
                            const SizedBox(height: 24),
                            
                            // Action Buttons (Placeholder Logic)
                            if (detail.registrationOpen)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Team Registration coming next!")),
                                    );
                                  },
                                  child: const Text("Register Team"),
                                ),
                              )
                            else 
                              const Center(
                                child: Text(
                                  "Registration Closed",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // TAB 2: MATCHES
                      detail.matches.isEmpty
                          ? const Center(child: Text("No matches scheduled yet."))
                          : ListView.builder(
                              itemCount: detail.matches.length,
                              itemBuilder: (context, index) {
                                final match = detail.matches[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          match.date,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(match.homeTeam, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                match.isFinished 
                                                  ? "${match.homeScore} - ${match.awayScore}"
                                                  : "VS",
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Expanded(child: Text(match.awayTeam, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // TAB 3: STANDINGS (Leaderboard)
                      detail.leaderboard.isEmpty
                          ? const Center(child: Text("No standings available."))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Team')),
                                  DataColumn(label: Text('MP'), tooltip: 'Matches Played'),
                                  DataColumn(label: Text('W'), tooltip: 'Wins'),
                                  DataColumn(label: Text('D'), tooltip: 'Draws'),
                                  DataColumn(label: Text('L'), tooltip: 'Losses'),
                                  DataColumn(label: Text('GD'), tooltip: 'Goal Difference'),
                                  DataColumn(label: Text('Pts'), tooltip: 'Points'),
                                ],
                                rows: detail.leaderboard.map((entry) {
                                  return DataRow(cells: [
                                    DataCell(Text(entry.teamName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(entry.played.toString())),
                                    DataCell(Text(entry.wins.toString())),
                                    DataCell(Text(entry.draws.toString())),
                                    DataCell(Text(entry.losses.toString())),
                                    DataCell(Text(entry.goalDifference.toString())),
                                    DataCell(Text(entry.points.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}