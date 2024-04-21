*! version 1.0.0 23jan2024
*! Innovations for Poverty Action 
* ipaappend: Safely append dataset

program define ipaappend, rclass

version 17
		
	#d;
	syntax anything(everything) [, 
		OUTFile(string)
		DETails
		keep(namelist)
		NOLabel
		NONOTEs
		safely
		report
		replace
		GENerate(name)
		]
	;
	#d cr

	qui {
		
		* create frames
		cap frame drop frm_data_info
		frame create frm_data_info
		
		* check using
		cap assert regexm("`anything'", "^using ")
		if _rc == 9 { 
			disp as err "using required"
			ex 198
		}
		
		* check that safely and report are not used together
		if !missing("`report'") & !missing("`safely'") {
				disp as err "options report and safely are mutually exclusive"
				ex 198
		}	
		
		* check outfile is specified if report or safely is specified
		if !missing("`outfile'") & missing("`report'`safely'") {
			disp as err "must specify option outfile() with report or safely"
			ex 198
		}
		
		* check that details is specified correctly
		if !missing("`details'") & missing("`outfile'") {
			disp as err "must specify option outfile() with option details"
			ex 198
		}

		* check that outfile is specified if replace is used
		if missing("`outfile'") & !missing("`replace'") {
			disp as err "option() outfile required if option replace() is used"
			ex 198
		}
		
		* get list of datasets
		loc anything = substr(`"`anything'"', strpos(`"`anything'"', "using") + 5, .)

		* if there is data in memory use as master data else use append 1 as master data
		tempfile tmf_m_data 
		if `c(N)' > 0 {

			save "`tmf_m_data'"
		
		}
		else {

			gettoken m anything: anything
			use "`m'", clear

			save "`tmf_m_data'"

		}

		loc using_cnt: word count `anything'
	
		forval i = 0/`using_cnt' {
			
			if `i' == 0 {

				loc pre "m"
				loc pre_lab "master"

				frame frm_data_info {
					gen variable 	= ""
					gen label 		= ""
					gen m_type 		= ""
					lab var m_type "master"
					gen m_dsg 		= ""
				}
			}
			
			else {
				
				loc u`i': word `i' of `anything'
				use "`u`i''", clear
				loc pre "u`i'"
				loc pre_lab "append `i'"
				
				tempfile tmf_`pre'_data
				loc u`i'_cnt `c(N)'
				if !missing("`keep'") keep `keep'

				save "`tmf_`pre'_data'"
				
				frame frm_data_info {
					
					gen u`i'_type = ""
					lab var u`i' "append `i'"
					gen u`i'_dsg  = ""
					gen u`i'_tmatch = .
				}
			}

			if !missing("`details'") {

				frame frm_data_info {
					gen `pre'_miss_cnt 	= ., after(`pre'_type)
					lab var `pre'_miss_cnt "# missing"	
					gen `pre'_miss_perc	= ., after(`pre'_miss_cnt)
					lab var `pre'_miss_perc "% missing"
					gen `pre'_uniq_cnt 	= ., after(`pre'_miss_perc)
					lab var `pre'_uniq_cnt "# unique"
					gen `pre'_uniq_perc 	= ., after(`pre'_uniq_cnt)
					lab var `pre'_uniq_perc "% unique"

				}

			}

			foreach var of varlist _all {

				* type and label
				loc vtype = "`:type `var''"
				if regexm("`vtype'", "^str") {
					destring `var', replace
					loc v_dsg = "`vtype'" ~= "`:type `var''"
				}
				else loc v_dsg ""
				loc vlab = "`:var lab `var''"
				
				* missing
				count if missing(`var')
				loc miss_cnt `r(N)'
				loc miss_perc `miss_cnt' /`=_N'
				
				* unique
				tab `var'
				loc uniq_cnt `r(r)'
				loc uniq_perc = `uniq_cnt'/`c(N)'
				
				frames frm_data_info {
					
					cap assert variable ~= "`var'"
					if !_rc {
						
						frames frm_data_info {
							
							loc obs_cnt = `c(N)' + 1
							set obs `obs_cnt'
							replace variable = "`var'" 	in `c(N)'
							replace label 	 = "`vlab'" in `c(N)'
						}
					}

					replace `pre'_type = "`vtype'" if variable == "`var'"
					replace `pre'_dsg  = "`v_dsg'" if variable == "`var'"

					if !missing("`details'") {
						
						replace `pre'_miss_cnt  = `miss_cnt'  if variable == "`var'"
						replace `pre'_miss_perc = `miss_perc' if variable == "`var'"
						replace `pre'_uniq_cnt  = `uniq_cnt'  if variable == "`var'"
						replace `pre'_uniq_perc = `uniq_perc'  if variable == "`var'"					
					}
					
					* check if the type match between master and each using
					if `i' > 0 {
						
						replace `pre'_tmatch = (regexm(`pre'_type, "^str") == regexm(m_type, "^str")) ///
												if variable == "`var'" & !missing(m_type)
							
					}				
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
			gen appends  = cond(str_cnt == (`using_cnt' + 1) | str_cnt == 0, 1, 0)
			lab var appends "appends"
			gen final_type = cond(str_cnt == dsg_cnt & str_cnt < (`using_cnt' + 1), ///
									"numeric", "string")
			lab var final_type "safe type"

			lab define yesno 0 "No" 1 "Yes"
			lab val appends yesno

			count if appends == 0
			loc appends_cnt `r(N)'

			loc var_cnt = `c(N)'
		}
		
		* Display text report if outfile is not specified
		if !missing("`report'") & missing("`safely'") {
			if `appends_cnt' > 0 {
				noi disp
				noi disp "IPAAPPEND report: Dataset cannot be appended normally."
				noi disp "`r(N)' variable(s) have different formats accross your datasets"
				noi disp "Use the safely() option to append the datasets"
				if missing("`outfile'") {
					noi disp "Use the outfile() option to get more details about the datasets"
					ex
				}
			}
			else if `appends_cnt' == `var_cnt' {
				noi disp "IPAAPPEND report: Dataset can be appended normally."
				ex 
			}
		}
		if !missing("`report'") & !missing("`outfile'") {
			
			* Output append report 
			frame copy frm_data_info frm_data_info_exp
			frame frm_data_info_exp {

				drop dsg_* *_dsg *_tmatch str_cnt

				export excel using "`outfile'", sheet("report") cell(A2) first(varlab) `replace'
				ipacolwidth using "`outfile'", sheet("report")
			}
		}
		
		* If option safely is used, correct datasets
		
		if !missing("`safely'") {

			loc u_tmfs ""	

			forval  i = 0/`using_cnt' {

				loc pre = cond(`i' == 0, "m", "u`i'")
				use "`tmf_`pre'_data'", clear

				forval j = 1/`var_cnt' {
					frame frm_data_info {
						loc var = variable[`j']
						loc c_type = `pre'_type[`j']
						loc f_type = final_type[`j']
					}

					if ("`f_type'" == "numeric") & regexm("`c_type'", "^str") {
						destring `var', replace
					} 
					else if ("`f_type'" == "string") & regexm("`c_type'", "^(byte|int|long|float|double)") {
						tostring `var', replace format("`:format `var''")
					}
				}
				
				save "`tmf_`pre'_data'", replace

				if `i' > 0 {
					
					loc u_tmfs = `"`u_tmfs'"' + " " + char(34) + "`tmf_`pre'_data'" + char(34)
					
				}

			}
		}
	
		if missing("`report'") {
			* Append datasets run append

			use "`tmf_m_data'", clear

			append using `u_tmfs', `nolabel' `nonotes' generate(`generate')

			if !missing("`outfile'") {
			
				* Output append report 
				frame copy frm_data_info frm_data_info_exp
				frame frm_data_info_exp {

					drop dsg_* *_dsg *_tmatch str_cnt

					forval i = 1/`c(N)' {
						loc var = variable[`i']
						frame default {
							loc type "`:type `var''"
						}
						replace final_type = "`type'" in `i'
					}

					lab var final_type "final type"

					export excel using "`outfile'",cell(A2) sheet("report") first(varlab) `replace'
					
				}
			}
		}
		
		* format output
		if !missing("`outfile'") {

			frame frm_data_info_exp {

				if !missing("`details'") {
					mata: format_report("`outfile'", "report", "details", `using_cnt')
				}
				else {
					mata: format_report("`outfile'", "report", "nodetails", `using_cnt')
				}
				
				ipacolwidth using "`outfile'", sheet("report")
				ipacellfont using "`outfile'", sheet("report") rows(1 `=c(N)+2') cols(1 `=c(k)+1') fontname("Calibri") fontsize(10)

			}
		}
	}

