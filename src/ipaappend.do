/*
--------------------------------------------------------------------------------
Title		: 04_ipaappend
Date		: 10oct2023
Last Updated: 10oct2023
Purporse	: Contains user written commands helpful for data cleanining
Ado(s)		: 
Authors		: David Torres
			  dtorres@poverty-action.org
--------------------------------------------------------------------------------
*/


*! version 1.0.0 01jul2023
*! Innovations for Poverty Action

cap program drop ipaappend

program define ipaappend
    version 17
    syntax, path(string) bases(string) [keep(string)] [GENerate(string)] [NOLabel] [NONOTEs] [safely] [OUTFile(string)]

qui {

**# a
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
						}
						
						* using's string cannot be converted (part 1/2)
						* convert the master's type instead
						else {

							local tostring_master `tostring_master' `var'
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
		
			* update the local //temp
			foreach var of local tostring_master { //temp
	
				local type_master: type `var' //temp
			}
		
		* also, if var is numeric within any using, convert it in string
		preserve
		
			forvalues  i = 1(1)`: list sizeof bases' {
			
				foreach var of local tostring_master {

					if ("`tu`i'_`var''" == "num") {
					
						use dt_`i', clear
						tostring `var', replace
						
						* upgrade the using type and tempfile
						local tu`i'_`var' = "str"
						save dt_`i', replace
					}
				}
			}
		
		restore
	}

	
**# f
	* append each using dataset and make short report

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
		if missing("`generate'") tempvar temp_genvar`i'
		else local generate `generate'`i'

		* sheet name	
		local sheetname `: word `i' of `bases''
		
		* prepare keep option
		if !missing("`keep'") local keep2 "keep(`keep')"

		* run the appends
		cap append using dt_`i', gen(`generate'`temp_genvar`i'') ///
									`nolabel' `nonotes' `keep2'
		
		* quick report on the append
		cap confirm var `generate'`temp_genvar`i''
		
		noi di ""
		noi di "Trying to apennd `sheetname'.."
		
			* display the success details
			if !_rc {
				
				noi di "Success"
			}
			
			* display the error details
			else {
				
				noi di as error "Numeric/string mistmatch error(s)"
				
				foreach var of local allvars_tmistake {
					
					if "`tu`i'_`var''" == "num" local tu_display "numeric"
					if "`tu`i'_`var''" == "str" local tu_display "string"
					if "`tm_`var''" == "num" local tm_display "numeric"
					if "`tm_`var''" == "str" local tm_display "string"
					noi di as error "`var' is `tm_display' in master but `tu_display' in `sheetname'"
				}

				exit 198
			}
			
			cap drop `temp_genvar`i''
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
					
					* label
					loc label: var lab `var'

					* original type
					if (`i' == `: list sizeof bases' + 1) ///
					loc orig_tu`i'_`var' `orig_tm_`var''

					loc origtype = regexr("`orig_tu`i'_`var''", ///
												"str", "string")
					loc origtype = regexr("`origtype'", ///
												"num", "numeric")

					* new type
					local type: type `var'
					local newtype = regexr(substr("`type'", 1, 3), ///
											"byt|int|lon|flo|dou", "numeric")
					local newtype = regexr("`newtype'", ///
											"str", "string")

					if ("`origtype'" == "`newtype'") {
						
						loc typereport "`origtype' (not changed)"	
					}
					else {
						
						loc typereport "was `origtype' now `newtype'"
					}
					
					* missing
					count if missing(`var')
					loc missing_cnt `r(N)'
	
					* unique
					cap tempvar tmv_uniq_index
					bys `var': gen `tmv_uniq_index' = _n
					count if !missing(`var') & `tmv_uniq_index' == 1
					loc unique_cnt `r(N)'

					* missing and unique
					loc missandunique_cnt "Out of the `=_N', `missing_cnt' (`=round(`missing_cnt' /`=_N' * 100)'%) are missing, and `unique_cnt' (`=round(`unique_cnt' /`=_N' * 100)'%) are unique"

					* 5 first values and 5 last values
					local firsandlast_val "`=`var'[1]', `=`var'[2]', `=`var'[3]', `=`var'[4]', `=`var'[5]' | `=`var'[_N-4]', `=`var'[_N-3]', `=`var'[_N-2]', `=`var'[_N-1]', `=`var'[_N]'"

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

