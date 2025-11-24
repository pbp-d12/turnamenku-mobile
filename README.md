# README PBP 2025/2026 D-12 PAS

---

## Anggota Kelompok
* **2406413842** - Gibran Tegar Ramadhan Putra Lynardi
* **2406495786** - Izzudin Abdul Rasyid
* **2406407266** - Hillary Elizabeth Clara Pasaribu
* **2406361712** - Muhathir Muhammad Radian Oki
* **2406347424** - Bermulya Anugrah Putra

---

## Tautan Penting
* **Tautan APK:** *(Akan ditambahkan setelah Tahap II selesai)*
* **Link Design Figma:** [Klik di sini untuk melihat desain Figma](https://www.figma.com/design/YH1UAtsqAUqK75yXMdK64S/Turnamenku-Design?node-id=1-2&p=f&t=1R1eB2GkLPTcDFhc-0)
* **Link Website (PWS):** [https://gibran-tegar-turnamenku.pbp.cs.ui.ac.id](https://gibran-tegar-turnamenku.pbp.cs.ui.ac.id)

---

## Deskripsi Aplikasi
**Turnamenku** adalah aplikasi manajemen turnamen berbasis *mobile* yang dirancang untuk mempermudah penyelenggara dalam mengelola event dan memberikan pengalaman interaktif bagi peserta. Aplikasi ini terintegrasi langsung dengan layanan web Turnamenku, memungkinkan pengguna untuk mengakses fitur-fitur utama seperti manajemen jadwal, pendaftaran tim, forum diskusi, dan prediksi pertandingan secara *real-time* dari perangkat seluler mereka.

Fitur utama aplikasi ini meliputi pembuatan turnamen, manajemen tim, papan skor interaktif, forum komunitas per turnamen, serta fitur gamifikasi berupa prediksi pemenang pertandingan.

---

## Daftar Modul & Pembagian Kerja
Aplikasi ini terdiri dari 5 modul utama yang terintegrasi. Berikut adalah rincian fungsionalitas dan pembagian tanggung jawab pengembangan (PIC) untuk setiap anggota:

| Nama Modul | Deskripsi Fitur | Penanggung Jawab (PIC) |
| :--- | :--- | :--- |
| **User Profile & Auth** (`main`) | Menangani registrasi, login, logout, serta tampilan dan pengeditan profil pengguna (Bio, Foto, Role). | **Gibran Tegar Ramadhan P. L.** |
| **Tournaments** (`tournaments`) | Menampilkan daftar turnamen, detail turnamen, pencarian, dan jadwal pertandingan (*Match*). | **Izzudin Abdul Rasyid** |
| **Teams** (`teams`) | Mengelola pembuatan tim, daftar anggota tim, serta fitur bergabung (*join*) atau keluar (*leave*) dari tim. | **Hillary Elizabeth Clara P.** |
| **Forum** (`forums`) | Menyediakan wadah diskusi (Thread & Comments) spesifik untuk setiap turnamen dengan tampilan interaktif. | **Muhathir Muhammad R. O.** |
| **Prediction** (`predictions`) | Fitur *voting* prediksi pemenang pertandingan dan menampilkan *leaderboard* poin pengguna. | **Bermulya Anugrah Putra** |

*(Catatan: Sesuaikan kolom PIC di atas dengan pembagian tugas aktual kelompok kalian)*

---

## Peran Pengguna (User Roles)
Aplikasi ini membedakan hak akses berdasarkan dua peran utama:

### 1. Penyelenggara (Tournament Maker)
Peran ini memiliki kontrol penuh terhadap event yang mereka buat.
* **Hak Akses:** Dapat membuat turnamen baru, mengedit detail turnamen, dan memperbarui skor pertandingan.
* **Fitur Tambahan:** Memiliki akses ke semua fitur yang dimiliki oleh Pemain.

### 2. Pemain (Player)
Peran standar bagi pengguna umum yang ingin berpartisipasi.
* **Hak Akses:** Dapat mendaftar, mengedit profil pribadi, melihat daftar turnamen, dan melihat detail pertandingan.
* **Interaksi:** Dapat membuat atau bergabung dengan tim, berdiskusi di forum, dan melakukan prediksi skor.

---

## Alur Pengintegrasian Data (Flutter & Django PWS)

Aplikasi mobile ini bekerja sebagai *client-side application* yang mengambil dan mengirim data ke server Django (PWS) yang telah dibuat sebelumnya. Berikut adalah mekanisme integrasinya:

1.  **Request Data (Flutter to Django):**
   * Aplikasi Flutter menggunakan library `pbp_django_auth` (atau `http`) untuk melakukan permintaan HTTP (GET/POST) ke URL endpoint di server Django.
   * Contoh: Untuk mengambil daftar turnamen, Flutter melakukan `GET` ke `https://.../tournaments/json/`.
   * Untuk fitur yang butuh login (seperti *Join Team*), request menyertakan *cookies* otentikasi yang disimpan dari proses login sebelumnya.

2.  **Processing (Django Server):**
   * Server Django menerima request tersebut melalui `views.py`.
   * Django mengolah logika bisnis (misalnya: memvalidasi apakah user boleh join tim).
   * Data dikembalikan dalam format **JSON** (bukan HTML Template).

3.  **Parsing & Rendering (Flutter):**
   * Flutter menerima respon JSON dari server.
   * Data JSON tersebut di-*parsing* menjadi objek Dart (Model) menggunakan fungsi `fromJson`.
   * Data yang sudah menjadi objek kemudian ditampilkan ke layar pengguna menggunakan Widget (seperti `ListView`, `Text`, atau `Card`).

4.  **State Management:**
   * Jika pengguna melakukan aksi (misal: mengirim komentar), Flutter mengirim `POST` request.
   * Jika server merespons "sukses", Flutter akan melakukan `setState` atau me-refresh tampilan untuk memunculkan data terbaru tanpa perlu me-restart aplikasi.
