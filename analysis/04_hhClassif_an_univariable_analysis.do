********************************************************************************
*
*	Do-file:		04_hhClassif_an_univariable_analysis.do
*	Project:		hh risk classification
*	Programmed by:	K Wing, based on files from Hforbes, Fizz & Krishnan
*	Data used:		analysis_dataset.dta
*	Data created:	None
*	Other output:	Log file: 04_hhClassif_an_univariable_analysis_`dataset'.log 
*
********************************************************************************
*

*  
********************************************************************************


local dataset `1'

/*PARSE DO-FILE ARGUMENTS (first should be outcome, rest should be variables)
local arguments = wordcount("`0'") 
local outcome `1'
local varlist
forvalues i=2/`arguments'{
	local varlist = "`varlist' " + word("`0'", `i')
	}
local firstvar = word("`0'", 2)
local lastvar = word("`0'", `arguments')
*/
	

* Open a log file
capture log close
log using ./logs/04_hhClassif_an_univariable_analysis_`dataset', replace t

* Open dataset and fit specified model(s)
foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more
	forvalues x=2/3 {

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta, clear

		*Fit and save model
		cap erase ./output/hhClassif_univariableAnalysis_`outcome'_ageband_`x'`dataset'.ster
		display "***********Outcome: `outcome', ageband: `x', dataset: `dataset'*************************"
		stcox i.hhRiskCatExp age1 age2 age3 i.male, strata(utla_group) vce(cluster hh_id)
		if _rc==0 {
			estimates
			estimates save ./output/hhClassif_univariableAnalysis_`outcome'_ageband_`x'`dataset'.ster, replace
			}
		else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"*/
	}
}
* Close log file
log close

