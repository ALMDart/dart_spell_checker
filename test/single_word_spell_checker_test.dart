library single_word_spell_checker_test;

import 'dart:math';
import 'package:test/test.dart';
import 'package:dart_spell/dart_spell.dart';
import 'package:list_english_words/list_english_words.dart';

final Random r = Random(0xbeef);

void main() {
  group('Test Word List', () {
    final checker = SingleWordSpellChecker(distance: 1.0);
    checker.addWords(list_english_words);

    test('All Words In List Come Back First', () {
      for(final s in list_english_words) {
        expect(checker.find(s)[0].word == s, isTrue);
      }
    });
  });

  group('Test Short List', () {
    final checker = SingleWordSpellChecker(distance: 1.0);
    checker.addWords(['apple', 'apply', 'applesauce', 'applause', 'pear']);
    final str = 'apple';
    test('All Variations', () {
      final delete = randomDelete(str, 1);
      for (final s in delete) {
        final findList = checker.find(s);
        final subSize = findList.length < 5 ? findList.length : 5;
        final testStrs =
            findList.sublist(0, subSize).map((e) => e.word).toList();
        expect(testStrs.contains(str), isTrue);
      }
      final insert = randomInsert(str, 1);
      for (var s in insert) {
        final findList = checker.find(s);
        final subSize = findList.length < 5 ? findList.length : 5;
        final testStrs =
            findList.sublist(0, subSize).map((e) => e.word).toList();
        expect(testStrs.contains(str), isTrue);
      }
      final substitute = randomSubstitute(str, 1);
      for (var s in substitute) {
        final findList = checker.find(s);
        final subSize = findList.length < 5 ? findList.length : 5;
        final testStrs =
            findList.sublist(0, subSize).map((e) => e.word).toList();
        expect(testStrs.contains(str), isTrue);
      }
      final transposition = transpositions(str);
      for (var s in transposition) {
        final findList = checker.find(s);
        final subSize = findList.length < 5 ? findList.length : 5;
        final testStrs =
            findList.sublist(0, subSize).map((e) => e.word).toList();
        expect(testStrs.contains(str), isTrue);
      }
    });
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
