EXPORT median := MODULE

   EXPORT INrec := RECORD
    STRING group_val;
    DECIMAL32_15 num_val;
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

  EXPORT Median_old(DATASET(INrec) INds) := FUNCTION 

    DistINDs := SORT(DISTRIBUTE(INds, HASH(group_val)), group_val, LOCAL);
    
    DNrec := RECORD
      STRING group_val;
      DATASET({DECIMAL32_15 num_val}) numsList;
    END;

    ProjectedInDS := PROJECT(TABLE(DistINDs, {group_val}, group_val),
                   TRANSFORM(DNrec, 
                             SELF.numsList := [];
                             SELF := LEFT;
                             )
                   , LOCAL);
                   
    denormDS := DENORMALIZE(ProjectedInDS, DistINDs,
                        LEFT.group_val = RIGHT.group_val,
                        TRANSFORM(DNrec,
                                  SELF.numsList := LEFT.numsList & ROW({RIGHT.num_val}, {DECIMAL32_15 num_val});
                                  SELF := LEFT) 
                        , LOCAL);
    Outrec := RECORD
      STRING     group_val;
      DECIMAL32_15 median;
    END;

    OutRec MedianTrans(denormDS L) := TRANSFORM
      numCnt          := COUNT(L.numsList);
      S_nums          := SORT(L.numsList, num_val);
      MidRec          := numCnt - (numCnt DIV 2); 
      SELF.median     := IF(numCnt % 2 = 1,
                              S_nums[MidRec].num_val
                              , (S_nums[MidRec].num_val + S_nums[MidRec + 1].num_val) / 2);
      SELF := L;   
    END;

    OutGroup := PROJECT(denormDS, MedianTrans(LEFT), LOCAL);

    RETURN OutGroup;
  END;
  
  SHARED dummy_val := Median_old(DATASET([], INrec));
  
  EXPORT Median(DATASET(INrec) INds) := FUNCTION 
      //
      // Create a stream of data values for each group ... in ascending order ...
      // compress the stream by coalescing like values in each group and noting how many
      // records had that value.
      //
      // Use the whole of the cluster to sort these values, and ... at the last moment ...
      // merge them into a single stream where all the values for each group are sent
      // to the same slave for aggregation.
      //
      // Notice the use of DISTRIBUTE(,MERGE()) to "zipper" the rows for each group into
      // a properly sorted stream. Any use of DISTRIBUTE(,MERGE()) is a task that Spark/Hadoop
      // can't natively accomplish.
      //
      median_data1 := INds;
      median_data2 := TABLE(median_data1,
        {
            group_val,
            num_val,
            unsigned record_cnt := COUNT(GROUP)
        }, group_val, num_val, MERGE);
      median_data3 := DISTRIBUTE(median_data2, HASH32(group_val, num_val));
      median_data4 := SORT(median_data3, group_val, num_val, LOCAL);
      median_data5 := DISTRIBUTE(median_data4, HASH32(group_val), MERGE(group_val, num_val));
      median_data  := median_data5;  // lhs of JOIN
 
      //
      // To compute the median, we need to know the total number of rows in each group.
      // Calculate this from our previously compressed data set and distribute each group's
      // result to the slave where it will be aggregated.
      //
      median_rowcnt1 := TABLE(median_data2,
        {
            group_val,
            unsigned group_record_cnt := SUM(GROUP, record_cnt)
        }, group_val, MERGE);
      median_rowcnt2 := DISTRIBUTE(median_rowcnt1, HASH32(group_val));
      median_rowcnt  := median_rowcnt2;   // rhs of JOIN
 
      //
      // Receive the stream of data, and append the total number of rows in each
      // group to the end of each record.
      //
      // Set up for the median calculaton, by creating the median field and filling
      // it in with the median values for groups with a single record.
      //
      // We've already placed the rhs data where it will be needed, so use
      // the LOCAL option to avoid sending all rhs data everywhere.
      //
      // Use of FEW tells the compiler that this is an "easy" operation and that
      // it doesn't need to give the normal weight to it when deciding how to
      // split up work into graphs. Compile with and without it and compare the
      // resultant graphs. Specifying FEW will probably allow the prior SORT and
      // this JOIN to stay within the same graph, removing a trip to a spill file ...
      // allowing this operation to stream smoothly.
      //
      median1 := JOIN(median_data, median_rowcnt,
      LEFT.group_val = RIGHT.group_val,
        TRANSFORM(
          {
              RECORDOF(LEFT),
              real median,
              unsigned group_record_cnt
          },
          SELF.median           := LEFT.num_val,
          SELF.group_record_cnt := RIGHT.group_record_cnt,
          SELF                  := LEFT),
        INNER,
        LOOKUP,
        LOCAL,
        FEW,
        ORDERED);
 
      //
      // Watch the data for each group to stream by. Notice when the TRANSFORM
      // processes the median record(s) and establish the median value at that point.
      //
      // Other values could be aggregated here too ... max, min, and sd (if you
      // aggregate the proper values as they stream by).
      //
      median2 := ROLLUP(median1,
        LEFT.group_val = RIGHT.group_val,
        TRANSFORM(RECORDOF(LEFT),
          median_recno       := LEFT.group_record_cnt / 2;
          median_modulo      := LEFT.group_record_cnt % 2;
          SELF.record_cnt    := LEFT.record_cnt + RIGHT.record_cnt,
          SELF.median        := IF(LEFT.record_cnt < median_recno,
                                   RIGHT.median,
                                   IF(LEFT.record_cnt > median_recno,
                                      LEFT.median,
                                      IF(median_modulo = 1,
                                         LEFT.median,
                                         (LEFT.median + RIGHT.median)/2))),
          SELF               := RIGHT));
      my_median  := PROJECT(median2,
        TRANSFORM(RECORDOF(dummy_val),
          SELF.group_val := LEFT.group_val,
          SELF.median   := LEFT.median));
 
      RETURN(my_median);
  END;
END;
