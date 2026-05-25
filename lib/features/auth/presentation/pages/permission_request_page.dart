import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class PermissionRequestPage extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionRequestPage({super.key, required this.onGranted});

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle app resuming from settings page
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final hasLocation = await Permission.location.isGranted;
    final hasNotification = await Permission.notification.isGranted;

    if (hasLocation && hasNotification) {
      widget.onGranted();
    }
  }

  Future<void> _requestPermissions() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      // Request Location and Notification in parallel
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.notification,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        widget.onGranted();
      } else {
        // Check if any permission was permanently denied
        final hasPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

        if (hasPermanentlyDenied) {
          _showPermanentlyDeniedDialog();
        } else {
          // If simply denied, show snackbar warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Semua perizinan wajib disetujui untuk menggunakan aplikasi SAFE.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.primaryRed,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Perizinan Wajib',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          content: const Text(
            'Anda telah menolak satu atau beberapa perizinan penting secara permanen. Aplikasi tidak dapat berjalan tanpa perizinan ini. Silakan aktifkan izin secara manual di Pengaturan Aplikasi.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Nanti',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Buka Pengaturan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.shield, color: AppColors.primaryRed, size: 28),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Header
              Text(
                'Perizinan Diperlukan',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Aktifkan semua izin di bawah ini agar aplikasi SAFE dapat berjalan dan melindungimu dengan maksimal.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subHeading.copyWith(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 20),

              // Permission items list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPermissionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Akses Lokasi (GPS)',
                      description:
                          'Digunakan untuk mendeteksi koordinat lokasi darurat Anda secara akurat saat memicu SOS agar kontak terdekat/keluarga dapat langsung menolong.',
                      color: AppColors.primaryRed,
                    ),
                    _buildPermissionCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Kirim Notifikasi',
                      description:
                          'Penting untuk menerima pemberitahuan instan saat kerabat Anda mengirimkan sinyal darurat SOS atau ketika ada permintaan kontak baru.',
                      color: const Color(0xFF3B82F6),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Request Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _checking ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primaryRed.withOpacity(0.3),
                  ),
                  child: _checking
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Aktifkan Semua Perizinan',
                          style: AppTextStyles.buttonPrimary.copyWith(fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subHeading.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
