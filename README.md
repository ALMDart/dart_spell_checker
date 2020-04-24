dart_spell
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
*0.1.2* Remove comparable from Result
*0.1.1+8* Update to effective dart and format with dartfmt  
*0.1.1+7* Make addChar private  
*0.1.1+6* Update addChar function header  
*0.1.1+5* Make root private to Search, make addChar iterative instead of recursive  
*0.1.1+4* Swap out List for Iterable in addWords  
*0.1.1+3* Remove uses of new to match modern dart  
*0.1.1+2* Remove unncessary hashing/index code
*0.1.1+1* Dart 2.0 clean-up  
*0.1.1* Dart 1.0 clean-up.  
*0.1.0* Initial release
