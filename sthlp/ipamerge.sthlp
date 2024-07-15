{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 15jul2024}{...}

{vieweralsosee "[D] merge" "help merge"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] append" "help append"}{...}
{vieweralsosee "[D] cross" "help cross"}{...}
{vieweralsosee "[D] fralias" "help fralias"}{...}
{vieweralsosee "[D] frget" "help frget"}{...}
{vieweralsosee "[D] frlink" "help frlink"}{...}
{vieweralsosee "[D] frunalias" "help frunalias"}{...}
{vieweralsosee "[D] joinby" "help joinby"}{...}
{vieweralsosee "[D] save" "help save"}{...}
{viewerjumpto "Syntax" "ipamerge##syntax"}{...}
{viewerjumpto "Description" "ipamerge##description"}{...}
{viewerjumpto "Options" "ipamerge##options"}{...}
{viewerjumpto "Examples" "ipamerge##examples"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:ipamerge} {hline 2}}Safely merge datasets{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
One-to-one merge on specified key variables

{p 8 15 2}
{opt ipamerge} {cmd:1:1} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
Many-to-one merge on specified key variables

{p 8 15 2}
{opt ipamerge} {cmd:m:1} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
One-to-many merge on specified key variables 

{p 8 15 2}
{opt ipamerge} {cmd:1:m} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
Many-to-many merge on specified key variables

{p 8 15 2}
{opt ipamerge} {cmd:m:m} {varlist} 
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{pstd}
One-to-one merge by observation

{p 8 15 2}
{opt ipamerge} {cmd:1:1 _n}
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opth keepus:ing(varlist)}}variables to keep from using data;
     default is all
{p_end}
{...}
{synopt :{opth gen:erate(newvar)}}name of new variable to mark merge
      results; default is {cmd:_merge}
{p_end}
{...}
{synopt :{opt nogen:erate}}do not create {cmd:_merge} variable
{p_end}
{...}
{synopt :{opt nol:abel}}do not copy value-label definitions from using{p_end}
{...}
{synopt :{opt nonote:s}}do not copy notes from using{p_end}
{...}
{synopt :{opt update}}update missing values of same-named variables in master
     with values from using
{p_end}
{...}
{synopt :{opt replace}}replace all values of same-named variables in master
     with nonmissing values from using (requires {cmd:update})
{p_end}
{...}
{synopt :{opt norep:ort}}do not display match result summary table
{p_end}
{synopt :{opt merger:eport}}check if datasets can merged without error
{p_end}
{synopt :{opt safely}}merge data safely
{p_end}
{synopt :{opt outf:ile("file.xlsx"[,replace])}}save report to Excel workbook with option to replace
{p_end}
{synopt :{opt det:ails}}include number and percentage of missing and unique in report file
{p_end}

