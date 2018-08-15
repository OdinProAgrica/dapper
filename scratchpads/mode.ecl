////WARNING: This cannot properly handle multimodal datasets at present. It will return the group that comes first and that's it. 

EXPORT mode := MODULE

  SHARED FreqRec := RECORD
    DECIMAL32_15 inList;
  END;

  SHARED Outrec := RECORD
    STRING     GroupVar;
    DECIMAL32_15 mode;
  END;  
  
  SHARED MostFrequent(DATASET (FreqRec) InDS) := FUNCTION
    CountRec1 := RECORD
      STRING inList      := (STRING) inDS.inList;
      UNSIGNED NoRecs := COUNT(GROUP);
    END;
    
    CountDS := TABLE(inDS, CountRec1, inDS.inList);
    SortedCountDS := SORT(CountDS, -NoRecs);

    RETURN (DECIMAL32_15) SET(SortedCountDS, inList)[1];
  END;


   EXPORT INrec := RECORD
    STRING GroupVar;
    DECIMAL32_15 num;
  END;

  // INds := DATASET([ {'Boston',23.5},
                     // {'Boston',43.2},
                     // {'Boston',29},
                     // {'Chicago',15.1},
                     // {'NY',12.0},
                     // {'NY',55},
                     // {'NY',57.2},
                     // {'NY',11.9}
                    // ], INrec);

  EXPORT mode(DATASET(INrec) INds) := FUNCTION 

    DistINDs := SORT(DISTRIBUTE(INds, HASH(GroupVar)), GroupVar, LOCAL);
    
    DNrec := RECORD
      STRING GroupVar;
      DATASET(FreqRec) numsList;
    END;

    ProjectedInDS := PROJECT(TABLE(DistINDs, {GroupVar}, GroupVar),
                   TRANSFORM(DNrec, 
                             SELF.numsList := [];
                             SELF := LEFT;
                             )
                   , LOCAL);
                   
    denormDS := DENORMALIZE(ProjectedInDS, DistINDs,
                        LEFT.GroupVar = RIGHT.GroupVar,
                        TRANSFORM(DNrec,
                                  SELF.numsList := LEFT.numsList + ROW({RIGHT.num}, {DECIMAL32_15 num});
                                  SELF := LEFT) 
                        , LOCAL);
                        
    OutRec ModeTrans(denormDS L) := TRANSFORM
      inTab     := L.numsList;
      mostFreq  := MostFrequent(inTab);
      SELF.mode := mostFreq;
      SELF      := L;   
    END;

    OutGroup := PROJECT(denormDS, ModeTrans(LEFT), LOCAL);

    RETURN OutGroup;
  END;
 END;