end

mata:
mata clear 

void format_report(string scalar file, string scalar sheet, string scalar details, real scalar using_cnt) 
{
	real scalar i, j, k, startcol, adjust_by
	class xl scalar b
	b = xl()
	b.load_book(file)
	b.set_sheet(sheet)
	b.set_mode("open")
	
	startcol = 3
	adjust_by = 0
	
	if (details == "details") {
		adjust_by = 4
	}
	
	b.put_string(1, startcol, "Master")
	b.set_sheet_merge(sheet, (1, 1), (startcol, startcol + adjust_by))
	b.set_horizontal_align((1, 1), (startcol, startcol + adjust_by), "center")
	b.set_left_border((1, st_nobs() + 2), (startcol, startcol), "medium")
	b.set_number_format((3, st_nobs() + 2), (startcol + 1, startcol + 1), "number_sep")
	b.set_number_format((3, st_nobs() + 2), (startcol + 2, startcol + 2), "percent_d2")
	b.set_number_format((3, st_nobs() + 2), (startcol + 3, startcol + 3), "number_sep")
	b.set_number_format((3, st_nobs() + 2), (startcol + 4, startcol + 4), "percent_d2")
	
	for (i = 1; i <= using_cnt; i++) {
		startcol = startcol + adjust_by + 1
		b.put_string(1, startcol, "Appending dataset " + strofreal(i))
		b.set_sheet_merge(sheet, (1, 1), (startcol, startcol + adjust_by))
		b.set_horizontal_align((1, 1), (startcol, startcol + adjust_by), "center")
		b.set_left_border((1, st_nobs() + 2), (startcol, startcol), "thin")
		b.set_number_format((3, st_nobs() + 2), (startcol + 1, startcol + 1), "number_sep")
		b.set_number_format((3, st_nobs() + 2), (startcol + 2, startcol + 2), "percent_d2")
		b.set_number_format((3, st_nobs() + 2), (startcol + 3, startcol + 3), "number_sep")
		b.set_number_format((3, st_nobs() + 2), (startcol + 4, startcol + 4), "percent_d2")
	}
	
	b.set_bottom_border((1, 1), (3, st_nvar()), "thin")
	b.set_bottom_border((2, 2), (1, st_nvar()), "thick")
	b.set_left_border((1, st_nobs() + 2), (startcol + adjust_by + 1, startcol + adjust_by + 1), "medium")
	
	b.close_book()

}

end