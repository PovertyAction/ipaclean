# ipaclean

The IPA Data Cleaning Package (ipaclean) is a Stata package that contains IPA's custom Stata programs for cleaning & validating survey data. The package includes the following programs:

### Programs

- `ipaappend` - Safely append datasets
- `ipamegre` - Safely merge datasets
- `ipaodksplit` - Split select_multiple responses into dummy variables
- `ipaodkmergerepeats` - Reshape and merge ODK/SurveyCTO stype repeat groups in wide format
- `ipacompare` - Compare data from multiple rounds of survey
- `ipacodebook` - Export nicely formatted codebooks to excel

## Installation

```Stata
* ipaclean may be installed directly from GitHub
net install ipaclean, all replace from("https://raw.githubusercontent.com/PovertyAction/ipaclean/main")

ipaclean update

* after initial installation ipaclean can be updated at any time using
ipaclean update

* to verify you have the latest versions of the commands
ipaclean version
```

## Learn about ipaclean
Check out the [IPACLEAN wiki](https://github.com/PovertyAction/ipaclean/wiki) for more information about ipaclean. 

If you encounter a clear bug, please file a minimal reproducible example on [github](https://github.com/PovertyAction/ipaclean/issues). For questions and other discussion, please email us at [researchsupport@poverty-action.org](mailto:researchsupport@poverty-action.org).

## Current Author(s)
 - [Ishmail Azindoo Baako](https://github.com/iabaako)
 - [Dalyo Sid Ousmane Ourba](https://github.com/dalyo)
 - [Arsène Baowendmanegré Zongo](https://github.com/azzongo)

## Acknowledgement
 
 - `ipaodksplit` is partly based on the [`odksplit`](https://github.com/ARCED-Foundation/odksplit) command written by A.R.M Mehrab Ali(https://github.com/ARCED-Foundation)
 - `ipaodkmergerepeats` is heavily based on [`odkmergerepeats`](https://github.com/PovertyAction/odkmergerepeats) written by [Chris Boyer](https://github.com/boyercb)
- `ipacodebook` is inspired by [cbook_stats](https://github.com/PovertyAction/cbook_stat) written by [Michael Rosenbaum](https://github.com/mfrosenbaum). The *template()* and *applyusing* options of the command are inspired by the *iecodebook* command from the World Bank [DIME Analytics Team](https://github.com/worldbank/iefieldkit). 