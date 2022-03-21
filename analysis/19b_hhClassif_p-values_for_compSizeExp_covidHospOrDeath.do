*************************************************************************
*Do file: 08_hhClassif_an_mv_analysis_perEth5Group_HR_table.do
*
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 2 outcomes 
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: K Wing, base on file from HFORBES, based on file from Krishnan Bhaskaran
*
*Date drafted: 17th June 2021
*************************************************************************


local dataset `1' 

/*for reference
capture noisily stcox i.HHRiskCatCOMPandSIZEBROAD##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke  i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
*/

*global demogadjlistWInts i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5
global demogadjlistWInts i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke i.male i.coMorbCat
	

prog drop _all


foreach outcome in covidHospOrDeath {
   
	
	* Open a log file
	capture log close
	log using "./logs/19b_hhClassif_p-values_compSizeExp_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	**REGRESSIONS**
	*only need to do the regressions once, so putting that code here and editing the outputHRsforvar program accordingly
	
	*first, create a main exposure variable that only has categories 3-5 in it (for the White test for trend analysis)
	generate HHRiskCatCOMPandSIZEBROAD_3_5=HHRiskCatCOMPandSIZEBROAD
	replace HHRiskCatCOMPandSIZEBROAD_3_5=. if HHRiskCatCOMPandSIZEBROAD<3 | HHRiskCatCOMPandSIZEBROAD>5
	recode HHRiskCatCOMPandSIZEBROAD_3_5 3=1 4=2 5=3
	label define HHRiskCatCOMPandSIZEBROAD_3_5   1 "67+ & 1 gen (hhsize=2)" 2 "67+ & 1 gen (hhsize=3-4)" 3 "67+ & 1 gen (hhsize=5+)"
	label values HHRiskCatCOMPandSIZEBROAD_3_5 HHRiskCatCOMPandSIZEBROAD_3_5 
	tab HHRiskCatCOMPandSIZEBROAD_3_5 
	tab HHRiskCatCOMPandSIZEBROAD_3_5 , nolabel
	tab HHRiskCatCOMPandSIZEBROAD_3_5  HHRiskCatCOMPandSIZEBROAD, miss
	*next, create a main exposure variable that only has categories 4, 6 and 8 in it (for the South Asian test for trend analysis)
	generate HHRiskCatCOMPandSIZEBROAD_4_6_8=HHRiskCatCOMPandSIZEBROAD
	replace HHRiskCatCOMPandSIZEBROAD_4_6_8=. if HHRiskCatCOMPandSIZEBROAD<4 | HHRiskCatCOMPandSIZEBROAD==5 | HHRiskCatCOMPandSIZEBROAD==7 | HHRiskCatCOMPandSIZEBROAD>8
	recode HHRiskCatCOMPandSIZEBROAD_4_6_8 4=1 6=2 8=3
	label define HHRiskCatCOMPandSIZEBROAD_4_6_8  1 "67+ & 1 gen (hhsize=5+)" 2 "67+ & 2 gen (hhsize=5+)" 3 "67+ & 3 gen (hhsize=5+)"
	label values HHRiskCatCOMPandSIZEBROAD_4_6_8 HHRiskCatCOMPandSIZEBROAD_4_6_8 
	tab HHRiskCatCOMPandSIZEBROAD_4_6_8 
	tab HHRiskCatCOMPandSIZEBROAD_4_6_8, nolabel
	tab HHRiskCatCOMPandSIZEBROAD_4_6_8  HHRiskCatCOMPandSIZEBROAD, miss
	*next, repeat MV adjusted linear with these variables 
	stcox c.HHRiskCatCOMPandSIZEBROAD_3_5##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
	estimates store whiteAnalysis
	stcox c.HHRiskCatCOMPandSIZEBROAD_4_6_8##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
	estimates store southAsianAnalysis
	
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	
	*White ethnicity
	display "*************Ethnicity: 1************ "
	*this is the linear hh lincom calculation for increasing household size within the 67+ & 1 gen category
	display "**Trend of >hh size in comp category 67+ & 1 gen:**"
	capture noisily estimates restore whiteAnalysis
	capture noisily lincom HHRiskCatCOMPandSIZEBROAD_3_5, eform

	*South Asian ethnicity
	display "*************Ethnicity: 2************ "
	*next line: commented out while testing testparm etc
	*cap noisily outputHRsforvar, variable(HHRiskCatCOMPandSIZEBROAD) catLabel(HHRiskCatCOMPandSIZEBROAD) min(1) max(5) ethnicity(`e') outcome(`outcome')
	*THIS CODE: outputs p-values for HHRiskCatCOMPandSIZEBROAD variable by each ethnicity (overall association or test for trend)
	*call estimates
	*this is the linear hh lincom calculation one for increasing generations within the 5+ category
	display "**Trend of >gens in hhsize 5+:**"
	capture noisily estimates restore southAsianAnalysis
	capture noisily lincom HHRiskCatCOMPandSIZEBROAD_4_6_8 + HHRiskCatCOMPandSIZEBROAD_4_6_8#2.eth5, eform
	cap log close
}



