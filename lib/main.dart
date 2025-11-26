import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:turnamenku_mobile/core/theme/app_theme.dart';
import 'package:turnamenku_mobile/features/main/screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Turnamenku Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.blue400,
            primary: AppColors.blue400,
            background: AppColors.blue50,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.blue50,
          fontFamily: 'Poppins', // Kalau udah nambah font
        ),
        home: const HomePage(), // Start as Guest
      ),
    );
  }
}
