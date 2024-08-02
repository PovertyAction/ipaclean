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
{cmdab:ipaodkmergerepeats} {cmd:using} {it:{help filename}}
[{cmd:,} {it:options}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt :{opth saving(filename)}} save a .dta file of the merged dataset{p_end}
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
    
{phang2}{cmd:. unzipfile "https://raw.github.com/PovertyAction/ipaclean/main/data/ipamergerepeats_test_data.zip"}{p_end}

    {hline}
    Example 1

{pstd}Reshape repeat groups data and merge into main dataset{p_end}

{phang2}{cmd:. ipaodkmergerepeats using "Nested Repeat Data.dta"}{p_end}

    {hline}
    Example 2

{pstd}Reshape repeat groups data and merge into main dataset and save a copy{p_end}

{phang2}{cmd:. ipaodkmergerepeats using "Nested Repeat Data.dta", saving("Nested Repeat Data_merged") replace}{p_end}


{text}
{title:Author}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}GRDS, Innovations for Poverty Action{p_end}

{text}
{title:Acknowledgement}

{pstd}{cmd:ipaodkmergerepeats} is heavily based on {browse "https://github.com/PovertyAction/odkmergerepeats":odkmergerepeats} written by Chris Boyer of IPA{p_end}

{title:Also see}

Related Help Files: {help ipaclean:ipaclean}