IMPORT DataScience.Tools.stringTools as st;
IMPORT DataScience.Operations_Flat_Full as off;

st.LongestWord ('The Quick Brown Fox');
st.LongestWord('Cat Bat Rat');
st.NumberSpacing('A String 12-3  4');
st.ShortestWordDistance('This is a string', 'They are strings');
st.makeBOW('One Fish Two Fish Red Fish');
st.allWordsPresentRegex('Blue Fish');


regexDS := DATASET(
	[{'[^a-z]'  , ' '},
  {'\\s+'    , ' '},
  {'with'    , ' '},
  {'words'   , ' '},
  {'useless' , ' '},
 	{'messy'   , 'tidy'}
	], {STRING Regex; STRING Repl});

inStr := 'This is 67a Messy s-t.r[i]ng with    usELess words';
st.regexLoop(inStr, regexDS);
  

  



























