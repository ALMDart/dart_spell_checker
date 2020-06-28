import 'package:spell_checker/spell_checker.dart';

void main() {
  final checker = SingleWordSpellChecker(distance: 1.0);
  checker.addWords(['apple', 'apply', 'applesauce', 'applause', 'pear']);
  final str = 'aple';
  final findList = checker.find(str);
  print(findList);
}
