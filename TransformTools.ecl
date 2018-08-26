  /**
   *  This MODULE has been created to ease the proces of data exploration in 
   *  ECL. Ever wanted to quickly combine two columns without writing a project?
   *  Wanted to output to CSV but had to lookup the syntax? Do a grouped Count
   *  without writing a RECORD definition? Then this package is for you! The
   *  main aim is to make exploration and QA quicker, more logical and easier 
   *  to read quickly by using shorthand notation and descriptive verbs. Try 
   *  it, we know you'll love it! Inspired by the very excellent dplyr package 
   *  in R. 
   *
   *  Note that to make these functions work from within a module or similar
   *  make sure any function or layout calls are shared. Also, you MUST
   *  have imported transformtools as tt otherwise internal imports will
   *  break.
   *
   *  Dev note, always trim(,ALL) a #TEXT command, it adds spaces
   *  
   */
 
//TODO: Should all functions have a LOCAL inDS := inDataSet? This resolves any concatenations or filters before you start the process 
// but may cause massive slowdown as the compiler MIGHT read it and thus seperate out the projects
  

EXPORT TransformTools := MODULE

   EXPORT NAMES(inDS) := FUNCTIONMACRO
   /**
    * Function takes a dataset and returns the names of all the columns as
    * 'name1, name2....' so note it returns a string that needs parsing.
    * 
    * @param inDs    the dataset to get column names from.
    * 
    * @return   list of column names, seperated by spaces.
    *  
    */
     IMPORT std;
		
      #EXPORTXML(DSxml, RECORDOF(inDS));
      #DECLARE(recSet)
      #SET(recSet, '')
      #FOR (DSxml)
       #FOR (Field) 
        #IF (%'{@isEnd}'% <> '')
        #ELSE
          #APPEND(recSet, %'{@label}'% + ' ')
          // OUTPUT(%'{@label}'% + ';');
        #END
       #END
       // OUTPUT(%'recSet'%)
      #END;
      
     LOCAL FullList := TRIM(%'recSet'%, LEFT, RIGHT);
     // ColumnSet := std.str.SplitWords(FullList, seperator);//IF(returnSet, std.str.SplitWords(FullList, seperator), FullList);
      
     RETURN FullList;
   ENDMACRO;
   
   
   EXPORT DeSelfer(inDS, inComm) := FUNCTIONMACRO   
   /**
    * Function takes a command in the form of var + var and modifies 
    * it to LEFT.var + LEFT.var. Allows for 
    * function calls such as REGEXFIND('aaa', LEFT.x). It will not 
    * work for joins (ie adding RIGHT). Returns a string
    * that will need #EXPAND() to use in a project. 
    * 
    * WARNING:if you pass a command where a variable name matches a 
    * function call you will get odd results and errors. Same issue
	* 				for strings. In such cases specify LEFT and you'll be fine. 
    * 
    * @param   inDS  the dataset to get colulmn names from.
    * @param   inComm  the command to parse, in raw ECL form, not string.
    * 
    * @return  An updataed ECL command with self. and left. added.
    *  
    */
	
     LOCAL columns1 := tt.names(inDS);
     LOCAL columns2 := REGEXREPLACE(' ', columns1, '|', NOCASE);
     LOCAL columns3 := '\\b(' + columns2 + ')\\b';
     
     LOCAL Command1 := TRIM(#TEXT(inComm), LEFT, RIGHT);
     // LOCAL Command2 := REGEXREPLACE('(\\bSELF\\s*\\.)|(\\bLEFT\\s*\\.)|(\\bRIGHT\\s*\\.)', Command1, ' ', NOCASE);
     LOCAL Command2 := REGEXREPLACE('(\\bLEFT\\s*\\.)', Command1, ' ', NOCASE);
     LOCAL Command3 := REGEXREPLACE(columns3, Command2, 'LEFT.\\1', NOCASE);
     LOCAL Command4 := REGEXREPLACE('\\s+', Command3, ' ', NOCASE);
    
     // LOCAL Command4 := REGEXREPLACE('^left\\.([^:=]*:=)',  command3, 'SELF.\\1', NOCASE);
     // LOCAL Command5 := REGEXREPLACE(';left\\.([^:=]*:=)',  command4, ';SELF.\\1', NOCASE);
     
     //If it already had LEFT., RIGHT. or SELF. in it then don't perform correction. 
     LOCAL outCommand := IF(REGEXFIND('(\\bSELF.)|(\\bLEFT.)|(\\bRIGHT.)', Command1, NOCASE), Command1, Command4);
     RETURN outCommand;
		 
   ENDMACRO;


   EXPORT DROP(inDS, dropCols) := FUNCTIONMACRO
   /**
    * Function takes a dataset and a string containing a list columns to  
    * drop. This should take the form of 'col1, col2, col3......'
    * 
    * @param inDS DataSet - the dataset to change
    * @param dropCols String - the columns to drop, seperaeted by ,
    * 
    * @return DataSet without the given columns
    * 
    */
    LOCAL outDS := PROJECT(inDS, 
              TRANSFORM(RECORDOF(LEFT) AND NOT [#EXPAND(dropCols)], 
              SELF := LEFT));
    RETURN outDS;
  ENDMACRO;


   EXPORT DROP_ASIS(inDS, dropCol) := FUNCTIONMACRO
   /**
    * Function takes a single column name as ECL (not a string) to drop
    *
    * @param    inDS   the dataset to change
    * @param    dropCol    the column to drop
    *
    * @return   DataSet without the given column
    * 
    */
    LOCAL outDS := PROJECT(inDS, 
              TRANSFORM(RECORDOF(LEFT) AND NOT [dropCol], 
              SELF := LEFT));
							
    RETURN outDS;
  ENDMACRO;
      
   EXPORT RENAME(inDS, currentName, newName) := FUNCTIONMACRO
   /**
    * Function renames given column in the input DS
    *
    * @param    inDS   the dataset to change
    * @param    currentName    current column name
    * @param    name to replace current with
    *
    * @return   DataSet with renamed column
    * 
    */
  
    LOCAL outRec := RECORD
      RECORDOF(inDS) AND NOT [currentName];
      TYPEOF(inDS.currentName) newName;
    END;
    
    LOCAL outDS := PROJECT(inDS, 
              TRANSFORM(outRec, 
                        SELF.newName := LEFT.currentName;
                        SELF := LEFT));
    RETURN outDS;
  ENDMACRO;



   EXPORT SELECT(inDS, keepCols) := FUNCTIONMACRO
   /**
    * Function takes a dataset and a string containing a list columns to  
    * keep. This should take the form of 'col1, col2, col3......'
    *
    * @param    inDS   the dataset to change
    * @param    keepCols   the columns to keep
    *  
    * @return   DataSet with all other columns dropped
    *  
    */     
						//This line is a bodge, yes. What it does is prevent an error when you select all columns in a DS
						//Can happen, especially if you use this for function calls
						LOCAL tempDS := tt.append(inDS, INTEGER1, THISISATEMPORARYFIELDADDEDBYROBMANSFIELDON20180301, 1);
			
					 LOCAL dropCols := {RECORDOF(tempDS) AND NOT [#EXPAND(keepCols)]};
      LOCAL outRec   := {RECORDOF(tempDS) AND NOT dropCols};
      LOCAL outDS    := PROJECT(inDS, TRANSFORM(outRec, SELF := LEFT));
    
						RETURN outDS;
  ENDMACRO;
  
	
  EXPORT SELECT_ASIS(inDS, keepCol) := FUNCTIONMACRO
  /**
   * Function takes a dataset and a the name of a column to keep
   *
   * @param inDS    the dataset to change
   * @param keepCol the column to keep
   * 
   * @return    DataSet with all but one column dropped
   * 
   */
	
    //This line is a bodge, yes. What it does is prevent an error when you select all columns in a DS
    //Can happen, especially if you use this for function calls
      LOCAL tempDS := tt.append(inDS, INTEGER1, THISISATEMPORARYFIELDADDEDBYROBMANSFIELDON20180301, 1);
      LOCAL dropCols := {RECORDOF(inDS) AND NOT [keepCol]};
      LOCAL outRec   := {RECORDOF(inDS) AND NOT dropCols};
      LOCAL outDS    := PROJECT(inDS, TRANSFORM(outRec, SELF := LEFT));
    RETURN outDS;
  ENDMACRO;


  EXPORT MUTATE(inDS, mutateColIn, comm) := FUNCTIONMACRO
  /**
   * Function performs a transformation command on the given DS. 
   * column definition must already exist in the source DS, if you 
   * want to create a new column use append. Note that you may supply
   * a transform without SELF or LEFT. It will be parsed with 
   * DeSelfer function. 
   *
   * @param inDS    the dataset to change
   * @param mutateColIn column to mutate
   * @param comm    transform command
   *
   * @return    DataSet with updated column
   *  
   */
  
    LOCAL mutateCol := 'SELF.' + REGEXREPLACE('^SELF\\s*\\.',  TRIM(#TEXT(mutateColIn), ALL), '', NOCASE);
    
    LOCAL outDS := PROJECT(inDS, 
              TRANSFORM(RECORDOF(LEFT), 
                        #EXPAND(mutateCol) := #EXPAND(tt.deSelfer(inDS, comm)); 
                        SELF := LEFT));
    RETURN outDS;
   ENDMACRO;
    
		
  EXPORT MUTATE_OLD(inDS, comm) := FUNCTIONMACRO
   /**
    * DEPRECATION WARNING
    *
    * Function performs a transformation command on the given DS. 
    * SELF definition must already exist in the source DS, if you 
    * want to create a new column use append. Unlike the new form
	* (above) this version requires the full SELF.x := LEFT.y 
	* transform. Kept for backwards compatability
    *
    * @param    inDs    the dataset to change
    * @param    comm    transform command
    *
    * @return   DataSet with updated column
    *
    */
    LOCAL outDS := PROJECT(inDS, 
              TRANSFORM(RECORDOF(LEFT), 
                        comm, 
                        SELF := LEFT));
    RETURN outDS;
   ENDMACRO;
   
   EXPORT APPEND(inDS, colType, colName, comm) := FUNCTIONMACRO
   /**
    * Function creates a new column in the inserted DS, dictated by 
    * colType and colName. The transform for the new column is dictated
    * by the comm command. Only one column can be added at a time. Note
    * that you do not need to specify SELF or LEFT, these are added at 
    * runtime using DeSelfer function.
    * 
    * @param    inDS   the dataset to change
    * @param    colType    the type of the column to add
    * @param    colName    the name of the column to add
    * @param    comm   transform command
    *
    * @return   DataSet with updated column
    * 
    */
    LOCAL outDS := PROJECT(inDS, 
                TRANSFORM({RECORDOF(LEFT), colType colName}, 
                          SELF.colName := #EXPAND(tt.deSelfer(inDS, comm));
                          SELF := LEFT));
    RETURN outDS;
   ENDMACRO;
  
  
  EXPORT APPEND_OLD(inDS, colType, colName, comm) := FUNCTIONMACRO
  /**
   * DEPRECATION WARNING
   *
   * Function creates a new column in the inserted DS, dictated by 
   * colType and colName. The transform for the new column is dictated
   * by the comm command. Only one column can be added at a time.
   *   
   * @param inDs    the dataset to change
   * @param colType the type of the column to add
   * @param colName the name of the column to add
   * @param comm    transform command
   *
   * @return    DataSet with added column
   * 
   */
    LOCAL outDS := PROJECT(inDS, 
                TRANSFORM({RECORDOF(LEFT), colType colName}, 
                          SELF.colName := comm;
                          SELF := LEFT));
    RETURN outDS;
  ENDMACRO;


  EXPORT FILTERSET(inDS, aCol, filterSetIn, isin = TRUE) := FUNCTIONMACRO
  /**
   * Function filters a dataset, similarly to the IN command but 
   * without the extra overhead that it entails (basically does a 
   * join under the bonnet). Takes a dataset and a column to filter
   * on, followed by a set to filter on (which is transformed to a 
   * table at readin). The isin command (defaulted to true) will 
   * determine if you are filtering for x IN y (true) or x NOT IN y 
   * (false).
   *
   * Note that using two datasets and tt.filter() is faster and 
   * preferred in most cases. 
   *
   * @param inDS    the dataset to change
   * @param aCol    the column in inDS to filter on
   * @param filterSetIn a set to filter upon
   * @param isin    do you want the filterset to be in the column (true) or not (false)
   *
   * @return    Filtered Dataset
   * 
   */
      
      LOCAL filterDSfromSet := DATASET(filterSetIn, {STRING match;});
      LOCAL uniqueFilterDS  := DEDUP(SORT(DISTRIBUTE(filterDSfromSet, HASH(match)), match, LOCAL), match, LOCAL);
      LOCAL filteredDS := IF(isin,
                        JOIN(inDS, uniqueFilterDS, LEFT.aCol = RIGHT.match, TRANSFORM(RECORDOF(LEFT), SELF := LEFT), INNER),
                        JOIN(inDS, uniqueFilterDS, LEFT.aCol = RIGHT.match, TRANSFORM(RECORDOF(LEFT), SELF := LEFT), LEFT ONLY));  
                        
      LOCAL outDS := filteredDS;
    RETURN outDS;
  ENDMACRO;
  
  
  EXPORT FILTER(inDS, filterDS, inCol, filterCol, isin = TRUE) := FUNCTIONMACRO
  /**
   * Function filters a dataset based on the contents of another. 
   * Takes a dataset and a dataset to filter on, followed by a 
   * the relevant column names. The isin command (defaulted to true) will 
   * determine if you are filtering for x IN y (true) or x NOT IN y 
   * (false).
   *
   * Note that the input is deduped before filtering, no need to do this
   * yourself. 
   *
   * @param inDS    the dataset to change
   * @param filterDS    the DS to filter by
   * @param inCol   the column in the original dataset
   * @param filterCol   the column in the dataset to filter by
   * @param isin    do you want the filter to be in the column (true) or not (false)
   *
   * @return    Filtered Dataset
   */

      LOCAL FilterColDS := TABLE(filterDS, {TYPEOF(filterDS.filterCol) filterCol := filterDS.filterCol});
      LOCAL uniqueDS    := DEDUP(SORT(DISTRIBUTE(FilterColDS, HASH(filterCol)), filterCol, LOCAL), filterCol, LOCAL);
      LOCAL filteredDS  := IF(isin,
      JOIN(inDS, uniqueDS, LEFT.inCol = RIGHT.filterCol, TRANSFORM(RECORDOF(LEFT), SELF := LEFT), INNER, SMART),
      JOIN(inDS, uniqueDS, LEFT.inCol = RIGHT.filterCol, TRANSFORM(RECORDOF(LEFT), SELF := LEFT), LEFT ONLY, SMART));  
      LOCAL outDS := filteredDS;
      RETURN outDS;
  ENDMACRO;  
  
  
  EXPORT DISTINCT_ASIS(inputDataSet, DedupOn, DistributeFlag = TRUE) := FUNCTIONMACRO
  /**
   * Performs a dedup with optional distribution, if only DistributeOn 
   * parameter given then it's sorted and deduped on the same value.
   * Note that this only takes a single column name (although concatenated 
   * columns are allowed(but, careful! I'd add a seperator there!))
   *
   * @param inDS    the dataset to change
   * @param DedupOn column to distribute by (and dedup on if other parameters not given)
   * @param DistributeFlag  if FALSE then don't re-distribute
   *
   * @return    DataSet that has been deduped
   *
   * TODO: allow DedupOn to be '' and dedup on whole dataset. 
   * 
   */ 
    LOCAL distdInDs := IF(DistributeFlag, DISTRIBUTE(inputDataSet, HASH32(DedupOn)), inputDataSet);
    LOCAL sortedDs  := SORT(distdInDs, DedupOn, LOCAL);        
    LOCAL dedDS     := DEDUP(sortedDs, DedupOn, LOCAL);    
    
    RETURN dedDS;
  ENDMACRO;  
  
  EXPORT DISTINCT(inputDataSet, DedupOn, DistributeFlag = TRUE) := FUNCTIONMACRO
  /**
   * Performs a dedup with optional distribution, if only DistributeOn 
   * parameter given then it's sorted and deduped on the same value.
   * Unlike the _ASIS call (above) this version can take a string in 
   * the form of 'col1, col2, col3....' allowing multiple columns to be 
   * used. 
   *
   * @param inDS    the dataset to change
   * @param DedupOn columns to distribute by and dedup on, comma seperated
   * @param DistributeFlag  if FALSE then don't re-distribute
   *
   * @return    DataSet that has been deduped
   *
   * TODO: allow dedup to be '' and distribute on whole dataset. 
   * 
   */ 
    LOCAL distdInDs := IF(DistributeFlag, DISTRIBUTE(inputDataSet, HASH32(#EXPAND(DedupOn))), inputDataSet);
    LOCAL sortedDs  := SORT(distdInDs, #EXPAND(DedupOn), LOCAL);        
    LOCAL dedDS     := DEDUP(sortedDs, #EXPAND(DedupOn), LOCAL);    
    
    RETURN dedDS;
  ENDMACRO;  
  
  
  
  EXPORT ARRANGE_ASIS(inputDataSet, SortOn) := FUNCTIONMACRO
  /**
   * Arranges the input data set by the given column name, takes a single
   * column (not a string, see ARRANGE_TXT for that functionality). 
   *
   * @param inDS    the dataset to change
   * @param SortOn  column to arrange by
   *
   * @return    DataSet that has been sorted
   *
   * TODO: allow sorton to be '' and sort on whole dataset. 
   * 
   */ 
   
    LOCAL sortedDs := SORT(inputDataSet, SortOn);
    // IF(DistributeFlag, 
      // SORT(DISTRIBUTE(inputDataSet, HASH(SortOn)), SortOn, LOCAL), 
      // SORT(inputDataSet, SortOn)
      // );
    
    RETURN sortedDs;
  ENDMACRO;
  
  
  EXPORT ARRANGE(inputDataSet, SortOn) := FUNCTIONMACRO
  /**
  * Arranges the input data set by the given column name, takes a 
  * string of column names in the form of 'col1, col2...' 
  * (See ARRANGE for a single column call without the string). 
  *
  * @param inDS the dataset to change
  * @param SortOn   columns to arrange by, comma seperated
  *
  * @return DataSet that has been sorted
  *
  * TODO: allow sorton to be '' and sort on whole dataset. 
  * 
  */ 
  
    // LOCAL distVar := STD.Str.SplitWords(SortOn,',')[1];
  
    // LOCAL sortedDs := IF(DistributeFlag, 
    // SORT(DISTRIBUTE(inputDataSet, HASH(#EXPAND(SortOn))), #EXPAND(SortOn), LOCAL), 
    // SORT(inputDataSet, #EXPAND(SortOn))
    // );
    sortedDs := SORT(inputDataSet, #EXPAND(SortOn));
    RETURN sortedDs;
  ENDMACRO; 
  
  EXPORT ARRANGEDISTINCT(inDS, DedupOn, SortOn, DistOn, DistributeFlag = TRUE) := FUNCTIONMACRO
  /**
   * Performs a distribute/sort/distinct opeation, with less boiler plate code. 
   *
   * @param inDS    the dataset to dedup
   * @param DedupOn columns to Dedup on, comma seperated
   * @param SortOn  columns to Sort on, comma seperated
   * @param DistOn  columns to Distribute on, comma seperated
   * @param DistributeFlag  if FALSE then don't re-distribute
   *
   * @return    DataSet that has been dedupped. 
   *
   * TODO: allow dedup to be '' and do on whole dataset. 
   */ 
  
    LOCAL distdInDs := IF(DistributeFlag, DISTRIBUTE(inDS, HASH32(#EXPAND(DistOn))), inDS);
    LOCAL sortedDs  := SORT(distdInDs, #EXPAND(SortOn), LOCAL);        
    LOCAL dedDS     := DEDUP(sortedDs, #EXPAND(DedupOn), LOCAL);    
    
    RETURN dedDS;
  ENDMACRO;
  
  
  
  EXPORT DUPLICATED(inDS, colName) := FUNCTIONMACRO
  /**
   * Adds a column to the given DS that flags if it is a duplicate 
   * or not. ALL duplicates are flagged, not just those after the first
   * if you want a dedup then see: DISTINCT. New column is called:
   * duplicated_[columnName].
   *
   * @param inDS    the dataset to change
   * @param colName column to check for dups on
   *
   * @return    DataSet with an extra column: duplicated_[colName]
   *  
   */ 
      LOCAL TempDS1  := tt.rename(inDS, colName, grp);
      LOCAL TempDS   := tt.select_asis(TempDS1, grp);
      LOCAL CountRec := {grp := TempDS.grp; n := COUNT(GROUP)};
      LOCAL counts   := TABLE(TempDS, CountRec, grp, MERGE);
			
	  LOCAL dupColName := 'duplicated_' + #TEXT(colName);

      LOCAL dupedRecs := JOIN(inDS, counts, 
                        LEFT.colName = RIGHT.grp, 
                        TRANSFORM({RECORDOF(LEFT); BOOLEAN #EXPAND(dupColName)},
                                  #EXPAND('SELF.' + dupColName) := RIGHT.n > 1;
                                  SELF := LEFT), 
                        INNER, SMART);    
    
    RETURN dupedRecs;
  ENDMACRO;
      
  
  EXPORT COUNTN(inDS, GroupColumns) := FUNCTIONMACRO
  /**
   * Produce a count based on the given grouping variables. Takes a 
   * string so multiple values can be given
   * 
   * @param inDS    the dataset to count
   * @param GroupColumns    the columns to group on, comma seperated
   * 
   * @return    DataSet of counts based on grouping columns
   */ 

      LOCAL neededDS := tt.select(inDS, GroupColumns);
      LOCAL countRec := {neededDS; INTEGER n := COUNT(GROUP);};      
      LOCAL countTable := TABLE(neededDS, CountRec, #EXPAND(GroupColumns), MERGE);
      
      RETURN countTable;
    
  ENDMACRO;
  
	
  EXPORT TO_CSV(inDS, outName, EXPIRY = 365) := FUNCTIONMACRO
  /**
   * Writes a CSV without having to remember the whole syntax. 
   *
   * @param inDs    the dataset to output
   * @param outName the CSV name, will auto add ~ if omitted
   * @param EXPIRY  expiry of the output, defaults to 365 days. 
   *
   * @return    String indicating write location
   *  
   */ 
  
    outNameCorr := IF(REGEXFIND('~', outName, NOCASE), outName, '~' + outName);
    OUTPUT(inDS, , outNameCorr, OVERWRITE, CSV(HEADING(SINGLE), QUOTE('"')), EXPIRE(EXPIRY), OVERWRITE);

    RETURN 'CSV Writen to: ' + outName;
  ENDMACRO;
  
  
  EXPORT TO_THOR(inDS, outName, EXPIRY = 365) := FUNCTIONMACRO
  /**
   * Writes a thor file without having to remember the whole syntax.
   *
   * @param inDs    the dataset to output
   * @param outName the CSV name, will auto add ~ if omitted
   * @param EXPIRY  expiry of the output, defaults to 365 days. 
   *
   * @return    String indicating write location
   * 
   */ 
  
    outNameCorr := IF(REGEXFIND('~', outName, NOCASE), outName, '~' + outName);
    OUTPUT(inDS, ,outNameCorr, THOR, EXPIRE(EXPIRY), OVERWRITE);

    RETURN 'THOR file Writen to: ' + outName;
  ENDMACRO;
  
  
  EXPORT HEAD(inDS, /* nameIn = '' ,*/ nrows = 100) := FUNCTIONMACRO
  /**
   *  Ouputs a table as a named output with only the top few rows visible.
   *  Do note that multiple calls to the same dataset name will error out your
   *  workunit!
   *
   *  @param inDS   the dataset to output
   *  @param nrows  rows to display, defaults to 100. 
   *
   *  @return   Output of the required length and the name of the dataset
   * 
   */ 
  
    // LOCAL nameOut := IF(nameIn = '', REGEXREPLACE('[^a-z0-9]', #TEXT(inDataSet), '', NOCASE), REGEXREPLACE('[^a-z0-9]', nameIn, '', NOCASE));
    LOCAL nameOut := REGEXREPLACE('[^a-z0-9]', #TEXT(inDS), '', NOCASE);
    
    RETURN OUTPUT(inDS[1..nrows], NAMED(nameOut)); 
    
  ENDMACRO;
  

  EXPORT NROWS(inDS) := FUNCTIONMACRO
  /**
   * Counts the rows in a dataset and produces an output with a sensible 
   * name. This allows you to quickly view counts without having to create
   * a named output box or new DataSet. 
   *
   * Do note that multiple calls to the same dataset name will error out your
   * workunit!
   *
   * @param inDS    the dataset to count
   *
   * @return    Output of the row number and the name COUNT[dataset name]  
   */ 
    IMPORT std;

    LOCAL nameOut := 'COUNT' + std.str.tolowercase(REGEXREPLACE('[^a-z0-9]', #TEXT(inDS), '', NOCASE));
    
    RETURN OUTPUT(COUNT(inDS), NAMED(nameOut)); 
    
  ENDMACRO; 
  
END;




