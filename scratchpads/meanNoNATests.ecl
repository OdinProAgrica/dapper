import datascience.Tools;

tools.meanNoNA(DATASET(['1','2','3','4','','5'],
                 {STRING InputData}));
                 
tools.meanNoNA(DATASET(['1','2','3','4'],
                 {STRING InputData}));
                 
tools.meanNoNA(DATASET(['1','2','3','4',''],
                 {STRING InputData}));
                 
tools.meanNoNA(DATASET(['1','2','3','4','','a'],
                 {STRING InputData}));                 
