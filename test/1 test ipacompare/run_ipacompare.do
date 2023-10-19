
* Prep Stata

	clear all
	cls
	
	set seed 		16738
	set sortseed 	89384
	
	
	* Generate Master Dataset
	
	qui include ipacompare.ado
	ipacompare, id(id) date(submissiondate) keepmaster(respondentname sex) ///
				consent(consent, 1) outcome(complete, 1 2) ///
				m("simulated data/Deworming Project - Master Dataset") ///
				s1("simulated data/Deworming Project - Census", "Census") ///
				s2("simulated data/Deworming Project - Baseline", "Baseline") ///
				s3("simulated data/Deworming Project - Midline", "Midline") ///
				s4("simulated data/Deworming Project - Endline", "Endline") ///
				outfile(compare.xlsx) replace
				
				
	* 
	
	