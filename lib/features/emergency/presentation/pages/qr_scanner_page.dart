import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe/core/theme/app_colors.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isScanned = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!mounted) return;
      
      // Show scanning/loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );

      final BarcodeCapture? barcodes = await controller.analyzeImage(image.path);
      
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
        final String? rawValue = barcodes.barcodes.first.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isScanned = true;
            });
            Navigator.pop(context, rawValue);
          }
        } else {
          _showErrorSnackBar(
            isEn ? 'No QR code found in this image.' : 'Tidak ada kode QR ditemukan di gambar ini.'
          );
        }
      } else {
        _showErrorSnackBar(
          isEn ? 'No QR code found in this image.' : 'Tidak ada kode QR ditemukan di gambar ini.'
        );
      }
    } catch (e) {
      if (mounted) {
        // Just in case loading dialog is still open
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      _showErrorSnackBar(
        isEn ? 'Error scanning image: $e' : 'Gagal memindai gambar: $e'
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEn ? 'Scan QR Code' : 'Pindai Kode QR',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // Flashlight button
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  final torchOn = state.torchState == TorchState.on;
                  return Icon(
                    torchOn ? Icons.flash_on : Icons.flash_off,
                    color: torchOn ? Colors.yellow : Colors.white,
                    size: 20,
                  );
                },
              ),
              onPressed: () => controller.toggleTorch(),
            ),
          ),
          const SizedBox(width: 8),
          // Camera switch button
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flip_camera_ios_outlined, size: 20),
              onPressed: () => controller.switchCamera(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner camera view
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        isEn 
                            ? 'Failed to open camera: ${error.errorCode}'
                            : 'Gagal membuka kamera: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.toString() ?? error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (BarcodeCapture capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  setState(() {
                    _isScanned = true;
                  });
                  Navigator.pop(context, rawValue);
                }
              }
            },
          ),
          
          // Semitransparent overlay cutout (renders a clean vector-based cutout with no black corner artifacts)
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerCutoutPainter(
                cutoutSize: scanAreaSize,
                borderRadius: 24,
              ),
            ),
          ),
          
          // Overlay border frame with custom visual design
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              size: Size(scanAreaSize, scanAreaSize),
              painter: ScannerOverlayPainter(
                borderColor: AppColors.primaryRed,
                borderRadius: 24,
                borderLength: 30,
                borderWidth: 4,
              ),
            ),
          ),

          // Animated scanner laser line (only if not scanned yet, runs smoothly using Transform.translate)
          if (!_isScanned)
            Positioned(
              top: (screenHeight - scanAreaSize) / 2,
              left: (screenWidth - scanAreaSize) / 2 + 12,
              right: (screenWidth - scanAreaSize) / 2 + 12,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value * scanAreaSize),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Bottom control dashboard card
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.75), // Slate 900
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'Align QR code within the frame'
                                  : 'Posisikan kode QR di dalam bingkai',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isEn
                            ? 'Scanning starts automatically. You can also import a QR code image from your library.'
                            : 'Pemindaian dimulai otomatis. Anda juga dapat mengambil gambar kode QR dari galeri.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 16),
                      // Gallery import button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.white),
                          label: Text(
                            isEn ? 'Import from Gallery' : 'Pilih dari Galeri',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the thin enclosing box
    final thinPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ),
      thinPaint,
    );

    // 2. Draw the thick bold corner frames
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top Left corner
    path.moveTo(0, borderLength);
    path.lineTo(0, borderRadius);
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(borderLength, 0);

    // Top Right corner
    path.moveTo(size.width - borderLength, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(size.width, borderLength);

    // Bottom Right corner
    path.moveTo(size.width, size.height - borderLength);
    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(size.width - borderLength, size.height);

    // Bottom Left corner
    path.moveTo(borderLength, size.height);
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(0, size.height - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScannerCutoutPainter extends CustomPainter {
  final double cutoutSize;
  final double borderRadius;

  ScannerCutoutPainter({
    required this.cutoutSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    // Create a path for the full screen
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a path for the cutout rounded rectangle in the center
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize,
      height: cutoutSize,
    );
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)));

    // Combine them to get the difference (background minus cutout)
    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerCutoutPainter oldDelegate) {
    return oldDelegate.cutoutSize != cutoutSize || oldDelegate.borderRadius != borderRadius;
  }
}

