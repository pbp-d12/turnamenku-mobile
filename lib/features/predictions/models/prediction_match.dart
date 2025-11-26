import 'dart:convert';

List<PredictionMatch> predictionMatchFromJson(String str) =>
    List<PredictionMatch>.from(json.decode(str).map((x) => PredictionMatch.fromJson(x)));

class PredictionMatch {
  int id;
  String tournament;
  String homeTeam;
  int homeTeamId;
  String awayTeam;
  int awayTeamId;
  String matchDate;
  int homeScore;
  int awayScore;
  bool isFinished;
  int? userPredictionTeamId;

  PredictionMatch({
    required this.id,
    required this.tournament,
    required this.homeTeam,
    required this.homeTeamId,
    required this.awayTeam,
    required this.awayTeamId,
    required this.matchDate,
    required this.homeScore,
    required this.awayScore,
    required this.isFinished,
    this.userPredictionTeamId,
  });

  factory PredictionMatch.fromJson(Map<String, dynamic> json) => PredictionMatch(
        id: json["id"],
        tournament: json["tournament"],
        homeTeam: json["home_team"],
        homeTeamId: json["home_team_id"],
        awayTeam: json["away_team"],
        awayTeamId: json["away_team_id"],
        matchDate: json["match_date"],
        homeScore: json["home_score"],
        awayScore: json["away_score"],
        isFinished: json["is_finished"],
        userPredictionTeamId: json["user_prediction_team_id"],
      );
}