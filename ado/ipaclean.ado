*! version 1.0.0 17sep2024
*! Innovations for Poverty Action
* ipaclean: IPA Stata Package for Data Cleaning

program ipaclean, rclass
	
	version 17
	
	syntax 	name(name=subcmd id="sub command") [,BRanch(name) force id(varname) OUTFile(string)]

	qui {
		if !inlist("`subcmd'", "version", "update", "check") {
			disp as err "illegal ipaclean sub command. Sub commands are:"
			noi di as txt 	"{cmd:ipaclean update}"
			noi di as txt 	"{cmd:ipaclean version}"
			ex 198
		}
		
		if "`subcmd'" ~= "" & "`force'" ~= "" {
			disp as err "Sub-command `subcmd' and option force are mutually exclusive"
			ex 198
		}
		
		loc url 	= "https://raw.githubusercontent.com/PovertyAction/ipaclean"

		if "`subcmd'" == "check" {
			noi ipaclean_`subcmd', branch(`branch') url(`url') id(`id') outfile(`outfile')
		}
		else {
			noi ipaclean_`subcmd', branch(`branch') url(`url') `force'
		}
		
	}
end

program define ipaclean_update
	
	qui {
		syntax, [branch(name)] url(string) [force]
		
		loc branch 	= cond("`branch'" ~= "", "`branch'", "main")
		noi net install ipaclean, all replace from("`url'/`branch'") `force'
		
	}
	
end

program define ipaclean_version
	
	qui {
		syntax, [branch(name)] url(string)
		
		loc branch 	= cond("`branch'" ~= "", "`branch'", "main")

		* create frame
		cap frames drop frm_verdate
		frames create frm_verdate str32 (line)
			
		* get list of programs from pkg file 
		tempname pkg
		loc linenum = 0
		file open `pkg' using "`url'/`branch'/ipaclean.pkg", read
		file read `pkg' line
		
		while r(eof)==0 {
			loc ++linenum
			frame post frm_verdate (`" `macval(line)'"')
			file read `pkg' line
		}
		
		file close `pkg'
		
		frame frm_verdate {
			egen program = ends(line), punct("/") tail
			drop if !regexm(program, "\.ado$")
			replace program = subinstr(program, ".ado", "", 1)
			loc prog_cnt `c(N)'
			
			gen loc_vers = ""
			gen loc_date = ""
			
			gen git_vers = ""
			gen git_date = ""
		}
		
		* for each program, find the loc version number and date as well as the github version
		forval i = 1/`prog_cnt' {
			frame frm_verdate: loc prg = program[`i']
			
			cap confirm file "`c(sysdir_plus)'i/`prg'.ado"
			if !_rc {
				mata: get_version("`c(sysdir_plus)'i/`prg'.ado")
				di regexm("`verdate'", "[1-4]\.[0-9]+\.[0-9]+")
				loc vers_num 	= regexs(0)
				di regexm("`verdate'", "[0-9]+[a-zA-Z]+[0-9]+")
				loc vers_date 	= regexs(0)
			
				frame frm_verdate: replace loc_vers = "`vers_num'" if program == "`prg'"
				frame frm_verdate: replace loc_date = "`vers_date'" if program == "`prg'"
			}
			
			mata: get_version("`url'/`branch'/ado/`prg'.ado")
			di regexm("`verdate'", "[1-4]\.[0-9]+\.[0-9]+")
			loc vers_num 	= regexs(0)
			di regexm("`verdate'", "[0-9]+[a-zA-Z]+[0-9]+")
			loc vers_date 	= regexs(0)
			
			frame frm_verdate: replace git_vers = "`vers_num'" if program == "`prg'"
			frame frm_verdate: replace git_date = "`vers_date'" if program == "`prg'"
		}
		
		frame frm_verdate {
			gen loc_vers_num = 	real(word(subinstr(loc_vers, ".", " ", .), 1)) * 100 + ///
								real(word(subinstr(loc_vers, ".", " ", .), 2)) * 10 + ///
								real(word(subinstr(loc_vers, ".", " ", .), 3))
			
			gen loc_date_num = date(loc_date, "DMY")
								
			gen git_vers_num = 	real(word(subinstr(git_vers, ".", " ", .), 1)) * 100 + ///
								real(word(subinstr(git_vers, ".", " ", .), 2)) * 10 + ///
								real(word(subinstr(git_vers, ".", " ", .), 3))
								
			gen git_date_num = date(loc_date, "DMY")
			
			format %td loc_date_num git_date_num
			
			* generate var to indicate if new version is available
			gen update_available = cond(git_date > loc_date | git_vers_num > loc_vers_num, "yes", "no")
			replace update_available = "" if missing(loc_date)
			
			gen current = loc_vers + " " + loc_date
			gen latest = git_vers + " " + git_date
			noi list program current latest update_available, noobs h sep(0) abbrev(32)
			
			count if update_available == "yes" 
			loc update_cnt `r(N)'
			if `update_cnt' > 0 {
				noi disp "Updates are available for `r(N)' programs."
			}
			count if update_available == ""
			loc new_cnt `r(N)'
			if `new_cnt' > 0 {
				noi disp "`r(N)' new programs available"
			}
			if `update_cnt' > 0 | `new_cnt' > 0 {
				noi disp "Click {stata ipaclean update:here} to update"
			}	
		}
	}

