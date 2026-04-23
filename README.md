# SAFE Project - Tactical Emergency System

Proyek ini terdiri dari **Backend Go** dan **Frontend Flutter**. Gunakan panduan ini untuk menyiapkan lingkungan pengembangan lokal.

## Prerequisites
- Docker & Docker Compose
- Flutter SDK (Latest Stable)
- Go (hanya jika ingin menjalankan tanpa Docker)

## 1. Persiapan Backend (Docker)
Backend menggunakan PostgreSQL dan Go. Kita menjalankan keduanya menggunakan Docker Compose sehingga database otomatis terkonfigurasi.

```bash
docker-compose up --build
```
*Catatan: File migrasi di `backend/migration/001_create_users.sql` akan otomatis dijalankan saat database pertama kali dibuat.*

### Konfigurasi Database (jika diperlukan koneksi manual):
- **User**: `safeuser`
- **Password**: `safepassword`
- **DB Name**: `safedb`
- **Port**: `5435` (Host) / `5432` (Internal)

## 2. Persiapan Frontend (Flutter)
Masuk ke direktori root proyek (lokasi `pubspec.yaml`), lalu jalankan:

```bash
flutter pub get
```

### Konfigurasi API Base URL
Buka file `lib/core/utils/injection.dart`. Pastikan `baseUrl` sesuai dengan lingkunganmu:
- **Emulator Android**: `http://10.0.2.2:8081` (default)
- **Local Linux/Web**: `http://localhost:8081`
- **HP Fisik**: Ganti dengan alamat IP lokal komputer kamu (contoh: `http://192.168.1.5:8081`)

## 3. Menjalankan Aplikasi
Setelah backend menyala (`docker-compose up`), jalankan Flutter:

```bash
flutter run
```

---
*Developed with SAFE Team*
