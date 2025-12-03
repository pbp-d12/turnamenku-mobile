import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import '../models/team.dart';

class TeamService {
  final CookieRequest request;

  TeamService(this.request);

  // Fetch List Tim (Mode: 'meet', 'manage', 'join')
  Future<Map<String, dynamic>> fetchTeams(String mode, int page, {String query = ''}) async {
    final qParam = Uri.encodeComponent(query);
    final url = '${Endpoints.searchTeams}?mode=$mode&page=$page&q=$qParam';
    // DEBUG: Print URL yang dipanggil
    print("Fetching URL: $url"); 

    final response = await request.get(url);

    // DEBUG: Print Response JSON Mentah
    print("Response JSON: $response");

    if (response['status'] == 'success') {
      var listData = response['results'];
      List<Team> listTeams = [];
      for (var d in listData) {
        if (d != null) listTeams.add(Team.fromJson(d));
      }
      // Return Data Tim + Pagination Info
      return {
        'teams': listTeams,
        'pagination': response['pagination']
      };
    }
    throw Exception('Gagal load tim');
  }

  // Gabung Tim
  Future<bool> joinTeam(int teamId) async {
    final response = await request.post(Endpoints.joinTeam(teamId), {});
    return response['status'] == 'success';
  }

  // Detail Tim
  Future<Team> fetchTeamDetail(int id) async {
    final response = await request.get(Endpoints.teamDetail(id));
    return Team.fromJson(response);
  }

  // Kick Member
  Future<bool> kickMember(int teamId, String username) async {
    final response = await request.post(Endpoints.kickMember(teamId, username), {});
    return response['status'] == 'success';
  }

  // Hapus Tim
  Future<bool> deleteTeam(int teamId) async {
    final response = await request.post(Endpoints.deleteTeam(teamId), {});
    return response['status'] == 'success';
  }

  // Leave Tim
  Future<bool> leaveTeam(int teamId) async {
    final response = await request.post(Endpoints.leaveTeam(teamId), {});
    return response['status'] == 'success';
  }

  // Edit Tim
  Future<Map<String, dynamic>> editTeam(int teamId, Map<String, dynamic> data) async {
    return await request.post(Endpoints.editTeam(teamId), data);
  }

  // Buat Tim
  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data) async {
     return await request.postJson(Endpoints.createTeam, data);
  }
}