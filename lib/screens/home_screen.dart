import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mission.dart';
import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'mission_screen.dart';

const _outline = Color(0xFF1B1F4B);

/// Peta misi berbentuk jalur: misi 1 di bawah, naik ke misi berikutnya.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = ScrollController();
  bool _jumped = false;

  static const _xs = [0.32, 0.70, 0.42, 0.68, 0.34, 0.66]; // posisi kiri-kanan tiap misi
  static const _rowH = 150.0; // jarak vertikal antar misi
  static const _nodeW = 104.0, _nodeH = 64.0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = context.watch<GameProvider>();
    final total = gm.missions.length * 3;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  _Pill(icon: Icons.star_rounded, color: AppColors.gold, text: '${gm.totalStars}/$total'),
                  const SizedBox(width: 10),
                  _Pill(icon: Icons.emoji_events_rounded, color: AppColors.accent, text: 'Skor ${gm.totalScore}'),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Progres saya',
                    icon: const Icon(Icons.insights_rounded, color: AppColors.accent),
                    onPressed: () => _showProgress(context, gm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (c, cons) => _map(c, gm, cons)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _map(BuildContext context, GameProvider gm, BoxConstraints cons) {
    final w = cons.maxWidth;
    final n = gm.missions.length;
    final totalH = math.max(cons.maxHeight, n * _rowH + 140.0);
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(w * _xs[i % _xs.length], totalH - 100 - i * _rowH),
    ];
    final reached = gm.missions.where((m) => gm.statusOf(m) != MissionStatus.locked).length;
    final curIdx = gm.missions.indexWhere((m) => gm.statusOf(m) == MissionStatus.open);

    // Saat pertama dibuka, gulir ke misi yang sedang aktif.
    if (!_jumped && n > 0) {
      _jumped = true;
      final focus = curIdx < 0 ? pts.last.dy : pts[curIdx].dy;
      final target = focus - cons.maxHeight / 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_ctrl.hasClients) {
          _ctrl.jumpTo(target.clamp(0.0, _ctrl.position.maxScrollExtent).toDouble());
        }
      });
    }

    return SingleChildScrollView(
      controller: _ctrl,
      child: SizedBox(
        width: w,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: _MapPainter(pts, reached))),
            ),
            for (var i = 0; i < n; i++) ..._node(context, gm, gm.missions[i], pts[i], i == curIdx),
          ],
        ),
      ),
    );
  }

  List<Widget> _node(BuildContext context, GameProvider gm, Mission m, Offset c, bool current) {
    final st = gm.statusOf(m);
    final locked = st == MissionStatus.locked;
    final done = st == MissionStatus.done;
    final stars = gm.results[m.id]?.stars ?? 0;
    final badge = done
        ? const Color(0xFF1E9BFF)
        : (locked ? const Color(0xFF6B6F92) : const Color(0xFFFF4D8D));

    void onTap() {
      if (locked) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Selesaikan misi sebelumnya!')));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissionScreen(mission: m)));
    }

    return [
      // Planet / pulau misi
      Positioned(
        left: c.dx - _nodeW / 2,
        top: c.dy - _nodeH / 2,
        width: _nodeW,
        height: _nodeH,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                child: CustomPaint(size: const Size(_nodeW, _nodeH), painter: _PlanetPainter(st)),
              ),
              if (done || locked)
                Positioned(
                  top: _nodeH * 0.26 - 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      done ? Icons.check_rounded : Icons.lock_rounded,
                      size: 28,
                      color: done ? _outline : const Color(0xFFC5CAF0),
                    ),
                  ),
                ),
              Positioned(left: -8, top: -10, child: _Badge(number: m.id, color: badge)),
            ],
          ),
        ),
      ),
      // Maskot di misi yang sedang aktif
      if (current)
        Positioned(
          left: c.dx - 32,
          top: c.dy - _nodeH / 2 - 62,
          child: const IgnorePointer(child: RepaintBoundary(child: FloatingMascot(size: 64))),
        ),
      // Nama misi + bintang
      Positioned(
        left: c.dx - 70,
        top: c.dy + _nodeH / 2 + 4,
        width: 140,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              Text(
                m.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: locked ? const Color(0xFF8A93C9) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (done)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s = 0; s < 3; s++)
                      Icon(Icons.star_rounded,
                          size: 20, color: s < stars ? AppColors.gold : const Color(0xFF2A3470)),
                  ],
                ),
            ],
          ),
        ),
      ),
    ];
  }

  void _showProgress(BuildContext context, GameProvider gm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Progres Saya'),
        content: Text('Misi selesai: ${gm.completedCount}/${gm.missions.length}\n'
            'Total bintang: ${gm.totalStars}\n'
            'Total skor: ${gm.totalScore}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
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

class _Badge extends StatelessWidget {
  final int number;
  final Color color;
  const _Badge({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: _outline, width: 2.5),
      ),
      child: Text('$number',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
    );
  }
}

void _dashed(Canvas canvas, Path path, Paint paint, {double dash = 6, double gap = 8}) {
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
      d += dash + gap;
    }
  }
}

