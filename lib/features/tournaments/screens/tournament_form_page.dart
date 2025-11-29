import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/tournaments/models/tournament_detail.dart';
import 'package:intl/intl.dart';

class TournamentFormPage extends StatefulWidget {
  final TournamentDetail? tournament; // Jika null -> Mode Create, Jika ada -> Mode Edit

  const TournamentFormPage({super.key, this.tournament});

  @override
  State<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends State<TournamentFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _bannerController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data jika mode edit
    _nameController = TextEditingController(text: widget.tournament?.name ?? '');
    _descController = TextEditingController(text: widget.tournament?.description ?? '');
    _bannerController = TextEditingController(text: widget.tournament?.bannerUrl ?? '');
    
    // Format tanggal untuk controller (UI)
    // Note: Model TournamentDetail Anda menyimpan format "12 Nov 2025" atau "2025-11-12". 
    // Kita asumsikan backend mengirim data raw juga atau kita parse. 
    // Untuk simplifikasi, kita kosongkan dulu saat edit atau gunakan data yang ada jika formatnya YYYY-MM-DD.
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    
    // Tips: Jika Anda ingin pre-fill tanggal dengan benar saat edit, 
    // pastikan model TournamentDetail menyimpan format 'yyyy-MM-dd' juga.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _bannerController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // Fungsi Helper untuk DatePicker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isEdit = widget.tournament != null;
    final url = isEdit 
        ? Endpoints.editTournament(widget.tournament!.id)
        : Endpoints.createTournament;

    final body = {
      'name': _nameController.text,
      'description': _descController.text,
      'banner': _bannerController.text,
      'start_date': _startDateController.text,
      'end_date': _endDateController.text,
      // 'registration_open': true, // Optional, default true
    };

    try {
      final response = await request.postJson(url, jsonEncode(body));

      if (!mounted) return;

      if (response['status'] == 'success') {
        CustomSnackbar.show(context, response['message'], SnackbarStatus.success);
        Navigator.pop(context, true); // Return true to signal refresh needed
      } else {
        CustomSnackbar.show(
          context, 
          response['message'] ?? "Gagal menyimpan turnamen.", 
          SnackbarStatus.error
        );
        // Jika ada error spesifik form dari Django
        if (response['errors'] != null) {
          print("Form Errors: ${response['errors']}");
        }
      }
    } catch (e) {
      if (mounted) CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isEdit = widget.tournament != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Tournament" : "Create Tournament"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAMA
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Tournament Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // DESKRIPSI
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // TANGGAL (Start & End)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Start Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _startDateController),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "End Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _endDateController),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // BANNER URL
              TextFormField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  labelText: "Banner Image URL",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: "http://example.com/image.jpg",
                ),
              ),
              const SizedBox(height: 24),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitForm(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "Update Tournament" : "Create Tournament", style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}