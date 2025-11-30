class Endpoints {
  static const String baseUrl =
      'https://gibran-tegar-turnamenku.pbp.cs.ui.ac.id';

  static const String homeData = '$baseUrl/api/home/';
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String userProfile = '$baseUrl/api/profile/';
  static const String updateProfile = '$baseUrl/api/profile/update/';
  static const String searchProfiles = '$baseUrl/api/search/';
  static const String changePassword = '$baseUrl/api/change-password/';

  //tournaments endpoints
  static const String tournaments = '$baseUrl/tournaments/json/';
  static const String createTournament = '$baseUrl/tournaments/create/';
  static String tournamentDetail(int id) => '$baseUrl/tournaments/json/$id/';
  static String editTournament(int id) => '$baseUrl/tournaments/edit/$id/';
  static String deleteTournament(int id) => '$baseUrl/tournaments/delete/$id/';
  static String registerTeam(int id) =>
      '$baseUrl/tournaments/$id/register_team/';
  static String deregisterTeam(int id) =>
      '$baseUrl/tournaments/$id/deregister_team/';
  static String checkCaptainStatus(int id) =>
      '$baseUrl/tournaments/captain_status/$id/';

  // Predictions endpoints
  static const String predictionMatches = '$baseUrl/predictions/api/matches/';
  static const String predictionLeaderboard =
      '$baseUrl/predictions/api/leaderboard/';
  static const String predictionSubmit = '$baseUrl/predictions/api/submit/';
  static const String predictionFormData =
      '$baseUrl/predictions/api/get-form-data/';
  static const String predictionCreateMatch =
      '$baseUrl/predictions/api/create-match/';
  static const String predictionEditScore =
      '$baseUrl/predictions/api/edit-score/';
  static const String predictionDelete =
      '$baseUrl/predictions/api/delete-prediction/';
  static const String forumSearch = '$baseUrl/forums/api/search/';
  static String forumThreads(int id) => '$baseUrl/forums/api/tournament/$id/threads/';
  static String forumPosts(int id) => '$baseUrl/forums/api/thread/$id/posts/';
}
