import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onLongPress;
  final String label;
  final String subLabel;

  const SosButton({
    super.key, 
    required this.onLongPress, 
    required this.label,
    required this.subLabel,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. SUBTLE OUTER RIPPLES (Very light and transparent)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ModernRipplePainter(_controller.value),
                size: const Size(320, 320),
              );
            },
          ),
          
          // 2. LARGE SOFT BACKGROUND CIRCLE
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed.withOpacity(0.05),
            ),
          ),

          // 3. WHITE BORDER RING
          Container(
            width: 215,
            height: 215,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // 4. MAIN RED BUTTON
          Material(
            elevation: 8,
            shadowColor: AppColors.primaryRed.withOpacity(0.3),
            shape: const CircleBorder(),
            child: InkWell(
              onLongPress: () {
                HapticFeedback.heavyImpact();
                widget.onLongPress();
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryRed,
                      Color(0xFFC62828),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning Icon in Sharp Diamond
                    _buildSharpDiamond(),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      style: AppTextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: 54,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subLabel,
                      style: AppTextStyles.inputLabel.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharpDiamond() {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Icon(
            Icons.priority_high,
            color: AppColors.primaryRed,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class ModernRipplePainter extends CustomPainter {
  final double animationValue;

  ModernRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final val = (animationValue + (i * 0.33)) % 1.0;
      final radius = 110 + (val * 50);
      final opacity = (1.0 - val).clamp(0.0, 1.0) * 0.1;
      
      canvas.drawCircle(
        center,
        radius,
        paint..color = AppColors.primaryRed.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(ModernRipplePainter oldDelegate) => true;
}
