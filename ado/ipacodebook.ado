*! version 2.0.0 17sep2024
*! Innovations for Poverty Action 
* ipacodebook: export and/or apply excel codebook

program define ipacodebook, rclass

	#d;
	syntax  [varlist]
			using/
			[if] [in]
			[, replace template]
			[Statistics(namelist) STATVariables(string)]
			[note(string)]
			[APPLYusing(string)]
			;
	#d cr

	* Create tempfile for data in memory
	tempfile tmf_data tmf_stats
	
	qui {

		save "`tmf_data'"
		
		* mark sample
		marksample touse, nov strok
		keep if `touse'
		drop `touse'
		
		* --------------------------------------------------------------------------
		* Check syntax 
		* --------------------------------------------------------------------------
		
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

		* if the apply option is indicated
		if "`applyusing'" ~= "" {
			
			* check that using and apply using files are not the same
			if "`using'" == "`applyusing'" {
				disp as err "must specify a different filename in applyusing"
				ex 198
			}

			* import new variable labels and names
			import excel using "`applyusing'", sheet("codebook") allstr first clear
			keep variable label new_label new_variable 
			
			foreach var of varlist _all {
				replace `var' = "" if `var' == "."
			}
			
			keep if !missing(new_label) | !missing(new_variable)
			
			count if !missing(new_label)
			loc new_label_cnt `r(N)'
			
			count if !missing(new_variable)
			loc new_variable_cnt `r(N)'
			
			cap frame drop frm_codebook
			frame put _all, into(frm_codebook)
			
			* import new value labels
			import excel using "`applyusing'", sheet("value labels") allstr first clear
			replace new_label = "" if new_label == "."
			
			keep if !missing(new_label)
			
			loc new_choice_label_cnt = `c(N)'
			
			frame put _all, into(frm_value_labels)

			* display an error if there is no change to apply
			if (`new_label_cnt' + `new_variable_cnt' + `new_choice_label_cnt') == 0 {
				disp as err "There is no change to apply: columns new_label, new_variable, and new_choice_label are all empty in the using file `usingapply'."
				ex 198
			}
			
			* ------------------------------------------------------------------
			*Apply changes
			* ------------------------------------------------------------------
			
			use "`tmf_data'", clear
			
			* apply new choice labels
			if `new_choice_label_cnt' > 0 {
				
				forval i = 1/`new_choice_label_cnt' {
					
					frames frm_value_labels: loc clab_name = choice_label[`i']
					frames frm_value_labels: loc clab_val  = value[`i']
					frames frm_value_labels: loc clab_new  = new_label[`i']
					
					* Check that choice value is numeric and show an error if it is not
					cap confrim num `clab_val'
					if _rc == 7 {
						disp as err "cannot label non-numeric value `clab_val'."
						ex 198
					}
		
					* define/modify the name of the new value label
					lab def `clab_name' `clab_val' "`clab_new'", modify
				}	
			}
					
			* apply new variable labels
			if `new_label_cnt' > 0 {

				forval i = 1/`=`new_label_cnt' + `new_variable_cnt'' {

					frames frm_codebook: loc vname 		= variable[`i']
					frames frm_codebook: loc vlab_new  	= new_label[`i']
					
					if "`vlab_new'" ~= "" lab var `vname' "`vlab_new'"
				}	
			}
			
			* apply new variable names
			if `new_variable_cnt' > 0 {

				forval i = 1/`=`new_label_cnt' + `new_variable_cnt'' {

					frames frm_codebook: loc vname 		= variable[`i']
					frames frm_codebook: loc vname_new  = new_variable[`i']
					
					if "`vname_new'" ~= "" ren `vname' `vname_new'

					loc oldlist = "`oldlist' `vname'"
					loc newlist = "`newlist' `vname_new'"
				}

				loc varlist: list varlist - oldlist
				loc varlist: list varlist | newlist

				unab alllist: _all
				loc varlist: list alllist & varlist	
			}
		}

		save "`tmf_data'", replace
		
		* ----------------------------------------------------------------------
		* Create additional statistics for numeric variables
		* ----------------------------------------------------------------------

		if !missing("`statistics'") | !missing("`statvariables'") {

			use "`tmf_data'", clear
			if !missing("`statvariables'") keep `statvariables'
			else {
				ds, has(type numeric)
				keep `r(varlist)'
			}
			unab vars: * 

			tabstat `vars', stat(`statistics') save
			mat X = r(StatTotal)'
			clear
			svmat X, names(col)

			unab statvarlist: * 

			gen str32 variable = ""
			loc i = 1
			foreach var in `vars' {
				replace variable = "`var'" in `i'
				loc ++i 
			}

			save "`tmf_stats'"

		}
		
		* ----------------------------------------------------------------------
		* Create and export the excel coodebook
		* ----------------------------------------------------------------------
		
		use "`tmf_data'", clear

		cap frame drop frm_codebook
		cap frame drop frm_choice_list
		#d;
		frames 	create 	frm_codebook 
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
			* using tab to gen and error when values are too many
			
			preserve
			bys `var': gen _index_n_cnt = _n
			count if _index_n_cnt == 1 & !missing(`var')
			loc unique_cnt `r(N)'
			restore
			
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
				frm_codebook (`"`var'"') 			///
							(`"`varlab'"') 			///
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
			
			if "`template'" ~= "" {
				
				gen new_variable = "", after(variable)
				gen new_label = "", after(label)
	
			}

			* Merge in stats
			if !missing("`statistics'") | !missing("`statvariables'") {
				gen __index = _n
				merge 1:1 variable using "`tmf_stats'", nogen 
				sort __index
				drop __index
			}
			
			export excel using "`using'", first(var) sheet("codebook") `replace'
			ipacolwidth using "`using'", sheet("codebook")
			ipacolformat using "`using'", sheet("codebook") vars(percent_missing) format("percent_d2")
			if !missing("`statvarlist'") ipacolformat using "`using'", sheet("codebook") vars(`statvarlist') format("number_sep_d2")
			iparowformat using "`using'", sheet("codebook") type(header)
			
			* save vallels in local
			levelsof vallabel, clean
			loc vallabels "`r(levels)'"
		}
		
		
		* choice_list
		* restore, preserve
		
		
		if "`vallabels'" ~= "" {
		    
			* create frame for choice_list
			#d;
			frames create 	 frm_choice_list
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
								("`vallabel'") 
								("`val'")
								("`:lab `vallabel' `val''")
						;
					#d cr
				}
			}
	
			* export & format output
			frame frm_choice_list {
				if "`template'" ~= "" gen new_label = "", after(label)
				export excel using "`using'", first(var) sheet("value labels")
				ipacolwidth using "`using'", sheet("value labels")
				iparowline using "`using'", sheet("value labels") rows(1 `=_N+1') style("medium")
			}
			
		}
	
		return scalar N_vars = `varscount'
		return scalar N_allmiss = `allmisscount'
		return scalar N_miss = `misscount'	
	}

end
