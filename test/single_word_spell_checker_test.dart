library single_word_spell_checker_test;

import 'package:unittest/unittest.dart';
import 'package:dart_spell/dart_spell.dart';
import 'dart:math';

Set<String> randomDelete(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = input.codeUnits;
    for (int j = 0; j < d; j++)
      sb.removeAt(r.nextInt(sb.length));
    result.add(sb.join(""));
  }
  return result;
}

Set<String> randomInsert(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = input.codeUnits;
    for (int j = 0; j < d; j++)
      sb.insert(r.nextInt(sb.length + 1), "x".codeUnitAt(0));
    result.add(sb.join(""));
  }
  return result;
}

Set<String> randomSubstitute(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = input.codeUnits;
    for (int j = 0; j < d; j++) {
      int start = r.nextInt(sb.length);
      sb[start]="x".codeUnitAt(0);
    }
    result.add(sb.join(""));
  }
  return result;
}

Set<String> transpositions(String input) {
  Set<String> result = new Set();
  for (int i = 0; i < input.length - 1; i++) {
    List<int> sb = input.codeUnits;
      int tmp = sb[i];
      sb[i]=sb[i+1];
      sb[i+1]=tmp;
      result.add(sb.join(""));
  }
  return result;    
}

