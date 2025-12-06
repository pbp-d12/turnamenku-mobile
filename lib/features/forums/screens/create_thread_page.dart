import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';

class CreateThreadPage extends StatefulWidget {
  final int tournamentId;

  const CreateThreadPage({super.key, required this.tournamentId});

  @override
  State<CreateThreadPage> createState() => _CreateThreadPageState();
}

class _CreateThreadPageState extends State<CreateThreadPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imageController = TextEditingController();
  
  String _title = "";
  String _body = "";
  
  String _previewImageUrl = ""; 
  
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _imageController.addListener(_onImageUrlChanged);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onImageUrlChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      String rawUrl = _imageController.text.trim();
      
      if (rawUrl.isEmpty) {
        setState(() => _previewImageUrl = "");
        return;
      }

      String fixedUrl = rawUrl;
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        fixedUrl = 'https://$rawUrl';
      }

      if (fixedUrl != _previewImageUrl) {
        setState(() {
          _previewImageUrl = fixedUrl;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    String rawUrl = _imageController.text.trim();
    String finalImageUrl = rawUrl;
    if (rawUrl.isNotEmpty && !rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      finalImageUrl = 'https://$rawUrl';
    }

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();
    final url = Endpoints.createForumThread(widget.tournamentId);

    try {
      final response = await request.post(url, {
        'title': _title,
        'body': _body,
        'image': finalImageUrl, 
      });

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (response['success'] == true) {
          CustomSnackbar.show(context, "Thread berhasil dibuat!", SnackbarStatus.success);
          Navigator.pop(context, true); 
        } else {
          CustomSnackbar.show(
            context, 
            "Gagal: ${response['error'] ?? 'Terjadi kesalahan'}", 
            SnackbarStatus.error
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.show(context, "Error: $e", SnackbarStatus.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Buat Thread Baru", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
        ),
        backgroundColor: AppColors.blue400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Judul Thread", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Contoh: Strategi Tim Terbaik...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
                validator: (value) => value == null || value.isEmpty ? "Judul tidak boleh kosong" : null,
                onSaved: (value) => _title = value!,
              ),
              
              const SizedBox(height: 20),
              
              const Text("Isi Thread", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Tuliskan pendapat atau pertanyaan Anda di sini...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6, 
                minLines: 4,
                validator: (value) => value == null || value.isEmpty ? "Isi Thread tidak boleh kosong" : null,
                onSaved: (value) => _body = value!,
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Media", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  ValueListenableBuilder(
                    valueListenable: _imageController,
                    builder: (context, TextEditingValue value, __) {
                      return Text(
                        value.text.isEmpty ? "" : "${value.text.length} chars", 
                        style: TextStyle(
                          fontSize: 12, 
                          color: value.text.length > 50 ? Colors.orange : Colors.grey
                        )
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  hintText: "URL Gambar (Opsional)",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.url,
              ),

              if (_previewImageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Pratinjau Gambar:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _previewImageUrl, 
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.red[50],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(height: 4),
                              Text("Gambar tidak ditemukan / Link rusak", style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        "Kirim Thread", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}