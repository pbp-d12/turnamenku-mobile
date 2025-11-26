class HomeData {
  final bool status;
  final List<dynamic> ongoingTournaments;
  final List<dynamic> upcomingMatches;
  final List<dynamic> recentThreads;
  final List<dynamic> topPredictors;
  final Map<String, dynamic>? userData; // Bisa null kalau Guest
  final Map<String, dynamic> stats;

  HomeData({
    required this.status,
    required this.ongoingTournaments,
    required this.upcomingMatches,
    required this.recentThreads,
    required this.topPredictors,
    this.userData,
    required this.stats,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      status: json['status'] ?? false,
      ongoingTournaments: json['ongoing_tournaments'] ?? [],
      upcomingMatches: json['upcoming_matches'] ?? [],
      recentThreads: json['recent_threads'] ?? [],
      topPredictors: json['top_predictors'] ?? [],
      userData: json['user_data'], // Otomatis null jika JSON-nya null
      stats:
          json['stats'] ??
          {
            'tournaments_count': 0,
            'matches_count': 0,
            'threads_count': 0,
            'predictors_count': 0,
          },
    );
  }
}
