*! version 0.0.1 16jan2023
*! Innovations for Poverty Action
* ipaodkmergerepeats: Reshape & Merge data from ODK style repeat groups

program define ipaodkmergerepeats, rclass
	
	version 13

	syntax using/[, saving(string) FOLDer(string)]
	
	tempfile tmf_master
	

	qui {
	    * load master data set
	    use "`using'", replace

	    * use master datasets folder as default if folder is not specified 
	    if "`folder'" == "" {
	    	loc pos    = min(strpos(reverse("`using'"), "\"), strpos(reverse("`using'"), "/"))
	    	
			if `pos' > 0 loc folder = substr("`using'", 1, length("`using'") - `pos')
	    	* else set to pwd
			else loc folder "`c(pwd)'"
	    }
		
		* confirm dataset has setof vars
		cap unab setof: setof*
		
		if _rc == 111 {
			disp as err "No setof variables in using dataset"
			exit 111
		}
		
		foreach var of varlist setof* {
			
			loc ext = substr("`var'", 6, .)
			
			* find file in folder 
			loc dta : dir "`folder'" files "*-`ext'.dta"
			loc dta = "`folder'/" + `dta'
			reshapemerge using "`dta'", svar(`var') folder("`folder'")
		}
		
	}
    
end

* recursively reshapes and merges repeat instances
program define reshapemerge

	syntax using/, svar(varname) folder(string)
	
	tempfile tmf_master tmf_touse
	tempname tmn_jvar

	save "`tmf_master'"
	
	use "`using'", clear
	
	* confirm dataset has setof vars
	unab setof: setof*
	loc nsetof: list setof - svar
	
	if "`nsetof'" ~= "" {
		foreach var of varlist `nsetof' {
			
			loc ext = substr("`var'", 6, .)
			
			* find file in folder 
			loc dta : dir "`folder'" files "*-`ext'.dta"
			loc dta = "`folder'/" + `dta'
			
			reshapemerge using "`dta'", svar(`var') folder("`folder'")
		}
	}
	
	* generate index var from key
	gen `tmn_jvar' = substr(key, -(strpos(reverse(key), "[") - 1), (strpos(reverse(key), "[") - strpos(reverse(key), "]") - 1))
	destring `tmn_jvar', replace
	
	drop 	key `svar'
	ren 	parent_key key
	ren (*) (*_)
	ren (key_ ) (key)

	ds key `tmn_jvar', not
	reshape wide `r(varlist)', i(key) j(`tmn_jvar')

	ds key, not
	loc _usingvars "`r(varlist)'"
	
	save "`tmf_touse'"
	
	* merge and save
	use "`tmf_master'"
	merge 1:1 key using "`tmf_touse'", nogen
	order `_usingvars', after(`svar')

end