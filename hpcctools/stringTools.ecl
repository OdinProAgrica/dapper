IMPORT std;

EXPORT StringTools := MODULE
  
  EXPORT regexLoopRec := {STRING Regex; STRING repl};
  EXPORT regexLoop(STRING inStr, DATASET(regexLoopRec) regexDS, BOOLEAN noCaseRegex = TRUE, BOOLEAN TidyToo = TRUE) := FUNCTION
    
    /*  -------------------------------------------------------------
      Loops through two sets and conducts a number of regex substitutions. 
      Takes a database containing regex and replacement (see above RECORD, RegexLoopRec). 

      Note this NOCASES by default. 

      @param inStr String - text to be replaced
      @param regexDS DataSet - See above recordset (RegexLoopRec). List of from and to strings, from can be a regex and replacement can contain capture groups. 
      @param noCaseRegex Boolean - Should the regex be conducted with nocase? Defaults to TRUE
      @param TidyToo Boolean - Shoulde the strings be lowercased and trimmed left and right before commencing? Defaults to TRUE

      @return - String with all regexs applied in order
      -------------------------------------------------------------*/        
    LOCAL aString := IF(TidyToo, TRIM(std.Str.ToLowerCase(inStr), LEFT, RIGHT), inStr);
    LOCAL regexDSBlankRow := DATASET([{' ',' '}], regexLoopRec);
    LOCAL regexDSconcat := regexDSBlankRow + regexDS;
    LOCAL inDSaddCol := PROJECT(regexDSconcat, TRANSFORM({RECORDOF(LEFT); STRING outString;}, SELF.outString := aString; SELF := LEFT;));

    LOCAL outDS := ROLLUP(inDSaddCol, TRUE,
                TRANSFORM(RECORDOF(LEFT), 
                          SELF.outString := IF(nocaseRegex, 
                                                REGEXREPLACE(RIGHT.regex, LEFT.outString, RIGHT.repl, NOCASE), 
                                                REGEXREPLACE(RIGHT.regex, LEFT.outString, RIGHT.repl));
                          SELF := RIGHT;)); 
                                                    
    LOCAL outStr := SET(outDS, outString)[1]; 
    RETURN outStr;
  END;
  

  EXPORT LongestWord (STRING InWords, STRING seperator = ' ') := FUNCTION       

    /*  -------------------------------------------------------------
      Takes a multi word string and returns just the longest word

      @param InWords String - collection of words
      @param seperator String - word seperator, defaults to space

      @return - String of the longest word
      -------------------------------------------------------------*/    
      
    SplitWords := STD.Str.SplitWords(InWords, seperator);
    WordDS := DATASET(SplitWords, {STRING words}); //Convert to DS
    
    GetLen := PROJECT(WordDS, 
                      TRANSFORM({INTEGER Len; STRING words;}, 
                              SELF.Len   := LENGTH(LEFT.words);
                              SELF       := LEFT;));
                    
    OrderedWords := SET(SORT(GetLen, -Len, Words), Words); //order by length descending, convert to set

    outString := IF(STD.Str.Contains(InWords, ' ', TRUE) //if a multi-word string
                    , OrderedWords[1]                    //returnLongest
                    , InWords);                          //else return whole string
                    
    RETURN outString;
  END;



  EXPORT NumberSpacing (STRING InWords) := FUNCTION
     /*  -------------------------------------------------------------
      Helps to create regex matchihng strings by allowing optional spaces between numbers.
      Also controlls for presence of hyphens.

      @param InWords String - Text to be modified

      @return - text with optional regex spaces between numbers
      -------------------------------------------------------------*/    
      
    ExtNumbers   := REGEXREPLACE('([0-9])'    , InWords     , '[ ]?$1[ ]?'); 
    noHyph       := REGEXREPLACE('[ ]?-[ ]?'  , ExtNumbers  , '[ ]?');
    DoubleSpace1 := REGEXREPLACE(' \\[ \\]\\?', noHyph      , '[ ]?');
    DoubleSpace2 := REGEXREPLACE('\\[ \\]\\? ', DoubleSpace1, '[ ]?');
    RETURN DoubleSpace2;
  END;
  
  
  
  EXPORT ShortestWordDistance (STRING inString1, STRING inString2) := FUNCTION

     /*  -------------------------------------------------------------
      Does a pairwise comparison of all words in each string, 
      returns the shortest distance between any two words. 

      @param inString1 String - Text to be compared 1
      @param inString2 String - Text to be compared 2

      @return - text of closest word present in both. Or '' if none
      -------------------------------------------------------------*/    
  //Extract must have's first as cannot be matching on two word strings and cannot be considering numbers as equal to letters.   
    split1 := DATASET(STD.Str.SplitWords(inString1, ' '), {STRING words;});
    split2 := DATASET(STD.Str.SplitWords(inString2, ' '), {STRING words;});

    
				// split1Proj := tt.append(split1, UNSIGNED1, match, 1);
				split1Proj := PROJECT(split1, TRANSFORM({RECORDOF(LEFT); INTEGER match;}, SELF.match := 1; SELF := LEFT;));
				split2Proj := PROJECT(split2, TRANSFORM({RECORDOF(LEFT); INTEGER match;}, SELF.match := 1; SELF := LEFT;));
    // split2Proj := tt.append(split2, UNSIGNED1, match, 1);

    Allcomparisons := JOIN(split1Proj, split2Proj, 
                           LEFT.match = RIGHT.match, 
                           TRANSFORM({STRING words1; STRING words2; INTEGER distance;},
                                        SELF.distance := STD.Str.EditDistance(LEFT.words, RIGHT.words);
                                        SELF.words1 := LEFT.words;
                                        SELF.words2 := RIGHT.words;), ALL);

    SortedAllComparisons := SORT(AllComparisons, distance);
    ShortestMatch := (INTEGER) SET(SortedAllComparisons, distance)[1];
    RETURN ShortestMatch;
  END;  
  
  
  EXPORT allWordsPresentRegex (STRING aStr, STRING sep = ' ') := FUNCTION
     /*  -------------------------------------------------------------
      Create a regex that takes each word in the input string and 
      states 'all these must be present to match'

      @param aStr String - Text to be converted
      @param sep String - word seperator, defaults to ' '

      @return - Regex that will find all words in a string in any order
      -------------------------------------------------------------*/        
    aStr1 := REGEXREPLACE(sep, aStr, '\\\\b)(?=.*\\\\b');
    aStr2 := '^(?=.*\\b' + aStr1 + '\\b).*$';
    RETURN aStr2;
  END; 
  
  
  EXPORT makeBOW(STRING aStr, STRING sep = ' ') := FUNCTION
    
     /*  -------------------------------------------------------------
      Generates a unique, alphabetised word list from a string. 

      @param aStr String - Text to be converted
      @param sep String - word seperator, defaults to ' '

      @return - an alphabetised list of all words present. 

      TODO: SHOULD BE A MACRO, THIS IS CONVOLUTED. 
      -------------------------------------------------------------*/        
    
    lower        := std.str.tolowercase(aStr);
    noPunct      := REGEXREPLACE('[^0-9a-z]', lower, ' ');
    oneSpac      := REGEXREPLACE('\\s+', noPunct, ' ');
    splits       := STD.Str.SplitWords(oneSpac, sep);
    splitsDS     := DATASET(splits, {STRING words});
    unqiueSplits := DEDUP(SORT(splitsDS, words), words);

    wordList := ITERATE(unqiueSplits, TRANSFORM({STRING words},  SELF.words := LEFT.words + ' ' + RIGHT.words));
    wordsOut := SET(wordList, words)[count(wordList)]; 
    
    RETURN TRIM(wordsOut, LEFT, RIGHT );
  END; 
  
  
  EXPORT regexLoopOld(inStr, regex, replacement) := FUNCTIONMACRO
  
    /*  -------------------------------------------------------------
      
      ***DEPRICATION WARNING*** Use new version (at top of this module!)

      Loops through two sets and conducts a number of regex substitutions. 
      Takes two Sets as regex and replacement.


      @param inStr - a string to correct
      @param regex - a set containing regex statements to sub
      @param replacement - what to sub the regex statements with

      @return - string with all regexes applied in order
      -------------------------------------------------------------*/    

    IMPORT std;
    
    // aString := IF(TidyToo, std.Str.ToLowerCase(inStr), inStr);
    
    #DECLARE(regexI);
    #DECLARE(replaceI);
    #DECLARE(outStr); #SET(outStr, inStr);

    #DECLARE(I);    #SET(I, 1);
    #DECLARE(Nmax); #SET(nmax, COUNT(regex));

    //need a warning for different sized sets
    #LOOP
     #SET(regexI, regex[%I%]);
     #SET(replaceI, replacement[%I%]);
     #SET(outStr, REGEXREPLACE(%'regexI'%, %'outStr'%, %'replaceI'%, NOCASE));
     // OUTPUT(%'outStr'%);
     #SET(I, 1 + %I%);
     #IF(%I% > %Nmax%); #BREAK #END;
    #END  
 
    // FinalOutStr := IF(TidyToo, TRIM(%'outStr'%, LEFT, RIGHT), %'outStr'%);
 
    RETURN %'outStr'%;
  ENDMACRO;
  
END;    