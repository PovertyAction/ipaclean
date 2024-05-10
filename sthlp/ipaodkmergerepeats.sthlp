{smcl}
{* *! version 1.1.0 Innovations for Poverty Action 07Apr2024}{...}

{viewerjumpto "Syntax" "ipaodkmergerepeats##syntax"}{...}
{viewerjumpto "Menu" "ipaodkmergerepeats##menu"}{...}
{viewerjumpto "Description" "ipaodkmergerepeats##description"}{...}
{viewerjumpto "Options" "ipaodkmergerepeats##options"}{...}
{viewerjumpto "Examples" "ipaodkmergerepeats##examples"}{...}

{p2colset 1 15 17 2}{...}
{p2col:{bf:ipaappend} {hline 2}}Reshape and Merge ODK/SurveyCTO repeat groups{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:ipaodkmergerepeats} {cmd:using} {it:{help filename}|folder_path}
[{cmd:,} {it:options}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 15}{...}
{synopthdr}
{synoptline}
{synopt :{opt saving("filename.dta")}} save a copy of the merged dataset{p_end}
{synopt :{opt fold:er}}specify folder containing repeat group datasets{p_end}
{synopt :{opt replace}}Overwrite saving dataset{p_end}
{synoptline}
{p2colreset}{...}


{marker menu}{...}
{title:Menu}

{phang}
{bf:Data > Reshape and Merge repeat group datasets}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ipaodkmergerepeats} offers a easy way to reshape and merge ODK/SuveyCTO style repeat data 
into the main dataset.  {cmd:ipaodkmergerepeats} If any {it:{help filename}} is specified without an
extension, {cmd:.dta} is assumed.


{marker options}{...}
{title:Options}  

{phang}
{opt savings()} saves a copy of the merged dataset to disk. Default is to only leave dataset in memory

{phang}
{opt folder()} specifies the folder contain the repeat group datasets. If not specified, then the 
current working directory is assumed. 

{phang}
{opt folder()} Overwrite existing file. 

{marker examples}{...}
{title:Examples}

    {hline}
    Setup
    {pstd}Reshape and merege repeat datasets from current directory and save a copy of the merged dataset{p_end}
{phang2}{cmd:. ipaodkmergerepeats "Baseline Survey", saving("Baseline Survey_WIDE") replace}{p_end}
{phang2}{cmd:. webuse odd}{p_end}
{phang2}{cmd:. list}


{text}
{title:Author}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{text}
{title:Acknowledgement}

{pstd}{ipaodkmergerepeats} is heavily based on {browse "https://github.com/PovertyAction/odkmergerepeats":odkmergerepeats} written by Chris Boyer of IPA{p_end}

{title:Also see}

Related Help Files: {help ipaclean:ipaclean}