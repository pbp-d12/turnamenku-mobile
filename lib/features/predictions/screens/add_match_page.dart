import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';

class AddMatchPage extends StatefulWidget {
  const AddMatchPage({super.key});

  @override
  State<AddMatchPage> createState() => _AddMatchPageState();
}

class _AddMatchPageState extends State<AddMatchPage> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String? _selectedTournamentId;
  String? _selectedHomeTeamId;
  String? _selectedAwayTeamId;
  DateTime? _selectedDate;

  // Data
  bool _isLoading = true;
  List<Map<String, dynamic>> _tournaments = [];
  Map<String, List<dynamic>> _teamsByTournament = {};
  List<dynamic> _currentAvailableTeams = [];

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _fetchFormData(request);
  }

  Future<void> _fetchFormData(CookieRequest request) async {
    try {
      final response = await request.get(Endpoints.predictionFormData);
      setState(() {
        _tournaments = List<Map<String, dynamic>>.from(response['tournaments']);
        _teamsByTournament = {};
        var rawData = response['teams_by_tournament'];
        if (rawData != null && rawData is Map) {
          rawData.forEach((key, value) {
            _teamsByTournament[key.toString()] = List<dynamic>.from(value);
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data form: $e")));
      }
    }
  }

  void _onTournamentChanged(String? newTournamentId) {
    setState(() {
      _selectedTournamentId = newTournamentId;
      _selectedHomeTeamId = null;
      _selectedAwayTeamId = null;
      if (newTournamentId != null &&
          _teamsByTournament.containsKey(newTournamentId)) {
        _currentAvailableTeams = _teamsByTournament[newTournamentId]!;
      } else {
        _currentAvailableTeams = [];
      }
    });
  }

  Future<void> _submitMatch(CookieRequest request) async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final response = await request.postJson(
        Endpoints.predictionCreateMatch,
        jsonEncode({
          'tournament': _selectedTournamentId,
          'home_team': _selectedHomeTeamId,
          'away_team': _selectedAwayTeamId,
          'match_date': _selectedDate!.toIso8601String().substring(0, 10),
        }),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pertandingan berhasil dibuat!")),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${response['message']}")),
          );
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih tanggal pertandingan")),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue400,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper untuk styling Dropdown agar seragam
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue300, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.blue50,
      appBar: AppBar(
        title: const Text(
          "Tambah Pertandingan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blue400),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration("Pilih Turnamen"),
                            value: _selectedTournamentId,
                            items: _tournaments.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['id'].toString(),
                                child: Text(t['name']),
                              );
                            }).toList(),
                            onChanged: _onTournamentChanged,
                            validator: (val) =>
                                val == null ? "Wajib dipilih" : null,
                          ),
                          const SizedBox(height: 16),

                          if (_selectedTournamentId == null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.blue50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Pilih turnamen terlebih dahulu untuk melihat daftar tim.",
                                style: TextStyle(color: AppColors.blue400),
                              ),
                            ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration("Tim Kandang (Home)"),
                            value: _selectedHomeTeamId,
                            items: _currentAvailableTeams.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['id'].toString(),
                                child: Text(t['name']),
                              );
                            }).toList(),
                            onChanged: _selectedTournamentId == null
                                ? null
                                : (val) =>
                                      setState(() => _selectedHomeTeamId = val),
                            validator: (val) =>
                                val == null ? "Wajib dipilih" : null,
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration("Tim Tandang (Away)"),
                            value: _selectedAwayTeamId,
                            items: _currentAvailableTeams.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['id'].toString(),
                                child: Text(t['name']),
                              );
                            }).toList(),
                            onChanged: _selectedTournamentId == null
                                ? null
                                : (val) =>
                                      setState(() => _selectedAwayTeamId = val),
                            validator: (val) {
                              if (val == null) return "Wajib dipilih";
                              if (val == _selectedHomeTeamId) {
                                return "Tim tidak boleh sama";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            tileColor: Colors.white,
                            title: Text(
                              _selectedDate == null
                                  ? "Pilih Tanggal Pertandingan"
                                  : "Tanggal: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.grey[600]
                                    : Colors.black87,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.calendar_today,
                              color: AppColors.blue400,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _submitMatch(request),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: AppColors.blue400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Simpan Pertandingan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
