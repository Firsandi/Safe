import 'package:dio/dio.dart';

/// Utility class untuk mengkonversi DioException menjadi pesan yang ramah user.
/// Semua pesan menggunakan bahasa Indonesia agar mudah dipahami pengguna.
class DioErrorHandler {
  /// Mengembalikan pesan error yang user-friendly berdasarkan tipe DioException.
  static String getMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Koneksi ke server terlalu lama. Periksa koneksi internet Anda.';
      case DioExceptionType.sendTimeout:
        return 'Pengiriman data terlalu lama. Coba lagi nanti.';
      case DioExceptionType.receiveTimeout:
        return 'Server tidak merespon. Coba lagi nanti.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan koneksi internet Anda aktif.';
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  /// Menangani error berdasarkan HTTP status code.
  static String _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Coba ambil pesan error dari response backend
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['error']?.toString() ?? data['message']?.toString();
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Permintaan tidak valid. Periksa data yang Anda kirim.';
      case 401:
        return serverMessage ?? 'Sesi Anda telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses untuk melakukan ini.';
      case 404:
        return serverMessage ?? 'Data tidak ditemukan.';
      case 409:
        return serverMessage ?? 'Data sudah ada atau terjadi konflik.';
      case 422:
        return serverMessage ?? 'Data yang dikirim tidak lengkap atau tidak sesuai.';
      case 500:
        return 'Terjadi kesalahan pada server. Tim kami sedang memperbaiki.';
      case 502:
      case 503:
        return 'Server sedang dalam pemeliharaan. Coba lagi nanti.';
      default:
        return serverMessage ?? 'Terjadi kesalahan (kode: $statusCode). Silakan coba lagi.';
    }
  }

  /// Mengembalikan pesan error yang user-friendly dari exception umum.
  /// Digunakan untuk catch block yang menangkap Exception generik.
  static String getGeneralMessage(dynamic e) {
    if (e is DioException) {
      return getMessage(e);
    }
    // Jangan tampilkan detail teknis ke user
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
