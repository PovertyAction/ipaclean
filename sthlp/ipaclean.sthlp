{smcl}
{* *! version 1.0.0 Innovations for Poverty Action 16may2024}{...}

{cmd:ipaclean} - IPA Stata package for data cleaning

{title:Syntax}

{phang}
Update the ipaclean package

{pmore}
{cmd:ipaclean update}
[{cmd:,} {it:{help ipaclean##options:options}}]

{phang}
Display version information for commands in the ipaclean package

{pmore}
{cmd:ipaclean version}
[{cmd:,} {it:{help ipaclean##options:options}}]

{marker options}
{synoptset 23 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt br:anch("branchname")}} - Install programs and files from a specified branch instead of the default master{p_end}
{synoptline}
{p2colreset}{...}

{title:Description} 

{pstd}
{cmd:ipaclean} a suite of commands for simplifying data cleaning task.
{p_end}

{hline}

{title:Options for ipaclean update}

{phang}
{cmd:branch("branchname")} - Specifies the GitHub repository branch to connect to for updates. This option is intended for debugging purposes or when specifically requested by the authors. 
{p_end}

{hline}

{pstd}
{cmd:ipaclean version} - Displays version information for all commands included in the ipaclean package.
{p_end}

{hline}

{title:Examples} 

{phang}
{txt}To check the version of all commands:{p_end}

{phang}{com}. ipaclean version{p_end}

{phang}
{txt}To update all commands within the package:{p_end}

{phang}{com}. ipaclean update{p_end}

{title:Remarks}

{pstd}Source code and all files for the {cmd:ipaclean} package can be found{p_end}

{synoptset 30 tabbed}{...}
{synopthdr:Program}
{synoptline}
{synopt:{help ipaappend:ipaappend}} - Safely append datasets{p_end}
{synopt:{help ipamerge:ipamerge}} - Safely merge datasets{p_end}
{synopt:{help ipaodksplit:ipaodksplit}} - Split select_multiple responses into dummy variables{p_end}
{synopt:{help ipaodkmergerepeats:ipaodkmergerepeats}} - Reshape and merge ODK/SurveyCTO stype repeat groups in wide format{p_end}
{synopt:{help ipacompare:ipacompare}} - Compare data from multiple rounds of survey{p_end}
{synopt:{help ipacodebook}} - Export nicely formatted codebooks to excel{p_end}

{synoptline}
{p2colreset}{...}

{title:Acknowledgements}

{pstd}The {cmd:ipaclean} package and all associated materials are developed by the Global Research & Data Support (GRDS) team at Innovations for Poverty Action.{p_end}

{title:Authors}

{pstd}Ishmail Azindoo Baako{p_end}
{pstd}Dalyo Sid Ousmane Ourba{p_end}
{pstd}Arsène Baowendmanegré Zongo{p_end}
{pstd}{it:Last updated: 17 September 2024 (v1.0.0)}{p_end}

Help: {help ipacheck:ipacheck} {help ipahelper:ipahelper}