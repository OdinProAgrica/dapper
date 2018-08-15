EXPORT quantile := MODULE

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

  EXPORT quantile(DATASET(INrec) INds, DECIMAL12_10 quant) := FUNCTION 
    
    //DIVIDE 0 DOESNT THROW AN ERROR!!!!!!!!!!!!!!!
    quantMult := 1/quant;

    DistINDs := SORT(DISTRIBUTE(INds, HASH(GroupVar)), GroupVar, LOCAL);
    
    DNrec := RECORD
      STRING GroupVar;
      DATASET({DECIMAL32_15 num}) numsList;
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

    Outrec := RECORD
      STRING     GroupVar;
      DECIMAL32_15 quant;
    END;

    OutRec MedianTrans(denormDS L) := TRANSFORM
      numCnt         := COUNT(L.numsList);
      S_nums         := SORT(L.numsList, num);
      quantRec1      := ROUND(numCnt / quantMult); 
      quantRec2      := IF(quantRec1 = 0 OR quant = 0, 1, quantRec1);
      quantRec       := IF(quant = 1, numCnt, quantRec2);
      SELF.quant     := IF(numCnt % quantMult = 1 OR quant = 1 OR quant = numCnt,
                                 S_nums[quantRec].num
                              , (S_nums[quantRec].num + S_nums[quantRec + 1].num) / 2);
      SELF := L;   
    END;

    OutGroup := PROJECT(denormDS, MedianTrans(LEFT), LOCAL);

    RETURN OutGroup;
    // RETURN 'BROKEN';
  END;
 END;