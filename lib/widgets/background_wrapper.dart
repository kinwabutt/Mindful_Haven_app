import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BackgroundWrapper extends StatefulWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  State<BackgroundWrapper> createState() => _BackgroundWrapperState();
}

class _BackgroundWrapperState extends State<BackgroundWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _BlobPainter(animationValue: _controller.value),
              );
            },
          ),
        ),
        // Applying a high-end blur globally to the blobs
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double animationValue;
  _BlobPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppTheme.primaryTeal.withValues(alpha: 0.1);
    final paint2 = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.08);

    // Blob 1 movement
    final x1 = size.width * 0.3 + (size.width * 0.2 * sin(animationValue * 2 * pi));
    final y1 = size.height * 0.3 + (size.height * 0.1 * cos(animationValue * 2 * pi));

    // Blob 2 movement
    final x2 = size.width * 0.7 + (size.width * 0.2 * cos(animationValue * 2 * pi));
    final y2 = size.height * 0.7 + (size.height * 0.1 * sin(animationValue * 2 * pi));

    canvas.drawCircle(Offset(x1, y1), size.width * 0.4, paint1);
    canvas.drawCircle(Offset(x2, y2), size.width * 0.35, paint2);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
