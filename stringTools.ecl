IMPORT std;
IMPORT DataScience.Tools.TransformTools AS t;

EXPORT StringTools := MODULE
    

  EXPORT LongestWord (STRING InWords) := FUNCTION       
  /*------------------------------------------------------
  Takes a multi word string and returns just the longest word
  ------------------------------------------------------*/
   
    SplitWords := STD.Str.SplitWords(InWords, ' ');
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
  /*------------------------------------------------------
  Helps to create regex matchihng strings by allowing optional spaces between numbers.
  Also controlls for presence of hyphens.
  ------------------------------------------------------*/
   
    ExtNumbers   := REGEXREPLACE('([0-9])'    , InWords     , '[ ]?$1[ ]?'); 
    noHyph       := REGEXREPLACE('[ ]?-[ ]?'  , ExtNumbers  , '[ ]?');
    DoubleSpace1 := REGEXREPLACE(' \\[ \\]\\?', noHyph      , '[ ]?');
    DoubleSpace2 := REGEXREPLACE('\\[ \\]\\? ', DoubleSpace1, '[ ]?');
    RETURN DoubleSpace2;
  END;
  
  
  
  EXPORT ShortestWordDistance (STRING inString1, STRING inString2) := FUNCTION
  /*------------------------------------------------------
  Does a pairwise comparison of all words in each string, 
  returns the shortest distance between any two words. 
  ------------------------------------------------------*/

  //Extract must have's first as cannot be matching on two word strings and cannot be considering numbers as equal to letters.   
    split1 := DATASET(STD.Str.SplitWords(inString1, ' '), {STRING words;});
    split2 := DATASET(STD.Str.SplitWords(inString2, ' '), {STRING words;});

    split1Proj := t.append(split1, UNSIGNED1, match, 1);
    split2Proj := t.append(split2, UNSIGNED1, match, 1);

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
    /*------------------------------------------------------
    Create a regex that takes each word in the input string and 
    states 'all these must be present to match'
    ------------------------------------------------------*/
    aStr1 := REGEXREPLACE(sep, aStr, '\\\\b)(?=.*\\\\b');
    aStr2 := '^(?=.*\\b' + aStr1 + '\\b).*$';
    RETURN aStr2;
  END; 
  

  
  
  EXPORT makeBOW(STRING aStr) := FUNCTION
    /*------------------------------------------------------
    Generates a unique, alphabetised word list. SHOULD BE A 
    MACRO, THIS IS CONVOLUTED. 
    ------------------------------------------------------*/
    lower        := std.str.tolowercase(aStr);
    noPunct      := REGEXREPLACE('[^0-9a-z]', lower, ' ');
    oneSpac      := REGEXREPLACE('\\s+', noPunct, ' ');
    splits       := STD.Str.SplitWords(oneSpac, ' ');
    splitsDS     := DATASET(splits, {STRING words});
    unqiueSplits := DEDUP(SORT(splitsDS, words), words);

    wordList := ITERATE(unqiueSplits, TRANSFORM({STRING words},  SELF.words := LEFT.words + ' ' + RIGHT.words));
    wordsOut := SET(wordList, words)[count(wordList)]; 
    
    RETURN TRIM(wordsOut, LEFT, RIGHT );
  END; 
  
  
  
  EXPORT regexLoopRec := {STRING Regex; STRING repl};
  EXPORT regexLoop(STRING inStr, DATASET(regexLoopRec) regexDS, BOOLEAN TidyToo = TRUE) := FUNCTION
    /*--------------------------------------------------------------------
    Loops through two sets and conducts a number of regex substitutions. 
    Takes two Sets as regex and replacement. A dataset would be preferred
    but that causes the function to crash as it can't take a dataset and create
    a count from it in a macro. What you could do is make a dataset and then cast
    the columns to sets in the function call. ECL is hard, okay? Note it also NOCASES
    by default. 

    
    --------------------------------------------------------------------*/
    
    aString := IF(TidyToo, std.Str.ToLowerCase(inStr), inStr);
    inDSaddCol := t.append(regexDS, STRING, outString, '');
    
    outDS := ITERATE(inDSaddCol, 
                TRANSFORM(RECORDOF(LEFT), 
                          firstRow := LEFT.Regex = '';
                          inString := IF(firstRow, aString, LEFT.outString);
                          SELF.outString := REGEXREPLACE(RIGHT.regex, inString, RIGHT.repl, NOCASE);
                          SELF := RIGHT;));   
                 
    outStr := SET(outDS, outString)[COUNT(outDS)];
    FinalOutStr := IF(TidyToo, TRIM(outStr, LEFT, RIGHT), outStr);
    OUTPUT(outDS);
 
    RETURN FinalOutStr;
  END;
  
  
  EXPORT regexLoopOld(inStr, regex, replacement/*, TidyToo = TRUE*/) := FUNCTIONMACRO
    /*--------------------------------------------------------------------
    Loops through two sets and conducts a number of regex substitutions. 
    Takes two Sets as regex and replacement. A dataset would be preferred
    but that causes the function to crash as it can't take a dataset and create
    a count from it in a macro. What you could do is make a dataset and then cast
    the columns to sets in the function call. ECL is hard, okay? Note it also NOCASES
    by default. 

    inStr - a string to correct
    regex - a set containing regex statements to sub
    replacement - what to sub the regex statements with
    TidyToo - Boolean. Should we lowercase and trim too?
    --------------------------------------------------------------------*/
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