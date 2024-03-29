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
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
*/

global demogadjlistWInts i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke i.male i.coMorbCat
*list of comorbidities for adjustment
*global comorbidadjlistWInts i.coMorbCat##i.eth5	

prog drop _all

*program for outputting HRs by ethnicity (i.e. for variables where this evidence of an interaction with ethnicity)
prog define outputHRsforvarByEthnicity
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				
				*get total count of people by for each ethnicity
				count if eth5==`ethnicity'
				local total = r(N)				

				forvalues i=`min'/`max' {
					*doing just mvadjusted without hh size
					estimates restore mvAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth5, eform
					local hr_mvAdj = r(estimate)
					local lb_mvAdj = r(lb)
					local ub_mvAdj = r(ub)

					*get variable name
					local lab: variable label `variable'
					*file write tablecontents  _tab  (`i') _n
					*get category name
					local category: label `catLabel' `i'
					display "Category label: `category'"
					
					
					*write each row hg
					if `i'==`min' {
						*write the total
						file write tablecontents ("`lab'") _n
						file write tablecontents _tab ("`category'") _tab "1"  _n
					}
					else {
						file write tablecontents  _tab ("`category'") _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")" _n
					}

				}
				*variable category
end


*program for outputting HRs that have a combined effect
prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) outcome(string) 

	*calculation of rates
				
				*get total count of people
				count
				local total = r(N)				

				forvalues i=`min'/`max' {
					*doing just mvadjusted without hh size
					estimates restore mvAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable', eform
					local hr_mvAdj = r(estimate)
					local lb_mvAdj = r(lb)
					local ub_mvAdj = r(ub)

					*get variable name
					local lab: variable label `variable'
					*file write tablecontents  _tab  (`i') _n
					*get category name
					local category: label `catLabel' `i'
					display "Category label: `category'"
					
					
					*write each row hg
					if `i'==`min' {
						*write the total
						file write tablecontents ("`lab'") _n
						file write tablecontents _tab ("`category'") _tab "1"  _n
					}
					else {
						file write tablecontents  _tab ("`category'") _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")" _n
					}

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

