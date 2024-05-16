{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 10May2023}{...}

{vieweralsosee "[D] split" "help split"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ipaodksplit##syntax"}{...}
{viewerjumpto "Menu" "ipaodksplit##menu"}{...}
{viewerjumpto "Description" "ipaodksplit##description"}{...}
{viewerjumpto "Options" "ipaodksplit##options"}{...}
{viewerjumpto "Examples" "ipaodksplit##examples"}{...}

{p2colset 1 15 17 2}{...}
{p2col:{bf:ipaodksplit}} {hline 2} Split select_multiple variables from an XLSForm into dummies{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:ipaodksplit} {cmd:using} {it:{help filename}}
[{cmd:,} {it:options}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 15}{...}
{synopthdr}
{synoptline}
{synopt :{opth order}}places the newly created dummy variables immediately after the original select_multiple variable{p_end}
{synopt :{opt exclude}}excludes the dummies for values not recorded in select_multiple variable{p_end}
{synopt :{opth label}}uses the choice-labels as variable labels for dummy variables based{p_end}
{synopt :{opth prefix(string)}}adds a specified prefix to the choice value of the created dummy variables to avoid name clashes{p_end}
{synopt :{opth lang:uage(string)}}specifies the language column to use from the choices sheet when the label option is used{p_end}
{synoptline}
{p2colreset}{...}

{marker menu}{...}
{title:Menu}

{phang}
{bf:Data > Variable utilities > Split select_multiple variables from XLSForm}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ipaodksplit} processes an XLSForm, specifically the 'survey' and 'choices' sheets, to create dummy variables for select_multiple questions. It imports the necessary sheets, processes the data and generates the dummy variables accordingly.

{marker options}{...}
{title:Options}

{phang}
{opt order} places the newly created dummy variables immediately after the original select_multiple variable in the order they appear.

{phang}
{opt exclude} excludes the dummies for specific select_multiple responses based on conditions defined within the script.

{phang}
{opth label} generates variable labels for the dummy variables based on the choices sheet. Must be used in conjunction with the {opt LANGuage} option if there are multiple language columns in the choices sheet.

{phang}
{opth prefix(string)} adds a specified prefix to the names of the created dummy variables to avoid name clashes.

{phang}
{opth language(string)} specifies the language column to use from the choices sheet when the {opt label} option is used. If not specified, the first label column is used.

{marker examples}{...}
{title:Examples}

    {hline}
    Example 1
{phang2}{cmd:. ipaodksplit using "form.xlsx", order label prefix(_r) LANG(en)}{p_end}

{pstd}
This command will process the "form.xlsx" file, split the select_multiple variables into dummies, order them after the original variable, add the prefix "_r" to the dummy variable names, and use the English language column for labeling.

    {hline}
    Example 2
{phang2}{cmd:. ipaodksplit using "form.xlsx", exclude}{p_end}

{pstd}
This command will process the "form.xlsx" file and exclude specific dummies based on certain conditions defined within the script.

{text}
{title:Acknowledgement}

{pstd}ipaodksplit is partly based on {browse odksplit:odksplit} command written by A.R.M Mehrab Ali of Innovations for Poverty Action{p_end}

{text}
{title:Author}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{title:Also see}

Related Help Files: {help split:[D] split}, {help ipaodkmergerepeats:ipaodkmergerepeats}, {help ipaclean:ipaclean}