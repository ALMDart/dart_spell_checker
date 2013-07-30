library single_word_spell_checker_test;

import 'package:unittest/unittest.dart';
import 'package:dart_spell/dart_spell.dart';
import 'dart:math';

main() {
  var checker = new SingleWordSpellChecker(distance:1.0);
  checker.addWords(["apple","pear"]);
  var str = "apple";
  test('All Variations',() {
    Set<String> delete = randomDelete(str,1);
    for(String s in delete) {
      expect(checker.find(s)[0].word==str, isTrue);   
    }
    Set<String> insert = randomInsert(str,1);
    for(String s in insert) {
      expect(checker.find(s)[0].word==str, isTrue);   
    }
    Set<String> substitute = randomSubstitute(str,1);
    for(String s in substitute) {
      expect(checker.find(s)[0].word==str, isTrue);   
    }
    Set<String> transposition = transpositions(str);
    for(String s in transposition) {
      expect(checker.find(s)[0].word==str, isTrue);   
    }
  });        
}

Set<String> randomDelete(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = new List.from(input.codeUnits, growable:true);
    for (int j = 0; j < d; j++)
      sb.removeAt(r.nextInt(sb.length));
    result.add(new String.fromCharCodes(sb));
  }
  return result;
}

Set<String> randomInsert(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = new List.from(input.codeUnits, growable:true);
    for (int j = 0; j < d; j++)
      sb.insert(r.nextInt(sb.length + 1), "x".codeUnitAt(0));
    result.add(new String.fromCharCodes(sb));
  }
  return result;
}

Set<String> randomSubstitute(String input, int d) {
  Set<String> result = new Set();
  Random r = new Random(0xbeef);
  for (int i = 0; i < 100; i++) {
    List<int> sb = new List.from(input.codeUnits, growable:true);
    for (int j = 0; j < d; j++) {
      int start = r.nextInt(sb.length);
      sb[start]="x".codeUnitAt(0);
    }
    result.add(new String.fromCharCodes(sb));
  }
  return result;
}

Set<String> transpositions(String input) {
  Set<String> result = new Set();
  for (int i = 0; i < input.length - 1; i++) {
    List<int> sb = new List.from(input.codeUnits, growable:true);
      int tmp = sb[i];
      sb[i]=sb[i+1];
      sb[i+1]=tmp;
      result.add(new String.fromCharCodes(sb));
  }
  return result;    
}

