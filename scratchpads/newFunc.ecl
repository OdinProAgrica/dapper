IMPORT $.^.TransformTools as tt;

//make a basic table
testTable    := DATASET([{155,'aa', 'p'}, {245,'baa', 'p'}, {987,'ca', 'p'}, {987,'ca', 'p'}, {123,'ca', 'p'}], {INTEGER diff, STRING reason; STRING Ps});   
testTable1   := DATASET([{155,'aa', 'p'}, {245,'baa', 'p'}, {987,'ca', 'p'}, {987,'ca', 'p'}, {123,'ca', 'p'}], {INTEGER asd, STRING ghdf; STRING kjug});   
testTable2   := DATASET([{'a'}, {'b'}, {'c'}, {'d'}, {'e'}], {STRING newcol;});   

tt.bindRows(testTable, testTable);
tt.bindRows(testTable, testTable1);
