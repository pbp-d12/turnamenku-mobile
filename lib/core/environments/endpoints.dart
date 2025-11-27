class Endpoints {
  static const String baseUrl =
      'https://gibran-tegar-turnamenku.pbp.cs.ui.ac.id';

  static const String homeData = '$baseUrl/api/home/';
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String userProfile = '$baseUrl/api/profile/';
  static const String updateProfile = '$baseUrl/api/profile/update/';

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
}