/// Latar bintang + garis putus-putus antar misi.
class _MapPainter extends CustomPainter {
  final List<Offset> pts;
  final int reached; // jumlah misi yang sudah terbuka
  _MapPainter(this.pts, this.reached);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final dot = Paint();
    for (var i = 0; i < 70; i++) {
      dot.color = (i % 6 == 0 ? const Color(0xFFFFE082) : Colors.white).withOpacity(0.35);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        1 + rnd.nextDouble() * 1.4,
        dot,
      );
    }
    final moon = Paint()..color = const Color(0xFF0E1740);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
          width: 30 + rnd.nextDouble() * 20,
          height: 20 + rnd.nextDouble() * 10,
        ),
        moon,
      );
    }

    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final ctrl = Offset(mid.dx + (b.dx > a.dx ? -35 : 35), mid.dy);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = i + 1 < reached ? const Color(0xFF9CC3E0) : const Color(0xFF4A6384);
      _dashed(canvas, path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.reached != reached || old.pts.length != pts.length || (pts.isNotEmpty && old.pts.last != pts.last);
}

/// Gambar planet/mangkuk: warna tutup menunjukkan status misi.
class _PlanetPainter extends CustomPainter {
  final MissionStatus status;
  _PlanetPainter(this.status);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lidColor = status == MissionStatus.done
        ? const Color(0xFF4ADE80)
        : (status == MissionStatus.open ? const Color(0xFFFFB800) : const Color(0xFF4F5896));
    final bodyColor =
        status == MissionStatus.locked ? const Color(0xFF4A5090) : const Color(0xFF6C74BD);
    final line = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // badan
    final bodyRect = Rect.fromLTWH(w * 0.03, h * 0.28, w * 0.94, h * 0.72);
    canvas.drawOval(bodyRect, Paint()..color = bodyColor);
    canvas.drawOval(bodyRect, line);
    final arc = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(w * 0.25, h * 0.52, w * 0.5, h * 0.30), 0.3, 2.5, false, arc);
    canvas.drawArc(Rect.fromLTWH(w * 0.38, h * 0.62, w * 0.24, h * 0.18), 0.4, 2.3, false, arc);

    // tutup
    final lidRect = Rect.fromLTWH(0, 0, w, h * 0.52);
    canvas.drawOval(lidRect, Paint()..color = lidColor);
    canvas.drawOval(lidRect, line);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.18, h * 0.07, w * 0.64, h * 0.24),
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    // lingkaran putus-putus untuk misi yang sedang aktif
    if (status == MissionStatus.open) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFB800);
      _dashed(canvas, Path()..addOval(lidRect.inflate(10)), ring, dash: 7, gap: 6);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter old) => old.status != status;
}
