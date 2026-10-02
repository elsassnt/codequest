import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mission_screen.dart';

class ResultScreen extends StatelessWidget {
  final Mission mission;
  final MissionResult result;
  final int lines, hints;
  final Mission? next;

  const ResultScreen({
    super.key,
    required this.mission,
    required this.result,
    required this.lines,
    required this.hints,
    this.next,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              const RainbowText('MISI SELESAI!', size: 34),
              const SizedBox(height: 4),
              Text(mission.title, style: const TextStyle(color: AppColors.accent, fontSize: 16)),
              const SizedBox(height: 18),
              const FloatingMascot(size: 150),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 250),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Icon(
                        i < result.stars ? Icons.star_rounded : Icons.star_border_rounded,
                        color: i < result.stars ? AppColors.gold : Colors.white38,
                        size: 58,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Skor: ${result.score}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Baris kode: $lines (optimal ${mission.optimalLines})  •  Hint dipakai: $hints',
                  style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              if (next != null)
                GradientButton(
                  label: 'LANJUT MISI',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => MissionScreen(mission: next!)),
                  ),
                )
              else
                const Text('Selamat! Kamu sudah menamatkan semua misi 🎉',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('KEMBALI KE PETA'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