*foreach outcome in covidDeath covidHosp nonCovidDeath nonCovidDeath {


foreach outcome in covidHospOrDeath nonCovidDeath {
   
	* Open a log file
	capture log close
	log using "./logs/22_hhClassif_an_mv_an_wInteractions_67alone_HR_ALLVARS_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	*open table
	file open tablecontents using ./output/22_hhClassif_an_mv_an_wInteractions_67alone_HR_ALLVARS_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("MV adjusted") _n
	
	**REGRESSION**
	*MV adjusted (without household size)
	stcox i.hhRiskCatExp_5cats##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
	estimates store mvAdj
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	

	
	*First, output variables where there is an interaction by ethnicity:
	file write tablecontents "VARIABLES THAT INTERACT WITH ETHNICITY" _n
	forvalues e=1/`maxEth5' {
		if `e'==1 {
			file write tablecontents "--Ethnicity: White--" _n
		}
		else if `e'==2 {
			file write tablecontents "--Ethnicity: South Asian--" _n
		}
		else if `e'==3 {
			file write tablecontents "--Ethnicity: Black--" _n
		}
		else if `e'==4 {
			file write tablecontents "--Ethnicity: Mixed--" _n
		}
		else if `e'==5 {
			file write tablecontents "--Ethnicity: Other--" _n
		}
		*main exposure
		*cap noisily outputHRsforvarByEthnicity, variable(hhRiskCatExp_5cats) catLabel(hhRiskCatExp_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*imd - just this one for now, left code for others in case reviewers want them
		cap noisily outputHRsforvarByEthnicity, variable(imd) catLabel(imd) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*age
		*cap noisily outputHRsforvarByEthnicity, variable(ageCatfor67Plus) catLabel(ageCatfor67Plus) min(0) max(4) ethnicity(`e') outcome(`outcome')
		*obesity
		*cap noisily outputHRsforvarByEthnicity, variable(obese4cat) catLabel(obese4cat) min(1) max(4) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	
	/*commented out for now, may need for reviewer's comments
	file write tablecontents "VARIABLES THAT DO NOT INTERACT WITH ETHNICITY" _n
	*then, output variables where there is no interaction by ethnicity
	*rural urban
	cap noisily outputHRsforvar, variable(rural_urbanFive) catLabel(rural_urbanFive) min(1) max(5) outcome(`outcome')
	*smoking
	cap noisily outputHRsforvar, variable(smoke) catLabel(smoke) min(1) max(3) outcome(`outcome')
	*sex
	cap noisily outputHRsforvar, variable(male) catLabel(male) min(0) max(1) outcome(`outcome')
	*comorbidities
	cap noisily outputHRsforvar, variable(coMorbCat) catLabel(coMorbCat) min(0) max(2) outcome(`outcome')
	*/
	
	cap file close tablecontents 
	cap log close
	*output excel
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}


****************ORIGINAL CODE BEFORE I STARTED EDITING TO MAKE SURE THE INTERACTIONS WERE ONLY PERFORMED ONCE!!!*********
/*
local dataset `1' 

/*for reference
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
*/

global demogadjlistWInts i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5
*list of comorbidities for adjustment
*global comorbidadjlistWInts i.coMorbCat##i.eth5	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				strate `variable' 
				**cox regressiona**
				*crude (only utla matched)
				stcox i.`variable'##i.eth5, strata(utla_group) vce(cluster hh_id)
				estimates store crude
				*age-adjusted
				stcox i.`variable'##i.eth5 i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
				estimates store ageAdj
				*MV adjusted (without household size)
				stcox i.`variable'##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
				estimates store mvAdj
				*MV adjusted (with household size categorical)
				capture noisily stcox i.`variable'##i.eth5 $demogadjlistWInts i.hh_total_cat##i.eth5, strata(utla_group) vce(cluster hh_id)
				capture noisily estimates store mvAdjWHHSize
				*MV adjusted (with household size continuous)
				/*
				capture noisily stcox i.`variable' $demogadjlist $comorbidadjlist i.imd i.hh_size, strata(utla_group) vce(cluster hh_id)
				capture noisily estimates store mvAdjWHHSizeCONT
				*/
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
					bysort `variable': egen total_follow_up = total(_t) 
					su total_follow_up if eth5==`ethnicity'
					local n_people_All = r(N)
					su total_follow_up if `variable' == `i' & eth5==`ethnicity'
					local n_people = r(N)
					local person_days = r(mean)
					local person_years=`person_days'/365.25
					local rate = 100000*(`event'/`person_years')
					local percent=100*(`n_people'/`n_people_All')
					*get HRs for each regression analysis
					*crude 
					estimates restore crude
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth5, eform
					local hr_crude = r(estimate)
					local lb_crude = r(lb)
					local ub_crude = r(ub)
					*age adjusted
					estimates restore ageAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth5, eform
					local hr_ageAdj = r(estimate)
					local lb_ageAdj = r(lb)
					local ub_ageAdj = r(ub)
					*mv adjusted
					estimates restore mvAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth5, eform
					local hr_mvAdj = r(estimate)
					local lb_mvAdj = r(lb)
					local ub_mvAdj = r(ub)
					*mv adjusted with hh size
					capture noisily estimates restore mvAdjWHHSize
					*cap noisily lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth5, eform
					capture noisily local hr_mvAdjWHHSize = r(estimate)
					capture noisily local lb_mvAdjWHHSize = r(lb)
					capture noisily local ub_mvAdjWHHSize = r(ub)
					*mv adjusted with hh size CONTINOUS
					/*
					capture noisily estimates restore mvAdjWHHSizeCONT
					cap noisily lincom `i'.`variable', eform
					capture noisily local hr_mvAdjWHHSizeCONT = r(estimate)
					capture noisily local lb_mvAdjWHHSizeCONT = r(lb)
					capture noisily local ub_mvAdjWHHSizeCONT = r(ub)
					*/

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
						file write tablecontents  _tab ("`category'") _tab (`n_people') (" (") %3.1f (`percent') (")") _tab (`event') _tab %3.0f (`person_years') _tab %3.0f (`rate') _tab "1"  _tab "1" _tab "1" _tab "1"  _n
					}
					else {
					file write tablecontents  _tab ("`category'") _tab (`n_people') (" (") %3.1f (`percent') (")")  _tab (`event')  _tab %3.0f (`person_years') _tab %3.0f (`rate') _tab %4.2f (`hr_crude')  " (" %4.2f (`lb_crude') "-" %4.2f (`ub_crude') ")" _tab %4.2f (`hr_ageAdj')  " (" %4.2f (`lb_ageAdj') "-" %4.2f (`ub_ageAdj') ")" _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")" _tab %4.2f (`hr_mvAdjWHHSize')  " (" %4.2f (`lb_mvAdjWHHSize') "-" %4.2f (`ub_mvAdjWHHSize') ")"  _n
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

*foreach outcome in covidDeath covidHosp nonCovidDeath nonCovidDeath {


foreach outcome in nonCovidDeath {
   
	
	* Open a log file
	capture log close
	log using "./logs/20_hhClassif_an_mv_an_wInteractions_67alone_HR_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	*open table
	file open tablecontents using ./output/20_hhClassif_an_mv_an_wInteractions_67alone_HR_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("N (%)") _tab ("Events") _tab ("Person years follow up") _tab ("Rate (per 100 000 person years)") _tab ("Crude") _tab ("Age adjusted") _tab ("MV adjusted") _tab ("MV adjusted incl HH size") _n
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	
	forvalues e=1/`maxEth5' {
		display "*************Ethnicity: `e'************ "
		display "`e'"
		cap noisily outputHRsforvar, variable(hhRiskCatExp_5cats) catLabel(hhRiskCatExp_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	
	cap file close tablecontents 
	cap log close
	*output excel
	*insheet using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.txt, clear
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}



*/
