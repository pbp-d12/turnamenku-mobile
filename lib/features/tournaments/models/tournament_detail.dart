class TournamentDetail {
  final int id;
  final String name;
  final String description;
  final String organizer;
  final String startDate;
  final String endDate;
  final String? bannerUrl;
  final bool isOrganizerOrAdmin;
  final bool registrationOpen;
  final String? winnerName;
  final List<TournamentMatch> matches;
  final List<LeaderboardEntry> leaderboard;

  TournamentDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
    required this.isOrganizerOrAdmin,
    required this.registrationOpen,
    this.winnerName,
    required this.matches,
    required this.leaderboard,
  });

  factory TournamentDetail.fromJson(Map<String, dynamic> json) {
    return TournamentDetail(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      organizer: json['organizer_username'],
      startDate: json['start_date_formatted'],
      endDate: json['end_date_formatted'],
      bannerUrl: json['banner_url'],
      isOrganizerOrAdmin: json['is_organizer_or_admin'] ?? false,
      registrationOpen: json['registration_open'] ?? false,
      winnerName: json['winner_name'],
      matches: (json['matches'] as List)
          .map((m) => TournamentMatch.fromJson(m))
          .toList(),
      leaderboard: (json['leaderboard'] as List)
          .map((l) => LeaderboardEntry.fromJson(l))
          .toList(),
    );
  }
}

class TournamentMatch {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String date;
  final int? homeScore;
  final int? awayScore;
  final bool isFinished;

  TournamentMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    this.homeScore,
    this.awayScore,
    required this.isFinished,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      homeTeam: json['home_team_name'],
      awayTeam: json['away_team_name'],
      date: json['match_date_formatted'],
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      isFinished: json['is_finished'],
    );
  }
}

class LeaderboardEntry {
  final String teamName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalDifference;
  final int points;

  LeaderboardEntry({
    required this.teamName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalDifference,
    required this.points,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      teamName: json['team_name'],
      played: json['played'],
      wins: json['wins'],
      draws: json['draws'],
      losses: json['losses'],
      goalDifference: json['goal_difference'],
      points: json['points'],
    );
  }
}