import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class _Page {
  final String line1, line2, body;
  const _Page(this.line1, this.line2, this.body);
}

const _pages = [
  _Page('Belajar Python Jadi', 'Menyenangkan',
      'Selesaikan tantangan coding, kumpulkan bintang, dan jadilah Python Master'),
  _Page('Kenalan dengan', 'Robot Py',
      'Tulis kode Python sungguhan untuk mengendalikan Py menuju garis finish'),
  _Page('Ketik Kode', 'Lebih Mudah',
      'Pakai keyboard coding khusus, auto-complete, dan template kode'),
  _Page('Raih', '3 Bintang',
      'Tulis kode seefisien mungkin dan hindari hint untuk skor sempurna'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  Future<void> _next() async {
    if (_i < _pages.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    final gm = context.read<GameProvider>();
    await gm.setOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Text(p.line1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(p.line2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.accent)),
                        const Spacer(),
                        const FloatingMascot(size: 260),
                        const Spacer(),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, height: 1.4, color: Colors.white)),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: i == _i ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _i ? const Color(0xFFF5E600) : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
              child: GradientButton(
                label: _i == _pages.length - 1 ? 'MULAI' : 'LANJUT',
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
