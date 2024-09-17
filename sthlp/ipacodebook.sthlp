{smcl}

{* *! version 2.0.0 Innovations for Poverty Action 15jul2024}{...}

{vieweralsosee "[D] codebook" "help codebook"}{...}
{vieweralsosee "[D] describe" "help describe"}{...}
{vieweralsosee "[R] summarize" "help summary"}{...}
{viewerjumpto "Syntax" "ipacodebook##syntax"}{...}
{viewerjumpto "Description" "ipacodebook##description"}{...}
{viewerjumpto "Options" "ipacodebook##options"}{...}
{viewerjumpto "Examples" "ipacodebook##examples"}{...}
{viewerjumpto "Stored Values" "ipacodebook##stored_values"}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:ipacodebook} {hline 2}}Describe data content and export codebook to excel{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pmore}
{cmd:ipacodebook}
{help varlist}
{cmd:using} 
{help filename}
{help if:[if]} {help in:[in]}
[{cmd:,}
{it:{help ipacodebook##options:options}}]

{marker options}
{synoptset 50 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{bf:note(#, {opt rep:lace}|{opt coal:esce}|{opt long:er}|{opt short:er})}}use notes as labels{p_end}
{synopt:{opt template}}generate codebook as a template for apply option{p_end}
{synopt:{opth apply:using(filename)}}apply new variable names and labels from template codebbok{p_end}
{synopt:{cmdab:s:tatistics:(}{it:{help ipacodebook##statname:statname}} [{it:...}]{cmd:)}}report specified statistics; default is no statistics{p_end}
{synopt:{cmdab:statv:ariables:(}{it:{help varlist}}{cmd:)}}report statistics for only variables specified; default is all variables{p_end}
{synopt:{opt replace}}overwrite Excel file{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description} 

{pstd}
{cmd:ipacodebook} creates a codebook in excel format saving the variable name, variable label, variable type, number and percentage of missing values, number of distinct values for each variable and additional optional statistics. Optionally, {cmd:ipacodebook} allows the user to generate a template for making corrections to labels and variable names as well. These changes can then be applied to the dataset using the apply option.{p_end}

{marker options}{...}
{title:Options}

{phang}
{cmd:note(#, replace|coalesce|longer|shorter)} specifies how notes and labels should be treated. {cmd:#} specifies the note number to use. {cmd:replace} specifies that the note should always be used as the variable label, {cmd:coalesce} indicates that the note be used if the variable label is missing, {cmd:longer} specifies that the note be used if it is longer than the variable label and {cmd:shorter} specifies that the note be used if it is not missing and shorter than the variable label. 

{phang}
{cmd:template} generates a template codebook which can be used to make edits to the variable names and labels. {cmd:template} generates a codebook file with "new_variable" and "new_label" columns which will be used to indicate new variable names or labels where neccesary. 

{phang}
{cmd:applyusing("codebook_template.xlsx")} is used to apply changes from codebook template created by {cmd:template} option to the dataset. This option can only be used to change the variable names or variable labels. 

{phang}
{cmd:statistics(}{it:statname} [{it:...}]{cmd:)}
   specifies the statistics to be displayed; If the option {cmd:statvariables()} is 
   specified, then the default is equivalent to specifying {cmd:statistics(mean)}, 
   otherwise the default is no statistics. Multiple statistics may be specified
   and are separated by white space, such as {cmd:statistics(mean sd)}.
   Available statistics are

{marker statname}{...}
{synoptset 17}{...}
{synopt:{space 4}{it:statname}}Definition{p_end}
{space 4}{synoptline}
{synopt:{space 4}{opt me:an}} mean{p_end}
{synopt:{space 4}{opt co:unt}} count of nonmissing observations{p_end}
{synopt:{space 4}{opt n}} same as {cmd:count}{p_end}
{synopt:{space 4}{opt su:m}} sum{p_end}
{synopt:{space 4}{opt ma:x}} maximum{p_end}
{synopt:{space 4}{opt mi:n}} minimum{p_end}
{synopt:{space 4}{opt r:ange}} range = {opt max} - {opt min}{p_end}
{synopt:{space 4}{opt sd}} standard deviation{p_end}
{synopt:{space 4}{opt v:ariance}} variance{p_end}
{synopt:{space 4}{opt cv}} coefficient of variation ({cmd:sd/mean}){p_end}
{synopt:{space 4}{opt sem:ean}} standard error of mean ({cmd:sd/sqrt(n)}){p_end}
{synopt:{space 4}{opt sk:ewness}} skewness{p_end}
{synopt:{space 4}{opt k:urtosis}} kurtosis{p_end}
{synopt:{space 4}{opt p1}} 1st percentile{p_end}
{synopt:{space 4}{opt p5}} 5th percentile{p_end}
{synopt:{space 4}{opt p10}} 10th percentile{p_end}
{synopt:{space 4}{opt p25}} 25th percentile{p_end}
{synopt:{space 4}{opt med:ian}} median (same as {opt p50}){p_end}
{synopt:{space 4}{opt p50}} 50th percentile (same as {opt median}){p_end}
{synopt:{space 4}{opt p75}} 75th percentile{p_end}
{synopt:{space 4}{opt p90}} 90th percentile{p_end}
{synopt:{space 4}{opt p95}} 95th percentile{p_end}
{synopt:{space 4}{opt p99}} 99th percentile{p_end}
{synopt:{space 4}{opt iqr}} interquartile range = {opt p75} - {opt p25}{p_end}
{synopt:{space 4}{opt q}} equivalent to specifying {cmd:p25 p50 p75}{p_end}
{space 4}{synoptline}
{p2colreset}{...}

{phang}
{cmd:statvariables(}{it:{help varlist}}{cmd:)}
   specifies the variables to display statistics for. If the option {cmd:statistics()} is 
   specified, then the default is equivalent to specifying {cmd:statvariables()} with 
   all numeric variables in the dataset, otherwise the default is no statvariables. 

{phang}
{cmd:replace} overwrites an existing Excel workbook.

{hline}

{marker examples}{...}
{title:Examples} 

{synoptline}
  {text:Setup}
	{phang}{com}   . sysuse auto, clear{p_end}

  {text:export codebook for all variables}
	{phang}{com}   . ipacodebook _all using "auto_codebook.xlsx", replace{p_end}

  {text:export codebook for all variables using the notes as variable labels if notes are longer}
	{phang}{com}   . ipacodebook _all using "auto_codebook.xlsx", note(1, longer) replace{p_end}

  {text:export codebook for all variables using the notes as variable labels if notes are longer}
	{phang}{com}   . ipacodebook _all using "auto_codebook.xlsx", template replace{p_end}

	{text:Make modifications to the "new_variable" and "new_label" columns and run the below code}
	{phang}{com}   . ipacodebook _all using "auto_codebook_NEW.xlsx", applyusing("auto_codebook.xlsx") replace{p_end}

  {text:export codebook for all variables and display mean p25 p50 and p75 statistics for all numeric variables}
	{phang}{com}   . ipacodebook _all using "auto_codebook.xlsx", replace stat(mean p25 p50 p75){p_end}

  {text:export codebook for all variables and display mean median sd statistics for price and mpg}
	{phang}{com}   . ipacodebook _all using "auto_codebook.xlsx", replace stat(mean median sd) statv(price mpg){p_end}

{synoptline}
{p2colreset}{...}

{marker stored_values}{...}
{title:Stored results}

{p 6} {cmd:ipacodebook} stores the following in r():{p_end}

{synoptset 25 tabbed}{...}
{syntab:{opt Scalars}}
{synopt:{cmd:r(N_vars)}}number variables{p_end}
{synopt:{cmd:r(N_allmiss)}}number of variables with all missing values{p_end}
{synopt:{cmd:r(N_miss)}}number of variables with at least 1 missing values{p_end}
{p2colreset}{...}

{text}
{title:Acknowlegement}

{pstd}ipacodebook uses elements from the {browse "https://github.com/PovertyAction/cbook_stat":cbook_stat} command written by Michael Rosenbaum of Innovations for Poverty Action. The {cmd:template} and {cmd:applyusing()} options of the command are inspired by the {browse "https://dimewiki.worldbank.org/Iecodebook":iecodebook} command from World Bank DIME analytics team{p_end}
	
{text}
{title:Author}

{pstd}Ishmail Azindoo Baako & Arsène Baowendmanegré Zongo, GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Help: {help codebook:[D] codebook}

User-written: {help codebookout:codebookout}, {help iecodebook:iecodebook}