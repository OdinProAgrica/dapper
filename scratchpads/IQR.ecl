IMPORT DataScience.tools.quantile as q;

EXPORT IQR := MODULE

   EXPORT INrec := RECORD
    STRING GroupVar;
    DECIMAL32_15 num;
  END;
  
  EXPORT OutRec := RECORD
    STRING GroupVar;
    DECIMAL32_15 Q1;
    DECIMAL32_15 Q2;
    DECIMAL32_15 IQR;
  END;

  EXPORT IQR(DATASET(INrec) INds) := FUNCTION 
    
    Q1 := q.quantile(inDs, 0.25);
    Q2 := q.quantile(inDs, 0.75);

    IQRange := JOIN (Q1, Q2
                     , LEFT.GroupVar = RIGHT.GroupVar
                     , TRANSFORM(OutRec,
                                  SELF.GroupVar := LEFT.groupvar;
                                  SELF.Q1 := LEFT.quant;
                                  SELF.Q2 := RIGHT.quant;
                                  SELF.IQR := RIGHT.quant - LEFT.quant;
                                  )
                     , INNER, SMART);                                

    RETURN IQRange;
    // RETURN 'BROKEN';
  END;
 END;