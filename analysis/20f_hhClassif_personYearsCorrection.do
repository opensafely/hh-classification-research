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
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke  i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
*/

*global demogadjlistWInts i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5
global demogadjlistWInts i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke i.male i.coMorbCat
	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				
				*get total count of people by for each ethnicity
				count if eth5==`ethnicity'
				local total = r(N)				

				forvalues i=`min'/`max' {
					display 
					*get overall number for each category
					cou if `variable' == `i' & eth5==`ethnicity'
					*get number of events
					cou if `variable' == `i' & _d == 1 & eth5==`ethnicity'
					local event = r(N)
					*get person time and rate and counts
					bysort `variable': egen total_follow_up = total(_t) if eth5==`ethnicity'
					su total_follow_up if eth5==`ethnicity'
					local n_people_All = r(N)
					su total_follow_up if `variable' == `i' & eth5==`ethnicity'
					local n_people = r(N)
					local person_days = r(mean)
					local person_years=`person_days'/365.25
					local rate = 100000*(`event'/`person_years')
					local percent=100*(`n_people'/`n_people_All')
					*get HRs for each regression analysis

					*get variable name
					local lab: variable label `variable'
					*file write tablecontents  _tab  (`i') _n
					*get category name
					local category: label `catLabel' `i'
					display "Category label: `category'"
					
					
					*write each row hg
					if `i'==1 {
						*write the total
						file write tablecontents "(Ethnicity="(`ethnicity') ")" _n
						file write tablecontents "(N="(`total') ")" _n
						file write tablecontents  _tab ("`category'") _tab %3.0f (`person_years') _n
					}
					else {
					file write tablecontents  _tab ("`category'") _tab %3.0f (`person_years')  _n
					}
			
					drop total_follow_up

				}
				*variable category
end

********Code that calls program and outputs tables*******

/*I think what I want here FOR EACH WAVE is
 - A single page PER OUTCOME containing
 - Results FOR EACH ETHNICITY for that outcome
*/

*Testing outcomes
*use ./output/hhClassif_analysis_dataset_STSET_covidDeath_ageband_3`dataset'.dta, clear

*foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath {
	
	


foreach outcome in covidHospOrDeath covidHosp nonCovidDeath covidDeath {
   
	
	* Open a log file
	capture log close
	log using "./logs/20f_hhClassif_personYearsCorrection_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	*open table
	file open tablecontents using ./output/20f_hhClassif_personYearsCorrection_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("Person years follow up") _n
	
	**REGRESSIONS**
	*only need to do the regressions once, so putting that code here and editing the outputHRsforvar program accordingly
	
	strate hhRiskCat67PLUS_5cats 
	**cox regressiona**
	*need to account for different models for wave 1 (only interaction is with hhrisk) versus wave 2 (multiple interactions)
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	
	forvalues e=1/`maxEth5' {
		display "*************Ethnicity: `e'************ "
		display "`e'"
		*next line: commented out while testing testparm etc
		cap noisily outputHRsforvar, variable(hhRiskCat67PLUS_5cats) catLabel(hhRiskCat67PLUS_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	
	cap file close tablecontents 
	cap log close
	*output excel
	*insheet using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.txt, clear
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}

