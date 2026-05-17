// lib/screens/help_screen.dart
//
// In-app function reference. Lists every operation the user can
// invoke from the keypad with a one-line example, plus the matrix
// syntax cheatsheet and step-by-step entry-point summary. Static
// content — no engine roundtrips.
//
// Reachable from Settings → "Help & function reference".

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _heading(context, t.helpFunctionsHeading),
          for (final group in _functionGroups) _functionGroup(context, group),
          const SizedBox(height: 24),
          _heading(context, t.helpMatrixHeading),
          _body(context, t.helpMatrixBody),
          const SizedBox(height: 24),
          _heading(context, t.helpStepsHeading),
          _body(context, t.helpStepsBody),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  Widget _body(BuildContext context, String text) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      );

  Widget _functionGroup(BuildContext context, _Group g) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(g.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              for (final f in g.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          f.name,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          f.desc,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
}

class _Group {
  final String title;
  final List<_Fn> items;
  const _Group(this.title, this.items);
}

class _Fn {
  final String name;
  final String desc;
  const _Fn(this.name, this.desc);
}

// Statically built so we can keep the screen simple and avoid any
// engine reflection — these mirror the keypad and the engine binding
// layer 1:1. Update when adding a new op.
const _functionGroups = <_Group>[
  _Group('Arithmetic', [
    _Fn('+ - * /', 'Add / subtract / multiply / divide'),
    _Fn('^', 'Power: 2^10 = 1024'),
    _Fn('mod', '5 mod 3 = 2'),
    _Fn('!', 'Factorial: 5! = 120'),
    _Fn('abs', 'Absolute value'),
  ]),
  _Group('Algebraic CAS', [
    _Fn('solve(eq, x)', 'Solve an equation for a variable'),
    _Fn('factor(p)', 'Factor a polynomial'),
    _Fn('expand(p)', 'Distribute a product / expand a power'),
    _Fn('simplify(e)', 'Reduce e to canonical form'),
    _Fn('subst(e, x, v)', 'Substitute v for x in e'),
    _Fn('gcd / lcm', 'gcd(a, b), lcm(a, b)'),
    _Fn('Ans', 'Last result'),
  ]),
  _Group('Calculus', [
    _Fn('d/dx(f)', 'Derivative of f with respect to x'),
    _Fn('d/dx⌄', 'Same, but show step-by-step trace'),
    _Fn('∫ f dx', 'Indefinite integral (∫ button)'),
    _Fn('∫ f dx [a,b]', 'Definite integral via the ∫ dialog'),
    _Fn('∫⌄', 'Indefinite integral with step-by-step trace'),
    _Fn('lim', 'One-sided / ∞ limit (numerical)'),
  ]),
  _Group('Trig & elementary', [
    _Fn('sin cos tan', 'Standard trig'),
    _Fn('asin acos atan', 'Inverse trig'),
    _Fn('sinh cosh tanh', 'Hyperbolic'),
    _Fn('exp', 'e^x'),
    _Fn('ln  log', 'Natural log'),
    _Fn('sqrt  ⁿ√x', 'Square root and n-th root'),
    _Fn('pi, e, i, ∞', 'Common constants'),
  ]),
  _Group('Vector & tensor', [
    _Fn('dot(u, v)', 'Dot product'),
    _Fn('cross(u, v)', 'Cross product (3-vectors)'),
    _Fn('norm(v)', 'Euclidean length'),
    _Fn('unit(v)', 'Unit vector'),
  ]),
  _Group('Matrix', [
    _Fn('det(M)', 'Determinant'),
    _Fn('inv(M)', 'Inverse'),
    _Fn('transpose(M)', 'Transpose'),
    _Fn('rref(M)', 'Reduced row echelon form (Gauss-Jordan)'),
    _Fn('A + B / A * B', 'Element-wise add / multiply'),
  ]),
  _Group('Probability', [
    _Fn('Statistics screen', 'Analysis hub → Statistics'),
    _Fn('Normal', 'PDF, CDF, quantile (z-score)'),
    _Fn('Binomial', 'PMF, CDF, mean, variance'),
  ]),
];
