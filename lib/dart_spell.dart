library dart_spell;

/**
 * Simple dictionary based spell checker.  
 */
class SingleWordSpellChecker {
  final bool checkNearKeySubstitution=false;
  
  final double INSERTION_PENALTY = 1.0;
  final double DELETION_PENALTY = 1.0;
  final double SUBSTITUTION_PENALTY = 1.0;
  final double TRANSPOSITION_PENALTY = 1.0;
  
  //TODO: not used yet.
  final double NEAR_KEY_SUBSTITUTION_PENALTY = 0.5;  
  Map<int, String> nearKeyMap = Map();
  
  double distance=1.0;
  _Node _root;
  
  SingleWordSpellChecker({this.distance:1.0}) {
    _root = _Node(0);
  }

  void addWord(String word) {    
    //TODO: locale aware lower casing is required.
    addChar(_root, 0, word.toLowerCase(), word);
  }

  void addWords(Iterable<String> words) {
    for (String word in words) {
      addWord(word);
    }
  }

  void addChar(_Node currentNode, int index, String word, String actual) {
    var tmpNode = _root;
    for(var rune in word.runes) {
      tmpNode = tmpNode.addChild(rune);
    }
    tmpNode.word = actual;
  }
  
  List<Result> find(String input) {
    _Hypothesis hyp = _Hypothesis(null, _root, 0.0, -1, _Hypothesis.N_A);
    Map<String,double> hypotheses = Map();
    Set<_Hypothesis> next = expand(hyp, input, hypotheses);
    while (true) {
      Set<_Hypothesis> newHyps = Set();
      for (_Hypothesis hypothesis in next) {
        newHyps.addAll(expand(hypothesis, input, hypotheses));
      }
      if (newHyps.length == 0)
        break;
      next = newHyps;
    }
    List<Result> result = [];
    for(String key in hypotheses.keys) {
      result.add(Result(key, hypotheses[key]));
    }   
    result.sort();
    return result;
  }  
  
  Set<_Hypothesis> expand(_Hypothesis hypothesis, String input, Map<String,double> finished) {
  
    Set<_Hypothesis> newHypotheses = Set();
  
    int nextIndex = hypothesis.index + 1;
  
    // no-error
    if (nextIndex < input.length) {
      if (hypothesis.node.hasChild(input.codeUnitAt(nextIndex))) {
        _Hypothesis hyp = hypothesis.getNewMoveForward(
            hypothesis.node.getChild(input.codeUnitAt(nextIndex)),
            0.0,
            _Hypothesis.NE);
        if (nextIndex >= input.length - 1) {
          if (hyp.node.word != null)
            addHypothesis(finished, hyp);
        } // TODO: below line may produce unnecessary hypotheses.
        newHypotheses.add(hyp);
      }
    } else if (hypothesis.node.word != null)
      addHypothesis(finished, hypothesis);
  
    // we don't need to explore further if we reached to max penalty
    if (hypothesis.distance >= distance)
      return newHypotheses;
  
    // substitution
    if (nextIndex < input.length) {
      for (_Node childNode in hypothesis.node.getChildNodes()) {
  
        double penalty = 0.0;
        if (checkNearKeySubstitution) {
          int nextChar = input.codeUnitAt(nextIndex);
          if (childNode.chr != nextChar) {
            String nearCharactersString = nearKeyMap[childNode.chr];
            if (nearCharactersString != null && containsCodeunit(nearCharactersString,nextChar))
              penalty = NEAR_KEY_SUBSTITUTION_PENALTY;
            else penalty = SUBSTITUTION_PENALTY;
          }
        } else penalty = SUBSTITUTION_PENALTY;
  
        if (penalty > 0 && hypothesis.distance + penalty <= distance) {
          _Hypothesis hyp = hypothesis.getNewMoveForward(
              childNode,
              penalty,
              _Hypothesis.SUB);          
          if (nextIndex == input.length - 1) {
            if (hyp.node.word != null)
              addHypothesis(finished, hyp);
          } else
            newHypotheses.add(hyp);
        }
      }
    }
  
    if (hypothesis.distance + DELETION_PENALTY > distance)
      return newHypotheses;
  
    // deletion
    newHypotheses.add(hypothesis.getNewMoveForward(hypothesis.node, DELETION_PENALTY, _Hypothesis.DEL));
  
    // insertion
    for (_Node childNode in hypothesis.node.getChildNodes()) {
      newHypotheses.add(hypothesis.getNew(childNode, INSERTION_PENALTY, hypothesis.index, _Hypothesis.INS));
    }
  
    // transposition
    if (nextIndex < input.length - 1) {
      int transpose = input.codeUnitAt(nextIndex + 1);
      _Node nextNode = hypothesis.node.getChild(transpose);
      int nextChar = input.codeUnitAt(nextIndex);
      if (hypothesis.node.hasChild(transpose) && nextNode.hasChild(nextChar)) {
        _Hypothesis hyp = hypothesis.getNew(
            nextNode.getChild(nextChar),
            TRANSPOSITION_PENALTY,
            nextIndex + 1,
            _Hypothesis.TR);
        if (nextIndex == input.length - 1) {
          if (hyp.node.word != null)
            addHypothesis(finished, hyp);
        } else
          newHypotheses.add(hyp);
      }
    }
    return newHypotheses;
  }
  
