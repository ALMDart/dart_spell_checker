library single_word_spell_checker_test;

import 'package:test/test.dart';
import 'package:dart_spell/dart_spell.dart';
import 'dart:math';

final Random r = Random(0xbeef);

void main() {
  final checker = SingleWordSpellChecker(distance: 1.0);
  checker.addWords(['apple', 'applesauce', 'applause', 'pear']);
  final str = 'apple';
  test('All Variations', () {
    final delete = randomDelete(str, 1);
    for (var s in delete) {
      expect(checker.find(s)[0].word == str, isTrue);
    }
    final insert = randomInsert(str, 1);
    for (var s in insert) {
      expect(checker.find(s)[0].word == str, isTrue);
    }
    final substitute = randomSubstitute(str, 1);
    for (var s in substitute) {
      expect(checker.find(s)[0].word == str, isTrue);
    }
    final transposition = transpositions(str);
    for (var s in transposition) {
      expect(checker.find(s)[0].word == str, isTrue);
    }
  });
}

Set<String> randomDelete(String input, int d) {
  final result = <String>{};
  for (var i = 0; i < 100; i++) {
    // ignore: omit_local_variable_types
    List<int> sb = List.from(input.codeUnits, growable: true);
    for (var j = 0; j < d; j++) {
      sb.removeAt(r.nextInt(sb.length));
    }
    result.add(String.fromCharCodes(sb));
  }
  return result;
}

Set<String> randomInsert(String input, int d) {
  final result = <String>{};
  for (var i = 0; i < 100; i++) {
    // ignore: omit_local_variable_types
    List<int> sb = List.from(input.codeUnits, growable: true);
    for (var j = 0; j < d; j++) {
      sb.insert(r.nextInt(sb.length + 1), 'x'.codeUnitAt(0));
    }
    result.add(String.fromCharCodes(sb));
  }
  return result;
}

Set<String> randomSubstitute(String input, int d) {
  final result = <String>{};
  for (var i = 0; i < 100; i++) {
    // ignore: omit_local_variable_types
    List<int> sb = List.from(input.codeUnits, growable: true);
    for (var j = 0; j < d; j++) {
      var start = r.nextInt(sb.length);
      sb[start] = 'x'.codeUnitAt(0);
    }
    result.add(String.fromCharCodes(sb));
  }
  return result;
}

Set<String> transpositions(String input) {
  final result = <String>{};
  for (var i = 0; i < input.length - 1; i++) {
    // ignore: omit_local_variable_types
    List<int> sb = List.from(input.codeUnits, growable: true);
    var tmp = sb[i];
    sb[i] = sb[i + 1];
    sb[i + 1] = tmp;
    result.add(String.fromCharCodes(sb));
  }
  return result;
}
