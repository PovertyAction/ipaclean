*! version 0.0.1 23jan2024
*! Innovations for Poverty Action

cap program drop ipamerge

program define ipamerge
    version 17
    
	syntax anything, 					///
					path(string) 		///
					bases(string) 		///
					[KEEPUSing(string)] ///
					[GENerate(string)] 	///
					[NOLabel] 			///
					[NONOTEs] 			///
					[safely] 			///
					[OUTFile(string)]	///
					[NOGENerate]		///
					[update]			///
					[replace]

	

qui {

**# a


	* check merging type is valid
	di "`0'"
	gettoken mtype : 0
	di "`mtype'" //temp

	* error in the merging type specification
	if("`mtype'" != "1:1" & "`mtype'" != "1:m" & "`mtype'" != "m:1" & "`mtype'" != "m:m") {
		
		di as err "merge `mtype':  invalid merge type"
		di as err "    merge types are 1:1, 1:m, m:1, or m:m"
		ex 198
	}

	* check id varlist is valid
	gettoken righttext : 0, parse(",")
	noi di "`righttext'"  //temp
	local idvarlist : list righttext - mtype
	noi di "`idvarlist'" //temp
	if ("`idvarlist'" != "_n") {
		
		foreach var of local idvarlist {
			
			noi confirm var `var'
		}
	}


	* check and set the wd
	* check that option path and bases are specified
		if missing("`path'") {
			noi disp as err "Missing path where datasets are stored"
			exit 198
		}
		 if missing("`bases'") {
		 	noi disp as err _column(5) "Missing datasets to append"
			exit 198
		 }
	
	* check outfile is used with safely
	if !missing("`outfile'") & missing("`safely'") {
		
		di as error "Syntax error: option outfile cannot be used without the safely option"
		exit 198
	}
	
	* select the defined path
	cd "`path'"
	
	
**# b
	* prepare the report on the master data
	* make current data as master dataset
	tempfile dt_master
	save `dt_master', replace //upgradable
	tempfile orig_dt_master 
	save `orig_dt_master', replace //original

	* list of all variables
	describe, varlist
	local master_varlist `r(varlist)'


	* for each variable: capture the label, type, # obs, # missing, and # unique
	foreach var of local master_varlist {

		* label
		loc m1_`var': var lab `var'

		* type
		local m2_`var': type `var'
		local tm_`var' = regexr(substr("`m2_`var''", 1, 3), ///
											  "byt|int|lon|flo|dou", "num")
				  
		local orig_m2_`var' `m2_`var''
		local orig_tm_`var' `tm_`var'' //origine type
		
		* missing and unique
		count if missing(`var')
		loc m3_1_`var' `r(N)'
		cap tempvar tmv_uniq_index_`i'
		bys `var': gen `tmv_uniq_index_`i'' = _n
		count if !missing(`var') & `tmv_uniq_index_`i'' == 1
		loc m3_2_`var' `r(N)'
		drop `tmv_uniq_index_`i''
		loc m3_`var' "Out of the `=_N', `m3_1_`var'' (`=round(`m3_1_`var'' /`=_N' * 100)'%) are missing, and `m3_2_`var'' (`=round(`m3_2_`var'' /`=_N' * 100)'%) are unique"
	
		* 5 first values and 5 last values;
			local m4_`var' "`=`var'[1]', `=`var'[2]', `=`var'[3]', `=`var'[4]', `=`var'[5]' | `=`var'[_N-4]', `=`var'[_N-3]', `=`var'[_N-2]', `=`var'[_N-1]', `=`var'[_N]'"
	}
	

**# c
	* create a tempfile for each using dataset and pick their variable types
	tokenize `bases'
	
	preserve
	
		forvalues i = 1(1)`: list sizeof bases' {
			
			use ``i'', clear
			
			* check if id varlist is valid
				if ("`idvarlist'" != "_n") {
		
					foreach var of local idvarlist {
			
						cap conf var `var'
						if _rc {

							noi di as err "variable `var' not found in ``i''"
							ex 198
						}
					}
				}

			* prepare keep option
			if !missing("`keep'") keep `keep'

			* upgradable
			tempfile dt_`i'
			save dt_`i', replace
			
			* original
			tempfile orig_dt_`i'
			save orig_dt_`i', replace
			
			* varlist
			describe, varlist
			local using`i'_varlist `r(varlist)'

			* for each var
			foreach var of local using`i'_varlist {
				
				* type in using
				local type: type `var'
				local tu`i'_`var' = regexr(substr("`type'", 1, 3), ///
												"byt|int|lon|flo|dou", "num")
												
				local orig_tu`i'_`var' `tu`i'_`var'' //origine type
												
			}

		}
		
	restore

	
**# d
	* safely prepare all using or master data if needed
	if !missing("`safely'") {
	
		* for each using
		forvalues i = 1(1)`: list sizeof bases' {

		//noi di "____________________________________________safely with using data `i'" //temp
			
			* preserve the master
			preserve
			
				* load using data `i'
				use dt_`i', clear
				
				* varlist
				describe, varlist
				local using`i'_varlist `r(varlist)'

				* for each var
				foreach var of local using`i'_varlist {
					
					* type in using and master
					local type: type `var'
					local tu`i'_`var' = regexr(substr("`type'", 1, 3), ///
											  "byt|int|lon|flo|dou", "num")

					//noi di "`tm_`var'' & `tu`i'_`var'': master & using `i' : nous avons affaire à la variable `var'" //temp

					* solve master's numeric versus using's string mismatch
					if ("`tm_`var''" == "num" & "`tu`i'_`var''" == "str") {
	
						tempvar destring_worked
						destring `var', gen(`destring_worked')
						cap conf variable `destring_worked'
						
						* using's string can be converted to numeric
						if !_rc {
							
							* convert the using's type
							destring `var', replace
							* upgrade the using type and tempfile
							local tu`i'_`var' = "num"
							save dt_`i', replace
							//noi di "num vs str/num: `var' should now be num, and it is indeed: `tu`i'_`var''" //temp
						}
						
						* using's string cannot be converted (part 1/2)
						* convert the master's type instead
						else {

							local tostring_master `tostring_master' `var'
							//noi di "num vs str/str: `tostring_master' will be converted in str in the master" //temp
	
						}
						
						cap drop `destring_worked'
					}

					* solve master's string versus using's numeric mismatch
					if (("`tm_`var''" == "str") & "`tu`i'_`var''" == "num") {
							
						* convert the using's type
						tostring `var', replace
						
						* upgrade the using type and tempfile
						local tu`i'_`var' = "str"
						save dt_`i', replace
						
						//noi di "str vs num/str: `var' should now be str, and it is indeed: `tu`i'_`var''" //temp
					}

				}

			* restore the master data
			restore
		}

		* using's string cannot be converted (part 2/2)
		* so, instead convert the master's type in string
		cap tostring `tostring_master', replace
		save `dt_master', replace //upgrade

		* upgrade the master type
		foreach var of local tostring_master {
			
			local tm_`var' = "str"
		}
		
		//noi di "num vs str/str: these master variables are now converted in str: `tostring_master'" //temp
		
			* update the local //temp
			foreach var of local tostring_master { //temp
	
				local type_master: type `var' //temp
				//noi di "num vs str/str 1/2: `var' should be str in the master and it is: `type_master'" //temp
			}
		
		* also, if var is numeric within any using, convert it in string
		preserve
		
			forvalues  i = 1(1)`: list sizeof bases' {
			
				foreach var of local tostring_master {
				
					//noi di "also, if var is numeric within any using, convert it in string ____________using base `i' var `var'" //temp

					if ("`tu`i'_`var''" == "num") {
					
						use dt_`i', clear
						tostring `var', replace
						
						* upgrade the using type and tempfile
						local tu`i'_`var' = "str"
						save dt_`i', replace
						
						//noi di "num vs str/str 2/2: `var' should now be str, and it is indeed: `tu`i'_`var''" //temp
					}
				}
			}
		
		restore
	}

	
**# f
	* merge each using dataset and make short report

	forvalues  i = 1(1)`: list sizeof bases' {
		
		* mismatching variables
		local allvars_tmistake ""
		
		* for each variable
		foreach var of local using`i'_varlist {
			
			if ("`tm_`var''" != "`tu`i'_`var''" & !missing("`tm_`var''") & !missing("`tu`i'_`var''")) {
				
				local allvars_tmistake `allvars_tmistake' `var'
			}
		}

		
		* tempvar for the append result
		if missing("`generate'") {
			
			if `: list sizeof bases' == 1 local generate _merge
			if `: list sizeof bases' > 1 local generate _merge`i'
		}
		else {
			
			if `: list sizeof bases' == 1 local generate `generate'
			if `: list sizeof bases' > 1 local generate `generate'`i'
		}
		
		* sheet name
		local sheetname `: word `i' of `bases''
		
		* prepare keep option
		if !missing("`keep'") local keep2 "keep(`keep')"

		
		* quick report on the append
		noi di ""
		noi di "Trying to merge `sheetname'.."
		
		* success
		if (missing("`allvars_tmistake'")) {
			
			* run the appends
			noi merge `mtype' `idvarlist' using dt_`i', gen(`generate') ///
									//`nolabel' `nonotes' `keep2'
									
			lab var `generate' "Matching result from merge"
			//noi di "Success"
			
		}
		
		* error
		else {
				
				noi di as error "Numeric/string mistmatch error(s)"
				
				foreach var of local allvars_tmistake {
					
					if "`tu`i'_`var''" == "num" local tu_display "numeric"
					if "`tu`i'_`var''" == "str" local tu_display "string"
					if "`tm_`var''" == "num" local tm_display "numeric"
					if "`tm_`var''" == "str" local tm_display "string"
					noi di as error "`var' is `tm_display' in master but `tu_display' in `sheetname'"
				}
				
				//noi di as error "`allvars_tmistake'" //temp
				exit 198
		}

	}

	* final dataset
	tempfile dt_final
	save `dt_final', replace
	
	
	

	
	
	


**# g
	* make a report
	* prepare the report on all using datasets
	preserve
		if !missing("`outfile'") & !missing("`safely'") {
			
			* for each using datasets: pick below infos
			forvalues  i = 1(1)`=`: list sizeof bases'+1' {
	
				//noi di "______________________________________using dataset: dt_`i'" //temp
			
				* load the dataset on which the report is based
				if (`i' == `: list sizeof bases' + 1) {
	
					* master data
					use `dt_master', clear
					local sheetname "master"
					describe using `dt_master', varlist
					
					* variable list
					local using`i'_varlist `r(varlist)'
				}
				
				else {
				
					* using data
					use dt_`i', clear
					local sheetname `: word `i' of `bases''
				}
	
				* for each using datasets: create a frame
				cap frame drop frm_append_`sheetname'
				#d;
				frames	create	frm_append_`sheetname'
						str32	variable
						strL	label
						strL	typereport
						strL	missinganduniq
						strL	firsandlast
				;
				#d cr	
		
				* for each using datasets: for each variable: pick below infos
				foreach var of local using`i'_varlist {
					
					//noi di "______________________________________var: `var'" //temp
					
					* label
					loc label: var lab `var'
					//noi di "var `var' : and label : `label'" //temp
	
					* original type
					if (`i' == `: list sizeof bases' + 1) ///
					loc orig_tu`i'_`var' `orig_tm_`var''
					
					//noi di "master: `orig_tu`i'_`var'' == `orig_tm_`var''" //temp
					
					loc origtype = regexr("`orig_tu`i'_`var''", ///
												"str", "string")
					loc origtype = regexr("`origtype'", ///
												"num", "numeric")
										
					//noi di "******************************** `orig_tu`i'_`var'' doit etre egale a `origtype' ?" //temp
					
					* new type
					local type: type `var'
					//noi di "`type'" //temp
					
					local newtype = regexr(substr("`type'", 1, 3), ///
												"byt|int|lon|flo|dou", "numeric")
					local newtype = regexr("`newtype'", ///
												"str", "string")
					
					//noi di "******************************** `type' doit etre egale a `newtype' ?" //temp
	
					if ("`origtype'" == "`newtype'") {
						
						loc typereport "`origtype' (not changed)"	
						
						//noi di "`typereport'" //temp
					}
					else {
						
						loc typereport "was `origtype' now `newtype'"
						//noi di "`typereport'" //temp
					}
					
					* missing
					count if missing(`var')
					loc missing_cnt `r(N)'
					//noi di "`missing_cnt'" //temp
	
					* unique
					cap tempvar tmv_uniq_index
					bys `var': gen `tmv_uniq_index' = _n
					count if !missing(`var') & `tmv_uniq_index' == 1
					loc unique_cnt `r(N)'
					//noi di "`unique_cnt'" //temp
	
					* missing and unique
					loc missandunique_cnt "Out of the `=_N', `missing_cnt' (`=round(`missing_cnt' /`=_N' * 100)'%) are missing, and `unique_cnt' (`=round(`unique_cnt' /`=_N' * 100)'%) are unique"
					//noi di "`missandunique_cnt'" //temp
	
					* 5 first values and 5 last values
					local firsandlast_val "`=`var'[1]', `=`var'[2]', `=`var'[3]', `=`var'[4]', `=`var'[5]' | `=`var'[_N-4]', `=`var'[_N-3]', `=`var'[_N-2]', `=`var'[_N-1]', `=`var'[_N]'"
					//noi di "`firsandlast_val'" //temp
	
					* post into the frames
				
						#d;
						frames	post 				///
							frm_append_`sheetname'	///
							("`var'") 				///
							("`label'") 			///
							("`typereport'") 		///
							("`missandunique_cnt'") ///
							("`firsandlast_val'")
						;
						#d cr	
				}
	
				* export the report
				frames frm_append_`sheetname' {
					
					export excel using "`outfile'", first(var) sheet("`sheetname'", replace)
					mata: colwidths("`outfile'", "`sheetname'")
					mata: addlines("`outfile'", "`sheetname'", (1, `=_N' + 1), "medium")
				}
			}
		}
		
	restore
}
end

