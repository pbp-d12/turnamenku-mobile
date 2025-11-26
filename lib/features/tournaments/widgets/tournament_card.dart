import 'package:flutter/material.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament.dart';
import 'package:turnamenku_mobile/features/tournaments/screens/tournament_detail_page.dart'; 

class TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Placeholder for navigation to detail page
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Detail for ${tournament.name} coming soon!"))
           );
           // UNCOMMENT THIS LATER when we build the detail page:
           // Navigator.push(
           //   context,
           //   MaterialPageRoute(
           //     builder: (context) => TournamentDetailPage(tournamentId: tournament.id),
           //   ),
           // );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(tournament.bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: tournament.bannerUrl == null || tournament.bannerUrl!.isEmpty
                  ? const Center(
                      child: Icon(Icons.emoji_events, size: 48, color: Colors.grey),
                    )
                  : null,
            ),
            
            // 2. Tournament Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.startDate} - ${tournament.endDate}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tournament.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organizer: ${tournament.organizer}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}