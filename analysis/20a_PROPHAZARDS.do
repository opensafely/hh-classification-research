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

*very useful reference: https://stats.oarc.ucla.edu/other/examples/asa2/testing-the-proportional-hazard-assumption-in-cox-models/
*************************************************************************


/*==============================================================================
DO FILE NAME:			08_an_model_checks
PROJECT:				HCQ in COVID-19 
DATE: 					13 July 2020 
AUTHOR:					C Rentsch
						adapted from A Schultze 						
DESCRIPTION OF FILE:	program 08 
						check the PH assumption, produce graphs 
DATASETS USED:			data in memory ($Tempdir/analysis_dataset_STSET_outcome)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
						table4, printed to $Tabfigdir
						schoenplots1-x, printed to $Tabfigdir 
							
==============================================================================*/

local dataset `1' 

* Open a log file

/* Quietly run models, perform test and store results in local macro==========*/

global demogadjlistWInts i.imd i.ageCatfor67Plus i.obese4cat i.rural_urbanFive i.smoke i.male i.coMorbCat

foreach outcome in covidHospOrDeath  {
	
capture log close
log using "./logs/20a_PROPHAZARDS_`outcome'_`dataset'", text replace

* Open Stata dataset
use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear


*Kaplin Meier
sts graph, by(hhRiskCatExp_5cats)
graph export "./output/Kaplin_Meier_`outcome'_`dataset'.svg", as(svg) replace



*Schoenfeld Residuals for each category of main exposure
*crude regression
stcox i.hhRiskCatExp_5cats, strata(utla_group) vce(cluster hh_id)
capture noisily estimates store crude 
estat phtest, detail
local univar_p1 = round(r(phtest)[2,4],0.001)

di `univar_p1'

*MV regression
capture noisily stcox i.hhRiskCatExp_5cats $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)estat phtest, detail
capture noisily estimates store mvAdj
local multivar1_p1 = round(r(phtest)[2,4],0.001)

sum hhRiskCatExp_5cats
local maxhhRiskCatExp_5cats=r(max) 
	
forvalues cat=1/`maxhhRiskCatExp_5cats' {
 
*univariable
capture noisily estimates restore crude
capture noisily estat phtest, plot(`cat'.hhRiskCatExp_5cats) ///
			  graphregion(fcolor(white)) ///
			  ylabel(, nogrid labsize(small)) ///
			  xlabel(, labsize(small)) ///
			  xtitle("Time", size(small)) ///
			  ytitle("Scaled Shoenfeld Residuals", size(small)) ///
			  msize(small) ///
			  mcolor(gs6) ///
			  msymbol(circle_hollow) ///
			  scheme(s1mono) ///
			  title ("Schoenfeld residuals against time, Univariable, category: `cat'", position(11) size(medsmall)) 

capture noisily graph export "./output/schoenplot_`outcome'_univariable_cat_`cat'_`dataset'.svg", as(svg) replace

* Close window 
graph close  
			  
			  
*multivariable			    
capture noisily estimates restore mvAdj
estat phtest, detail
local multivar1_p1 = round(r(phtest)[2,4],0.001)
 
capture noisily estat phtest, plot(`cat'.hhRiskCatExp_5cats) ///
			  graphregion(fcolor(white)) ///
			  ylabel(, nogrid labsize(small)) ///
			  xlabel(, labsize(small)) ///
			  xtitle("Time", size(small)) ///
			  ytitle("Scaled Shoenfeld Residuals", size(small)) ///
			  msize(small) ///
			  mcolor(gs6) ///
			  msymbol(circle_hollow) ///
			  scheme(s1mono) ///
			  title ("Schoenfeld residuals against time, Multivariable, category: `cat'", position(11) size(medsmall)) 			  

capture noisily graph export "./output/schoenplot_`outcome'_multivariable_cat_`cat'_`dataset'.svg", as(svg) replace

* Close window 
graph close
}	  

* Print table of results======================================================*/	


cap file close tablecontent
file open tablecontent using "./output/20a_PROPHAZARDS_`outcome'_`dataset'.txt", t w replace

* Column headings 
file write tablecontent ("Table of results for testing the PH assumption") _n
file write tablecontent _tab ("Univariable") _tab  ("Fully Adjusted") _tab _n
						
file write tablecontent _tab ("p-value") _tab ("p-value")  _n

* Row heading and content  
file write tablecontent ("`univar_p1'") _tab ("`multivar1_p1'") _n

file write tablecontent _n
file close tablecontent


* Close log file 
log close

}

