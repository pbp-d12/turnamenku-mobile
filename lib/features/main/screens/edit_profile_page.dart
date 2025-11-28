import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late String _username;
  late String _email;
  late String _bio;
  late String _profilePicture;
  late String _role;

  late bool _canEditUsername;

  @override
  void initState() {
    super.initState();
    _username = widget.userData['username'] ?? "";
    _email = widget.userData['email'] ?? "";
    _bio = widget.userData['bio'] ?? "";
    _profilePicture = widget.userData['profile_picture'] ?? "";

    _role = (widget.userData['role'] ?? "PEMAIN").toString().toUpperCase();
    _canEditUsername = widget.userData['can_edit_username'] ?? false;
  }

  Widget _buildProfileImagePreview() {
    String finalUrl;
    if (_profilePicture.isNotEmpty) {
      if (_profilePicture.startsWith('http')) {
        finalUrl = _profilePicture;
      } else {
        finalUrl =
            "${Endpoints.baseUrl}${_profilePicture.startsWith('/') ? '' : '/'}$_profilePicture";
      }
    } else {
      finalUrl = "${Endpoints.baseUrl}/static/images/default_avatar.png";
    }

    return Container(
      width: 150,
      height: 150,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue100, width: 4),
        color: Colors.black,
      ),
      child: ClipOval(
        child: Image.network(
          finalUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: const Icon(Icons.person, size: 80, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    String? helperText,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
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
          initialValue: initialValue,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
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
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    bool isTargetAdmin = (widget.userData['role'] == 'ADMIN');
    List<String> roleOptions = ['PENYELENGGARA', 'PEMAIN'];

    if (isTargetAdmin) {
      if (!roleOptions.contains('ADMIN')) {
        roleOptions.add('ADMIN');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Role",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _role,
          items: roleOptions.map((String role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Text(
                role,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: isTargetAdmin
              ? null
              : (String? newValue) {
                  setState(() {
                    _role = newValue!;
                  });
                },
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: isTargetAdmin ? Colors.grey[100] : Colors.white,
            helperText: isTargetAdmin
                ? "Role Admin tidak dapat diubah."
                : "Pilih role Anda.",
            helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    bool isAdminAccount = (widget.userData['role'] == 'ADMIN');

    String displayTitle = "Edit Profil ${widget.userData['username']}";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Profil",
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
                  Text(
                    displayTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildProfileImagePreview(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: "Username",
                        initialValue: _username,
                        enabled: _canEditUsername,
                        helperText: _canEditUsername
                            ? "Username bisa diedit (Mode Admin)."
                            : (isAdminAccount
                                  ? "Username Admin permanen."
                                  : "Hubungi Admin untuk ubah username."),
                        onChanged: (val) => _username = val,
                        validator: (val) =>
                            val!.isEmpty ? "Username wajib diisi" : null,
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        label: "Email address",
                        initialValue: _email,
                        onChanged: (val) => _email = val,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Email wajib diisi";
                          }
                          final emailRegex = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          );
                          if (!emailRegex.hasMatch(val)) {
                            return "Format email tidak valid";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        label: "URL Foto Profil",
                        initialValue: _profilePicture,
                        helperText:
                            "Masukkan link gambar (akhiri dengan .png/.jpg)",
                        onChanged: (val) {
                          setState(() {
                            _profilePicture = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildRoleDropdown(),
                      const SizedBox(height: 24),

                      _buildTextField(
                        label: "Bio",
                        initialValue: _bio,
                        maxLines: 3,
                        onChanged: (val) => _bio = val,
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final response = await request.postJson(
                                Endpoints.updateProfile,
                                jsonEncode({
                                  'id': widget.userData['id'],
                                  'username': _username,
                                  'email': _email,
                                  'bio': _bio,
                                  'profile_picture': _profilePicture,
                                  'role': _role,
                                }),
                              );

                              if (context.mounted) {
                                if (response['status'] == 'success') {
                                  CustomSnackbar.show(
                                    context,
                                    "Profil berhasil diperbarui!",
                                    SnackbarStatus.success,
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  CustomSnackbar.show(
                                    context,
                                    response['message'] ?? "Gagal update.",
                                    SnackbarStatus.error,
                                  );
                                }
                              }
                            }
                          },
                          child: const Text(
                            "Simpan Perubahan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
