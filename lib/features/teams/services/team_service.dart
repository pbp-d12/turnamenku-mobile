import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import '../models/team.dart';

class TeamService {
  final CookieRequest request;

  TeamService(this.request);

  Future<Map<String, dynamic>> fetchTeams(String mode, int page, {String query = ''}) async {
    final qParam = Uri.encodeComponent(query);
    try {
      final response = await request.get('${Endpoints.searchTeams}?mode=$mode&page=$page&q=$qParam');
      
      if (response['status'] == 'success') {
        var listData = response['results'] ?? response['data'];
        List<Team> listTeams = [];
        if (listData != null) {
          for (var d in listData) {
            listTeams.add(Team.fromJson(d));
          }
        }
        return {'teams': listTeams, 'pagination': response['pagination'] ?? {}};
      }
      return {'teams': [], 'pagination': {}};
    } catch (e) {
      return {'teams': [], 'pagination': {}};
    }
  }

  Future<bool> _sendAction(String url) async {
    try {
      final response = await request.post(url, {});
      if (response is Map && response['status'] == 'success') return true;
      return true; 
    } catch (e) {
      if (e.toString().contains("SyntaxError") || e.toString().contains("Unexpected token")) {
         return true;
      }
      return false;
    }
  }

  Future<bool> joinTeam(int teamId) async {
    return _sendAction(Endpoints.joinTeam(teamId));
  }

  Future<bool> kickMember(int teamId, String username) async {
    return _sendAction(Endpoints.kickMember(teamId, username));
  }

  Future<bool> deleteTeam(int teamId) async {
    return _sendAction(Endpoints.deleteTeam(teamId));
  }

  Future<bool> leaveTeam(int teamId) async {
    return _sendAction(Endpoints.leaveTeam(teamId));
  }

  Future<Map<String, dynamic>> editTeam(int teamId, Map<String, dynamic> data) async {
    try {
      final response = await request.post(Endpoints.editTeam(teamId), data);
      if (response is Map) return Map<String, dynamic>.from(response);
      return {'status': 'success', 'message': 'Berhasil edit'};
    } catch (e) {
      if (e.toString().contains("SyntaxError") || e.toString().contains("Unexpected token")) {
         return {'status': 'success', 'message': 'Berhasil edit'};
      }
      return {'status': 'error', 'message': 'Gagal edit'};
    }
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data) async {
     return await request.postJson(Endpoints.createTeam, jsonEncode(data));
  }

  Future<Team> fetchTeamDetail(int id) async {
    final response = await request.get(Endpoints.teamDetail(id));
    return Team.fromJson(response);
  }
}