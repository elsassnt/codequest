import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

const kMascot = 'assets/images/py.png';

/// Maskot Py yang melayang naik-turun.
class FloatingMascot extends StatefulWidget {
  final double size;
  const FloatingMascot({super.key, this.size = 200});

  @override
  State<FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<FloatingMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -10 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Image.asset(kMascot, width: widget.size, height: widget.size, fit: BoxFit.contain),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const GradientButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(8);
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(gradient: rainbowGradient, borderRadius: r),
          child: InkWell(
            onTap: onTap,
            borderRadius: r,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RainbowText extends StatelessWidget {
  final String text;
  final double size;
  const RainbowText(this.text, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => rainbowGradient.createShader(r),
      child: Text(
        text,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
      ),
    );
  }
}

/// Garis-garis warna pelangi di atas judul (seperti di desain splash).
class RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 1.4;
    const angles = [-160.0, -128.0, -102.0, -78.0, -52.0, -20.0];
    const colors = [
      Color(0xFFE01B1B),
      Color(0xFFF5871F),
      Color(0xFFFFD600),
      Color(0xFF9DC25A),
      Color(0xFF0A9BDC),
      Color(0xFF6A4C9C),
    ];
    for (var i = 0; i < 6; i++) {
      final a = angles[i] * pi / 180;
      final r1 = size.height * 0.75, r2 = size.height * 1.3;
      canvas.drawLine(
        Offset(cx + r1 * 1.6 * cos(a), cy + r1 * sin(a)),
        Offset(cx + r2 * 1.6 * cos(a), cy + r2 * sin(a)),
        Paint()
          ..color = colors[i]
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
