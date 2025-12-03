import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/environments/endpoints.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/core/widgets/custom_snackbar.dart';
import 'package:turnamenku_mobile/features/forums/models/forum_tournament.dart';
import 'package:turnamenku_mobile/features/forums/screens/daftar_thread.dart';


class CreateThreadScreen extends StatefulWidget {
  final ForumTournament tournament;

  const CreateThreadScreen({Key? key, required this.tournament}) : super(key: key);

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
} 

class _CreateThreadScreenState extends State<CreateThreadScreen> {
    final _formKey = GlobalKey<FormState>();
    String _title = "";
    String _content = "";

    // Removed incorrect placeholder function. Navigation now uses existing pages.

    @override
    Widget build(BuildContext context) {
      final request = context.watch<CookieRequest>();
      return Scaffold(
        appBar: AppBar(
          title: Text('Buat Thread Baru'),
          backgroundColor: AppColors.blue400,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Judul Thread'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _title = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Isi Thread'),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Isi tidak boleh kosong';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _content = value!;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final response = await request.post(
                        Endpoints.createForumThread(widget.tournament.id),
                        {
                          'title': _title,
                          'content': _content,
                        },
                      );
                      if (response['success']) {
                        CustomSnackbar.show(
                          context,
                          'Thread berhasil dibuat',
                          SnackbarStatus.success,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DaftarThreadPage(tournament: widget.tournament),
                          ),
                        );
                      } else {
                        CustomSnackbar.show(
                          context,
                          'Gagal membuat thread',
                          SnackbarStatus.error,
                        );

                      }
                    }
                  },
                  child: Text('Buat Thread'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }