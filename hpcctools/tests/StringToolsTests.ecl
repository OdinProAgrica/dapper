IMPORT $.^.stringTools as st;

ASSERT('Brown' = st.LongestWord ('The Quick Brown Fox'));
ASSERT('Bat' = st.LongestWord('Cat Bat Rat'));
ASSERT('A String[ ]?1[ ]?[ ]?2[ ]?[ ]?[ ]?3[ ]?[ ]?4[ ]?' = st.NumberSpacing('A String 12-3  4'));
ASSERT(1 = st.ShortestWordDistance('This is a string', 'They are strings'));
ASSERT('fish one red two' = st.makeBOW('One Fish Two Fish Red Fish'));
ASSERT('^(?=.*\\bBlue\\b)(?=.*\\bFish\\b).*$' = st.allWordsPresentRegex('Blue Fish'));

regexDS := DATASET(
	[{'[^a-z]'  , ' '},
  {'\\s+'    , ' '},
  {'with'    , ' '},
  {'words'   , ' '},
  {'useless' , ' '},
 	{'messy'   , 'tidy'}
	], {STRING Regex; STRING Repl});

inStr := 'This is 67a Messy s-t.r[i]ng with    usELess words';
ASSERT('this is a tidy s t r i ng' = st.regexLoop(inStr, regexDS));




