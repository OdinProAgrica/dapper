	EXPORT bindCol(inDS, bindDS, index_col_l, index_col_r='') := FUNCTIONMACRO
		//THIS NEEDS SOME SERIOUS TESTING!
				
				LOCAL OutRec := RECORD
					 RECORDOF(inDS);
					 RECORDOF(bindDS) AND NOT RECORDOF(inDS);
				END;
				
				LOCAL RIGHT_JOIN := IF(index_col_r = '', index_col_l, index_col_r);
				
				//#WARNING( message ); Need to warn if names are shared as this will cause override (excepting the join columns). 
				
				LOCAL boundDS := JOIN(inDS, bindDS, 
									LEFT.index_col_l = RIGHT.RIGHT_JOIN, 
									TRANSFORM(OutRec, SELF := LEFT; SELF := RIGHT;),
									FULL OUTER, SMART);

				//Theoretically, this could be used for an indexless concat. Probably too vulnerable to screw ups though. 
				// LOCAL Outrec DoColBind(inDS L, INTEGER C) := TRANSFORM
					// R := bindDS[C];
					// SELF := L;
					// SELF := R;
				// END;

				// LOCAL boundDS := PROJECT(inDS, DoColBind(LEFT, COUNTER));	
				
				return(boundDS);
	ENDMACRO;
