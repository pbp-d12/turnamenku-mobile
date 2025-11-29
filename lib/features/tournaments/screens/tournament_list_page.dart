import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament.dart';
import 'package:turnamenku_mobile/features/tournaments/widgets/tournament_card.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart'; 
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_form_page.dart';

class TournamentListPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const TournamentListPage({super.key, this.userData});

  @override
  State<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  Future<List<Tournament>> fetchTournaments(CookieRequest request) async {
    final response = await request.get(Endpoints.tournaments);

    // Validate response structure
    var listData =
        response['tournaments']; // Django returns { 'tournaments': [...] }

    List<Tournament> listTournaments = [];
    for (var d in listData) {
      if (d != null) {
        listTournaments.add(Tournament.fromJson(d));
      }
    }
    return listTournaments;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // CEK AKSES: Hanya Penyelenggara yang bisa membuat turnamen
    final bool isOrganizer =
        widget.userData != null &&
        (widget.userData!['role'] == 'PENYELENGGARA' ||
            widget.userData!['role'] == 'ADMIN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: LeftDrawer(userData: widget.userData),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke Form tanpa parameter (Mode Create)
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TournamentFormPage(),
            ),
          );

          // Refresh list jika berhasil membuat
          if (shouldRefresh == true) {
            setState(() {});
          }
        },
        tooltip: 'Create Tournament',
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder(
        future: fetchTournaments(request),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No tournaments available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (_, index) =>
                  TournamentCard(tournament: snapshot.data![index]),
            );
          }
        },
      ),
    );
  }
}
