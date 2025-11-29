import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/tournaments/models/captain_status.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament_detail.dart';
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_form_page.dart';

class TournamentDetailPage extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  Future<Map<String, dynamic>> fetchAllData(CookieRequest request) async {
    final detailResponse = await request.get(Endpoints.tournamentDetail(widget.tournamentId));
    final detail = TournamentDetail.fromJson(detailResponse);

    final statusResponse = await request.get(Endpoints.checkCaptainStatus(widget.tournamentId));
    final status = CaptainStatus.fromJson(statusResponse);

    return {
      'detail': detail,
      'status': status,
    };
  }

  // --- LOGIC PESERTA (Register/Deregister) ---
  Future<void> _handleRegister(CookieRequest request) async {
    try {
      final response = await request.post(Endpoints.registerTeam(widget.tournamentId), {});
      if (!mounted) return;
      if (response['status'] == 'success') {
        CustomSnackbar.show(context, response['message'], SnackbarStatus.success);
        setState(() {}); 
      } else {
        CustomSnackbar.show(context, response['message'] ?? "Gagal mendaftar.", SnackbarStatus.error);
      }
    } catch (e) {
      if (mounted) CustomSnackbar.show(context, "Terjadi kesalahan: $e", SnackbarStatus.error);
    }
  }

  Future<void> _handleDeregister(CookieRequest request) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pendaftaran?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pendaftaran tim?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await request.post(Endpoints.deregisterTeam(widget.tournamentId), {});
      if (!mounted) return;
      if (response['status'] == 'success') {
        CustomSnackbar.show(context, response['message'], SnackbarStatus.success);
        setState(() {});
      } else {
        CustomSnackbar.show(context, response['message'] ?? "Gagal membatalkan.", SnackbarStatus.error);
      }
    } catch (e) {
      if (mounted) CustomSnackbar.show(context, "Terjadi kesalahan: $e", SnackbarStatus.error);
    }
  }

  // --- LOGIC ADMIN/ORGANIZER (Delete) ---
  Future<void> _handleDelete(CookieRequest request) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Turnamen?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan. Semua data pertandingan akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Backend Anda menggunakan method DELETE atau POST untuk penghapusan?
      // Sesuai urls.py: path('delete/<int:tournament_id>/', ...) biasanya menghandle POST atau DELETE.
      // Kita coba DELETE request sesuai best practice, atau gunakan postJson jika view Django require_POST.
      // Di view Django Anda: @require_http_methods(["DELETE"]) -> Gunakan request.delete
      
      final response = await request.post(
          Endpoints.deleteTournament(widget.tournamentId),
          {} 
      );
      if (!mounted) return;

      if (response['status'] == 'success') {
        CustomSnackbar.show(context, "Turnamen berhasil dihapus", SnackbarStatus.success);
        Navigator.pop(context); // Kembali ke list page
      } else {
        CustomSnackbar.show(context, response['message'] ?? "Gagal menghapus.", SnackbarStatus.error);
      }
    } catch (e) {
      if (mounted) CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchAllData(request),
      builder: (context, snapshot) {
        // Tampilkan loading/error standard
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Loading...")),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final detail = snapshot.data!['detail'] as TournamentDetail;
        final status = snapshot.data!['status'] as CaptainStatus;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Tournament Detail"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              // TOMBOL KHUSUS ORGANIZER / ADMIN
              if (detail.isOrganizerOrAdmin) ...[
                // Di dalam Actions AppBar:
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Edit Turnamen",
                  onPressed: () async {
                    // Navigasi ke Form dengan membawa data detail saat ini
                    final bool? shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentFormPage(tournament: detail),
                      ),
                    );
                    
                    // Jika kembali dengan nilai true, refresh halaman
                    if (shouldRefresh == true) {
                      setState(() {});
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Hapus Turnamen",
                  onPressed: () => _handleDelete(request),
                ),
              ]
            ],
          ),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                if (detail.bannerUrl != null && detail.bannerUrl!.isNotEmpty)
                  Container(
                    height: 180,
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
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: OVERVIEW & ACTIONS
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                                    Text("Winner: ${detail.winnerName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.calendar_today, "${detail.startDate} - ${detail.endDate}"),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.person, "Organizer: ${detail.organizer}"),
                            const SizedBox(height: 16),
                            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(detail.description),
                            const SizedBox(height: 32),

                            // --- ACTION BUTTONS (LOGIC PESERTA) ---
                            // Jangan tampilkan tombol daftar jika user adalah Organizer (opsional, tapi biasanya organizer tidak daftar sendiri)
                            if (!detail.isOrganizerOrAdmin) ...[ 
                              if (status.canDeregister) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleDeregister(request),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.exit_to_app),
                                    label: const Text("Batalkan Pendaftaran Tim"),
                                  ),
                                ),
                              ] else if (status.canRegister) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleRegister(request),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.how_to_reg),
                                    label: const Text("Daftarkan Tim Saya"),
                                  ),
                                ),
                              ] else if (!status.isRegistrationOpen) ...[
                                _buildStatusContainer("Pendaftaran Ditutup", Colors.grey[300]!, Colors.black54),
                              ] else ...[
                                _buildStatusContainer("Hanya Kapten Tim yang dapat mendaftar.", Colors.white, Colors.grey, border: true),
                              ],
                            ],
                          ],
                        ),
                      ),

                      // TAB 2: MATCHES
                      detail.matches.isEmpty
                          ? const Center(child: Text("Belum ada jadwal pertandingan."))
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
                                        Text(match.date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(match.homeTeam, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                              child: Text(match.isFinished ? "${match.homeScore} - ${match.awayScore}" : "VS", style: const TextStyle(fontWeight: FontWeight.bold)),
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

                      // TAB 3: STANDINGS
                      detail.leaderboard.isEmpty
                          ? const Center(child: Text("Belum ada klasemen."))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Team')),
                                  DataColumn(label: Text('MP'), tooltip: 'Main'),
                                  DataColumn(label: Text('W'), tooltip: 'Menang'),
                                  DataColumn(label: Text('D'), tooltip: 'Seri'),
                                  DataColumn(label: Text('L'), tooltip: 'Kalah'),
                                  DataColumn(label: Text('Pts'), tooltip: 'Poin'),
                                ],
                                rows: detail.leaderboard.map((entry) {
                                  return DataRow(cells: [
                                    DataCell(Text(entry.teamName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(entry.played.toString())),
                                    DataCell(Text(entry.wins.toString())),
                                    DataCell(Text(entry.draws.toString())),
                                    DataCell(Text(entry.losses.toString())),
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
          ),
        );
      },
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

  Widget _buildStatusContainer(String text, Color bgColor, Color textColor, {bool border = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: Colors.grey) : null,
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}