// test/notepad_incomplete_test.dart
//
// The Notepad recalculates 300 ms after every keystroke, so on the way
// to `2 + 3` the evaluator genuinely sees `2`, `2 `, and `2 +`. Before
// this guard, that middle state was dispatched to the CAS and painted
// an error under the cursor while the user was still typing — on web,
// literally "Error: evaluate failed: [object Object]".
//
// These tests pin the contract: a line that is a valid *prefix* of an
// expression produces no result and no error, and a line that is
// actually wrong still errors exactly as it did before.

import 'package:crisp_math/engine/notepad.dart';
import 'package:crisp_math/engine/notepad_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

NotepadDocument docOf(List<String> sources) => NotepadDocument(
      id: 'test-doc',
      name: 'Test',
      createdAt: DateTime.utc(2026, 5, 25),
      updatedAt: DateTime.utc(2026, 5, 25),
      lines: [
        for (var i = 0; i < sources.length; i++)
          NotepadLine(id: 'l$i', source: sources[i]),
      ],
    );

/// Dispatcher that records what it was asked to evaluate, so a test can
/// assert the engine was never called at all.
class RecordingDispatcher {
  final List<String> calls = [];
  Future<String> call(String expr) async {
    calls.add(expr);
    return 'DISPATCHED';
  }
}

Future<NotepadLine> evalSingle(String source,
    {RecordingDispatcher? recorder}) async {
  final doc = docOf([source]);
  final rec = recorder ?? RecordingDispatcher();
  await NotepadEvaluator(dispatcher: rec.call).evaluateAll(doc);
  return doc.lines.first;
}

void main() {
  group('half-typed lines stay silent', () {
    const prefixes = [
      '2 +',
      '2 -',
      '2 *',
      '2 /',
      '2 ^',
      'x +',
      '(3+4',
      '((',
      'sin(',
      'sin(x',
      'max(1,',
      '+',
      '.',
      'y=',
      'y =',
      'y = ',
      'total_cost =',
    ];

    for (final src in prefixes) {
      test('"$src" produces neither a result nor an error', () async {
        final rec = RecordingDispatcher();
        final line = await evalSingle(src, recorder: rec);
        expect(line.cachedError, isNull,
            reason: '"$src" is a prefix, not a mistake — it must not error');
        expect(line.cachedResult, isNull,
            reason: '"$src" must not show a result');
        expect(rec.calls, isEmpty,
            reason: '"$src" should never reach the engine');
      });
    }
  });

  group('finished lines still evaluate', () {
    const complete = ['2 + 3', 'sin(x)', '(3+4)', 'x = 5', 'max(1, 2)'];

    for (final src in complete) {
      test('"$src" reaches the dispatcher', () async {
        final rec = RecordingDispatcher();
        final line = await evalSingle(src, recorder: rec);
        expect(rec.calls, isNotEmpty,
            reason: '"$src" is complete and must be evaluated');
        expect(line.cachedResult, 'DISPATCHED');
        expect(line.cachedError, isNull);
      });
    }
  });

  group('genuine mistakes still error', () {
    // These are not prefixes of anything valid, so silencing them would
    // hide a real problem from the user.
    const broken = ['2+3)', ')'];

    for (final src in broken) {
      test('"$src" is still dispatched (and can error)', () async {
        final rec = RecordingDispatcher();
        await evalSingle(src, recorder: rec);
        expect(rec.calls, isNotEmpty,
            reason: '"$src" is wrong, not unfinished — it must not be hidden');
      });
    }
  });

  group('typing a line character by character', () {
    test('only the finished expression shows a result', () async {
      // Exactly what the debounced recalc sees as someone types "2 + 3".
      const keystrokes = ['2', '2 ', '2 +', '2 + ', '2 + 3'];
      final results = <String, ({String? res, String? err})>{};
      for (final src in keystrokes) {
        final line = await evalSingle(src);
        results[src] = (res: line.cachedResult, err: line.cachedError);
      }

      // No intermediate state is ever an error.
      for (final entry in results.entries) {
        expect(entry.value.err, isNull,
            reason: 'typing "${entry.key}" must not surface an error');
      }
      // The mid-typing operator state shows nothing at all.
      expect(results['2 +']!.res, isNull);
      // The complete states do evaluate.
      expect(results['2']!.res, 'DISPATCHED');
      expect(results['2 + 3']!.res, 'DISPATCHED');
    });
  });

  group('downstream lines are unaffected', () {
    test('an unfinished line does not block a later independent line',
        () async {
      final doc = docOf(['2 +', '7 * 6']);
      final rec = RecordingDispatcher();
      await NotepadEvaluator(dispatcher: rec.call).evaluateAll(doc);
      expect(doc.lines[0].cachedError, isNull);
      expect(doc.lines[0].cachedResult, isNull);
      expect(doc.lines[1].cachedResult, 'DISPATCHED');
      expect(doc.lines[1].cachedError, isNull);
    });
  });
}
