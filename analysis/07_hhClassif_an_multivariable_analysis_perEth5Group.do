********************************************************************************
*
*	Do-file:		07_hhClassif_an_multivariable_analysis_perEth5Group.do
*	Project:		hh risk classification
*	Programmed by:	K Wing, based on files from Hforbes, Fizz & Krishnan
*	Data used:		analysis_dataset.dta
*	Data created:	None
*	Other output:	Log file: 07_hhClassif_an_multivariable_analysis_.log 
*
********************************************************************************
*

*  
********************************************************************************


* Set globals that will print in programs and direct output
*global outdir  	  "output" 
*global logdir     "log"
*global tempdir    "tempdata"

local dataset `1'

*list of demographic variables for adjustment: age (spline), sex, BMI, smoking, density of housing, geographic area (already taken account of in stratified analysis)
global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.rural_urbanFive
*list of comorbidities for adjustment
global comorbidadjlist i.coMorbCat	

/*
local outcome `1' 
local dataset `2'
*/

************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************

* Open a log file
capture log close
log using ./logs/07_hhClassif_an_multivariable_analysis_perEth5Group_`dataset', replace t

* Open dataset for each ethnicity and fit specified model(s)
*Multivariable adjusted for ses
*loop by each ethnicity


foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath {
	*2 and 3 here are the two age categories I've created so far, need to change these when there are more
	forvalues x=2/3 {
		use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta, clear
		
		sum eth5
		local maxEth5Cat=r(max)
		forvalues ethCat=1/`maxEth5Cat' {
			display "ethCat: `ethCat'"
			capture noisily use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'_ethnicity_`ethCat'`dataset'.dta, clear
			cap erase ./output/hhClassif_multvariableAnalysisPerEth5_`outcome'_ageband_`x'_ethnicity_`ethCat'`dataset'.ster
			*Fit and save model
			display "***********Outcome: `outcome', ageband: `x', ethnicity: `ethCat' dataset: `dataset'*************************"
			capture noisily stcox i.hhRiskCatExp $demogadjlist $comorbidadjlist i.imd, strata(utla_group) vce(cluster hh_id)
			if _rc==0 {
				estimates
				estimates save ./output/hhClassif_multvariableAnalysisPerEth5_`outcome'_ageband_`x'_ethnicity_`ethCat'`dataset', replace
			}
			else di "WARNING - Outcome: `outcome', ageband: `x', ethnicity: `ethCat' dataset: `dataset' MODEL DID NOT SUCCESSFULLY FIT"
		}
	}
}

* Close log file
log close
