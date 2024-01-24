*! version 1.0.0 01jul2023
*! Innovations for Poverty Action 
* ipacodebook: export and/or apply excel codebook

cap program drop ipacodebook_v2
program define ipacodebook_v2, rclass

	#d;
	syntax  [varlist]
			using/
			[if] [in]
			[, replace]
			[note(string)]
			[, apply] //az
			;
	#d cr

	preserve
	
	* mark sample
	marksample touse, strok
	keep if `touse'
	drop `touse'

	
	
	qui {

	* if the apply option is indicated
	if "`apply'" ~= "" {

		* import new variable labels and names
		import excel using "`using'", sheet("codebook") first clear
		tostring new_label, replace
		tostring new_variable, replace
		replace new_label = "" if new_label == "."
		replace new_variable = "" if new_variable == "."
		tempfile codebooksheet
		save `codebooksheet'

		* count new varible labels
		count if new_label != ""
		local count_new_lab `r(N)'

		* count new varibale names 
		count if new_variable != ""
		local count_new_var `r(N)'

		* import new value labels
		import excel using "`using'", sheet("value labels") first clear
		tostring new_choice_label, replace
		replace new_choice_label = "" if new_choice_label == "."
		tempfile valuelabsheet
		save `valuelabsheet'

		* count new value labels
		count if new_choice_label != ""
		local count_new_choice_label `r(N)'
		
		* display an error if there is no change to apply
		if `count_new_lab' + `count_new_var' + `count_new_choice_label' == 0 {
			di as err "There is no change to apply: columns new_label, new_variable, and new_choice_label are all empty in the using file `using'."
		}

	restore

		* apply new variable labels
		if `count_new_lab' > 0 {

			foreach num of numlist 1/`count_new_lab' {

	preserve
	
				use `codebooksheet', clear
				keep if new_label != ""
				keep if _n == `num'
				levelsof variable, loc(old_var)
				levelsof new_label, loc(new_varlab)
				loc old_var_run: word 1 of `old_var'
				loc new_varlab_run: word 1 of `new_varlab'
			
	restore
	
				noi lab var `old_var_run' "`new_varlab_run'"
				noi di "Variable `old_var_run': the new variable label is applied"
			}	
		}
		
		* apply new choice labels
		if `count_new_choice_label' > 0 {
			
			foreach num of numlist 1/`count_new_choice_label' {

	preserve
	
				* only keep the current new value label
				use `valuelabsheet', clear
				keep if new_choice_label != ""
				keep if _n == `num'
				
				* get the current new value label and corresponding choice label and value
				levelsof choice_label, loc(choice_label)
				levelsof value, loc(value)
				levelsof new_choice_label, loc(new_choice_label)
				loc choice_label_run: word 1 of `choice_label'
				loc value_run: word 1 of `value'
				loc new_choice_label_run: word 1 of `new_choice_label'
			
	restore
	
				* define/modify the name of the new value label
				noi label define `choice_label_run' `value_run' "`new_choice_label_run'", modify
		
	preserve
				* get all variables using the above new choice label
				describe, replace clear
				levelsof name if vallab == "`choice_label_run'", local(varstoapply)
	restore
				* count all variables using the above new value label
				local countvarstoapply: word count `varstoapply'
				
				* for each variable using the older value label: apply the new value label
				foreach num of numlist 1/`countvarstoapply' {
					
					loc varstoapply_run: word `num' of `varstoapply'
					noi label val `varstoapply_run' `choice_label_run'
					noi di "Variable `varstoapply_run': the new choice label is applied"
					continue, break	
				}	
			}	
		}
		

		* apply new variable names
		if `count_new_var' > 0 {
			
			foreach num of numlist 1/`count_new_var' {
				preserve
					use `codebooksheet', clear
					keep if new_variable != ""
					keep if _n == `num'
					levelsof variable, local(old_var)
					levelsof new_variable, local(new_var)
					loc old_var_run: word 1 of `old_var'
					loc new_var_run: word 1 of `new_var'
				restore
				
				* rename/apply new variable names
				rename `old_var_run' `new_var_run'
				noi di "Variable `old_var_run' is renamed as `new_var_run'" 
				
				* replace the old variable name by the new name within the local `varlist'
				local varlist = subinword("`varlist'", "`old_var_run'", "`new_var_run'", 1)
			}
		}
		preserve
	}
	

	* export the excel coodebook
		* check notes option
		* expected format note(#, REPLace|COALesce|LONGer|SHORTer)
	
		if "`note'" ~= "" {
			tokenize "`note'", parse(",")
			cap confirm number `1'
			if _rc == 7 {
				disp as err "`1' found at option note() where number expected"
				ex 7
			} 
			cap assert regexm(lower("`3'"), "^(repl)|^(coal)|^(long)|^(short)")
			if _rc == 9 {
			    disp as err "`3' found were any of the replace, coalesce, longer or shorter expected"
				ex 9
			}
			else {
			    loc note_num `1'
				loc note_priority "`3'"
			}
			
		}
		
		cap frame drop frm_codebook
		cap frame drop frm_choice_list
		#d;
		frames 	create 	frm_codebook 
				str32	new_variable //az
				strL	new_label //az
				str32  	variable 
				strL 	label
				str10   type 
				str32   vallabel 
				double  (number_missing percent_missing number_unique) 
			;
		#d cr

		*** create output ***

		if "`varlist'" ~= "" unab vars: `varlist'
		else unab vars: _all

		* create & post stats for each variable
		foreach var of varlist `vars' {

			* count missing values for var
			qui count if missing(`var')
			loc missing_cnt `r(N)'
			
			* count number of unique nonmissing values for var
			qui tab `var'
			loc unique_cnt `r(r)'
			
			loc label 	"`:var lab `var''"
			if "`note'" ~= ""  loc notelab "``var'[note`note_num']'"
			
			if "`note'" == ""	{
			    loc varlab "`label'"
			}
			else if regexm("`note_priority'", "^(repl)") {
				loc varlab "`notelab'"
			}
			else if  regexm("`note_priority'", "^(coal)") {
				if "`label'" ~= "" {
					loc varlab "`label'"
				}
				else {
					loc varlab "`notelab'"
				}
			}
			else if regexm("`note_priority'", "^(long)") {
				if length(`"`label'"') <= length(`"`notelab'"') {
					loc varlab "`notelab'"
				}
				else {
					loc varlab "`label'"
				}
			}
			else if regexm("`note_priority'", "^(short)") {
				if (length(`"`label'"') <= length(`"`notelab'"')) | missing("`notelab'") {
					loc varlab "`label'"
				}
				else {
					loc varlab "`notelab'"
				}
			}
			
			
			* post results to frame
			frames post ///
				frm_codebook ("") 			///
						 ("") 			///
						 (`"`var'"') 			///
						 (`"`varlab'"') 		///
						 ("`:type `var''")		///
						 ("`:val lab `var''")	///
						 (`missing_cnt') 		///
						 (`missing_cnt'/`=_N') 	///
						 (`unique_cnt')

		}

		* export results
		frames frm_codebook {
			
			* count number of variables to check
			loc varscount = wordcount("`vars'")

			* count number of variables that are all missing
			count if percent_missing == 1
			loc allmisscount `r(N)'

			* count number of vars with at least 1 missing variables
			count if percent_missing ~= 1
			loc misscount `r(N)'
			
			* replace unique_cnt  with missing if all missing
			replace number_unique = . if percent_missing == 1			
			
			//az
			if "`apply'" ~= "" {
				
				* export & format output
				loc _pos1 strrpos("`using'", "/")
				loc _pos2 strrpos("`using'", "\")
				loc _pos max(`_pos1', `_pos2')
				loc using_part1 substr("`using'", 1, `_pos')
				loc using_part2 substr("`using'", `_pos' + 1, .)
				loc new_using = `using_part1' + "new_" + `using_part2'
				export excel using "`new_using'", first(var) sheet("codebook") `replace'
				mata: colwidths("`new_using'", "codebook")
				mata: colformats("`new_using'", "codebook", "percent_missing", "percent_d2")
				mata: addlines("`new_using'", "codebook", (1, `=_N' + 1), "medium")
				
			}
				
			else {
				* export & format output
				export excel using "`using'", first(var) sheet("codebook") `replace'
				mata: colwidths("`using'", "codebook")
				mata: colformats("`using'", "codebook", "percent_missing", "percent_d2")
				mata: addlines("`using'", "codebook", (1, `=_N' + 1), "medium")

			}
			//endaz
			
			* save vallels in local
			levelsof vallabel, clean
			loc vallabels "`r(levels)'"
		}
		
		
		* choice_list
		restore, preserve
		
		
		if "`vallabels'" ~= "" {
		    
			* create frame for choice_list
			#d;
			frames create 	 frm_choice_list
				   str32	 new_choice_label //az
				   str32 	 (choice_label) 
				   strL      (value label)
				   ;
			#d cr	
			
			* order list
			loc vallabels: list sort vallabels
			
		    foreach vallabel in `vallabels' {
			    * get variables using vallabel
				
				ds, has(vallabel `vallabel')
				loc var = word("`vallabel'", 1)
				
				* get values in actual label.
				qui lab list 	`vallabel'
				loc list_min  	`r(min)'
				loc list_max  	`r(max)'
				loc list_miss 	`r(hasemiss)'
					
				* check labels
				if `r(k)' > 2 {
					loc list_vals ""
					forval j = `list_min'/`list_max' {
						if !mi("`:lab `vallabel' `j', strict'") loc list_vals = "`list_vals' `j'"
					}
					
					loc list_vals: list sort list_vals
				}
				else {
					loc list_vals: list list_min | list_max
				}
				
				* check for possible extended missing values
				if `list_miss' {
					foreach letter in `c(alpha)' {
						if !mi("`:lab `vallabel' .`letter''") loc list_vals = "`list_vals' .`letter'"
					}
				}
				
				loc list_vals: list uniq list_vals
				foreach val in `list_vals' {
				    #d;
					frames post 
						   frm_choice_list 
						   		("") //az
								("`vallabel'") 
								("`val'")
								("`:lab `vallabel' `val''")
						;
					#d cr
				}
			}

			//az
			if "`apply'" ~= "" {
				
				* export & format output
				frame frm_choice_list {
					export excel using "`new_using'", first(var) sheet("value labels")
					mata: colwidths("`new_using'", "value labels")
					mata: addlines("`new_using'", "value labels", (1, `=_N' + 1), "medium")
					noi di "This is the export of the new excel codebook: `new_using'"
				}
			}
			
			else {
				* export & format output
				frame frm_choice_list {
					export excel using "`using'", first(var) sheet("value labels")
					mata: colwidths("`using'", "value labels")
					mata: addlines("`using'", "value labels", (1, `=_N' + 1), "medium")
				}
			}
			//endaz
		}
	
		return scalar N_vars = `varscount'
		return scalar N_allmiss = `allmisscount'
		return scalar N_miss = `misscount'	
	}

end