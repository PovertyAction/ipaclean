{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 10May2023}{...}

{vieweralsosee "[D] split" "help split"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ipaodksplit##syntax"}{...}
{viewerjumpto "Description" "ipaodksplit##description"}{...}
{viewerjumpto "Options" "ipaodksplit##options"}{...}
{viewerjumpto "Examples" "ipaodksplit##examples"}{...}

{p2colset 1 15 17 2}{...}
{p2col:{bf:ipaodksplit}} {hline 2} Create dummy variables from SurveyCTO/ODK style select_multiple type questions{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:ipaodksplit} {cmd:using} {it:{help filename}}
[{cmd:,} {it:options}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt :{opt order}}order dummies right after each original select_multiple variable{p_end}
{synopt :{opt exclude}}do not create dummies for unused values in select_multiple variable{p_end}
{synopt :{opt label}}label dummies using choice labels defined in XLS form{p_end}
{synopt :{opt vallab(lblname)}} label dummy variables using lblname{p_end}
{synopt :{opth prefix(string)}}prefix dummies{p_end}
{synopt :{opth lang:uage(string)}}use labels from language{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ipaodksplit} processes an XLSForm, specifically the 'survey' and 'choices' sheets, to create dummy variables for select_multiple questions. It imports the necessary sheets, processes the data and generates the dummy variables accordingly.

{marker options}{...}
{title:Options}

{phang}
{opt order} places the newly created dummy variables right after each original select_multiple variable in the order they appear.

{phang}
{opt exclude} excludes the dummies for specific select_multiple responses which are not in the data. By default, {cmd:ipaodksplit} will include dummy variables for all values of select_multiple variable as defined in the XLS form. If the option {cmd:exclude} is use, {cmd:ipaodksplit} will only create dummy variables for values are present at least once in the dataset. 

{phang}
{opt label} generates variable labels for the dummy variables based on the choices sheet. Must be used in conjunction with the {cmd:language} option if there are multiple language columns in the XLS form.

{phang}
{opt vallab(lblname)} label values of dummy variables using the labels defined by lblname.

{phang}
{opth prefix(string)} adds a specified prefix to the names of the new dummy variables to avoid name clashes. For instance if prefix is defined as {cmd:prefix("_")}, then dummy variables for a select_multiple variable (eg. religion) will be created as religion_1, religion_2 etc instead of religion1 religion2 etc.

{phang}
{opth language(string)} specifies the language column to use from the choices sheet when when the XLS form has multiple language columns.

{marker examples}{...}
{title:Examples}

    {hline}
    Setup
	
{phang2}{cmd:. unzipfile "https://raw.github.com/PovertyAction/ipaclean/main/data/ipaodksplit_test_data.zip"}{p_end}

	{hline}
	Example 1

{pstd}Split select_multiple variables and order dummies after parent variable{p_end}
{phang2}{cmd:. use "Employment Status and Consumption Patterns in 2023.dta", clear}{p_end}
{phang2}{cmd:. ipaodksplit using "Employment Status and Consumption Patterns in 2023.xlsx", order}{p_end}

    {hline}
    Example 2

{pstd}Split select_multiple variables, use the value labels as variable labels and label values as yes and no{p_end}
{phang2}{cmd:. use "Employment Status and Consumption Patterns in 2023.dta", clear}{p_end}
{phang2}{cmd:. label define yesno 0 "No" 1 "Yes"}{p_end}
{phang2}{cmd:. ipaodksplit using "Employment Status and Consumption Patterns in 2023.xlsx", order label vallab(yesno) prefix(_)}{p_end}
   
{text}
{title:Acknowledgement}

{pstd}ipaodksplit is partly based on {cmd:odksplit} command written by A.R.M Mehrab Ali of Innovations for Poverty Action{p_end}

{text}
{title:Author}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Related Help Files: {help split:[D] split}, {help ipaodkmergerepeats:ipaodkmergerepeats}, {help ipaclean:ipaclean}