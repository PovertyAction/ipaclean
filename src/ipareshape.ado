
program define ipareshape, rclass
    
	#d;
		syntax anything,
		i(varname)
		j(name)
	;
	#d cr 
	
	qui {
		
		* Parse input
		gettoken rtype stubs : anything
		
		loc ivar `i'
		loc jvar `j'
		
		* Make sure we are either reshaping long or wide
		if !inlist("`rtype'", "long", "wide") {
			disp as err "Invalid syntax: In the reshape command that you typed, you omitted the word wide or long"
			ex 198
		}

		* For Reshape Long:
		if "`rtype'" == "long" {
			
			* check that jvar is new
			cap confirm var `jvar'
			if !_rc {
				disp as error "Invalid Syntax: variable `jvar' already exist"
				ex 198
			}
			
			* check that ivar is unique
			isid `ivar'
			
		}
		
		* For reshape long
		if "`rtype'" == "wide" {
			* check that jvar exist
			confirm var `jvar'
			
			* check that ivar and jvar combine to create a unique id
			isid `ivar' `jvar'
		}

		* Reshape to long
		
		 if "`rtype'" == "long" {
				
				* current frame name
				local curframe = c(frame)
				
				* drop all frame name starting with frm_*
				capture frame drop frm_*

				* create a list of all stubs variable list and pattern after stubs key word
				local stub_var
				local j_var 
				local stub_val_list
 				foreach stub in `stubs' {
					unab stub_list: `stub'?*			
					local stub_var `stub_var' `stub_list'
					local stub_len=strlen("`stub'")
					foreach var in `stub_list' {
						local j_value=substr("`var'", `stub_len' + 1 , .)
						local stub_val=substr("`var'", 1 , `stub_len')
						local stub_val_list `stub_val_list' `stub_val'
						local j_var `j_var' `j_value'
					}
				}
				
				local j_var: list uniq j_var
				local j_len: word count `j_var'
				
				*  create a frame with stubs variable and stubs key word
				frame create frm_stub `stub_var'
				frame frm_stub: {
					ds
					local var_len: word count `r(varlist)'
					tostring *, replace
					set obs 1
					
					forvalues val=1/`var_len' {
						local curr_val: word `val' of `stub_val_list'
						local curr_var: word `val' of `stub_var'
						replace `curr_var' = "`curr_val'"
					}
				}
				
			
			
				* create different frame for j different values
				ds `stub_var', not
				local no_stub `r(varlist)'
				local num 0
				foreach stub_j_var in `j_var' {
					local ++num
					frame frm_stub: ds *`stub_j_var'
					local stub_curr `r(varlist)'
					frame put `no_stub' `stub_curr', into(frm_`num')
					 frame frm_`num': gen `jvar' = `stub_j_var'
						foreach stub_curr_name in `stub_curr' {
							frame frm_stub: local stub_final_name=`stub_curr_name'[1]
							frame frm_`num': rename `stub_curr_name' `stub_final_name'
						}
						
					* Generate missing values for variables stubs that do not have certain values j
					frame frm_`num': ds `no_stub' `jvar', not
					local final_stub `r(varlist)'
					foreach unuse_var in `stubs' {
						if !strpos("`final_stub'", "`unuse_var'") {
							ds `unuse_var'*
							local unuse_varlist `r(varlist)'
							capture confirm numeric variable `unuse_varlist'
							if !_rc {
									frame frm_`num': gen `unuse_var' = .
							}
							else {
									frame frm_`num': gen `unuse_var' = ""
							}
									
						}
					}
																
								
				}
				
				
				* appending all frames 
				frame change frm_1
				frame drop `curframe'
				
				forvalues val=2/`j_len' {
					
					myfrappend _all, from(frm_`val')
					capture frame drop frm_`val'
				}
				
				frame rename frm_1 `curframe'
				frame drop frm_stub
				
				order `jvar',  last
				
		}
		
		else {
			
			* current frame name
			local curframe = c(frame)
			
			* drop all frame name starting with frm_*
			capture frame drop frm_*
			
			* create a list of all stubs variable list and pattern after stubs key word
			local stub_var
			local stub_val_list
			foreach stub in `stubs' {
				ds `stub'*
				local stub_list `r(varlist)'			
				local stub_var `stub_var' `stub_list'
				}
			
			local num 0
			
			ds `stub_var' `jvar', not
			local no_stub `r(varlist)'
			
			levelsof `jvar',   local(j_values)
			foreach j_val in `j_values' {
				local ++num
				frame put `no_stub' `stub_var' if `jvar'== `j_val', into(frm_`num')
				frame frm_`num' : {
					foreach var in `stub_var' {
						rename `var' `var'`j_val'
					}
				
				}
			}
			
			
			
			frame change frm_1
			forvalues n=2/`num' {
				frlink 1:1 `ivar', frame(frm_`n') gen(lk_`n')
				frame frm_`n' : ds `stub_var'
				frget `r(varlist)' , from(lk_`n')
				frame drop  frm_`n'
			}
			
			drop lk_*
			frame drop  `curframe'
			frame rename  frm_1 `curframe'		
	}
	
}

end

program myfrappend
	version 17

	syntax varlist, from(string)

	confirm frame `from'

	foreach var of varlist `varlist' {
		confirm var `var'
		frame `from' : confirm var `var'
	}

	frame `from': local obstoadd = _N

	local startn = _N+1
	set obs `=_N+`obstoadd''

	foreach var of varlist `varlist' {
	   quietly replace `var' = _frval(`from',`var',_n-`startn'+1) in `startn'/L
	}
	
end