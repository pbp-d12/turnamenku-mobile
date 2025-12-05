import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart'; 
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/team_logo.dart';
import '../services/team_service.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = "";
  String _logo = "";
  final Color bgColor = const Color(0xFFDDE6ED);

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final teamService = TeamService(request);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Buat Tim", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.blue400, 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 40, backgroundColor: Colors.green[100], child: const Icon(Icons.group_add, size: 40, color: Colors.green)),
                  const SizedBox(height: 20),
                  const Text("Mulai Perjalananmu!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Isi detail tim kamu di bawah ini", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Nama Tim", prefixIcon: const Icon(Icons.flag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                    onChanged: (v) => _name = v,
                    validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(labelText: "URL Logo (Opsional)", prefixIcon: const Icon(Icons.image), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                    onChanged: (v) => setState(() => _logo = v),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_logo.isNotEmpty) ...[
                    const Text("Preview Logo:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    TeamLogo(url: _logo, radius: 30),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D13B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final response = await request.postJson(Endpoints.createTeam, 
                            jsonEncode({'name': _name, 'logo': _logo})
                          );

                          if (context.mounted) {
                            if (response['status'] == 'success') {
                              CustomSnackbar.show(context, "Tim berhasil dibuat! 🚀", SnackbarStatus.success);
                              Navigator.pop(context);
                            } else {
                              CustomSnackbar.show(context, response['message'] ?? "Gagal buat tim", SnackbarStatus.error);
                            }
                          }
                        }
                      },
                      child: const Text("Buat Tim", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}