{syntab: Results}
{synopt :{cmd:assert(}{help merge##results:{it:results}}{cmd:)}}specify required match results
{p_end}
{...}
{synopt :{cmd:keep(}{help merge##results:{it:results}}{cmd:)}}specify which match results to keep
{p_end}
{...}

{synopt :{opt sorted}}do not sort; datasets already sorted
{p_end}
{...}
{synoptline}
{p2colreset}{...}


{marker menu}{...}
{title:Menu}

{phang}
{bf:Data > Safely Combine datasets > Merge two datasets}


{marker description}{...}
{title:Description}

{pstd}
{cmd:merge} joins corresponding observations from the dataset currently in
memory (called the master dataset) with those from
{it:{help filename}}{cmd:.dta}
(called the using dataset), matching on one or more key variables.  {cmd:ipamerge}
can perform match merges (one-to-one, one-to-many, many-to-one, and
many-to-many), which are often called 'joins' by database people. {cmd:ipamerge} provides 
a safer way to merge datasets without loosing data or running into errors caused by differences in 
variable types.  
 
{pstd}
Key variables cannot be {helpb data types:strL}s.

{pstd}
If {it:filename} is specified without an extension, then {cmd:.dta} is assumed. 

{marker options}{...}
{title:Options}

{phang}
{opth keepusing(varlist)}
    specifies the variables from the using dataset that are kept
    in the merged dataset. By default, all variables are kept. 
    For example, if your using dataset contains 2,000
    demographic characteristics but you want only
    {cmd:sex} and {cmd:age}, then type {cmd:merge} ...{cmd:,}
    {cmd:keepusing(sex} {cmd:age)} ....

{phang}
{opth generate(newvar)} specifies that the variable containing match
      {help merge##results:results} information should be named {it:newvar}
      rather than {cmd:_merge}.

{phang}
{cmd:nogenerate} specifies that {cmd:_merge} not be created.  This
    would be useful if you also specified {cmd:keep(match)}, because
    {cmd:keep(match)} ensures that all values of {cmd:_merge} would be 3.

{phang}
{cmd:nolabel}
    specifies that value-label definitions from the using file be ignored.
    This option should be rare, because definitions from the master are
    already used.

{phang}
{cmd:nonotes}
    specifies that notes in the using dataset not be added to the 
    merged dataset; see {manhelp notes D:notes}.

{phang}
{cmd:update} and {cmd:replace}
    both perform an update merge rather than a standard merge.
    In a standard merge, the data in the master are
    the authority and inviolable.  For example, if the master
    and using datasets both contain a variable {cmd:age}, then
    matched observations will contain values from the master
    dataset, while unmatched observations will contain values
    from their respective datasets.

{pmore}
    If {cmd:update} is specified, then matched observations will update missing
    values from the master dataset with values from the using dataset.
    Nonmissing values in the master dataset will be unchanged.

{pmore}
    If {cmd:replace} is specified, then matched observations will contain
    values from the using dataset, unless the value in the using dataset
    is missing. 

{pmore}
    Specifying either {cmd:update} or {cmd:replace} affects the meanings of the
    match codes. See
    {mansection D mergeRemarksandexamplesTreatmentofoverlappingvariables:{it:Treatment of overlapping variables}}
    in {bf:[D] merge} for details.

{phang}
{cmd:noreport}
    specifies that {cmd:merge} not present its summary table of
    match results.

{phang}
{opt mergereport} checks if the datasets can be merged without the force option and 
reports the result in Stata's result window. optionally, users may specify the {cmd:outfile()}
option to get a more detailed report in excel. If the file already exist, the users must specify the option replace eg. {cmd:outfile("mergereport.xlsx", replace)} to overwrite the existing file.

{phang}
{opt safely} merges the dataset in memory without the loss of data that will result from 
using the {cmd:force} option with Stata's native {help:merge} command. When {cmd:safely()} 
is specified, {cmd:ipaappend} will assess all datasets, and for each variable, change the {help type:data type} 
to the type that will preserve the values accross all datasets. For example, assuming the "price" 
variable is numeric in the master dataset and string in the using dataset, {ipamerge} will 
convert price to a numeric dataset in the using dataset. In a situation that "price" cannot be converted to 
a numeric, then {cmd:ipaappend} will convert "price" in the master dataset to a string variable, ensuring that 
the data can be merged without loss of information.    

{phang}
{opt outfile} must be used with the mergereport or safely option. Saves an excel workbook of the append 
report generated by {cmd:ipaappend} 

{phang}
{opt details} must be used with the {cmd:outfile()} option. includes number and percentage of missingness and 
uniqueness to the merge report 

{dlgtab:Results}

{phang}
{cmd:assert(}{it:results}{cmd:)}
    specifies the required match results.  The possible
    {it:results} are 

{marker results}{...}
           Numeric    Equivalent
            code      word ({it:results})     Description
           {hline 67}
              {cmd:1}       {cmdab:mas:ter}             observation appeared in master only
              {cmd:2}       {cmdab:us:ing}              observation appeared in using only
              {cmd:3}       {cmdab:mat:ch}              observation appeared in both

              {cmd:4}       {cmdab:match_up:date}       observation appeared in both,
{col 44}missing values updated
              {cmd:5}       {cmdab:match_con:flict}     observation appeared in both,
{col 44}conflicting nonmissing values
           {hline 67}
           Codes 4 and 5 can arise only if the {cmd:update} option is specified.
	   If codes of both 4 and 5 could pertain to an observation, then 5 is
           used.

{pmore}
Numeric codes and words are equivalent when used in the {cmd:assert()}
or {cmd:keep()} options.

{pmore}
The following synonyms are allowed:
{cmd:masters} for {cmd:master}, 
{cmd:usings} for {cmd:using},
{cmd:matches} and {cmd:matched} for {cmd:match},
{cmd:match_updates} for {cmd:match_update}, 
and 
{cmd:match_conflicts} for {cmd:match_conflict}. 

{pmore}
    Using {cmd:assert(match master)} specifies that the merged file is
    required to include only matched master or using 
    observations and unmatched master observations, and may not 
    include unmatched using observations.  Specifying {cmd:assert()}
    results in {cmd:merge} issuing an error message if there are match results
    you did not explicitly allow.

{pmore}
The order of the words or codes is not important, so all the following
{cmd:assert()} specifications would be the same:

{pmore2}
{cmd:assert(match master)}

{pmore2}
{cmd:assert(master matches)}

{pmore2}
{cmd:assert(1 3)}

{pmore}
    When the match results contain codes other than those allowed,
    return code 9 is returned, and the 
    merged dataset with the unanticipated results is left in memory
    to allow you to investigate.

{phang}
{cmd:keep(}{help ipamerge##results:{it:results}}{cmd:)}
    specifies which observations are to be kept from the merged dataset.
    Using {cmd:keep(match master)} specifies keeping only
    matched observations and unmatched master observations after merging.

{pmore}
    {cmd:keep()} differs from {cmd:assert()} because it selects
    observations from the merged dataset rather than enforcing requirements.
    {cmd:keep()}
    is used to pare the merged dataset to a given set of observations when
    you do not care if there are other observations in the merged dataset.
    {cmd:assert()} is used to verify that only a given set of observations
    is in the merged dataset.

{pmore}
   You can specify both {cmd:assert()} and {cmd:keep()}.  If you require 
   matched observations and unmatched master observations
   but you want only the matched observations, then you could specify
   {cmd:assert(match master)} {cmd:keep(match)}.

{pmore}
    {cmd:assert()} and {cmd:keep()} are convenience options whose functionality
    can be duplicated using {cmd:_merge} directly.

            . {cmd:merge} ...{cmd:, assert(match master) keep(match)}

{pmore}
    is identical to

            . {cmd:merge} ...
            . {cmd:assert _merge==1 | _merge==3}
            . {cmd:keep if _merge==3}

{marker examples}{...}
{title:Examples}

    {synoptline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse autosize}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. webuse autoexpense}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}Perform 1:1 match merge{p_end}
{phang2}{cmd:. webuse autosize}{p_end}
{phang2}{cmd:. ipamerge 1:1 make using https://www.stata-press.com/data/r18/autoexpense}{p_end}
{phang2}{cmd:. list}{p_end}

    {synoptline}ss
{pstd}Perform 1:1 match merge, with different data types{p_end}

(The {cmd:merge} command intentionally causes an error message.){p_end}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price trunk weight length turn displacement gear_ratio foreign}{p_end}
{phang2}{cmd:. tostring foreign, force replace}{p_end}
{phang2}{cmd:. save "using_data", replace}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg rep78 headroom foreign}{p_end}
{phang2}{cmd:. tostring price, replace}{p_end}
{phang2}{cmd:. save "master_data", replace}{p_end}

{pstd}Performing a regular merge using the merge command produces and error{p_end}

{phang2}{cmd:. merge 1:1 make using "using_data"}{p_end}

{pstd}Using the force option will lead to missing values in the dataset{p_end}
{phang2}{cmd:. ipamerge 1:1 make using "using_data", force}{p_end}


{pstd}We can use ipappend with the safe option to safely{p_end}

{phang2}{cmd:. use "master_data", clear}{p_end}
{phang2}{cmd:. ipamerge 1:1 make using "using_data", safely outfile("mergereport.xlsx", replace)}{p_end}
{synoptline}

{text}
{title:Author}

{pstd}Arsène Baowendmanegré Zongo & Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Related Help Files: {help ipaclean:ipaclean}, {help ipaappend:ipamerge}, {help merge:[D] append}