  bool containsCodeunit(String s, int i) {
    for(int c in s.codeUnits) {
      if(c==i)
        return true;
    }
    return false;
  }
  
  addHypothesis(Map<String,double> result, _Hypothesis hypothesis) {
    String hypWord = hypothesis.node.word;
    if (hypWord == null) {
      return;
    }
    if (!result.containsKey(hypWord)) {
      result[hypWord]=hypothesis.distance;
    } else if (result[hypWord] > hypothesis.distance) {
      result[hypWord]=hypothesis.distance;
    }
  }
}

class _Node {
  int chr;
  Map<int, _Node> nodes = Map();
  String word;
  
  _Node(this.chr);
  
  Iterable<_Node> getChildNodes() {
    return nodes.values;
  }

  bool hasChild(int c) {
    return nodes.containsKey(c);
  }

  _Node getChild(int c) {
    return nodes[c];
  }  
  
  _Node addChild(int c) {
    _Node node = nodes[c];
    if (node == null) {
      node = _Node(c);
      nodes[c]=node;      
    }
    return node;
  }
}

class _Hypothesis implements Comparable<_Hypothesis> {
  static const NE = 0;
  static const INS = 1;
  static const DEL = 2;  
  static const SUB = 3;  
  static const TR = 4;  
  static const N_A= 5;
  
  int operation = N_A;
  _Hypothesis previous;
  _Node node;
  double distance;
  int index = -1;  
     
  _Hypothesis(this.previous, this.node, this.distance, this.index, this.operation);  
  
  int compareTo(_Hypothesis other) => distance.compareTo(other.distance);
  
  _Hypothesis getNewMoveForward(_Node node, double penaltyToAdd, int operation) {
    return _Hypothesis(this, node, this.distance + penaltyToAdd, index + 1, operation);    
  }  
  
  _Hypothesis getNew(_Node node, double penaltyToAdd, int index, int operation) {
    return _Hypothesis(this, node, this.distance + penaltyToAdd, index, operation);    
  }    
  
  bool operator ==(other) {
    if (other is! _Hypothesis) return false;
    return index ==  other.index && 
        distance.compareTo(other.distance)==0 && 
        node==other.node;    
  }
}

class Result implements Comparable<Result> {
  final String word;
  final double distance;
  
  Result(this.word, this.distance);
  int compareTo(Result other) => distance.compareTo(other.distance); 
  
  String toString() {
    return "$word:$distance"; 
  }  
}

main() {
  var spellChecker = SingleWordSpellChecker(distance:1.0);
  spellChecker.addWords(["apple","apples","appl"]);
  List<Result> hypotheses = spellChecker.find("apple");
  print (hypotheses);
}
