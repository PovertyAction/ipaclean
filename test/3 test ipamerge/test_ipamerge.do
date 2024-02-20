

* run to test

ipamerge 1:1 make using "using1" "using2", mastertype safely outfile("my file 9") detail //safely  //nol gen(sdfg) //nogen

e

merge 1:1 make using using1, keepusing(make v1_school) force


e

create frame returntab {
	
	gen 
	
	
	
}












e
						count if using`i'_tmatch == 1
						loc using`i'_nbtmatch `r(N)'
						count if !missing(using`i'_type) //ici
						loc using`i'_nbvar `r(N)'
						loc using`i'_ready = (`using`i'_nbtmatch' == `using`i'_nbvar')
						
						
e
noi merge `mtype' `varlist' using "`using`i''", gen(`generate') ///
										//`nolabel' `nonotes' `keep2'		