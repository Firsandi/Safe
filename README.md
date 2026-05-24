# SAFE Project - Tactical Emergency & Security System

Aplikasi sistem keamanan taktis terintegrasi yang terdiri dari **Frontend Flutter**, **Backend Go (Gin)**, dan **Supabase (PostgreSQL)** sebagai database utama. Aplikasi ini dirancang untuk mendeteksi kondisi darurat secara otomatis (seperti kecelakaan) dan memfasilitasi pengiriman sinyal darurat (SOS) secara cepat.

---

## 🌟 Fitur Utama (Frontend)
1. **Crash Detection (Sensor-based)**: Mendeteksi benturan/kecelakaan secara otomatis menggunakan sensor Akselerometer & Giroskop.
2. **Interactive SOS Countdown**: Hitung mundur darurat 15 detik sebelum alarm dikirimkan, dengan gesture slider **"Swipe to Cancel"** yang interaktif.
3. **Medical Information (Profil Medis)**: Penyimpanan golongan darah dan riwayat medis/alergi pengguna untuk mempercepat penanganan medis darurat.
4. **Google Sign-In**: Login cepat menggunakan akun Google (dengan UI custom modern).
5. **Emergency Contacts Management**: Daftar kontak darurat pilihan yang akan otomatis menerima pesan SOS.

---

## 🚀 Persiapan & Konfigurasi

### A. Backend & Database Produksi
* **Backend**: Menggunakan **Go (Gin)** yang dideploy di **Railway**.
  - **Production Base URL**: `https://safe-backend-production-abb2.up.railway.app/`
* **Database**: Menggunakan **PostgreSQL** yang di-host di **Supabase**.

### B. Persiapan Frontend (Flutter)
1. Masuk ke direktori root proyek Flutter (lokasi `pubspec.yaml`), lalu jalankan:
   ```bash
   flutter pub get
   ```

2. **Konfigurasi API Base URL**:
   Buka file `lib/core/utils/injection.dart` dan pastikan `baseUrl` pada objek `Dio` mengarah ke backend produksi:
   `https://safe-backend-production-abb2.up.railway.app/`

3. **Menjalankan Aplikasi**:
   Pastikan emulator atau perangkat fisik (disarankan untuk tes sensor) terhubung, lalu jalankan:
   ```bash
   flutter run
   ```

---
*Developed with ❤️ by SAFE Team*
