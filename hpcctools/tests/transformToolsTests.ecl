IMPORT $.^.TransformTools as tt;

//make a basic table
testTable    := DATASET([{155,'aa', 'p'}, {245,'baa', 'p'}, {987,'ca', 'p'}, {987,'ca', 'p'}, {123,'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
filterDS     :=  DATASET([{155,'aa'}, {245,'baa'}], {INTEGER crap; STRING filterColumn;});    
filterDS1Col :=  DATASET([{'aa'}, {'baa'}], {STRING filterColumn;});

// TODO: _TXT tests!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


// ASSERT(t.names(filterDS1Col) = 'filterColumn', FAIL); 
ASSERT(tt.deselfer(testTable, reason + std.str.touppercase(reason)) = 'LEFT.reason + std . str . touppercase( LEFT.reason)', FAIL);

//Drop and select tests
DropResult := DATASET([{155, 'p'}, {245, 'p'}, {987, 'p'}, {987, 'p'}, {123,'p'}], {INTEGER diff, STRING Ps});   
ASSERT(tt.drop(testTable, 'reason') = dropResult, FAIL);
ASSERT(tt.select(testTable, 'diff, Ps') = dropResult, FAIL);

//Filter tests
FilterResult1 := DATASET([{155,'aa', 'p'}, {245,'baa', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
FilterResult2 := DATASET([{245,'baa', 'p'}], {INTEGER diff, STRING reason; STRING Ps});  
ASSERT(tt.FilterSet(testTable, reason,  ['aa', 'baa']) = FilterResult1, FAIL);
ASSERT(tt.FilterSet(testTable, reason,  ['aa', 'ca'], FALSE) = FilterResult2, FAIL);

ASSERT(tt.Filter(testTable, filterDS, reason, filterColumn) = FilterResult1, FAIL);
ASSERT(tt.Filter(testTable, filterDS1Col, reason, filterColumn) = FilterResult1, FAIL);
// ASSERT(t.Filter(testTable, filterDS, reason, filterColumn, FALSE) = FilterResult2, FAIL);

//rename tests
renameResult := DATASET([{'aa', 'p', 155}, {'baa', 'p', 245}, {'ca', 'p', 987}, {'ca', 'p', 987}, {'ca', 'p', 123}], {STRING reason; STRING Ps; INTEGER newdiff;});   
ASSERT(tt.names(tt.rename(testTable, diff, newDiff)) = tt.names(renameResult), FAIL);

//duplicated tests
DuplicatedResult := DATASET([{155,'aa', 'p', FALSE}, {245,'baa', 'p', FALSE}, {987,'ca', 'p', TRUE}, {987,'ca', 'p', TRUE}, {123,'ca', 'p', TRUE}], {INTEGER diff, STRING reason; STRING Ps; BOOLEAN duplicated_reason;});   
ASSERT(tt.duplicated(testTable, reason) = DuplicatedResult, FAIL);

//distinct tests
DistinctResult1 := DATASET([{155, 'aa', 'p'}, {245, 'baa', 'p'}, {987, 'ca', 'p'}, {123, 'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
DistinctResult2 := DATASET([{155, 'aa', 'p'}, {245, 'baa', 'p'}, {987, 'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
DistinctResult3 := DATASET([{155, 'aa', 'p'}, {245, 'baa', 'p'}, {123, 'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
// ASSERT(t.distinct(testTable, diff) = DistinctResult1, FAIL);
ASSERT(tt.distinct_asis(testTable, reason) = DistinctResult2, FAIL);
// ASSERT(t.distinct(testTable, diff+reason) = DistinctResult3, FAIL);

//Append tests
AppendResult1 := DATASET([{155,'aa', 'p', 'aaaa'}, {245,'baa', 'p', 'baabaa'}, {987,'ca', 'p', 'caca'}, {987,'ca', 'p', 'caca'}, {123,'ca', 'p', 'caca'}], {INTEGER diff, STRING reason; STRING Ps; STRING x;});   ;
AppendResult2 := DATASET([{155,'aa', 'p', 'zzzz'}, {245,'baa', 'p', 'bzzbzz'}, {987,'ca', 'p', 'czcz'}, {987,'ca', 'p', 'czcz'}, {123,'ca', 'p', 'czcz'}], {INTEGER diff, STRING reason; STRING Ps; STRING x;});   ;

ASSERT(tt.append(testTable, STRING, x, LEFT.reason + LEFT.reason) = AppendResult1, FAIL);
ASSERT(tt.append(testTable, STRING, x, reason + reason) = AppendResult1, FAIL);
ASSERT(tt.append(testTable, STRING, x, REGEXREPLACE('a', LEFT.reason + LEFT.reason, 'z')) = AppendResult2, FAIL);
ASSERT(tt.append(testTable, STRING, x, REGEXREPLACE('a', reason + reason, 'z')) = AppendResult2, FAIL);

//mutate Tests
mutateResult1 := DATASET([{1,'aa', 'p'}, {1,'baa', 'p'}, {1,'ca', 'p'}, {1,'ca', 'p'}, {1,'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   ;
mutateResult2 := DATASET([{156,'aa', 'p'}, {246,'baa', 'p'}, {988,'ca', 'p'}, {988,'ca', 'p'}, {124,'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
mutateResult3 := DATASET([{155,'zz', 'p'}, {245,'bzz', 'p'}, {987,'cz', 'p'}, {987,'cz', 'p'}, {123,'cz', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   

ASSERT(tt.mutate(testTable, diff, 1) = mutateResult1, FAIL);
ASSERT(tt.mutate(testTable, diff, LEFT.diff + 1) = mutateResult2, FAIL);
ASSERT(tt.mutate(testTable, reason, REGEXREPLACE('a', LEFT.reason, 'z')) = mutateResult3, FAIL);
ASSERT(tt.mutate(testTable, reason, REGEXREPLACE('a', reason, 'z')) = mutateResult3, FAIL);
ASSERT(tt.mutate(testTable, reason, REGEXREPLACE('a', reason, 'z')) = mutateResult3, FAIL);
ASSERT(tt.mutate(testTable, SELF.reason, REGEXREPLACE('a', LEFT.reason, 'z')) = mutateResult3, FAIL);

//arrane tests
arrangeResult := DATASET([{123,'ca', 'p'}, {155,'aa', 'p'}, {245,'baa', 'p'}, {987,'ca', 'p'}, {987,'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps;});   
ASSERT(tt.arrange_asis(testTable, diff) = arrangeResult, FAIL);

// CountN tests
coutnResult := DATASET([{'aa', 1}, {'baa', 1}, {'ca', 3}], {STRING reason; INTEGER n;}); 
tt.arrange_asis(tt.CountN(testTable, 'reason'), reason);
tt.arrange_asis(tt.CountN(testTable, 'reason, ps'), reason);
coutnResult;
// ASSERT(t.arrange(t.CountN(testTable, 'reason'), reason) = coutnResult, FAIL);
  
tt.head(testTable);
tt.head(filterDS, 2);
tt.to_csv(testTable, '~ROB::TEMP::ACSV');


/* IMPORT DataScience.Operations_Flat_Full as off;
   
   ops := off.opproduct;
   
   t.arrange(t.CountN(ops, 'cropzoneentityuid'), n);
   t.arrange(TABLE(ops, {STRING cropzone := ops.cropzoneentityuid; INTEGER n := COUNT(GROUP);}, cropzoneentityuid), n);
   t.arrange(TABLE(ops, {STRING cropzone := ops.cropzoneentityuid; INTEGER n := COUNT(GROUP);}, cropzoneentityuid, MERGE), n);
*/







