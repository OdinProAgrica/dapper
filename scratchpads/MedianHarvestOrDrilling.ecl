//THIS SCRIPT IS USED TO REGENERATE THE AVERAGES USED IN THE PAST GS MODEL. IT GIVES THE MEDIAN DIFFERENCE BETWEEN THE 
//1ST OF JAN OF CROPYEAR AND EITHER HARVEST DAY OR DRILLING DAY. IT IS QUITE A BLUNT TOOL BUT DOES THE JOB, PREFERABLE WOULD 
//BE A SAMPLE OF A DISTRIBUTION THAT MATCHED THE DATE DISTRIBUTION. 
#OPTION('outputlimit', 100);

IMPORT Constants.InternalOutputConstants; 
IMPORT SourceSystem;
IMPORT OutputEntities.BaseOutputEntity;
IMPORT datascience.Operations_Flat_Full;
IMPORT datascience.tools.median;
IMPORT std;

outFileName := BaseOutputEntity.BuildFileName(InternalOutputConstants.DataScienceFileNamePrefix) + 'HarvestAndDrillingDifferences';

////Find average drilling difference
CZdaysDiff := PROJECT(Operations_Flat_Full.CropZoneDrills(FirstDrillingDate != ''),  
                      TRANSFORM({STRING plannedcropname;
                                 STRING plannedcropUID; 
                                 INTEGER cropyear; 
                                 STRING CropYearStart; 
                                 INTEGER daysAfterCropYear; 
                                 STRING FirstDrillingDate; 
                                 // STRING CropAndYear;
                                  },
                                SELF.plannedcropname    := LEFT.plannedcropname;
                                SELF.plannedcropUID     := LEFT.plannedcropUID;
                                SELF.cropyear           := (INTEGER)LEFT.cropyear;
                                SELF.CropYearStart      := (STRING) LEFT.cropyear + '0101';
                                SELF.FirstDrillingDate  := LEFT.FirstDrillingDate;
                                SELF.daysAfterCropYear := STD.Date.DaysBetween((INTEGER) SELF.CropYearStart, (INTEGER) LEFT.FirstDrillingDate);
                                // SELF.CropAndYear        := SELF.plannedcropname + ';-;-' + (STRING) SELF.cropyear;
                                ),
                       LOCAL);                    
                    
medianDrilingDiffDS := PROJECT(CZdaysDiff, TRANSFORM(median.inrec, 
                                          SELF.Group_Val := LEFT.plannedcropUID; 
                                          SELF.num_Val   := (DECIMAL32_15) LEFT.daysAfterCropYear;
                                          )
                    );

// OUTPUT(medianDrilingDiffDS, NAMED('medianDrilingDiffDS'));   
medianDrillingDiff := median.median(medianDrilingDiffDS);


////Find average harvest difference
CZdaysDiffHarvest := PROJECT(Operations_Flat_Full.CropZoneYields(FirstHarvestDate != ''),  
                      TRANSFORM({STRING plannedcropname;
                                 STRING plannedcropUID; 
                                 INTEGER cropyear; 
                                 STRING CropYearStart; 
                                 INTEGER daysAfterCropYear; 
                                 STRING FirstHarvestDate; 
                                  },
                                SELF.plannedcropname    := LEFT.plannedcropname;
                                SELF.plannedcropUID     := LEFT.plannedcropUID;
                                SELF.cropyear           := (INTEGER)LEFT.cropyear;
                                SELF.CropYearStart      := (STRING) LEFT.cropyear + '0101';
                                SELF.FirstHarvestDate   := LEFT.FirstHarvestDate;
                                SELF.daysAfterCropYear  := (INTEGER) STD.Date.DaysBetween((INTEGER) SELF.CropYearStart, (INTEGER) LEFT.FirstHarvestDate);
                                )
                       , LOCAL);                    
                    
medianDiffHarvestDS := PROJECT(CZdaysDiffHarvest, TRANSFORM(median.inrec, 
                                          SELF.Group_Val := LEFT.plannedcropUID; 
                                          SELF.num_Val   := (DECIMAL32_15) LEFT.daysAfterCropYear;)
                    );
// OUTPUT(medianDiffHarvestDS, NAMED('medianDiffHarvestDS'));   
medianHarvestDiff := median.median(medianDiffHarvestDS);
// OUTPUT(medianHarvestDiff, NAMED('medianHarvestDiff'));   


differences := JOIN(medianHarvestDiff, medianDrillingDiff
                     , LEFT.Group_Val = RIGHT.Group_Val,
                     TRANSFORM({STRING CropEntityUID;
                                DECIMAL32_15 HarvestDiff;
                                DECIMAL32_15 DrillingDiff;
                                },
                                SELF.CropEntityUID := LEFT.Group_Val;
                                SELF.HarvestDiff   := LEFT.median;
                                SELF.DrillingDiff  := RIGHT.median;
                                )
                      , SMART);
                      
 EXPORT MedianHarvestOrDrilling := JOIN(differences, operations_flat_full.cropEntity
                     , LEFT.CropEntityUID = RIGHT.CropEntityUID,
                     TRANSFORM({RECORDOF(LEFT);
                                STRING CropName;
                                },
                                SELF.CropName := RIGHT.name;
                                SELF          := LEFT;
                                )
                      , SMART);               
                      
;
// OUTPUT(MedianHarvestOrDrilling, NAMED('differences'));                 
// OUTPUT(MedianHarvestOrDrilling, , outFileName, OVERWRITE, EXPIRE(30));

// EXPORT MedianHarvestOrDrilling := MedianHarvestOrDrillingFile;