import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  String _oldPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  Widget _buildPasswordField({
    required String label,
    required Function(String) onChanged,
    required String? Function(String?)? validator,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.blue300, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Ganti Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.blue400,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 512),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Ubah Kata Sandi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildPasswordField(
                    label: "Password Lama",
                    obscureText: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                    onChanged: (val) => _oldPassword = val,
                    validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(
                    label: "Password Baru",
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: (val) => _newPassword = val,
                    validator: (val) {
                      if (val!.isEmpty) return "Wajib diisi";
                      if (val.length < 8) return "Minimal 8 karakter";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(
                    label: "Konfirmasi Password Baru",
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: (val) => _confirmPassword = val,
                    validator: (val) {
                      if (val!.isEmpty) return "Wajib diisi";
                      if (val != _newPassword) return "Password tidak cocok";
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  final response = await request.postJson(
                                    Endpoints.changePassword,
                                    jsonEncode({
                                      'old_password': _oldPassword,
                                      'new_password': _newPassword,
                                      'confirm_password': _confirmPassword,
                                    }),
                                  );

                                  if (context.mounted) {
                                    if (response['status'] == 'success') {
                                      CustomSnackbar.show(
                                        context,
                                        "Password berhasil diubah!",
                                        SnackbarStatus.success,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      CustomSnackbar.show(
                                        context,
                                        response['message'] ??
                                            "Gagal mengubah password.",
                                        SnackbarStatus.error,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    CustomSnackbar.show(
                                      context,
                                      "Terjadi kesalahan koneksi.",
                                      SnackbarStatus.error,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Simpan Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
