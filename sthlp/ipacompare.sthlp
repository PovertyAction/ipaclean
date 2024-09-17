ca{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 18jul2024}{...}

{vieweralsosee "ipatracksurvey" "help ipatracksurvey"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ipaappend##syntax"}{...}
{viewerjumpto "Description" "ipaappend##description"}{...}
{viewerjumpto "Options" "ipaappend##options"}{...}
{viewerjumpto "Examples" "ipaappend##examples"}{...}

{p2colset 1 15 17 2}{...}
{p2col:{bf:ipacompare} {hline 2}}Compare Datasets across multiple rounds of survey data collection{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:ipacompare}, id({help varname}) date({help varname}) 
s1({help filename} {cmd:,} "survey round") [s2({help filename} {cmd:,} "survey round") ... s10({help filename} {cmd:,} "survey round")] outfile({help filename}) replace [{it:{help ipacompare##options:options}}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt :{cmd:{ul:outc}ome({help varname}}, {help numlist})}survey outcome variable and values{p_end}
{synopt :{cmd:{ul:cons}ent({help varname}}, {help numlist})}survey consent variable and values{p_end}
{synopt :{opth m:asterdata(filename)}}master dataset with information of all respondents{p_end}
{synopt :{opth keepm:aster(varlist)}}variables from master data to keep in report{p_end}
{synoptline}
{p2colreset}{...}


{marker menu}{...}
{title:Menu}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ipacompare} offers and easy way to track and compare datasets across multiple survey rounds. {cmd:ipacompare} 
generates an Excel report, highlighting the survey completion rates across the different rounds of data collection 
as well as highlighting the completeness of the data across different data collection rounds.
{p_end}

{marker options}{...}
{title:Options}

{phang}
{cmd:outcome(}{help varname}, {help numlist}{cmd:)} specifies the survey outcome variable and values. This is useful for knowing if respondents were interviewed in all survey rounds. {cmd:varname} specifies the name of the variable eg {cmd:survey_outcome} and numlist specifies values that indicate survey completeness eg. {cmd:1/2} or {cmd:2 3}. If {cmd:outcome()} is not specified, the report will not show information about survey outcome.  

{phang}
{cmd:consent(}{help varname}, {help numlist}{cmd:)} specifies the survey consent variable and values. When speicified, the report will include information about consent for each respondent as well as consent rates per survey round. {cmd:varname} specifies the name of the variable that indicates consent eg {cmd:consent_yn} and numlist specifies values that indicate valid consent eg. {cmd:1} or {cmd:2 3}. 

{phang}
{opth masterdata(filename)} specifies the master dataset that contains the details of each respondent to be interviewed. This dataset must contain 1 observation for each targeted respondent and must be unique by the variable specified in {cmd:id()}. If {cmd:masterdata()} is not specified, {cmd:ipacompare} will create a master dataset by making a list of all IDs from all survey rounds.  

{phang}
{opth keepmaster(varlist)} specifies additional variables to be kept from the master dataset. By default, only the {cmd:id()} is kept. 


{marker examples}{...}
{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. unzipfile "https://raw.github.com/PovertyAction/ipaclean/main/data/ipacompare_test_data.zip"}{p_end}

{pstd}Compare data from 4 rounds of data collection to a master dataset{p_end}
{phang2}. ipacompare, id(hhid) date(submissiondate) keepmaster(sex) consent(consent, 1) outcome(complete, 1 2) m("Deworming Project - Master Dataset") s1("Deworming Project - Census", "Census") s2("Deworming Project - Baseline", "Baseline") s3("Deworming Project - Midline", "Midline") s4("Deworming Project - Endline", "Endline") outfile(compare.xlsx) replace{p_end}

{pstd}Compare data from 4 rounds of data collection without a master dataset{p_end}
{phang2}. ipacompare, id(hhid) date(submissiondate) consent(consent, 1) outcome(complete, 1 2) s1("Deworming Project - Census", "Census") s2("Deworming Project - Baseline", "Baseline") s3("Deworming Project - Midline", "Midline") s4("Deworming Project - Endline", "Endline") outfile(compare.xlsx) replace{p_end}

{text}
{title:Author}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Related Help Files: {help ipaclean:ipaclean}, {help ipatracksurvey:ipatracksurvey}