import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/team_logo.dart';
import '../models/team.dart';
import '../services/team_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final Color bgColor = const Color(0xFFDDE6ED);

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final teamService = TeamService(request);
    
    final ScrollController memberScrollController = ScrollController();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Detail Tim", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Team>(
        future: teamService.fetchTeamDetail(widget.teamId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final team = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueGrey[200],
                  ),
                  child: Hero(
                      tag: 'team_logo_${team.id}',
                      child: TeamLogo(url: team.logo, radius: 60, iconSize: 50)),
                ),
                const SizedBox(height: 15),
                Text(
                  team.name, 
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))
                ),
                Text("Member ${team.members.length}/n", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text(
                  "Ketua: ${team.captain}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27496D), fontSize: 16)
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Anggota:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A5F))),
                      const SizedBox(height: 10),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        // PASANG CONTROLLER (1)
                        child: Scrollbar(
                          controller: memberScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            // PASANG CONTROLLER (2)
                            controller: memberScrollController,
                            padding: const EdgeInsets.all(15),
                            itemCount: team.members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return Row(
                                children: [
                                  CircleAvatar(radius: 18, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                                  const SizedBox(width: 10),
                                  Text(team.members[index], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A6572))),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD60000), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Keluar Tim?"),
                          content: const Text("Yakin ingin keluar dari tim ini?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                Navigator.pop(ctx); 
                                if (await teamService.leaveTeam(team.id) && context.mounted) {
                                  Navigator.pop(context, true); 
                                }
                              },
                              child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("Keluar Tim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}