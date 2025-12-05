import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/features/teams/models/team.dart';
import 'package:turnamenku_mobile/features/teams/services/team_service.dart';

class FakeCookieRequest extends CookieRequest {
  bool forceSyntaxError = false;
  bool forceNetworkError = false;
  bool forceApiError = false;
  dynamic mockGetResponse;

  void reset() {
    forceSyntaxError = false;
    forceNetworkError = false;
    forceApiError = false;
    mockGetResponse = null;
  }

  @override
  Future<dynamic> get(String url) async {
    if (forceNetworkError) throw Exception("Network Error");
    return mockGetResponse;
  }

  @override
  Future<dynamic> post(String url, dynamic data) async {
    if (forceNetworkError) throw Exception("Connection Refused");

    if (forceSyntaxError) {
      throw const FormatException("SyntaxError: Unexpected token <");
    }

    if (forceApiError) {
      return {'status': 'error', 'message': 'Gagal'};
    }

    return {'status': 'success', 'message': 'Berhasil'};
  }

  @override
  Future<dynamic> postJson(String url, dynamic data) async {
    if (forceNetworkError) throw Exception("Connection Refused");
    return {'status': 'success', 'message': 'Created', 'team_id': 123};
  }
}

void main() {
  late FakeCookieRequest fakeRequest;
  late TeamService teamService;

  final teamJson = {
    "id": 1,
    "name": "Tim Garuda",
    "logo": "http://logo.com/img.png",
    "captain": "Budi",
    "members_count": 5,
    "members": ["Budi", "Ani", "Siti"]
  };

  setUp(() {
    fakeRequest = FakeCookieRequest();
    teamService = TeamService(fakeRequest);
  });

  group('1. Model Team Tests', () {
    test('Parsing JSON valid', () {
      final team = Team.fromJson(teamJson);
      expect(team.name, "Tim Garuda");
      expect(team.members.length, 3);
      expect(team.logo, "http://logo.com/img.png");
    });

    test('Parsing JSON dengan nilai null', () {
      final nullJson = {
        "id": 2,
        "name": "Tim Kosong",
        "logo": null,
        "captain": null,
        "members_count": 0,
        "members": null
      };
      final team = Team.fromJson(nullJson);

      expect(team.logo, "");
      expect(team.captain, anyOf("No Captain", "Unknown")); 
      expect(team.members, []);
    });

    test('toJson works correctly', () {
      final team = Team(
        id: 1, 
        name: "Tes", 
        logo: "Logo", 
        captain: "Me", 
        membersCount: 1, 
        members: ["Me"]
      );
      final jsonMap = team.toJson();
      expect(jsonMap['name'], "Tes");
      expect(jsonMap['logo'], "Logo");
    });
  });

  group('2. TeamService Tests', () {
    test('fetchTeams: Sukses load data', () async {
      fakeRequest.mockGetResponse = {
        "status": "success",
        "results": [teamJson],
        "pagination": {}
      };
      final result = await teamService.fetchTeams('join', 1);
      expect(result['teams'], isNotEmpty);
      expect((result['teams'][0] as Team).name, "Tim Garuda");
    });

    test('fetchTeams: Return kosong saat error', () async {
      fakeRequest.forceNetworkError = true;
      final result = await teamService.fetchTeams('join', 1);
      expect(result['teams'], isEmpty);
    });

    test('joinTeam: Return TRUE jika server balas JSON success', () async {
      final success = await teamService.joinTeam(1);
      expect(success, true);
    });

    test('joinTeam: Return TRUE jika server balas HTML (Redirect/SyntaxError)', () async {
      fakeRequest.forceSyntaxError = true;
      final success = await teamService.joinTeam(1);
      expect(success, true);
    });

    test('joinTeam: Return FALSE jika koneksi putus beneran', () async {
      fakeRequest.forceNetworkError = true;
      final success = await teamService.joinTeam(1);
      expect(success, false);
    });

    test('editTeam: Return fake success map jika kena SyntaxError', () async {
      fakeRequest.forceSyntaxError = true;
      final result = await teamService.editTeam(1, {'name': 'Baru'});
      expect(result['status'], 'success');
    });

    test('createTeam: Menggunakan postJson', () async {
      final result = await teamService.createTeam({'name': 'Baru', 'logo': ''});
      expect(result['status'], 'success');
    });
    
    test('leaveTeam & deleteTeam & kickMember basic flow', () async {
       expect(await teamService.leaveTeam(1), true);
       expect(await teamService.deleteTeam(1), true);
       expect(await teamService.kickMember(1, 'User'), true);
    });
  });
}