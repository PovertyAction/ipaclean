*! version 0.0.1 01jul2023

program define ipaodksplit, rclass

version 17

	syntax [using/], [order ignore]
	
	qui {
		
		preserve
			
			//1- XLS form: import the survey sheet
			import excel type name disabled using "`using'", sheet("survey") clear
			keep if regexm(type, "select_multiple") & !regexm(lower(disabled), "yes")
			
			* Count number of select_multiple variables
			loc sm_count `=_N'
			
			* Foreach select_multiple variable: pick out the variable name and its choice name
			forval i = 1/`sm_count' {
				loc sm_`i'_chn = subinstr(type[`i'], "select_multiple ", "", .)
				loc sm_`i' = name[`i']
			}

			
			//2- XLS form: import the choices sheet
			import excel list_name value label using "`using'", sheet("choices") clear
			replace value = subinstr(value, "-", "x", .) //az?
			
			* Foreach select_multiple variable:
			forval i = 1/`sm_count' {
			
				* For each choice name: pic out the values
				levelsof value if list_name == "`sm_`i'_chn'", loc(sm_`i'_chv) clean
				
					* For each choice name: pic out the value's labels
					foreach j in `sm_`i'_chv' {
						
						if regexm("`j'", "x") loc j2 = subinstr("`j'", "x", "", .)
						else loc j2 = "`j'"
						levelsof label if list_name == "`sm_`i'_chn'" & value == "`j'", loc(m_`i'_chv_`j2') clean
					}
					
			}
			
		restore


		//3- Dummies variables for all values defined in XLS form, with ignore option
		local nbvarsplit = 0
		tempvar _split_var
		gen `_split_var' = ""
		lab define _yesno 0 "No" 1 "Yes"
		
		noi disp "Splitting select_multiple variable into dummies ..."
		noi disp
		noi disp "{ul:select_multiple}" _column(25) "{ul:number of dummies}"
		
		forval i = 1/`sm_count' {
			
			cap confirm var `sm_`i''
			if !_rc | missing("`ignore'") {
				
				qui replace `_split_var' = "_" + subinstr(`sm_`i'', " ", "_", .) + "_" if `sm_`i'' != ""
				
				foreach j in `sm_`i'_chv' {
					gen `sm_`i''_`j' = regex(`_split_var', "_`j'_") //if !missing(`sm_`i'')
					* label dummy
					lab values `sm_`i''_`j' _yesno
					* label variables
					loc varlab "`:variable label `sm_`i'''"
					lab var `sm_`i''_`j' "`sm_`i'' [`j']"
					notes `sm_`i''_`j': "`sm_`i'' - [`j'] - `varlab'"
				}
	
				//4- Option to Order new dummy vars right after original select_multiple variable
				if !missing("`order'") {
					order `sm_`i''_*, after(`sm_`i'') sequential
				}
		
				//5- Show information about variables that are split
				loc newvar_count = wordcount("`sm_`i'_chv'")
				noi disp "`sm_`i''" _column(25) "`newvar_count'"
				local nbvarsplit = `nbvarsplit' + 1

			}
		}
		
		//6- Return the number of variables split
		return local N_vars =  `nbvarsplit'
	}

end


