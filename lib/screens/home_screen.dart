import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mission.dart';
import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mission_screen.dart';

const _folderColors = [
  Color(0xFFFFFFFF),
  Color(0xFF00BFFF),
  Color(0xFFFAFF00),
  Color(0xFF6A47D9),
  Color(0xFF0A4BFF),
  Color(0xFFCC00E6),
];

/// Peta misi: 5 folder misi + 1 folder progres.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = context.watch<GameProvider>();
    final total = gm.missions.length * 3;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const FloatingMascot(size: 120),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Pill(icon: Icons.star_rounded, color: AppColors.gold, text: '${gm.totalStars}/$total'),
                const SizedBox(width: 12),
                _Pill(icon: Icons.emoji_events_rounded, color: AppColors.accent, text: 'Skor ${gm.totalScore}'),
              ],
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 1.15,
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                children: [
                  for (var i = 0; i < gm.missions.length; i++)
                    _missionFolder(context, gm, gm.missions[i], _folderColors[i]),
                  _progressFolder(context, gm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionFolder(BuildContext context, GameProvider gm, Mission m, Color color) {
    final st = gm.statusOf(m);
    final fg = _fg(color);
    final stars = gm.results[m.id]?.stars ?? 0;
    return FolderCard(
      color: color,
      dimmed: st == MissionStatus.locked,
      onTap: () {
        if (st == MissionStatus.locked) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Selesaikan misi sebelumnya!')));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissionScreen(mission: m)));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('MISI ${m.id}', style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 2),
          Text(m.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          if (st == MissionStatus.locked)
            Icon(Icons.lock_rounded, color: fg, size: 22)
          else if (st == MissionStatus.open)
            Icon(Icons.play_circle_fill_rounded, color: fg, size: 24)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 0; s < 3; s++)
                  Icon(s < stars ? Icons.star_rounded : Icons.star_border_rounded, color: fg, size: 20),
              ],
            ),
        ],
      ),
    );
  }

  Widget _progressFolder(BuildContext context, GameProvider gm) {
    const color = Color(0xFFCC00E6);
    return FolderCard(
      color: color,
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Progres Saya'),
          content: Text('Misi selesai: ${gm.completedCount}/${gm.missions.length}\n'
              'Total bintang: ${gm.totalStars}\n'
              'Total skor: ${gm.totalScore}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, color: Colors.white, size: 30),
          SizedBox(height: 4),
          Text('PROGRES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  Color _fg(Color bg) => bg.computeLuminance() > 0.5 ? const Color(0xFF0B1238) : Colors.white;
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Pill({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class FolderCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final bool dimmed;
  const FolderCard({super.key, required this.color, required this.child, required this.onTap, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: CustomPaint(
          painter: _FolderPainter(color),
          child: Padding(padding: const EdgeInsets.fromLTRB(8, 24, 8, 8), child: child),
        ),
      ),
    );
  }
}

class _FolderPainter extends CustomPainter {
  final Color color;
  _FolderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final tabH = size.height * 0.16;
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, size.width * 0.42, tabH + 24, const Radius.circular(16)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0, tabH, size.width, size.height, const Radius.circular(18)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FolderPainter old) => old.color != color;
}
