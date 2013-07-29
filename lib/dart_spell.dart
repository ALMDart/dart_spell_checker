library dart_spell;

import 'dart:collection';

int _nodeIndexCounter=0;

class SingleWordSpellChecker {
  bool checkNearKeySubstitution=false;
  
  final double INSERTION_PENALTY = 1.0;
  final double DELETION_PENALTY = 1.0;
  final double SUBSTITUTION_PENALTY = 1.0;
  final double NEAR_KEY_SUBSTITUTION_PENALTY = 0.5;
  final double TRANSPOSITION_PENALTY = 1.0;
  
  Map<int, String> nearKeyMap = new Map();
  double maxPenalty=0.0;
  Node root;
  
  SingleWordSpellChecker(this.maxPenalty) {
    root = new Node(_nodeIndexCounter++,0);
  }

  void addWord(String word) {    
    //TODO: locale aware lower casing is required.
    addChar(root, 0, word.toLowerCase(), word);
  }

  void addWords(List<String> words) {
    for (String word in words) {
      addWord(word);
    }
  }

  Node addChar(Node currentNode, int index, String word, String actual) {
    int c = word.codeUnitAt(index);
    Node child = currentNode.addChild(c);
    if (index == word.length - 1) {
      child.word = actual;
      return child;
    }
    index++;
    return addChar(child, index, word, actual);
  }
  
  Map<String,double> decode(String input) {
    Hypothesis hyp = new Hypothesis(null, root, 0.0, -1, Hypothesis.N_A);
    Map<String,double> hypotheses = new Map();
    Set<Hypothesis> next = expand(hyp, input, hypotheses);
    while (true) {
      Set<Hypothesis> newHyps = new Set();
      for (Hypothesis hypothesis in next) {
        newHyps.addAll(expand(hypothesis, input, hypotheses));
      }
      if (newHyps.length == 0)
        break;
      next = newHyps;
    }
    return hypotheses;
  }  
  
  Set<Hypothesis> expand(Hypothesis hypothesis, String input, Map<String,double> finished) {
  
    Set<Hypothesis> newHypotheses = new Set();
  
    int nextIndex = hypothesis.index + 1;
  
    // no-error
    if (nextIndex < input.length) {
      if (hypothesis.node.hasChild(input.codeUnitAt(nextIndex))) {
        Hypothesis hyp = hypothesis.getNewMoveForward(
            hypothesis.node.getChild(input.codeUnitAt(nextIndex)),
            0.0,
            Hypothesis.NE);
        if (nextIndex >= input.length - 1) {
          if (hyp.node.word != null)
            addHypothesis(finished, hyp);
        } // TODO: below line may produce unnecessary hypotheses.
        newHypotheses.add(hyp);
      }
    } else if (hypothesis.node.word != null)
      addHypothesis(finished, hypothesis);
  
    // we don't need to explore further if we reached to max penalty
    if (hypothesis.penalty >= maxPenalty)
      return newHypotheses;
  
    // substitution
    if (nextIndex < input.length) {
      for (Node childNode in hypothesis.node.getChildNodes()) {
  
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
  
        if (penalty > 0 && hypothesis.penalty + penalty <= maxPenalty) {
          Hypothesis hyp = hypothesis.getNewMoveForward(
              childNode,
              penalty,
              Hypothesis.SUB);
          if (nextIndex == input.length - 1) {
            if (hyp.node.word != null)
              addHypothesis(finished, hyp);
          } else
            newHypotheses.add(hyp);
        }
      }
    }
  
    if (hypothesis.penalty + DELETION_PENALTY > maxPenalty)
      return newHypotheses;
  
    // deletion
    newHypotheses.add(hypothesis.getNewMoveForward(hypothesis.node, DELETION_PENALTY, Hypothesis.DEL));
  
    // insertion
    for (Node childNode in hypothesis.node.getChildNodes()) {
      newHypotheses.add(hypothesis.getNew(childNode, INSERTION_PENALTY, hypothesis.index, Hypothesis.INS));
    }
  
    // transposition
    if (nextIndex < input.length - 1) {
      int transpose = input.codeUnitAt(nextIndex + 1);
      Node nextNode = hypothesis.node.getChild(transpose);
      int nextChar = input.codeUnitAt(nextIndex);
      if (hypothesis.node.hasChild(transpose) && nextNode.hasChild(nextChar)) {
        Hypothesis hyp = hypothesis.getNew(
            nextNode.getChild(nextChar),
            TRANSPOSITION_PENALTY,
            nextIndex + 1,
            Hypothesis.TR);
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
  
  addHypothesis(Map<String,double> result, Hypothesis hypothesis) {
    String hypWord = hypothesis.node.word;
    if (hypWord == null) {
      return;
    }
    if (!result.containsKey(hypWord)) {
      result[hypWord]=hypothesis.penalty;
    } else if (result[hypWord] > hypothesis.penalty) {
      result[hypWord]=hypothesis.penalty;
    }
  }
}

class Node {
  int index;
  int chr;
  Map<int, Node> nodes = new Map();
  String word;
  
  Node(this.index, this.chr);
  
  Iterable<Node> getChildNodes() {
    return nodes.values;
  }

  bool hasChild(int c) {
    return nodes.containsKey(c);
  }

  Node getChild(int c) {
    return nodes[c];
  }  
  
  Node addChild(int c) {
    Node node = nodes[c];
    if (node == null) {
      node = new Node(_nodeIndexCounter++, c);
      nodes[c]=node;      
    }
    return node;
  }  
  
  bool operator ==(other) {
    if (!(other is Node)) return false;
    return (index == other.index);
  }  
  
  int get hashCode => index; 
  
}

class Hypothesis implements Comparable<Hypothesis> {
  static const NE = 0;
  static const INS = 1;
  static const DEL = 2;  
  static const SUB = 3;  
  static const TR = 4;  
  static const N_A= 5;
  
  int operation = N_A;
  Hypothesis previous;
  Node node;
  double penalty;
  int index = -1;  
     
  Hypothesis(this.previous, this.node, this.penalty, this.index, this.operation);  
  
  int compareTo(Hypothesis other) => penalty.compareTo(other.penalty);
  
  Hypothesis getNewMoveForward(Node node, double penaltyToAdd, int operation) {
    return new Hypothesis(this, node, this.penalty + penaltyToAdd, index + 1, operation);    
  }  
  
  Hypothesis getNew(Node node, double penaltyToAdd, int index, int operation) {
    return new Hypothesis(this, node, this.penalty + penaltyToAdd, index, operation);    
  }    
  
  bool operator ==(other) {
    if (other is! Hypothesis) return false;
    return index ==  other.index && 
        penalty.compareTo(other.penalty)==0 && 
        node==other.node;    
  }    
  
  int get hashCode {
    int result = node.hashCode;
    result= result*31+penalty.hashCode;
    result= result*31+index;
    return result;
  }    
}

main() {
  var spellChecker = new SingleWordSpellChecker(1.0);
  spellChecker.addWords(["apple","apples","appl"]);
  Map<String,double> hypotheses = spellChecker.decode("apples");
  print (hypotheses);
}