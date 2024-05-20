*! version 1.0.0 16may2024
*! Innovations for Poverty Action
* ipaclean: IPA Stata Package for Data Cleaning

program ipahelper, rclass
	
	version 17
	
	syntax 	name(name=subcmd id="sub command") [,BRanch(name) force]

	qui {
		if !inlist("`subcmd'", "version", "update") {
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

		noi ipaclean_`subcmd', branch(`branch') url(`url')
		
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
		file open `pkg' using "`url'/`branch'/ipahelper.pkg", read
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

mata: 
void get_version(string scalar program) {
	real scalar fh
	
    fh = fopen(program, "r")
    line = fget(fh)
    st_local("verdate", line) 
    fclose(fh)
}
end


