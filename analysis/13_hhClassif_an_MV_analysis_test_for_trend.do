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
*This file tests for interactions with smoking and IMD, in order to see if they should be included as interaction parameters
*  
********************************************************************************


* Set globals that will print in programs and direct output
*global outdir  	  "output" 
*global logdir     "log"
*global tempdir    "tempdata"

local dataset `1'

*list of demographic variables for adjustment: age (spline), sex, BMI, smoking, density of housing, geographic area (already taken account of in stratified analysis)
*global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.rural_urbanFive
*list of comorbidities for adjustment
*global comorbidadjlist i.coMorbCat	

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


*include hhRiskCatExp_4cats as a linear variable and see what p-value is in output
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke_nomiss##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 age1 age2 age3 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)

log close

