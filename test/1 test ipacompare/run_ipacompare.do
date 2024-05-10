
* Prep Stata

	clear all
	cls
	
	set seed 		16738
	set sortseed 	89384
	
	
	* Generate Master Dataset
	
	net install ipaclean, all replace from(C:\Users\IBaako\Documents\github\ipaclean)
	
	loc data "../0 test data/simulated data"

	ipacompare, id(hhid) date(submissiondate) keepmaster(sex) ///
				consent(consent, 1) outcome(complete, 1 2) ///
				m("`data'/Deworming Project - Master Dataset") ///
				s1("`data'/Deworming Project - Census", "Census") ///
				s2("`data'/Deworming Project - Baseline", "Baseline") ///
				s3("`data'/Deworming Project - Midline", "Midline") ///
				s4("`data'/Deworming Project - Endline", "Endline") ///
				outfile(compare.xlsx) replace
	* 