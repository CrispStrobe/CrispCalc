import 'package:flutter/material.dart';

/// Map of the seven Australian states/territories, colored from a
/// solution to the `mapColoringAustralia` DSL gallery program.
///
/// The regions are drawn in their true relative positions with a
/// recognizable Australia silhouette (the broad Western Australia third,
/// the Cape York peninsula, the south-eastern wedge, Tasmania offshore).
/// It stays a *teaching* visualization rather than a survey-grade map:
/// every Russell & Norvig adjacency is rendered as a genuine **shared
/// border** (the bordering polygons reuse the same boundary vertices —
/// including the real tri-state corners Poeppel, Cameron and the Murray
/// junction), so the four-color-theorem property — no two bordering
/// regions share a color — is exact and visible at a glance. Tasmania is
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

  /// Region boundary polygons keyed by variable name, on the same
  /// 0..100 logical grid the painter uses. Exposed for the topology test
  /// that verifies every Russell & Norvig adjacency is a real shared edge
  /// (two regions referencing the same two boundary vertices).
  @visibleForTesting
  static Map<String, List<Offset>> get regionPolygons => {
        for (final r in _regions) r.varName: r.points,
      };

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

// Region polygons on a 100×100 logical grid (x → right, y → down),
// positioned to read as a real Australia silhouette. Every internal
// border meets at a named junction vertex that the bordering regions
// *both* reference, so each Russell & Norvig adjacency is a genuine
// shared edge (two polygons referencing the same two vertices), not two
// shapes that merely touch. That keeps the four-color property exact.
//
// The internal junctions follow Australia's real surveyed corners:
const Offset _waNtTop = Offset(40, 20); // WA·NT meridian, north end
const Offset _ntQTop = Offset(64, 20); // NT·QLD meridian, north end
const Offset _waNtSa = Offset(40, 52); // WA·NT·SA tri-corner
const Offset _ntSaQ = Offset(64, 52); // NT·SA·QLD tri-corner (Poeppel)
const Offset _saQNsw = Offset(74, 60); // SA·QLD·NSW tri-corner (Cameron)
const Offset _saNswV = Offset(63, 74); // SA·NSW·VIC tri-corner (Murray jct)
const Offset _waSaCoast = Offset(40, 70); // WA·SA meridian, south (coast) end
const Offset _saVCoast = Offset(57, 80); // SA·VIC border, south (coast) end
const Offset _qNswCoast = Offset(92, 52); // QLD·NSW border, east (coast) end
const Offset _nswVCoast = Offset(70, 72); // NSW·VIC border, east end

const List<_Region> _regions = [
  // Western Australia — the broad western third. Its whole east side is
  // the 129°E meridian, split by the WA·NT·SA corner into the WA/NT
  // border (above) and the WA/SA border (below).
  _Region(
      'wa',
      'WA',
      [
        Offset(8, 28), // NW coast
        _waNtTop, // NE: top of the WA/NT meridian
        _waNtSa, // WA·NT·SA tri-corner
        _waSaCoast, // SE: bottom of the WA/SA meridian
        Offset(28, 77), // S coast
        Offset(10, 68),
        Offset(3, 45), // W coast
      ],
      Offset(21, 48)),
  // Northern Territory — central-north block. Borders WA (west, meridian),
  // QLD (east, meridian), SA (south).
  _Region(
      'nt',
      'NT',
      [
        _waNtTop,
        _ntQTop,
        _ntSaQ, // Poeppel
        _waNtSa,
      ],
      Offset(52, 36)),
  // Queensland — north-east, with the Cape York peninsula reaching up.
  // Borders NT (west), SA (south-west) and NSW (south).
  _Region(
      'q',
      'QLD',
      [
        _ntQTop,
        Offset(78, 12), // Cape York tip
        Offset(96, 30), // NE coast
        _qNswCoast, // QLD·NSW border, east end
        _saQNsw, // Cameron
        _ntSaQ, // Poeppel
      ],
      Offset(79, 33)),
  // South Australia — central-south. The five-way state: borders WA, NT,
  // QLD, NSW and VIC.
  _Region(
      'sa',
      'SA',
      [
        _waNtSa,
        _ntSaQ, // Poeppel
        _saQNsw, // Cameron
        _saNswV, // Murray junction
        _saVCoast, // S coast (SA/VIC border)
        Offset(40, 80), // S coast
        _waSaCoast, // back up the WA/SA meridian
      ],
      Offset(50, 63)),
  // New South Wales — south-east. Borders QLD (north), SA (west) and
  // VIC (south).
  _Region(
      'nsw',
      'NSW',
      [
        _saQNsw, // Cameron
        _qNswCoast, // QLD·NSW border, east end
        Offset(94, 66), // E coast
        _nswVCoast, // NSW·VIC border, east end
        _saNswV, // Murray junction
      ],
      Offset(79, 63)),
  // Victoria — the south-east corner of the mainland. Borders SA (west)
  // and NSW (north).
  _Region(
      'v',
      'VIC',
      [
        _saNswV, // Murray junction
        _nswVCoast, // NSW·VIC border, east end
        Offset(86, 76), // SE coast
        Offset(72, 84), // S coast
        _saVCoast, // SA/VIC border, south end
      ],
      Offset(71, 77)),
  // Tasmania — offshore island, no land border (freely colorable).
  _Region(
      't',
      'TAS',
      [
        Offset(70, 88),
        Offset(80, 86),
        Offset(82, 95),
        Offset(72, 96),
      ],
      Offset(76, 91)),
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
