*! version 1.0.0 10may2023

program define ipaodksplit, rclass

version 17

	syntax [using/], [order exclude label vallab(name) prefix(string) LANGuage(string)]
	
	qui {
		
		* clear frames 
		cap frame drop frm_*
		
		* create new frames
		frame create frm_survey
		frame create frm_choices

		* check syntax
		if !mi("`language'") & mi("`label'") {
			disp as err "Option language cannot be specified without option label"
			ex 198
		}
		
		frame frm_survey {

			* Import XLS form: import the survey sheet
			import excel using "`using'", sheet("survey") clear allstr first
			keep type name disabled 

			keep if regexm(type, "select_multiple") & !regexm(lower(disabled), "yes")

			* Count number of select_multiple variables
			loc sm_count `=_N'
			
			* Foreach select_multiple variable: pick out the variable name and its choice name
			gen choice_name = word(type, 2)

			* make a list of choice_names used in sm
			levelsof choice_name, loc(choice_names) clean
		}

		frame frm_choices {

			* XLS form: import the choices sheet
			import excel using "`using'", sheet("choices") clear first allstr case(l)
			keep if !missing(list_name)
			keep list_name value label*
			
			* check for multiple language columns
			* If language is not specified, assume first column as language column

			unab labels: label*

			if wordcount("`labels'") > 1 {
				if !missing("`language'") {
					cap confirm var label`language'
					if _rc == 111 {
						disp as err "Label language `language' not found"
						ex 198
					}
					loc labuse = word("`labels'", 1)
				}
				else loc labuse = word("`labels'", 1) 

				loc labdrop: list labels - labuse
				drop `labdrop' 
			}
			else loc labuse "label"

			* keep only relevant choice list 
			gen keep_choice = 0
			foreach choice in `choice_names' {
				replace keep_choice = 1 if list_name == "`choice'"
			}

			keep if keep_choice
			drop keep_choice
		}

		* Create dummy vars for all values defined in XLS form, with ignore option
		
		local nbvarsplit = 0
		tempvar _split_var
		gen `_split_var' = ""
		
		noi disp "Splitting select_multiple variable into dummies ..."
		noi disp
		noi disp "{ul:select_multiple}" _column(25) "{ul:number of dummies}"
		
		tempname sm_var_use 
		gen `sm_var_use' = ""

		forval i = 1/`sm_count' {

			frame frm_survey: loc sm_var 	= name[`i']
			replace `sm_var_use' = "_" + subinstr(trim(itrim(`sm_var')), " ", "_", .) + "_" if !mi(`sm_var')

			frame frm_survey: loc sm_list 	= choice_name[`i']

			frame copy frm_choices frm_single

			frame frm_single: keep if list_name == "`sm_list'"
			frame frm_single {
				loc list_cnt = `=_N'
			} 

			loc new_cnt 0
			loc new_list ""
			forval j = 1/`list_cnt' {
				
				frame frm_single: loc item = value[`j']

				cap confirm var `sm_var'`prefix'`j'
				if !_rc {
					disp as err "variable `sm_var'_`j' already exist. Use prefix opton eg. prefix(_r)"
					ex 198
				}
				else {
					if !mi("`exclude'") {
						count if regexm(`sm_var_use', "_`j'_") & !mi(`sm_var_use')
						loc exc_var = cond(`r(N)' == 0, 1, 0)
					}
					else loc exc_var 0
					if !`exc_var' {
						gen `sm_var'`prefix'`j' = regexm(`sm_var_use', "_`j'_") if !mi(`sm_var_use')
						
						if !mi("`label'") {
							frame frm_single: loc lab = `labuse'[`j']
							lab var `sm_var'`prefix'`j' "`lab'"
						}
						
						if !missing("`vallab'") lab val `sm_var'`prefix'`j' `vallab'

						loc new_list "`new_list' `sm_var'`prefix'`j'"
						loc ++new_cnt
					}
				}

			}

			if "`order'" ~= "" order `new_list', after(`sm_var')

			noi disp "`sm_var'" _column(25) "`new_cnt'"
			loc ++nbvarsplit
			
			frame drop frm_single

		}
		
		//6- Return the number of variables split
		return local N_vars =  `nbvarsplit'
	}

end
