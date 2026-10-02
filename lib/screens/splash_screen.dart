import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Splash 3 detik: logo + maskot, lalu bar "Memuat petualangan...".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
  }

  Future<void> _next() async {
    final gm = context.read<GameProvider>();
    while (!gm.loaded) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => gm.onboarded ? const HomeScreen() : const OnboardingScreen(),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final planetOpacity = c01(1 - v * 3);
          final loadOpacity = c01((v - 0.25) * 4);
          return Stack(
            children: [
              Positioned(
                left: -w * 0.25,
                bottom: -(w * 1.5 - w * 0.6),
                child: Opacity(
                  opacity: planetOpacity,
                  child: Container(
                    width: w * 1.5,
                    height: w * 1.5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF4D00), Color(0xFFF9C200), Color(0xFFF5FF00), Color(0xFF7DBB8A)],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    SizedBox(height: 70, width: w * 0.8, child: CustomPaint(painter: RaysPainter())),
                    const SizedBox(height: 4),
                    const RainbowText('CODEQUEST', size: 46),
                    const Text('PYTHON ADVENTURE',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.accent)),
                    const SizedBox(height: 18),
                    const Text('Belajar Python Jadi Menyenangkan',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                    const SizedBox(height: 24),
                    const FloatingMascot(size: 230),
                    const Spacer(),
                    Opacity(
                      opacity: loadOpacity,
                      child: Column(
                        children: [
                          const Text('Memuat petualangan....', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 10),
                          Container(
                            width: w * 0.68,
                            height: 18,
                            alignment: Alignment.centerLeft,
                            color: Colors.white10,
                            child: FractionallySizedBox(
                              widthFactor: c01(v),
                              child: Container(decoration: const BoxDecoration(gradient: rainbowGradient)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${(v * 100).floor()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
