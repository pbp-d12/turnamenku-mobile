import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';

class AuthService {
  final CookieRequest request;

  AuthService(this.request);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await request.login(
        Endpoints.login,
        jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );
      return response;
    } catch (e) {
      return {"status": false, "message": "Gagal koneksi: $e"};
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password,
    String passwordConf,
    String email, // BARU: Tambah email
    String role, // BARU: Tambah role
  ) async {
    final response = await request.postJson(
      Endpoints.register,
      jsonEncode(<String, String>{
        'username': username,
        'email': email, // BARU: Kirim email
        'password': password,
        'password_confirmation': passwordConf,
        'role': role, // BARU: Kirim role
      }),
    );
    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await request.logout(Endpoints.logout);
    return response;
  }
}
