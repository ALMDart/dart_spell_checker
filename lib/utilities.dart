import 'package:spell_checker/constants.dart';

bool isNull(Object obj) {
  return obj == null;
}

bool isChar(int char) {
  return !isNull(char) &&
      char >= CHARACTER_RANGE_LOW &&
      char <= CHARACTER_RANGE_HIGH;
}

extension ContainsCodeUnit on String {
  bool containsCodeUnit(int i) => runes.contains(i);
}
