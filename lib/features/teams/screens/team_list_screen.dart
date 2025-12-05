import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/left_drawer.dart';
import '../../../core/widgets/team_logo.dart'; 
import '../models/team.dart';
import '../services/team_service.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';
import 'team_manage_screen.dart';

class TeamListScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; 
  const TeamListScreen({super.key, this.userData});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  int _selectedIndex = 0;
  int _currentPage = 1;
  String _searchQuery = "";
  Timer? _debounce;

  final Color bgColor = const Color(0xFFDDE6ED); 
  final Color btnActiveColor = const Color(0xFF27496D);
  final Color btnInactiveColor = const Color(0xFF748DA6);

  String get _currentMode {
    if (_selectedIndex == 0) return 'meet';
    if (_selectedIndex == 1) return 'manage';
    return 'join';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final teamService = TeamService(request);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Teams", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: LeftDrawer(userData: widget.userData),
      body: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Hero(
              tag: 'searchBar',
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Cari tim atau kapten...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Row(
              children: [
                _buildTabButton("Tim Kamu", 0),
                const SizedBox(width: 10),
                _buildTabButton("Kelola Tim", 1),
                const SizedBox(width: 10),
                _buildTabButton("Gabung Tim", 2),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: teamService.fetchTeams(_currentMode, _currentPage, query: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError || !snapshot.hasData || (snapshot.data!['teams'] as List).isEmpty) return _buildEmptyState();

                final List<Team> teams = snapshot.data!['teams'];
                final Map pagination = snapshot.data!['pagination'];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: teams.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTeamCard(teams[index], teamService, context);
                        },
                      ),
                    ),
                    _buildPaginationControls(pagination),
                  ],
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            decoration: BoxDecoration(color: bgColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 5)]),
            child: Column(
              children: [
                SizedBox(
                  width: 180, 
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D13B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 3,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context, 
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const CreateTeamScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        )
                      );
                      setState(() {});
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Buat Tim Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Jadilah kapten dari teammu sendiri! 🫡", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? btnActiveColor : btnInactiveColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: btnActiveColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildTeamCard(Team team, TeamService service, BuildContext ctx) {
    String btnLabel = "Detail";
    Color btnColor = btnActiveColor;
    VoidCallback? onTapAction;

    if (_selectedIndex == 0) { // Meet
      btnLabel = "Detail";
      onTapAction = () async {
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: team.id)));
        if (result == true && ctx.mounted) {
           CustomSnackbar.show(ctx, "Berhasil keluar dari tim!", SnackbarStatus.success);
           setState((){});
        }
      };
    } 
    else if (_selectedIndex == 1) { // Manage
      btnLabel = "Kelola";
      onTapAction = () async {
        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => TeamManageScreen(teamId: team.id)));
        if (result == true && ctx.mounted) {
           CustomSnackbar.show(ctx, "Tim berhasil dihapus!", SnackbarStatus.success);
           setState((){});
        } else {
           setState((){}); 
        }
      };
    } 
    else { // Join
      btnLabel = "Join";
      btnColor = const Color(0xFF00D13B);
      onTapAction = () => _showJoinConfirmDialog(ctx, team, service);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Hero(
            tag: 'team_logo_${team.id}', 
            child: TeamLogo(url: team.logo, radius: 25),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text("Member ${team.membersCount}/n", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            ),
            onPressed: onTapAction,
            child: Text(btnLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showJoinConfirmDialog(BuildContext ctx, Team team, TeamService service) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text("Gabung ke ${team.name}?"),
        content: const Text("Apakah kamu yakin ingin bergabung dengan tim ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D13B)),
            onPressed: () async {
              Navigator.pop(context); 
              
              bool success = await service.joinTeam(team.id);
              
              if (ctx.mounted) {
                if (success) {
                  CustomSnackbar.show(ctx, "Berhasil join tim! 🎉", SnackbarStatus.success);
                  setState(() {}); 
                } else {
                  CustomSnackbar.show(ctx, "Gagal join tim.", SnackbarStatus.error);
                }
              }
            },
            child: const Text("Ya, Gas!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = "Tidak ada tim ditemukan.";
    if (_searchQuery.isEmpty) {
      if (_selectedIndex == 0) message = "Kamu belum masuk tim manapun.";
      if (_selectedIndex == 1) message = "Kamu belum jadi kapten tim.";
      if (_selectedIndex == 2) message = "Tidak ada tim tersedia untuk join.";
    } else {
      message = "Tidak ada tim dengan nama '$_searchQuery'";
    }
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 60, color: Colors.grey[400]), const SizedBox(height: 10), Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14))]));
  }

  Widget _buildPaginationControls(Map pagination) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: pagination['has_previous'] ? () => setState(() => _currentPage--) : null),
          const SizedBox(width: 5),
          Text("$_currentPage", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
          const SizedBox(width: 5),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: pagination['has_next'] ? () => setState(() => _currentPage++) : null),
        ],
      ),
    );
  }
}