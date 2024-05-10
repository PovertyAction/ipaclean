ca{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 08may2024}{...}

{vieweralsosee "ipatracksurvey" "help ipatracksurvey"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ipaappend##syntax"}{...}
{viewerjumpto "Menu" "ipaappend##menu"}{...}
{viewerjumpto "Description" "ipaappend##description"}{...}
{viewerjumpto "Options" "ipaappend##options"}{...}
{viewerjumpto "Examples" "ipaappend##examples"}{...}

{p2colset 1 15 17 2}{...}
{p2col:{bf:ipacompare} {hline 2}}Compare Datasets across multiple rounds of survey{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:ipacompare}, id({help varname}) date({help varname}) 
s1({help filename} {cmd:,} "survey round") [s2({help filename} {cmd:,} "survey round") ... s10({help filename} {cmd:,} "survey round")] outfile("filename.xlsx") replace [{it:{help ipacompare##options:options}}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 15}{...}
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
outcome({help varname}, {help numlist}) specifies the survey outcome variable and values. This is useful for knowing if respondents were 
interviewed during the various survey rounds. {cmd:varname} specifies the name of the variable eg {cmd:survey_outcome} and numlist specifies values that indicate survey completeness eg. {cmd:1/2} or {cmd:2 3}. If {cmd:outcome()} is not specified, {cmd:ipacompare} defaults to not showing information about survey outcome.  

{phang}
consent({help varname}, {help numlist}) specifies the survey consent variable and values. This is useful for knowing if respondents consent was granted during the various survey rounds. {cmd:varname} specifies the name of the variable eg {cmd:consent_yn} and numlist specifies values that indicate valid consent eg. {cmd:1} or {cmd:2 3}. If {cmd:consent()} is not specified, {cmd:ipacompare} defaults to not showing information about survey consent.  

{phang}
masterdata({help filename}) specifies the master dataset that contains the details of each respondent to be interviewed. This dataset must contain 1 observation for each targeted respondent and must be unique by id()). If {cmd:masterdata()} is not specified, {cmd:ipacompare} will create a master dataset by making a list of all from all survey rounds.  

{phang}
{opth keepmaster(varlist)} specifies additional variables to be kept from the master dataset. By default, only the {cmd:id()} is kept. 


{marker examples}{...}
{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. webuse even}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. webuse odd}{p_end}
{phang2}{cmd:. list}

{pstd}Append even data to the end of the odd data{p_end}
{phang2}{cmd:. ipaappend using https://www.stata-press.com/data/r18/even}{p_end}

{pstd}List the results{p_end}
{phang2}{cmd:. list}

    {hline}
    Setup
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep if foreign == 0}{p_end}
{phang2}{cmd:. tostring price, replace}{p_end}
{phang2}{cmd:. save domestic}{p_end}
{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. keep if foreign == 1}{p_end}

{pstd}Appending domestic car data to the end of the foreign car data using the 
native append command will result in an error as price is "string" in master and 
"numeric" in appending dataset. Using the force option will result in losing data 
from the appending dataset. Using {cmd:ipaappend's} safely option can append the 
datasets without lose of data{p_end}
{phang2}{cmd:. ipaappend using domestic, outfile("append_report.xlsx") safely replace}{p_end}

{text}
{title:Author}

{pstd}Arsène Baowendmanegré Zongo & Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Related Help Files: {help ipaclean:ipaclean}, {help ipamerge:ipamerge}, {help append:[D] append}