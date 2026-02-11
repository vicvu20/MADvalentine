import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ValentineApp());

class ValentineApp extends StatelessWidget {
  const ValentineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ValentineHome(),
    );
  }
}

class ValentineHome extends StatefulWidget {
  const ValentineHome({super.key});

  @override
  State<ValentineHome> createState() => _ValentineHomeState();
}

class _ValentineHomeState extends State<ValentineHome>
    with SingleTickerProviderStateMixin {
  final List<String> emojiOptions = ['Sweet Heart', 'Party Heart'];
  String selectedEmoji = 'Sweet Heart';

  // Stores where the user drew hearts.
  final List<StampedEmoji> stamps = [];

  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(); // loop sparkles
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _addStamp(Offset localPosition) {
    stamps.add(
      StampedEmoji(
        type: selectedEmoji,
        position: localPosition,
        rotation: (Random().nextDouble() - 0.5) * 0.25,
        scale: selectedEmoji == 'Party Heart' ? 1.05 : 0.95,
        seed: Random().nextInt(1 << 31),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cupid's Canvas"),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: () => setState(stamps.clear),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: selectedEmoji,
                items: emojiOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedEmoji = value ?? selectedEmoji),
              ),
              Text(
                "Tap/drag to draw",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _addStamp(d.localPosition),
                  onPanUpdate: (d) {
                    // Space stamps a bit so it doesn't spam too densely.
                    if (stamps.isEmpty) return _addStamp(d.localPosition);
                    final last = stamps.last.position;
                    if ((d.localPosition - last).distance > 18) {
                      _addStamp(d.localPosition);
                    }
                  },
                  onTapDown: (d) => _addStamp(d.localPosition),
                  child: AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: size,
                        painter: ValentineCanvasPainter(
                          stamps: stamps,
                          sparkleT: _sparkleController.value,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StampedEmoji {
  final String type;
  final Offset position;
  final double rotation;
  final double scale;
  final int seed;

  StampedEmoji({
    required this.type,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.seed,
  });
}

class ValentineCanvasPainter extends CustomPainter {
  ValentineCanvasPainter({
    required this.stamps,
    required this.sparkleT,
  });

  final List<StampedEmoji> stamps;
  final double sparkleT;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    // Draw all stamped hearts.
    for (final s in stamps) {
      canvas.save();
      canvas.translate(s.position.dx, s.position.dy);
      canvas.rotate(s.rotation);
      canvas.scale(s.scale);

      // Heart "aura / trail" outline behind main heart
      _drawHeart(
        canvas,
        heartSize: 92,
        type: s.type,
        auraOnly: true,
        sparkleT: sparkleT,
        seed: s.seed,
      );

      // Main heart emoji
      _drawHeart(
        canvas,
        heartSize: 86,
        type: s.type,
        auraOnly: false,
        sparkleT: sparkleT,
        seed: s.seed,
      );

      canvas.restore();
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF1F6),
          const Color(0xFFFFC1D7),
          const Color(0xFFFF8FB1),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));

    canvas.drawRect(rect, bgPaint);
  }

  void _drawHeart(
    Canvas canvas, {
    required double heartSize,
    required String type,
    required bool auraOnly,
    required double sparkleT,
    required int seed,
  }) {
    final heartPath = _heartPath(heartSize);

    if (auraOnly) {
      final aura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.white.withOpacity(0.25);
      canvas.drawPath(heartPath, aura);
      return;
    }

    // Heart gradient fill
    final heartRect = Rect.fromCenter(
      center: Offset.zero,
      width: heartSize * 2,
      height: heartSize * 2,
    );

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: type == 'Party Heart'
            ? const [Color(0xFFFFB3C7), Color(0xFFF06292), Color(0xFFEC407A)]
            : const [Color(0xFFFF1744), Color(0xFFE91E63), Color(0xFFD81B60)],
      ).createShader(heartRect);

    canvas.drawPath(heartPath, fill);

    // Soft highlight
    final highlight = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.12);
    canvas.drawCircle(const Offset(-22, -28), 18, highlight);

    // Face
    _drawFace(canvas, type: type, heartSize: heartSize);

    // Party extras
    if (type == 'Party Heart') {
      _drawPartyHat(canvas, heartSize: heartSize);
      _drawConfetti(canvas, heartSize: heartSize, seed: seed);
    }

    // Animated sparkles around any heart
    _drawSparkles(canvas, heartSize: heartSize, t: sparkleT, seed: seed);
  }

  Path _heartPath(double s) {
    // Centered at (0,0)
    // s controls overall size
    return Path()
      ..moveTo(0, s * 0.75)
      ..cubicTo(s * 1.2, s * 0.05, s * 0.65, -s * 1.05, 0, -s * 0.35)
      ..cubicTo(-s * 0.65, -s * 1.05, -s * 1.2, s * 0.05, 0, s * 0.75)
      ..close();
  }

  void _drawFace(Canvas canvas, {required String type, required double heartSize}) {
    final eyeWhite = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF2B2B2B);

    final eyeY = -heartSize * 0.10;
    final eyeX = heartSize * 0.35;

    // Eyes
    canvas.drawCircle(Offset(-eyeX, eyeY), heartSize * 0.12, eyeWhite);
    canvas.drawCircle(Offset(eyeX, eyeY), heartSize * 0.12, eyeWhite);

    // Pupils
    canvas.drawCircle(Offset(-eyeX, eyeY), heartSize * 0.05, pupil);
    canvas.drawCircle(Offset(eyeX, eyeY), heartSize * 0.05, pupil);

    // Blush
    final blush = Paint()..color = Colors.white.withOpacity(0.22);
    canvas.drawCircle(Offset(-eyeX * 0.95, eyeY + heartSize * 0.25), heartSize * 0.10, blush);
    canvas.drawCircle(Offset(eyeX * 0.95, eyeY + heartSize * 0.25), heartSize * 0.10, blush);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final mouthRect = Rect.fromCenter(
      center: Offset(0, heartSize * 0.28),
      width: heartSize * 0.70,
      height: heartSize * 0.55,
    );

    // Sweet heart: gentle smile, Party: bigger grin
    final sweep = type == 'Party Heart' ? 3.35 : 3.05;
    final start = type == 'Party Heart' ? 0.05 : 0.10;
    canvas.drawArc(mouthRect, start, sweep, false, mouthPaint);
  }

  void _drawPartyHat(Canvas canvas, {required double heartSize}) {
    final hatPaint = Paint()..color = const Color(0xFFFFD54F);

    final top = Offset(0, -heartSize * 1.05);
    final left = Offset(-heartSize * 0.45, -heartSize * 0.25);
    final right = Offset(heartSize * 0.45, -heartSize * 0.25);

    final hatPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(hatPath, hatPaint);

    // Hat stripe
    final stripe = Paint()..color = const Color(0xFF7E57C2);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -heartSize * 0.32),
        width: heartSize * 0.75,
        height: heartSize * 0.10,
      ),
      stripe,
    );

    // Pom-pom
    final pom = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, -heartSize * 1.05), heartSize * 0.10, pom);
  }

  void _drawConfetti(Canvas canvas, {required double heartSize, required int seed}) {
    final rnd = Random(seed);

    for (int i = 0; i < 18; i++) {
      final angle = rnd.nextDouble() * pi * 2;
      final r = heartSize * (0.95 + rnd.nextDouble() * 0.65);
      final p = Offset(cos(angle) * r, sin(angle) * r);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Color.fromARGB(
          255,
          80 + rnd.nextInt(175),
          80 + rnd.nextInt(175),
          80 + rnd.nextInt(175),
        );

      // Mix lines + dots
      if (i % 3 == 0) {
        canvas.drawCircle(p, 4 + rnd.nextDouble() * 3, paint..style = PaintingStyle.fill);
      } else {
        final p2 = p + Offset(rnd.nextDouble() * 10 - 5, rnd.nextDouble() * 10 - 5);
        canvas.drawLine(p, p2, paint);
      }
    }
  }

  void _drawSparkles(Canvas canvas, {required double heartSize, required double t, required int seed}) {
    // twinkle using sine wave
    final rnd = Random(seed ^ 0x55AA55AA);
    final tw = (sin(t * 2 * pi) + 1) / 2; // 0..1

    for (int i = 0; i < 10; i++) {
      final a = (i / 10) * pi * 2 + rnd.nextDouble() * 0.3;
      final r = heartSize * (1.10 + (i % 2) * 0.25);
      final p = Offset(cos(a) * r, sin(a) * r);

      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity(0.15 + tw * 0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      // Small star burst: 2 crossing lines
      final len = 6 + tw * 6;
      canvas.drawLine(p + Offset(-len, 0), p + Offset(len, 0), sparklePaint);
      canvas.drawLine(p + Offset(0, -len), p + Offset(0, len), sparklePaint);

      // Tiny dot accent
      canvas.drawCircle(p + const Offset(2, -2), 1.8 + tw * 1.2,
          Paint()..color = Colors.white.withOpacity(0.25 + tw * 0.45));
    }
  }

  @override
  bool shouldRepaint(covariant ValentineCanvasPainter oldDelegate) {
    return oldDelegate.sparkleT != sparkleT || oldDelegate.stamps != stamps;
  }
}