import 'package:flutter/material.dart';
// Pastikan import LeftDrawer dan AppColors kamu benar
import 'package:turnamenku_mobile/core/widgets/left_drawer.dart'; 
import 'package:turnamenku_mobile/core/theme/app_theme.dart'; 

class TeamSelectionPage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const TeamSelectionPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Turnamenku",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.blue400, // Sesuaikan primary color
        foregroundColor: Colors.white, // Warna teks/icon header
      ),
      
      drawer: LeftDrawer(userData: userData),
      
      backgroundColor: AppColors.blue50, // Background sesuai request sebelumnya
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildCard(
                    context,
                    icon: Icons.analytics_outlined,
                    title: "Tim Kamu",
                    description:
                        "Saatnya melihat siapa partner kamu! Cek detail tim kamu dan mulai rencanakan langkah selanjutnya!. GASKEUNN!!!",
                    buttonText: "Mana teamku?",
                    onPressed: () {},
                  ),
                  _buildCard(
                    context,
                    icon: Icons.groups_outlined,
                    title: "Gabung Tim",
                    description:
                        "Kamu butuh team? mungkin dari sini perjalanan kamu dimulai. Ga mungkin ditolak jadi member karena pasti diterima.",
                    buttonText: "Aku butuh tim",
                    onPressed: () {},
                  ),
                  _buildCard(
                    context,
                    icon: Icons.manage_accounts_outlined,
                    title: "Kelola Tim",
                    description:
                        "Sebagai kapten mengeluarkan anggota team dan mengganti komponen team lainnya adalah hal yang mudah.",
                    buttonText: "Saatnya bekerja",
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71), // Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Buat Tim Baru",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Jadilah kapten dari teammu sendiri!",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 320,
      height: 350,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(icon, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154378), // Dark Blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}