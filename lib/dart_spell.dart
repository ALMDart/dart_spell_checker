library dart_spell;

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
  Map<int, String> nearKeyMap = <int, String>{};
  Map<String, double> hypotheses;

  double distance;
  _Node _root;

  SingleWordSpellChecker({num distance = 1}) {
    if (distance != null) this.distance = distance;
    _root = _Node(0);
  }

  void addWord(String word) => _addChar(word.toLowerCase(), word);
  void addWords(Iterable<String> words) => words.forEach(addWord);

  void _addChar(String word, String actual) {
    var tmpNode = _root;
    for (var rune in word.runes) {
      tmpNode = tmpNode.addChild(rune);
    }
    tmpNode.word = actual;
  }

  List<Result> find(String input) {
    hypotheses = <String, double>{};

    var hyp = _Hypothesis(null, _root, 0.0, -1, _Hypothesis.N_A);
    var next = expand(hyp, input);
    while (true) {
      var newHyps = <_Hypothesis>{};
      for (var hypothesis in next) {
        newHyps.addAll(expand(hypothesis, input));
      }
      if (newHyps.isEmpty) break;
      next = newHyps;
    }

    return hypotheses.keys.map((key) => Result(key, hypotheses[key])).toList()
      ..sort();
  }

  Set<_Hypothesis> expand(_Hypothesis hypothesis, String input) {
    var newHypotheses = <_Hypothesis>{};
    var nextIndex = hypothesis.index + 1;

    // no-error
    if (nextIndex < input.length) {
      if (hypothesis.node.hasChild(input.codeUnitAt(nextIndex))) {
        var hyp = hypothesis.getNewMoveForward(
            hypothesis.node.getChild(input.codeUnitAt(nextIndex)),
            0.0,
            _Hypothesis.NE);
        if (nextIndex >= input.length - 1) {
          if (hyp.node.word != null) addHypothesis(hyp);
        } // TODO: below line may produce unnecessary hypotheses.
        newHypotheses.add(hyp);
      }
    } else if (hypothesis.node.word != null) {
      addHypothesis(hypothesis);
    }

    // we don't need to explore further if we reached to max penalty
    if (hypothesis.distance >= distance) return newHypotheses;

    // substitution
    if (nextIndex < input.length) {
      for (var childNode in hypothesis.node.children) {
        var penalty = 0.0;
        if (checkNearKeySubstitution) {
          var nextChar = input.codeUnitAt(nextIndex);
          if (childNode.chr != nextChar) {
            var nearCharactersString = nearKeyMap[childNode.chr];
            if (nearCharactersString != null &&
                containsCodeunit(nearCharactersString, nextChar)) {
              penalty = NEAR_KEY_SUBSTITUTION_PENALTY;
            } else {
              penalty = SUBSTITUTION_PENALTY;
            }
          }
        } else {
          penalty = SUBSTITUTION_PENALTY;
        }

        if (penalty > 0 && hypothesis.distance + penalty <= distance) {
          var hyp =
              hypothesis.getNewMoveForward(childNode, penalty, _Hypothesis.SUB);
          if (nextIndex == input.length - 1) {
            if (hyp.node.word != null) addHypothesis(hyp);
          } else {
            newHypotheses.add(hyp);
          }
        }
      }
    }

    if (hypothesis.distance + DELETION_PENALTY > distance) return newHypotheses;

    // deletion
    newHypotheses.add(hypothesis.getNewMoveForward(
        hypothesis.node, DELETION_PENALTY, _Hypothesis.DEL));

    // insertion
    for (var childNode in hypothesis.node.children) {
      newHypotheses.add(hypothesis.getNew(
          childNode, INSERTION_PENALTY, hypothesis.index, _Hypothesis.INS));
    }

    // transposition
    if (nextIndex < input.length - 1) {
      var transpose = input.codeUnitAt(nextIndex + 1);
      var nextNode = hypothesis.node.getChild(transpose);
      var nextChar = input.codeUnitAt(nextIndex);
      if (hypothesis.node.hasChild(transpose) && nextNode.hasChild(nextChar)) {
        var hyp = hypothesis.getNew(nextNode.getChild(nextChar),
            TRANSPOSITION_PENALTY, nextIndex + 1, _Hypothesis.TR);
        if (nextIndex == input.length - 1) {
          if (hyp.node.word != null) addHypothesis(hyp);
        } else {
          newHypotheses.add(hyp);
        }
      }
    }
    return newHypotheses;
  }

  bool containsCodeunit(String s, int i) {
    for (var c in s.codeUnits) {
      if (c == i) return true;
    }
    return false;
  }

  void addHypothesis(_Hypothesis hypToAdd) {
    var hypWord = hypToAdd.node.word;
    if (hypWord == null) {
      return;
    }
    if (!hypotheses.containsKey(hypWord)) {
      hypotheses[hypWord] = hypToAdd.distance;
    } else if (hypotheses[hypWord] > hypToAdd.distance) {
      hypotheses[hypWord] = hypToAdd.distance;
    }
  }
}

class _Node {
  int chr;
  Map<int, _Node> nodes = <int, _Node>{};
  String word;

  _Node(this.chr);

  Iterable<_Node> get children => nodes.values;

  bool hasChild(int c) => nodes.containsKey(c);
  _Node getChild(int c) => nodes[c];
  _Node addChild(int c) => nodes.putIfAbsent(c, () => _Node(c));
}

class _Hypothesis {
  static const NE = 0;
  static const INS = 1;
  static const DEL = 2;
  static const SUB = 3;
  static const TR = 4;
  static const N_A = 5;

  int operation;
  _Hypothesis previous;
  _Node node;
  double distance;
  int index = -1;

  _Hypothesis(
      this.previous, this.node, this.distance, this.index, this.operation);

//  _Hypothesis
  _Hypothesis getNewMoveForward(
      _Node node, double penaltyToAdd, int operation) {
    return _Hypothesis(
        this, node, distance + penaltyToAdd, index + 1, operation);
  }

  _Hypothesis getNew(
      _Node node, double penaltyToAdd, int index, int operation) {
    return _Hypothesis(this, node, distance + penaltyToAdd, index, operation);
  }

  @override
  bool operator ==(other) {
    if (other is! _Hypothesis) return false;
    return index == other.index &&
        distance.compareTo(other.distance) == 0 &&
        node == other.node;
  }
}

class Result {
  final String word;
  final double distance;

  Result(this.word, this.distance);

  @override
  String toString() => '$word:$distance';
}