end

program define ipaclean_check, rclass

	version 17

    syntax, id(varname) [OUTFile(string) branch(string) url(string) replace]

    * declare temp names 
    tempvar dup row len

    * drop frames 
    cap frames drop frm_*

	qui {

		* check for duplicates on ID variable

		cap isid `id'
		if _rc == 459 {
			
			duplicates tag `id', gen(`dup')
			count if `dup'
		    
		    noi disp "`r(N)' duplicates found. id() variable `id' does not uniquely identify the observations."

			if "`outfile'" ~= "" {
				
				gen `row' = _n
				lab var `row' "row"
				sort `id' `row'
				export excel `row' `id' using "`outfile'" if `dup', first(varl) sheet("duplicates", replace)  

				drop `row'
				ipacolwidth using "`outfile'", sheet("duplicates")
			}

			drop `dup' 
		}

		* If ID variable is numeric, check that the length of ID variable is less 8 chars long
					
		cap confirm numeric variable `id'
		if !_rc {
			
			gen `len' = floor(log10(`id')) + 1
			capture assert `len' <= 7
			
			if _rc == 9 {
				
				noi disp "id() variable `id' has long numeric values. Long numeric values could be converted to scientific notation"
				if "`outfile'" != "" {
					
					export excel using "`outfile'", first(var) sheet("id length", replace)
					ipacolwidth using "`outfile'", sheet("id length")
		
				}
			}

		}
		else gen `len' = length(`id')

		* check that the len of the ID variables are the same 
		tab `len'
		if `r(r)' > 1 {
			
			noi disp "The length of id() variable `id' is not uniform. It is recommeded to IDs of the same characters length."
			
		}

		drop `len'

		* Check variable labels
		* Check that variable labels are not missing
		* Check that variable with labels of exactly 80 chars have longer notes

		* create frame
		frame create frm_variables str32 variable str80 label

		foreach var of varlist _all {

			frames post frm_variables ("`var'") ("`:var lab `var''")
	
		}

		* Check for use and labeling of extended missing values

		frame create frm_ext_miss str32 variables ext_miss_num labelled_miss

		ds, has(vallabel)
		
		foreach var of `r(varlist)' {
			
			* Check for extended missing values
			count if `var' >= .a & `var' <= .z
			loc extmiss_num `r(N)'
			
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

		*** Check for missing variable or value labels ***
		 
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
		
		* Check that variable labels that are exactly 80 chars has a 
		* longer variable name stored in notes 

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

mata: 
void get_version(string scalar program) {
	real scalar fh
	
    fh = fopen(program, "r")
    line = fget(fh)
    st_local("verdate", line) 
    fclose(fh)
}
end
