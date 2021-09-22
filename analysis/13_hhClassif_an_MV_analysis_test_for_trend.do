********************************************************************************
*
*	Do-file:		12_hhClassif_an_MV_analysis_W_SA_multipleinteractions.do
*	Project:		hh risk classification
*	Programmed by:	K Wing, based on files from Hforbes, Fizz & Krishnan
*	Data used:		analysis_dataset.dta
*	Data created:	None
*	Other output:	Log file: 12_hhClassif_an_MV_analysis_W_SA_multipleinteractions.do 
*
********************************************************************************
*
*This file allows estimation of p-values for test for trend
*  
********************************************************************************


* Set globals that will print in programs and direct output
*global outdir  	  "output" 
*global logdir     "log"
*global tempdir    "tempdata"

local dataset `1'

global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke i.rural_urbanFive
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
log using ./logs/13_hhClassif_an_MV_analysis_test_for_trend_`dataset', replace t


**************TEST FOR TREND ONE: SOUTH ASIAN ETHNICITY (PARTICULARLY INTERESTED IN WAVE 2)**********************

use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3_ethnicity_2`dataset'.dta, clear

*model with hhRiskCatExp_4 cats as linear
capture noisily stcox hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)

*model with categorical to check I have the right one and results are as I expect
capture noisily stcox i.hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)



**************TEST FOR TREND TWO: WHITE ETHNICITY (PARTICULARLY INTERESTED IN WAVE 1)**********************

use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3_ethnicity_1`dataset'.dta, clear

*model with hhRiskCatExp_4 cats as linear
capture noisily stcox hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)

*model with categorical to check I have the right one and results are as I expect
capture noisily stcox i.hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)


**************TEST FOR TREND THREE: BLACK ETHNICITY (PARTICULARLY INTERESTED IN WAVE 2)**********************

use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3_ethnicity_3`dataset'.dta, clear

*model with hhRiskCatExp_4 cats as linear
capture noisily stcox hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)

*model with categorical to check I have the right one and results are as I expect
capture noisily stcox i.hhRiskCatExp_4cats $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)



log close

