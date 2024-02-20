*! version 1.0.0 01jul2023
*! Innovations for Poverty Action

cap program drop ipamerge //temp to be deleted

program define ipamerge

version 17
		
		#d;
		syntax anything(everything) [, 
			OUTFile(string)
			DETails
			FORMATinput(string)
			GENerate(name)
			KEEPUsing(namelist)
			NOGENerate
			NOLabel
			NONOTEs
			update
			replace
			safely
			report
			]
		;
		#d cr
		
		qui {
			
			* declare tempfiles
			tempfile master_tempdata
			save `master_tempdata', replace
			
			* create frames
			cap frame drop frm_data_info
			frame create frm_data_info

			* check using 
			cap assert regexm("`anything'", "using ")
			if _rc == 9 { 
				di as err "using required"
				ex 198
			}
			
			* check the merging type
			gettoken mtype anything: anything
			cap assert regexm("`mtype'", "^(1|m):(?:1|m)$")
			if _rc == 9 {
				di as err "ipamerge `mtype' is an invalid merge type"
				di as err "    merge types are 1:1, 1:m, m:1, or m:m"
				ex 198
			}
			
			* check varlist
			loc varlist = substr(`"`anything'"', 1, strpos(`"`anything'"', "using") - 1)
			unab varlist: `varlist'
			
			* check safely and report
			if !missing("`report'") & !missing("`safely'") {
				di as err "report and safely cannot be combined together "
				ex 198
			}
			
			* check outfile and report and safely
			if !missing("`outfile'") & missing("`report'`safely'") {
				di as err "outfile cannot be used without report or safely"
				ex 198
			}
			* check detail and outfile
			if !missing("`details'") & missing("`outfile'") {
				di as err "details cannot be used without outfile"
				ex 198
			}
			* check generate and nogenerate
			if !missing("`generate'") & !missing("`nogenerate'") {
				di as err "syntax error: cannot apply both generate() and nogenrate options together"
				ex 198
			}
			* get list of datasets
			loc anything = substr(`"`anything'"', strpos(`"`anything'"', "using") + 5, .)
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
					tempfile `prefix'_tempdata
					if !missing("`keepusing'") keep `varlist' `keepusing' //keep using
					save ``prefix'_tempdata', replace

					frame frm_data_info {
						gen using`i'_type = ""
						gen using`i'_dsg  = ""
						gen using`i'_tmatch = .
						if !missing("`details'") {
							gen using`i'_nb_missing = .
							gen using`i'_percent_missing = .
							gen using`i'_nb_unique = .
							gen using`i'_percent_unique = .
							gen using`i'_head = ""
							gen using`i'_tail = ""
						}
					}
				}
				
				ds
				foreach var of varlist `r(varlist)' {
					
					* type and label
					if `i' == 0 loc master_vtype = "`:type `var''"
					loc vtype = "`:type `var''"
					if regexm("`vtype'", "^str") {
						destring `var', replace
						loc v_dsg = "`vtype'" ~= "`:type `var''"
					}
					loc vlab = "`:var lab `var''"
					
					* missing
					count if missing(`var')
					loc cnt_missing `r(N)'
					loc perc_missing `cnt_missing' /`=_N'
					list if _n < 6
					
					* head and tail
					loc head "`=`var'[1]', `=`var'[2]', `=`var'[3]', `=`var'[4]', `=`var'[5]'"
					loc tail "`=`var'[_N-4]', `=`var'[_N-3]', `=`var'[_N-2]', `=`var'[_N-1]', `=`var'[_N]'"
					
					* unique
					cap tempvar tmv_uniq_index restore_sort
					gen `restore_sort' = _n
					bys `var': gen `tmv_uniq_index' = _n
					sort `restore_sort' //restore sorting
					count if !missing(`var') & `tmv_uniq_index' == 1
					loc cnt_unique `r(N)'
					loc perc_unique `cnt_unique' /`=_N'
					
					frames frm_data_info {
						cap assert variable ~= "`var'"
						if !_rc {
							frames frm_data_info {
								
								set obs `=`c(N)' + 1'
								replace variable = "`var'" 	in `c(N)'
								replace label 	 = "`vlab'" in `c(N)'
							}
						}
						replace `prefix'_type = "`vtype'" if variable == "`var'"
						replace `prefix'_dsg = "`v_dsg'" if variable == "`var'"
						loc v_dsg = ""
						
						* check if the type match between master and each using
						if `i' > 0 {
							
							replace `prefix'_tmatch = (regexm(`prefix'_type, "^str") == regexm(master_type, "^str")) ///
													if variable == "`var'" & !missing(master_type)
													
							if !missing("`details'") {
								replace `prefix'_nb_missing = `cnt_missing' if variable == "`var'"
								replace `prefix'_percent_missing = `perc_missing' if variable == "`var'"
								replace `prefix'_nb_unique = `cnt_unique' if variable == "`var'"
								replace `prefix'_percent_unique = `perc_unique' if variable == "`var'"
								replace `prefix'_head = "`head'" if variable == "`var'"
								replace `prefix'_tail = "`tail'" if variable == "`var'"						
								if `i' > 1 order using`i'_type, after(using`=`i'-1'_tail)
							}
						}
					}
				}
				
				* decide if using is mergeable without safely
				if `i' > 0 {
					frame frm_data_info {
						count if using`i'_tmatch == 0
						loc using`i'_ready = (`r(N)' == 0)
						* get all variables that cannot be merged
						if `i' > 0 ///
						levelsof variable if `prefix'_tmatch == 0, loc(using`i'_allvarstm) clean
					}
				}
			}

			* report and outfile
			if !missing("`report'") {
				* foreach using
				forval i = 1/`using_cnt' {

					* report	
					frame frm_data_info {			
						noi di in white "" //temp improve
						noi di in white "Reporting on `using`i''"
						if !missing("`using`i'_allvarstm'") {
							noi di as err "numeric/string mistmatch error(s) with `: word count `using`i'_allvarstm'' variables"
							foreach var of local using`i'_allvarstm {
								levelsof master_type if variable == "`var'", loc(master_tm) clean
								levelsof using`i'_type if variable == "`var'", loc(using_tm) clean
								noi di as err "`var' is `master_tm' in master but `using_tm' in `using`i''"
							}
						}
						else {
							noi di in white "no numeric/string mistmatch error is found"
						}
					}
					
					* outfile
					if !missing("`outfile'") {
						frame frm_data_info {
							gen using`i'_report = ""
							foreach var of local using`i'_allvarstm {
								levelsof master_type if variable == "`var'", loc(master_tm) clean
								levelsof using`i'_type if variable == "`var'", loc(using_tm) clean
								replace using`i'_report = "`using_tm' but `master_tm' in master" ///
								if variable == "`var'"
								order using`i'_report, after(using`i'_type)
							}
							replace using`i'_report = "ok" ///
							if master_type == using`i'_type & !missing(using`i'_type)
							replace using`i'_report = "missing in master" ///
							if missing(master_type) & !missing(using`i'_type)
						}
					}
				}

				* export if outfile
				if !missing("`outfile'") {
					
					frame frm_data_info {
						
						noi di in white "" //temp to be improved
						noi di in white "Exporting the report"
						if !missing("`details'") keep variable label *_type *_report *_missing *_unique *_head *_tail
						else keep variable label *_type *_report
						
						export excel using "`outfile'", replace firstrow(variable) sheet("report_output")
						noi di in white "Successfully exported in `outfile'.xlsx"
						
						mata: colwidths("`outfile'", "report_output")
						mata: addlines("`outfile'", "report_output", (1, `=_N' + 1), "medium")
						putexcel set "`outfile'.xlsx", modify sheet("report_output")
						putexcel (A1:A`=`=_N'+1'), border("left", "medium", "black")
						putexcel (B1:B`=`=_N'+1'), border("right", "medium", "black")
						putexcel (C1:C`=`=_N'+1'), border("right", "medium", "black")
						
						forval i = 1/`using_cnt' {
							if !missing("`details'") {
								mata: colformats("`outfile'", "report_output", ("using`i'_percent_missing", "using`i'_percent_unique"), "percent_d2")
								mata : st_local("column_letter", numtobase26(`=3+(8*`i')'))
								putexcel (`column_letter'1:`column_letter'`=`=_N'+1'), border("right", "medium", "black")
							}
							else {
								mata : st_local("column_letter", numtobase26(`=3+(2*`i')'))
								putexcel (`column_letter'1:`column_letter'`=`=_N'+1'), border("right", "medium", "black")
							}
						}
					}
				}
				noi di in white "" //temp to be improved
				exit 198
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
				gen final_type = cond(str_cnt == dsg_cnt & str_cnt < (`using_cnt' + 1), ///
											"numeric", "string")
			}
		
			* safely
			if !missing("`safely'") {
	
				forvalues  i = 0/`using_cnt' {
					
					* do the changes
					if `i' == 0 {
						use `master_tempdata', clear
						loc prefix "master"
					}
					else {
						local prefix "using`i'"
						use ``prefix'_tempdata', clear
					}
					ds
					foreach var of varlist `r(varlist)' {
						frame frm_data_info {
							levelsof `prefix'_type if variable == "`var'", loc(p_type) clean
							levelsof final_type if variable == "`var'", loc(f_type) clean
						}
						
						* tostring
						if regexm("`f_type'", "^str") == 1 & regexm("`p_type'", "^str") == 0 {
							loc fvar: format `var'
							tostring `var', replace format("`fvar'")
						}
						
						* destring
						if regexm("`f_type'", "^str") == 0 & regexm("`p_type'", "^str") == 1 {				
							destring `var', replace
						}
					}
					save ``prefix'_tempdata', replace
					loc using`i'_ready = 1		
				}
			}

		* run merge
		use `master_tempdata', clear //master
		
		forval i = 1/`using_cnt' {
			noi di ""
			noi di "Trying to merge `using`i''.."
			
			* no, cannot be merged
			if "`using`i'_ready'" ~= "1" {
				
				* error and details
				noi di as error "Numeric/string mistmatch error(s)"
				frame frm_data_info {
					foreach var of local using`i'_allvarstm {
						levelsof master_type if variable == "`var'", loc(master_tm) clean
						levelsof using`i'_type if variable == "`var'", loc(using_tm) clean
						noi di as error "`var' is `master_tm' in master but `using_tm' in `using`i''"
						exit 198
					}
				}
			}
			
			* yes, can be merged
			else {
				
				* prepare generate
				if missing("`nogenerate'") {
					if missing("`generate'") {
						if `using_cnt' == 1 local generate2 "gen(_merge)"
						if `using_cnt' > 1 local generate2 "gen(_merge`i')"
					}
					else {
						if `using_cnt' == 1 local generate2 "gen(`generate')"
						if `using_cnt' > 1 local generate2 "gen(`generate'`i')"
					}
				}
				
				* run merge
				noi merge `mtype' `varlist' using `using`i'_tempdata', ///
					`generate2' `nogenerate' `nolabel' `nonotes'  `update' `replace'
			}
		}
		
		* outfile and safely
		if !missing("`safely'") & !missing("`outfile'") {
			
			frame frm_data_info {
				
				noi di in white ""
				noi di in white "Exporting safely option's outcomes"
				order variable label master_type final_type
				if !missing("`details'") keep variable label master_type final_type using*_type *_missing *_unique *_head *_tail
				else keep variable label master_type final_type using*_type
				
				export excel using "`outfile'", replace firstrow(variable) sheet("safely_output")
				noi di in white "Successfully exported in `outfile'.xlsx"
				
				mata: colwidths("`outfile'", "safely_output")
				mata: addlines("`outfile'", "safely_output", (1, `=_N' + 1), "medium")
				putexcel set "`outfile'.xlsx", modify sheet("safely_output")
				putexcel (A1:A`=`=_N'+1'), border("left", "medium", "black")
				putexcel (A1:A`=`=_N'+1'), border("right", "medium", "black")
				putexcel (C1:C`=`=_N'+1'), border("right", "medium", "black")
				putexcel (D1:D`=`=_N'+1'), border("right", "medium", "black")
				
				forval i = 1/`using_cnt' {
					if !missing("`details'") {
						mata: colformats("`outfile'", "safely_output", ("using`i'_percent_missing", "using`i'_percent_unique"), "percent_d2")
						mata : st_local("column_letter", numtobase26(`=4+(7*`i')'))
						putexcel (`column_letter'1:`column_letter'`=`=_N'+1'), border("right", "medium", "black")
					}
					else {
						mata : st_local("column_letter", numtobase26(`=4+(1*`i')'))
						putexcel (`column_letter'1:`column_letter'`=`=_N'+1'), border("right", "medium", "black")
					}
				}
			}
		}	
	}
end


