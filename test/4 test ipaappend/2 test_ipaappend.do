* set the working directory
gl arsene "C:/Users/Arsene Zongo/Box/Az/Github"
cd "${arsene}/ipaclean/test/4 test ipaappend/1 test data"

* run to test
ipaappend using "using1" "using2", safely outfile("myoutfile1") //details report keepusing(v1_school v2_dir) nol
