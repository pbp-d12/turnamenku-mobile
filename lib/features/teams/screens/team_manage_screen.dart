import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/team_logo.dart';
import '../models/team.dart';
import '../services/team_service.dart';

class TeamManageScreen extends StatefulWidget {
  final int teamId;
  const TeamManageScreen({super.key, required this.teamId});

  @override
  State<TeamManageScreen> createState() => _TeamManageScreenState();
}

class _TeamManageScreenState extends State<TeamManageScreen> {
  final Color bgColor = const Color(0xFFDDE6ED);

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final teamService = TeamService(request);
    
    final ScrollController memberScrollController = ScrollController();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Kelola Tim", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueGrey[200]),
                  child: Hero(
                      tag: 'team_logo_${team.id}',
                      child: TeamLogo(url: team.logo, radius: 60, iconSize: 50)),
                ),
                const SizedBox(height: 15),
                Text(team.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                Text("Member ${team.members.length}/n", style: const TextStyle(color: Colors.grey)),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton("Ganti Nama", () => _showEditDialog(context, team.id, 'name', teamService)),
                    const SizedBox(width: 10),
                    _buildActionButton("Ganti Logo", () => _showEditDialog(context, team.id, 'logo', teamService)),
                  ],
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
                        // PASANG CONTROLLER DI SINI (1)
                        child: Scrollbar(
                          controller: memberScrollController, 
                          thumbVisibility: true,
                          child: ListView.separated(
                            // PASANG CONTROLLER DI SINI (2)
                            controller: memberScrollController,
                            padding: const EdgeInsets.all(15),
                            itemCount: team.members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 15),
                            itemBuilder: (context, index) {
                              final memberName = team.members[index];
                              final isMe = memberName == team.captain;
                              
                              return Row(
                                children: [
                                  CircleAvatar(radius: 18, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A6572)))),
                                  
                                  if (!isMe)
                                  SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8D4F55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      onPressed: () => _showConfirmDialog(
                                        context, 
                                        "Kick Member?", 
                                        "Yakin ingin mengeluarkan $memberName?",
                                        () async {
                                          if (await teamService.kickMember(team.id, memberName) && context.mounted) {
                                            CustomSnackbar.show(context, "$memberName di-kick!", SnackbarStatus.success);
                                            setState(() {}); 
                                          }
                                        }
                                      ),
                                      child: const Text("Kick", style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  )
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
                    onPressed: () => _showConfirmDialog(
                      context, 
                      "Hapus Tim?", 
                      "Yakin ingin menghapus tim ini permanen?",
                      () async {
                         if (await teamService.deleteTeam(team.id) && context.mounted) {
                            Navigator.pop(context, true); 
                         }
                      }
                    ),
                    child: const Text("Hapus Tim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  void _showEditDialog(BuildContext context, int teamId, String field, TeamService service) {
    String value = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(field == 'name' ? "Ganti Nama Tim" : "Ganti Logo Tim"),
        content: TextField(onChanged: (v) => value = v, decoration: InputDecoration(hintText: "Masukkan $field baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); 
              await service.editTeam(teamId, {field: value});
              CustomSnackbar.show(context, "Berhasil update!", SnackbarStatus.success);
              setState(() {});
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); 
              onConfirm(); 
            },
            child: const Text("Ya", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}