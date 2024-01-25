*! version 0.0.1 25jan2024
*! Innovations for Poverty Action

cap program drop ipaclean_check
program define ipaclean_check, rclass

	version 17

    syntax [using/], id(varname) [OUTFile(string) replace]
 
********************************************************************************
	* Check ID - uniqueness, check that IDs are not long numeric values.
	* Check that IDs are similar length
********************************************************************************

qui {
	
	if "`using'" != "" {
		import excel using "`using'", first clear
	}
	

	cap frame drop frm_1
	cap isid `id'
	if _rc == 459 {
			duplicates tag `id', gen(dup)
			frame put `id' dup if dup, into(frm_1)
			cap drop dup
		    nois disp as err "id() variable `id' does not uniquely identify the observations"
			if "`outfile'" != "" {
				frame frm_1 {
					export excel using "`outfile'", first(var) sheet("uniqueness", replace)
					*mata: colwidths("`outfile'", "uniqueness")
				}  
			} 
		}
		
		
		cap frame drop frm_2
		cap confirm numeric variable `id'
		if !_rc {
			gen len = floor(log10(`id'))+1
			capture assert len>7
			if _rc {
				frame put `id' len if len > 7, into(frm_2)
				nois disp as err "id() varible `id' have long numeric values"
				if "`outfile'" != "" {
					capture frame frm_2 {
						export excel using "`outfile'", first(var) sheet("id_length", replace)
						*mata: colwidths("`outfile'", "id_length")
					}  
				}
				
				qui sum len
				local sd  `r(sd)'

				if `sd' != 0 {
					nois display as err "All IDs do not have the same length"
				}
			}
		}
			
			
		
		cap drop len

		
	
********************************************************************************	
	**** Check for use and labeling of extended missing values ****
********************************************************************************

	ds, has(vallabel)
	local ext_miss `r(varlist)'

	cap frame drop frm_3
	
	frame create frm_3 str32 variables ext_miss_num labelled_miss
	
	foreach miss in `ext_miss' {
		
		* Check for extended missing values
		count if `miss' >= .a & `miss' <= .z
		local extmiss_num `r(N)'
		
		if `extmiss_num' > 0 {
			nois display as err "Variable `miss' has " `r(N)' " extended missing values."
			
			* Check for labels of extended missing values
			local vallabel: value label `miss'
			label list `vallabel'
			local hasemiss `r(hasemiss)'
			if `hasemiss' == 0 {
					nois display as err "The variable `miss' has extended missing values which have not been labelled"
					frame post frm_3 ("`miss'") (`extmiss_num') (`hasemiss')
				}
			
			 }
			  
			    
		}


	if "`outfile'" != "" {
		frame frm_3 {
			if `=_N' > 0 {
				export excel using "`outfile'", first(var) sheet("Extended missing", replace)
				*mata: colwidths("`outfile'", "Extended missing")
			}
			
		}  
		
	}

********************************************************************************	
			*** Check for missing variable or value labels ***
********************************************************************************
	 
	ds, has(type numeric)
	local numvars = r(varlist)
	
	* create output frame for missing values label
	cap frame drop frm_4
		
	frame create frm_4 str32 variable 
	
	
	foreach var of local numvars {
	capture label list `var'
	if _rc != 0 {
		frame post frm_4 ("`var'")
       nois di as err "Missing value label for variable `var'"
        }	
	}
	
	if "`outfile'" != "" {
		frame frm_4 {
			if `=_N' > 0 {
				export excel using "`outfile'", first(var) sheet("missing value label", replace)
				*mata: colwidths("`outfile'", "missing value label")
			}
		}  
	}
	
	* create output frame for missing variable label
	cap frame drop frm_5
		
	frame create frm_5 str32 variable 
	
	ds
	local allvar  `r(varlist)'
	foreach var of local allvar {
		local varlabel : variable label `var'
		if "`varlabel'" == "" {
			frame post frm_5 ("`var'")
		nois	di as err "Missing variable label for variable `var'"
		}
	}
	
	if "`outfile'" != "" {
		frame frm_5 {
			if `=_N' > 0 {
				export excel using "`outfile'", first(var) sheet("missing variable label", replace)
				*mata: colwidths("`outfile'", "missing variable label")
			}
		}  
		
	}
	
********************************************************************************	
	* Check that variable labels that are exactly 80 chars has a 
	* longer variable name stored in notes 
********************************************************************************

	ds, has(varlabel)
	local labellist `r(varlist)'
	
	* create output frame 
	cap frame drop frm_6
	frame create frm_6 str32 variable
	
	* Loop over each variable
	foreach var of local labellist  {
		* Get the variable label
		local varlabel : variable label `var'
		
		* Check if the variable label is exactly 80 characters long
		if strlen("`varlabel'") == 80 {
			* Get the variable note
			local varnote : notes `var'
			
			* Check if the variable note is fewer than the variable label
			if strlen("`varnote'") < strlen("`varlabel'") {
				nois display as err "`var' has a variable label of exactly 80 characters and a fewer variable name stored in notes."
				frame post frm_6 ("`var'")
			}
		}
	}
	
	if "`outfile'" != "" {
		frame frm_6 {
			if `=_N' > 0 {
				frame frm_6:  export excel using "`outfile'", first(var) sheet("notes length", replace)
				*mata: colwidths("`outfile'", "notes length")
			}
		}
		
		
	}
}	
	
end