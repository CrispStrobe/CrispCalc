import 'package:flutter/material.dart';

/// Schematic map of the seven Australian states/territories, colored
/// from a solution to the `mapColoringAustralia` DSL gallery program.
///
/// This is a *pedagogical* visualization, not a geographically accurate
/// map: the regions are stylized polygons laid out in roughly their real
/// relative positions so the four-color-theorem property — no two
/// bordering regions share a color — is visible at a glance. Tasmania is
/// drawn as a separate island (it has no land border, so it is freely
/// colorable).
class AustraliaMapView extends StatelessWidget {
  /// The solved assignment: region variable name → color index (1-based).
  final Map<String, int> assignment;

  const AustraliaMapView({super.key, required this.assignment});

  /// The variable names the `mapColoringAustralia` program declares.
  static const Set<String> regionKeys = {
    'wa',
    'nt',
    'sa',
    'q',
    'nsw',
    'v',
    't',
  };

  /// True when [solution] is an assignment over exactly the Australia
  /// region variables — the signal for the DSL result panel to render
  /// this map. The exact key-set match keeps it from firing on unrelated
  /// problems that merely declare a similar number of variables.
  static bool matches(Map<String, int> solution) =>
      solution.length == regionKeys.length &&
      solution.keys.toSet().containsAll(regionKeys);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: AspectRatio(
        aspectRatio: 1.25, // Australia is wider than tall.
        child: CustomPaint(
          painter: _AustraliaMapPainter(
            assignment: assignment,
            labelStyle: (Theme.of(context).textTheme.labelSmall ??
                    const TextStyle(fontSize: 11))
                .copyWith(fontWeight: FontWeight.w600),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// One region: its variable name, display label, polygon (in a 0..100
/// logical grid), and the offset (also 0..100) at which to place the
/// label.
class _Region {
  final String varName;
  final String label;
  final List<Offset> points;
  final Offset labelAt;
  const _Region(this.varName, this.label, this.points, this.labelAt);
}

/// Stylized region polygons on a 100×100 logical grid (x → right,
/// y → down). Shared edges are approximate — the goal is recognizability
/// and visually-adjacent borders, not cartographic accuracy.
const List<_Region> _regions = [
  _Region(
      'wa',
      'WA',
      [
        Offset(3, 30),
        Offset(30, 22),
        Offset(40, 30),
        Offset(40, 70),
        Offset(15, 73),
        Offset(5, 55),
      ],
      Offset(20, 50)),
  _Region(
      'nt',
      'NT',
      [
        Offset(40, 18),
        Offset(58, 16),
        Offset(58, 46),
        Offset(40, 46),
      ],
      Offset(49, 33)),
  _Region(
      'q',
      'QLD',
      [
        Offset(58, 16),
        Offset(95, 19),
        Offset(92, 50),
        Offset(62, 50),
        Offset(58, 46),
      ],
      Offset(76, 33)),
  _Region(
      'sa',
      'SA',
      [
        Offset(40, 46),
        Offset(58, 46),
        Offset(62, 72),
        Offset(40, 70),
      ],
      Offset(50, 58)),
  _Region(
      'nsw',
      'NSW',
      [
        Offset(62, 50),
        Offset(92, 50),
        Offset(88, 64),
        Offset(63, 64),
      ],
      Offset(76, 57)),
  _Region(
      'v',
      'VIC',
      [
        Offset(63, 64),
        Offset(88, 64),
        Offset(84, 74),
        Offset(66, 74),
      ],
      Offset(75, 69)),
  _Region(
      't',
      'TAS',
      [
        Offset(70, 83),
        Offset(82, 83),
        Offset(80, 94),
        Offset(72, 94),
      ],
      Offset(76, 88)),
];

/// Color-index → fill color. The DSL program's domain is `1..3`, but the
/// palette carries a few extra entries so a hand-edited program with more
/// colors still renders distinctly. Indexing is `(value - 1) % length`.
const List<Color> _palette = [
  Color(0xFFEF9A9A), // red 200
  Color(0xFF90CAF9), // blue 200
  Color(0xFFA5D6A7), // green 200
  Color(0xFFFFE082), // amber 200
  Color(0xFFCE93D8), // purple 200
];

class _AustraliaMapPainter extends CustomPainter {
  final Map<String, int> assignment;
  final TextStyle labelStyle;

  _AustraliaMapPainter({required this.assignment, required this.labelStyle});

  Offset _scale(Offset p, Size size) =>
      Offset(p.dx / 100 * size.width, p.dy / 100 * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF424242);

    for (final region in _regions) {
      final value = assignment[region.varName];
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = value == null
            ? const Color(0xFFE0E0E0)
            : _palette[(value - 1) % _palette.length];

      final path = Path()
        ..moveTo(_scale(region.points.first, size).dx,
            _scale(region.points.first, size).dy);
      for (final p in region.points.skip(1)) {
        final s = _scale(p, size);
        path.lineTo(s.dx, s.dy);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);

      // Label centered at the region's anchor point.
      final tp = TextPainter(
        text: TextSpan(text: region.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = _scale(region.labelAt, size);
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_AustraliaMapPainter old) =>
      old.assignment != assignment || old.labelStyle != labelStyle;
}
