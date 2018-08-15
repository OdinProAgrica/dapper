EXPORT meanNoNA(DATASET({STRING InputData}) inVals) := FUNCTION

  //NOT RESISTANT TO NON-NUMERICS

  RunVals := inVals(InputData != '');
  
  a := SUM(RunVals, (DECIMAL32_12) RunVals.InputData);
  b := COUNT(RunVals);

  meanNoNA := a/b;
  
  RETURN meanNoNA;
  END;