

clear all

set obs 5


gen double v1 = 123456789.1

loc locl: format v1
di "`locl'"

tostring v1, gen(v2) format("`locl'")
list v1 v2
e

// tostring works with float == 7 digits and double == 10 digits
// tostring cannot work with variables that have more than 10 digits
//double has max 16 digits of precision

/*
//colmax(strlen(st_sdata(. , .)))
mata: colmax(strlen(st_sdata(. , "v3")))
mata: colmax(strlen(st_sdata(. , .)))
*/

/*


gen v2 = "arso"
gen v3 = "queensess"
replace v3 = "queensesss" if _n == 4
*/