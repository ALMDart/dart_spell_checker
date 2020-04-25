library dart_spell;

final int CHARACTER_SPACE = 32;
final int CHARACTER_RANGE_LOW = 32;
final int CHARACTER_RANGE_HIGH = 126;

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

///
/// Simple dictionary based spell checker.
///
class SingleWordSpellChecker {
  final bool checkNearKeySubstitution = false;

  final double INSERTION_PENALTY = 1.0;
  final double DELETION_PENALTY = 1.0;
  final double SUBSTITUTION_PENALTY = 1.0;
  final double TRANSPOSITION_PENALTY = 1.0;

  //TODO: not used yet.
  final double NEAR_KEY_SUBSTITUTION_PENALTY = 0.5;
  final Map<int, String> nearKeyMap = <int, String>{};
  Map<String, double> hypotheses;

  double distance;
  _Node _root;

  SingleWordSpellChecker({num distance = 1}) {
    if (distance != null) this.distance = distance;
    _root = _Node(0);
  }

  void addWord(String word) => _addChar(word, word);
  void addWords(Iterable<String> words) => words?.forEach(addWord);

  void _addChar(String word, String actual) {
    var tmpNode = _root;
    for (var rune in word.toLowerCase().runes) {
      tmpNode = tmpNode?.addChild(rune);
    }
    tmpNode.word = actual;
  }

  List<Result> find(String input) {
    var lowered = input.toLowerCase();
    hypotheses = <String, double>{};

    final hyp = _Hypothesis(_root, 0.0, -1);
    var next = _expand(hyp, lowered);
    while (next.isNotEmpty) {
      var expanded = next.map((hyp) => _expand(hyp, lowered));
      next = expanded.reduce((e, v) => v?.union(e));
    }

    return hypotheses.keys.map((key) => Result(key, hypotheses[key])).toList()
      ..sort();
  }

  Set<_Hypothesis> _noError(_Hypothesis hypothesis, String input) {
    final nextIndex = hypothesis.index + 1;
    final hypNode = hypothesis.node;
    final newHypotheses = <_Hypothesis>{};

    if (nextIndex < input.length) {
      if (hypNode.hasChild(input.codeUnitAt(nextIndex))) {
        var hyp = hypothesis.getNewMoveForward(
            hypNode.getChild(input.codeUnitAt(nextIndex)),
            0.0);
        newHypotheses.add(hyp);
      }
    } else {
      _addHypothesis(hypothesis);
    }
    return newHypotheses;
  }

  Set<_Hypothesis> _expand(_Hypothesis hypothesis, String input) {
    final newHypotheses = <_Hypothesis>{};
    final nextIndex = hypothesis.index + 1;
    final hypDist = hypothesis.distance;
    final hypNode = hypothesis.node;

    // no-error
    newHypotheses.addAll(_noError(hypothesis, input));

    // we don't need to explore further if we reached to max penalty
    if (hypDist >= distance) return newHypotheses;

    // substitution
    if (nextIndex < input.length) {
      for (var childNode in hypNode.children) {
        var penalty = 0.0;
        if (checkNearKeySubstitution) {
          var nextChar = input.codeUnitAt(nextIndex);
          if (childNode.chr != nextChar) {
            var nearCharactersString = nearKeyMap[childNode.chr];
            if (nearCharactersString != null &&
                nearCharactersString.containsCodeUnit(nextChar)) {
              penalty = NEAR_KEY_SUBSTITUTION_PENALTY;
            } else {
              penalty = SUBSTITUTION_PENALTY;
            }
          }
        } else {
          penalty = SUBSTITUTION_PENALTY;
        }

        if (penalty > 0 && hypDist + penalty <= distance) {
          var hyp = hypothesis.getNewMoveForward(
              childNode, penalty);
          if (nextIndex == input.length - 1) {
            _addHypothesis(hyp);
          } else {
            newHypotheses.add(hyp);
          }
        }
      }
    }

    if (hypDist + DELETION_PENALTY > distance) return newHypotheses;

    // deletion
    newHypotheses.add(hypothesis.getNewMoveForward(
        hypNode, DELETION_PENALTY));

    // insertion
    for (var childNode in hypNode.children) {
      newHypotheses.add(hypothesis.getNew(
          childNode, INSERTION_PENALTY, hypothesis.index));
    }

    // transposition
    if (nextIndex < input.length - 1) {
      var transpose = input.codeUnitAt(nextIndex + 1);
      var nextNode = hypNode.getChild(transpose);
      var nextChar = input.codeUnitAt(nextIndex);
      if (hypNode.hasChild(transpose) && nextNode.hasChild(nextChar)) {
        var hyp = hypothesis.getNew(
            nextNode.getChild(nextChar), TRANSPOSITION_PENALTY, nextIndex + 1);
        if (nextIndex == input.length - 1) {
          _addHypothesis(hyp);
        } else {
          newHypotheses.add(hyp);
        }
      }
    }
    return newHypotheses;
  }

  void _addHypothesis(_Hypothesis hypToAdd) {
    var hypWord = hypToAdd.node.word;
    if (isNull(hypWord)) return;
    hypotheses[hypWord] = hypToAdd.distance;
  }
}

class _Node {
  final int _index = 0;

  final int chr;
  final Map<int, _Node> nodes = <int, _Node>{};

  String _word;
  set word(String word) => _word = word ?? _word;
  String get word => _word;


  _Node(this.chr);

  _Node.withIndex(this.chr, int index);

  Iterable<_Node> get children => nodes.values;

  bool hasChild(int c) => nodes.containsKey(c);
  _Node getChild(int c) => nodes[c];
  _Node addChild(int c) => nodes.putIfAbsent(c, () => _Node.withIndex(c, _index + 1));
  bool endsWord() => _word != null;
}

class _Hypothesis {
  final _Node node;
  final double distance;
  final int index;

  _Hypothesis(this.node, this.distance, this.index);

  _Hypothesis.initialNode(this.node, this.distance) : index = -1;

  //  _Hypothesis
  _Hypothesis getNewMoveForward(_Node node, double penaltyToAdd) {
    return _Hypothesis(node, distance + penaltyToAdd, index + 1);
  }

  _Hypothesis getNew(_Node node, double penaltyToAdd, int index) {
    return _Hypothesis(node, distance + penaltyToAdd, index);
  }

//  @override
//  bool operator ==(other) {
//    if (other is! _Hypothesis) return false;
//    return index == other.index &&
//        distance.compareTo(other.distance) == 0 &&
//        node == other.node;
//  }
}

class Result implements Comparable<Result> {
  final String word;
  final double distance;

  const Result(this.word, this.distance);

  @override
  int compareTo(Result other) => distance.compareTo(other.distance);

  @override
  String toString() => '$word:$distance';
}
