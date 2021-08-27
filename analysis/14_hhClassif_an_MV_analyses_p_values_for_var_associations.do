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
log using ./logs/14_hhClassif_an_MV_analyses_p_values_for_var_associations_`dataset', replace t


**************OVERALL P-VALUE FOR HH COMPOSITION: WHITE, SOUTH ASIAN AND BLACK ETHNCITIES**********************

forvalues e=1/3 {
	use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3_ethnicity_`e'`dataset'.dta, clear
	if `e'==1 {
		display "******Ethnicity: White******" _n
	}
	else if `e'==2 {
		display  "******Ethnicity: South Asian*****" _n
	}
	else if `e'==3 {
		display  "******Ethnicity: Black*****" _n
	}
	capture noisily stcox i.hhRiskCatExp_4cats i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store A
	capture noisily stcox i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store B
	display "***************P-VALUE FOR OVERALL HH VARIABLE*****************"
	lrtest A B, force
}


**************OVERALL P-VALUE FOR HH COMPOSITION: INDIAN, PAKISTANI AND BANGLADESHI ETHNCITIES**********************

forvalues e=4/6 {
	use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3_eth16Cat_`e'`dataset'.dta, clear
	if `e'==4 {
		display "*******Ethnicity: Indian******" _n
	}
	else if `e'==5 {
		display "*******Ethnicity: Pakistani******" _n
	}
	else if `e'==6 {
		display "*******Ethnicity: Bangladeshi*******" _n
	}
	capture noisily stcox i.hhRiskCatExp_4cats i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store A
	capture noisily stcox i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store B
	display "***************P-VALUE FOR OVERALL HH VARIABLE*****************"
	lrtest A B, force
}


log close

