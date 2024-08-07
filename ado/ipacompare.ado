*! version 1.0.0 18jul2024
*! Innovations for Poverty Action

program define ipacompare, rclass
	
	#d;
	syntax, 
		id(name)
		date(name)
		[OUTCome(string)]
		[CONSent(string)]
		[Masterdata(string) KEEPMaster(namelist)] 
		s1(string)
		[s2(string)
		s3(string)
		s4(string)
		s5(string)
		s6(string)
		s7(string)
		s8(string)
		s9(string)
		s10(string)]
		OUTFile(string) replace
		;
		#d cr

	version 17	
	
	qui {

		preserve
		
		* tempfiles 
		tempfile tmf_master tmf_using
		
		* tempvars 
		tempvar tmv_consent_yn tmv_subdate tmv_submitted
		
		* create dummies locals for options
		loc _cons 	= "`consent'" 	~= ""
		loc _outc 	= "`outcome'" 	~= ""
		
		* consent: consent(consent, 1) or consent(consent, 1 2 3)
		if `_cons' {
			gettoken consent_var consent_vals: consent, parse(,)
			loc consent_vals = subinstr("`consent_vals'", ",", "", .)
			if "`consent_var'" == "" | "`consent_vals'" == "" {
				disp as err "option consent() incorrectly specified."
				ex 198
			}
			foreach val in `consent_vals' {
				cap confirm number `val'
				if _rc == 7 {
					disp as err "Invalid value `val' specified in option consent(). Numeric value expected"
					ex 198
				}
				else loc consent_vals_com = cond(missing("`consent_vals_com'"), "`val'", "`consent_vals_com', `val'")
			}
		}
		
		* outcome: outcome(outcome, 1) or outcome(outcome, 1 2 3)
		if `_cons' {
			gettoken outcome_var outcome_vals: outcome, parse(,)
			loc outcome_vals = subinstr("`outcome_vals'", ",", "", .)
			if "`outcome_var'" == "" | "`outcome_vals'" == "" {
				disp as err "option outcome() incorrectly specified."
				ex 198
			}
		
			foreach val in `outcome_vals' {
				cap confirm number `val'
				if _rc == 7 {
					disp as err "Invalid value `val' specified in option outcome(). Numeric value expected"
					ex 198
				}
				else loc outcome_vals_com = cond(missing("`outcome_vals_com'"), "`val'", "`outcome_vals_com', `val'")
			}
			
		}
		
		* mark the number of survey rounds specified 
		forval i = 1/10 {
			if "`s`i''" ~= "" loc srs = trim(itrim("`srs' `i'"))
		}
		
		* Check syntax
		* Check that if master is not specified, at least 2 survey rounds are specified

		if "`masterdata'" == "" & wordcount("`srs'") == 1 {
			disp as err "at least 2 survey rounds mist be specified if no masterdata is specified"
			ex 198
		}
		else if "`masterdata'" == "" & wordcount("`srs'") > 1 {
			
			* create masterdata of IDs if masterdata was not specified
			loc i 1
			foreach sr of numlist `srs' {

				gettoken filename desc : s`sr', p(,)
				
				loc filename`sr' = trim("`filename'")
				importfile using "`filename`sr''"
				
				keep `id'
				if `i' > 1 merge 1:1 `id' using "`tmf_master'", nogen
				save "`tmf_master'", replace

				loc ++i
			}
			
			loc masterdata = "`tmf_master'"
		}
		
		* --------------------------------
		* Create Summary & Variables Sheet
		* --------------------------------
		
		* Create Frames 
		
		cap frame drop frm_*
		
			* Summary Frame
			#d;
			frame create frm_summ 
				int round 
				str10 desc 
				long (vars vars_nomiss vars_allmiss obs miss consent complete days firstdate lastdate)
			;
			#d cr
			
			frame frm_summ: set obs `:word count `srs''
			
			* Variables Frame
			
			frame create frm_vars str32 varname
			
		* Loop through datasets and create information needed
		
		loc i 1
		foreach sr of numlist 0 `srs' {
			
			if !`sr' loc filename`sr' = "`masterdata'"
			else {
				
				gettoken filename`sr' desc : s`sr', p(,)
				loc filename`sr' = trim("`filename`sr''")
				loc desc`sr' 	 = trim(itrim(subinstr("`desc'", ",", "", 1)))
			}
			
			if `sr' > 0 {
				
				importfile using "`filename`sr''"
				
				loc vars = `c(k)'
				loc obs  = `c(N)'
			
				misscount _all
				loc miss `r(miss)'
				loc nomiss `r(nomiss)'
				loc allmiss `r(allmiss)'
				
				ipagettd `date'
				su `date'
				loc firstdate `r(min)'
				loc lastdate  `r(max)'
				
				tab `date'
				loc days `r(r)'
				
				if `_cons' count if inlist(`consent_var', `consent_vals_com')
				loc consent `r(N)'
				
				if `_outc' count if inlist(`outcome_var', `outcome_vals_com')
				loc complete `r(N)'
				
				frame frm_summ {
					replace round 		  = `sr' 	 				in `i'
					replace desc  		  = "`desc`sr''" 			in `i'
					replace vars  		  = `vars' 	 				in `i'
					replace vars_nomiss   = `nomiss'      			in `i'
					replace vars_allmiss  = `allmiss'     			in `i'
					replace obs   		  = `obs' 	 				in `i'
					replace miss  		  = `miss' 					in `i'
					replace days  		  = `days' 	 				in `i'
					replace firstdate 	  = `firstdate' 			in `i'
					replace lastdate 	  = `lastdate' 				in `i'
					if `_cons' replace consent     = `consent'      in `i'
					if `_outc' replace complete    = `complete'     in `i'
					
					format %td firstdate lastdate
				}
				
				* Populate variable frame
				
				loc var_count `c(k)'
				loc obs_count `c(N)'
				
				frame frm_vars {
					gen varl`sr' = ""
					gen vall`sr' = ""
					gen misn`sr' = .
					gen unqn`sr' = .
					
					lab var varl`sr' "label"
					lab var vall`sr' "value label"
					lab var misn`sr' "# miss"
					lab var unqn`sr' "# uniq"
				}
				
				foreach var of varlist _all {
					
					loc varlab = "`:var lab `var''"
					loc vallab = "`:val lab `var''"
					
					count if missing(`var')
					loc misscnt = `r(N)'
					
					qui tab `var'
					loc uniqcnt = `r(r)'
					
					frame frm_vars {

						count if varname == "`var'"
						if `r(N)' == 0 {
							set obs `=`=_N' + 1'
							replace varname = "`var'" in `=_N'
						}
						
						replace varl`sr' = "`varlab'"	if varname == "`var'"
						replace vall`sr' = "`vallab'"	if varname == "`var'"
						replace misn`sr' = `misscnt'	if varname == "`var'"
						replace unqn`sr' = `uniqcnt'	if varname == "`var'"
					}
					
				}
				
				loc ++i
			}
		}
		
		* export summary sheet
		frame frm_summ {
			
			* label variables
			lab var round				"round"			
			lab var desc				"description"
			lab var vars				"# vars"
			lab var vars_nomiss			"# nomiss vars"	
			lab var vars_allmiss		"# allmiss vars"		
			lab var obs				    "# obs"
			lab var miss				"# miss values"
			lab var consent				"# consented"
			lab var complete			"# completed"	
			lab var days				"# days"
			lab var firstdate			"first date"	
			lab var lastdate			"last date"	
			
			if !`_cons' drop consent
			if !`_outc' drop complete
			
			export excel using "`outfile'", sheet("summary") replace first(varl)
			
			iparowformat using "`outfile'", sheet("summary") type(header)
			ipacolwidth using "`outfile'", sheet("summary")
			if `_cons' loc vars "consent"
			if `_outc' loc vars "`vars' complete"
			ipacolformat using "`outfile'", sheet("summary") vars(round vars vars_nomiss vars_allmiss obs miss `vars') format("number_sep")
			ipacolformat using "`outfile'", sheet("summary") vars(firstdate lastdate) format("date_d_mon_yy")
		}
		
		* export variables sheet 
		frame frm_vars {
			
			export excel using "`outfile'", sheet("variables") first(varl) cell(A2)
			ipacolwidth using "`outfile'", sheet("variables")

			ipacolformat using "`outfile'", sheet("variables") vars(misn* unqn*) format(number_sep)
			
			loc headers = ""
			foreach sr of numlist `srs' {
				if missing(`"`headers'"') loc headers = char(34)  + "`desc`sr''" + char(34)
				else loc headers = `"`headers'"' + "," + char(34)  + "`desc`sr''" + char(34) 
			}
			
			mata: format_ipc_variables("`outfile'", "variables", (`headers'))
			
		} 

		frame drop frm_summ frm_vars
		
		* -----------------------
		* Create tracking Sheet
		* -----------------------
			
		use `id' `keepmaster' using "`masterdata'", clear
		
		foreach var of varlist _all {
			lab var `var' "`var'"
		}
		
		save "`tmf_master'", replace
		
		* loop through and merge info from other forms
		foreach sr of numlist `srs' {
		
			importfile using "`filename`sr''"
			keep `id' `date' `consent_var' `outcome_var'
			
			order `id' `date' `outcome_var' `consent_var'
			
			ipagettd `date'
		
			ren `date' date`sr'
			lab var date`sr' "`date'"
			
			if `_cons' {
				ren `consent_var' consent`sr'
				lab var consent`sr' "`consent_var'"
				gen consent_yn`sr' = inlist(consent`sr', `consent_vals_com')
			}
			if `_outc' {
				ren `outcome_var' outcome`sr'
				lab var outcome`sr' "`outcome_var'"
				gen outcome_yn`sr' = inlist(consent`sr', `outcome_vals_com')
			}
			
			save "`tmf_using'", replace
			
			use "`tmf_master'", clear
			merge 1:1 `id' using "`tmf_using'", nogen 
			
			save "`tmf_master'", replace
			
		}
		
		egen `tmv_submitted' = rownonmiss(date*)
		lab var `tmv_submitted' "# submitted"
		
		order `tmv_submitted', before(date1)
		
		if `_cons' {
			egen consent_n = rowtotal(consent_yn*)
			drop consent_yn*
			lab var consent_n "# consent"
			order consent_n, before(date1)
		}
		if `_outc' {
			egen outcome_n = rowtotal(outcome_yn*)
			drop outcome_yn*
			lab var outcome_n "# completed"
			order outcome_n, before(date1)
		}
		
		export excel using "`outfile'", sheet("tracking") first(varl) cell(A2)
		ipacolwidth using "`outfile'", sheet("tracking")
		
		loc vars = ""
		ds, has(format %td)
		ipacolformat using "`outfile'", sheet("tracking") vars(`r(varlist)') format("date_d_mon_yy")
		
		mata: st_local("n", strofreal(st_varindex("date1")))
		noi mata: format_ipc_tracking("`outfile'", "tracking", (`headers'), `n', `=`_cons' + `_outc'')

	}

