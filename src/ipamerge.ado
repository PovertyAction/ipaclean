*! version 1.0.0 01jul2023
*! Innovations for Poverty Action

program define ipamerge

version 17
		
		#d;
		syntax anything(everything) [, 
			OUTFile(string)
			DETails
			USEMASTERtype
			GENerate(name)
			KEEPUsing(namelist)
			NOGENerate
			NOLABel
			update
			replace
			safely
			]
		;
		#d cr
		
		qui {
			
			* declare tempfiles
			tempfile master_data
			
			* save master dataset 
			save "`master_data'", replace
			
			* create frames
			frame create frm_data_info
			
			
			* check that the syntax includes using 
			cap assert regexm("`anything'", "using") 
			if _rc == 9 {
				disp as err "using required"
				ex 198
			}
			
			* get mtype
			gettoken mtype anything: anything
			
			noi disp "`mtype'"
		
			* get varlist 
			loc varlist = substr(`"`anything'"', 1, strpos(`"`anything'"', "using") - 1)
			unab varlist: `varlist'
			
			noi di "`varlist'"
			
			loc anything = substr(`"`anything'"', strpos(`"`anything'"', "using") + 5, .)
	
			* get list of datasets
			loc using_cnt: word count `anything'
			
			forval i = 0/`using_cnt' {
				
				if `i' == 0 {
					frame frm_data_info {
						gen variable 	= ""
						gen label 		= ""
						gen master_type = ""
						gen master_dsg 	= ""
					} 
					
					loc prefix "master"
				}
				else {
					loc using`i': word `i' of `anything'
					
					use "`using`i''", clear
					loc prefix "using`i'"
					
					frame frm_data_info {
						gen using`i'_type = ""
						gen using`i'_dsg  = ""
					} 

				}
				
				ds
				foreach var of varlist `r(varlist)' {
					
					loc vtype = "`:type `var''"
					if regexm("`vtype'", "^str") {
						destring `var', replace
						
						loc v_dsg = "`vtype'" ~= "`:type `var''"
					}
					
					loc vlab = "`:var lab `var''"
					
					frames frm_data_info {
						
						cap assert variable ~= "`var'"
						if !_rc {
							frames frm_data_info {
								set obs `=`c(N)' + 1'
								replace variable = "`var'" 	in `c(N)'
								replace label 	 = "`vlab'" in `c(N)'
							}
						}
						else replace label 	 = "`vlab'" in `c(N)' if missing(label[`c(N)'])
						
						replace `prefix'_type = "`vtype'" if variable == "`var'"
						replace `prefix'_dsg = "`v_dsg'" if variable == "`var'"
								
						loc v_dsg = ""
					}
					
				}
			}
			
			* decide what the final variable type should be using the following rule
				* if var in all datasets are string, keep the final as a string
				* if var is numeric in at least 1 dataset and all other can be converted, 
					* use the highest numeric type 
				* if var is numeric in at least 1 dataset and cannot be converted in at least 1 
					* dataset, the set format to string
					
			frame frm_data_info {
				
				destring *_dsg, replace
				egen str_cnt = rownonmiss(*_dsg)
				egen dsg_cnt = anycount(*_dsg), values(1)
				
				gen final_format = cond(str_cnt == dsg_cnt & str_cnt < (`using_cnt' + 1), ///
										"numeric", "string")
				
				noi list
				
			}
						
		}
		
		

end


