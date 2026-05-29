import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe/core/theme/app_colors.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEn ? 'Scan QR Code' : 'Pindai Kode QR',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Flashlight button
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                if (state.torchState == TorchState.on) {
                  return const Icon(Icons.flash_on, color: Colors.yellow);
                } else {
                  return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            iconSize: 24.0,
            onPressed: () => controller.toggleTorch(),
          ),
          // Camera switch button
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                if (state.cameraDirection == CameraFacing.front) {
                  return const Icon(Icons.camera_front);
                } else {
                  return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 24.0,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
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
          
          // Semitransparent overlay cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: scanAreaSize,
                    width: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.black, // acts as cutout due to blend mode
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
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
          
          // Info instructions text below cutout
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    isEn
                        ? 'Position the QR code inside the box to scan'
                        : 'Posisikan kode QR di dalam kotak untuk memindai',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
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
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top Left corner
    path.moveTo(0, borderLength);
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.lineTo(borderLength, 0);

    // Top Right corner
    path.moveTo(size.width - borderLength, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, borderLength);

    // Bottom Right corner
    path.moveTo(size.width, size.height - borderLength);
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - borderRadius, size.height);
    path.lineTo(size.width - borderLength, size.height);

    // Bottom Left corner
    path.moveTo(borderLength, size.height);
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, size.height - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
