dart-spell
==========

A simple spell checker implementation in Dart. For now it only finds the single words from a given 
dictionary. Algorithm is different than Peter Norvig's implementation (http://norvig.com/spell-correct.html). This implementation 
is more complicated but probably much faster (finds several thousands matches in a second). 
It uses dynamic decoding over a simple trie generated from the dictionary. System finds words with a distance to the input.
Deletions, insertions, substitutions and transpositions are supported.  

	import 'package:dart_spell/dart_spell.dart';
	
	...
	// optional distance parameter. Default is 1.0
	var checker = new SingleWordSpellChecker(distance:1.0);
	
	var dictionary = ["apple", "apples", "pear", "ear"];
	checker.addWords(dictionary);	
	
	List<Result> matches = checker.find("apple");
	print(matches);

	Output:
	[apple:0.0, apples:1.0]
	
##TODO
* Add less substitution penalty for near keys in keyboard layout.
* Add language model support so that it gives more logical suggestions.
* Add multi word spell suggestion with space and out of vocabulary word handling.  

## Change List
*0.1.1* Dart 1.0 clean-up.  
*0.1.0* Initial release  



   