end

* Import file
program define importfile 

	syntax using/
	
	loc ext = substr("`using'", -strpos(reverse("`using'"), "."), .)
	
	if "`ext'" == ".xlsx" | "`ext'" == ".xls" {
		import excel using "`using'", first clear 
	}
	else if "`ext'" == ".csv" {
		import delim using "`using'", clear varnames(1)
	}
	else {
		use "`using'", clear
	}

end 

* calculate number of missing values
program define misscount, rclass

	syntax varlist
	
	loc misscount = 0
	loc nomiss    = 0
	loc allmiss   = 0
	foreach var of varlist `varlist' {
		count if missing(`var') 
		if `r(N)' == 0 		loc ++nomiss
		if `r(N)' == `=_N' 	loc ++allmiss
		loc misscount = `misscount' + `r(N)'
	}
	
	return local miss = `misscount'
	return local nomiss = `nomiss'
	return local allmiss = `allmiss'
	
end

* mata program for formatting variables column
mata:
mata clear

void format_ipc_variables (string scalar file, string scalar sheet, string vector headers)

{
	real scalar i
	class xl scalar b
	b = xl()
	b.load_book(file)
	b.set_sheet(sheet)
	b.set_mode("open")
	
	real scalar n
	
	b.set_font_bold((1, 2), (1, st_nvar()), "on")
	b.set_font_italic((1, 2), (1, st_nvar()), "on")
	b.set_bottom_border((2, 2), (1, st_nvar()), "medium")
	b.set_left_border((1, st_nobs() + 2), (2, 2), "thin")
	
	n = 2
	
	for (i = 1; i <= length(headers); i++) {
		
		startcol = n
		
		b.put_string(1, n, headers[i])
		
		b.set_sheet_merge(sheet, (1, 1), (n, n + 3))
		b.set_horizontal_align((1, 1), (n, n + 4), "center")
		
		b.set_left_border((1, st_nobs() + 2), (n + 4, n + 4), "thin")
		
		n = n + 4
	}
	
	b.close_book()
}

void format_ipc_tracking (string scalar file, string scalar sheet, string vector headers, real scalar n, real scalar adj)

{
	real scalar i
	class xl scalar b
	b = xl()
	b.load_book(file)
	b.set_sheet(sheet)
	b.set_mode("open")
	
	b.set_font_bold((1, 2), (1, st_nvar()), "on")
	b.set_font_italic((1, 2), (1, st_nvar()), "on")
	b.set_bottom_border((2, 2), (1, st_nvar()), "medium")
	b.set_left_border((1, st_nobs() + 2), (2, 2), "thin")
	
	for (i = 1; i <= length(headers); i++) {
	
		b.put_string(1, n, headers[i])
		b.set_sheet_merge(sheet, (1, 1), (n, n + adj))
		b.set_horizontal_align((1, 1), (n, n + adj), "center")
		b.set_left_border((1, st_nobs() + 2), (n, n), "thin")
		n = n + adj + 1
	}
	
	b.close_book()
}

end

