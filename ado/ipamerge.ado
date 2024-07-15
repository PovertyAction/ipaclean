*! version 1.0.0 15jul2024
*! Innovations for Poverty Action

program define ipamerge

version 17
		
	#d;
	syntax anything(everything) [, 
		OUTFile(string)
		DETails
		KEEPUSing(namelist)
		NOLabel
		NONOTEs
		update
		replace
		safely
		MERGEREport
		noreport
		GENerate(name)
		NOGENerate
		assert(string)
		keep(string)
		sorted
		]
	;
	#d cr
		
	qui {

		* tempfiles 
		tempfile tmf_m_data tmf_u_data
			
		* create frames
		cap frame drop frm_data_info
		cap frame from frm_data_info_exp
		frame create frm_data_info

		* get merge type
		gettoken mtype anything: anything

		* check if using is including in syntax
		if !regexm(`"`anything'"', "using") { {
			disp as err "using required"
			ex 198
		}

		* get outfile and replace options
		if !missing("`outfile'") {
			gettoken filename outfile: outfile, parse(,)
			
			if !missing(trim(itrim("`outfile'"))) loc sheetreplace = subinstr("`outfile'", ",", "", .)
			loc outfile = "`filename'"
		}

		* check for merge variables 
		loc id_vars = substr(`"`anything'"', 1, strpos(`"`anything'"', "using") - 1)
		unab id_vars: `id_vars'

		* check that safely and report are not used together
		if !missing("`mergereport'") & !missing("`safely'") {
				disp as err "options mergereport and safely are mutually exclusive"
				ex 198
		}	

		* check outfile is specified if report or safely is specified
		if !missing("`outfile'") & missing("`mergereport'`safely'") {
			disp as err "must specify option outfile() with mergereport or safely"
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
		loc using_data = substr(`"`anything'"', strpos(`"`anything'"', "using") + 5, .)
		
		* if there is data in memory use as master data else use append 1 as master data
		save "`tmf_m_data'"

		forval i = 0/1 {

			if `i' == 0 {
				loc pre "m"
				loc pre_lab "master"
			}
			else {
				loc pre "u"
				loc pre_lab "using"
			} 

			frame frm_data_info {
				if `i' == 0 gen variable 	= ""
				if `i' == 0 gen label 		= ""
				
				gen `pre'_type 		= ""
				lab var `pre'_type "`pre_lab'"
				gen `pre'_dsg 		= ""
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

			if `i' == 0 use "`tmf_m_data'", clear
			else {
				loc data: word 1 of `using_data'
				use "`data'", clear

				save "`tmf_u_data'"
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
							
						loc obs_cnt = `c(N)' + 1
						set obs `obs_cnt'
						replace variable = "`var'" 	in `c(N)'
						replace label 	 = "`vlab'" in `c(N)'
			
					}

					replace `pre'_type = "`vtype'" if variable == "`var'"
					replace `pre'_dsg  = "`v_dsg'" if variable == "`var'"
					
					if !missing("`details'") {
						
						replace `pre'_miss_cnt  = `miss_cnt'  if variable == "`var'"
						replace `pre'_miss_perc = `miss_perc' if variable == "`var'"
						replace `pre'_uniq_cnt  = `uniq_cnt'  if variable == "`var'"
						replace `pre'_uniq_perc = `uniq_perc'  if variable == "`var'"					
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
			gen merges  = cond(str_cnt == 2 | str_cnt == 0, 1, 0)
			lab var merges "merges"
			gen final_type = cond(str_cnt == dsg_cnt & str_cnt < 2, "numeric", "string")
			lab var final_type "safe type"

			lab define yesno 0 "No" 1 "Yes"
			lab val merges yesno

			count if merges == 0
			loc merges_cnt `r(N)'

			loc var_cnt = `c(N)'
		}
	
		* Display text report if outfile is not specified
		
		if !missing("`mergereport'") & missing("`safely'") {
			if `merges_cnt' > 0 {
				noi disp
				noi disp "IPAMERGE report: Dataset cannot be merged normally."
				noi disp "`r(N)' variable(s) have different formats accross your datasets"
				noi disp "Use the safely() option to append the datasets"
				if missing("`outfile'") {
					noi disp "Use the outfile() option to get more details about the datasets"
					ex
				}
			}
			else if `merges_cnt' == `var_cnt' {
				noi disp "IPAMERGE report: Dataset can be appended normally."
				if missing("`outfile'") ex 
			}
		}
		
		if !missing("`mergereport'") & !missing("`outfile'") {
			
			* Output merge report 
			frame copy frm_data_info frm_data_info_exp
			frame frm_data_info_exp {

				drop dsg_* *_dsg str_cnt

				export excel using "`outfile'", sheet("report") cell(A2) first(varlab) `sheetreplace'
				ipacolwidth using "`outfile'", sheet("report")
			}
		}

		* If option safely is used, correct datasets

		if !missing("`safely'") {

			forval  i = 0/1 {

				loc pre = cond(`i' == 0, "m", "u")
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

			}
		}

		if missing("`mergereport'") {
			
			* Merge datasets run merge

			use "`tmf_m_data'", clear

			merge `mtype' `id_vars' using "`tmf_u_data'", ///
				`nolabel' `nonotes' ///
				generate(`generate') `nogenerate' ///
				`update' `replace' ///
				`noreport' `sorted' ///
				assert(`assert')

			if !missing("`outfile'") {
			
				* Output append report 
				frame copy frm_data_info frm_data_info_exp
				frame frm_data_info_exp {

					drop dsg_* *_dsg str_cnt

					forval i = 1/`c(N)' {
						loc var = variable[`i']
						frame default {
							loc type "`:type `var''"
						}
						replace final_type = "`type'" in `i'
					}

					lab var final_type "final type"

					export excel using "`outfile'",cell(A2) sheet("report") first(varlab) `sheetreplace'
					
				}
			}

			* format output
			if !missing("`outfile'") {

				frame frm_data_info_exp {

					if !missing("`details'") {
						mata: format_report("`outfile'", "report", "details", 1)
					}
					else {
						mata: format_report("`outfile'", "report", "nodetails", 1)
					}
					
					ipacolwidth using "`outfile'", sheet("report")
					ipacellfont using "`outfile'", sheet("report") rows(1 `=c(N)+2') cols(1 `=c(k)+1') fontname("Calibri") fontsize(10)

				}
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
		b.put_string(1, startcol, "Using dataset ")
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
