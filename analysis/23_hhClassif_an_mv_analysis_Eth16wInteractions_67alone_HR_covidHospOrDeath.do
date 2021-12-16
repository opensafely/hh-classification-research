*************************************************************************
*Do file: 08_hhClassif_an_mv_analysis_pereth16Group_HR_table.do
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
capture noisily stcox i.hhRiskCatExp_4cats##i.eth16 i.imd##i.eth16 i.smoke##i.eth16 i.obese4cat##i.eth16 i.hh_total_cat##i.eth16 i.rural_urbanFive##i.eth16 i.ageCatfor67Plus##i.eth16 i.male##i.eth16 i.coMorbCat##i.eth16, strata(utla_group) vce(cluster hh_id)
*/

global demogadjlistWIntsEth16 i.imd##i.eth16 i.smoke##i.eth16 i.obese4cat##i.eth16 i.rural_urbanFive##i.eth16 i.ageCatfor67Plus##i.eth16 i.male##i.eth16 i.coMorbCat##i.eth16
*list of comorbidities for adjustment
*global comorbidadjlistWInts i.coMorbCat##i.eth16	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

				*get total count of people by for each ethnicity
				count if eth16==`ethnicity'
				local total = r(N)				

				forvalues i=`min'/`max' {
					display 
					*get overall number for each category
					cou if `variable' == `i' & eth16==`ethnicity'
					*get number of events
					cou if `variable' == `i' & _d == 1 & eth16==`ethnicity'
					local event = r(N)
					*get person time and rate and counts
					bysort `variable': egen total_follow_up = total(_t) 
					su total_follow_up if eth16==`ethnicity'
					local n_people_All = r(N)
					su total_follow_up if `variable' == `i' & eth16==`ethnicity'
					local n_people = r(N)
					local person_days = r(mean)
					local person_years=`person_days'/365.25
					local rate = 100000*(`event'/`person_years')
					local percent=100*(`n_people'/`n_people_All')
					*get HRs for each regression analysis
					*crude 
					estimates restore crude
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth16, eform
					local hr_crude = r(estimate)
					local lb_crude = r(lb)
					local ub_crude = r(ub)
					*age adjusted
					estimates restore ageAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth16, eform
					local hr_ageAdj = r(estimate)
					local lb_ageAdj = r(lb)
					local ub_ageAdj = r(ub)
					*mv adjusted
					estimates restore mvAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth16, eform
					local hr_mvAdj = r(estimate)
					local lb_mvAdj = r(lb)
					local ub_mvAdj = r(ub)
					*mv adjusted with hh size
					capture noisily estimates restore mvAdjWHHSize
					*cap noisily lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.eth16, eform
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

*foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath

foreach outcome in covidHospOrDeath {    
	
	* Open a log file
	capture log close
	log using "./logs/23_hhClassif_an_mv_analysis_Eth16wInteractions_67alone_HR_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	*keep only the South Asian ethnicities
	keep if eth16>=4 & eth16<=6
	tab eth16
	
	*open table
	file open tablecontents using ./output/23_hhClassif_an_mv_analysis_Eth16wInteractions_67alone_HR_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("N (%)") _tab ("Events") _tab ("Person years follow up") _tab ("Rate (per 100 000 person years)") _tab ("Crude") _tab ("Age adjusted") _tab ("MV adjusted") _tab ("MV adjusted incl HH size") _n
	
	**REGRESSIONS**
	*only need to do the regressions once, so putting that code here and editing the outputHRsforvar program accordingly
	strate hhRiskCat67PLUS_5cats 
	**cox regressiona**
	*crude (only utla matched)
	stcox i.hhRiskCat67PLUS_5cats##i.eth16, strata(utla_group) vce(cluster hh_id)
	estimates store crude
	*age-adjusted
	stcox i.hhRiskCat67PLUS_5cats##i.eth16 i.ageCatfor67Plus##i.eth16, strata(utla_group) vce(cluster hh_id)
	estimates store ageAdj
	*MV adjusted (without household size)
	stcox i.hhRiskCat67PLUS_5cats##i.eth16 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
	estimates store mvAdj
	*MV adjusted (with household size categorical)
	capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth16 $demogadjlistWInts i.hh_total_cat##i.eth16, strata(utla_group) vce(cluster hh_id)
	capture noisily estimates store mvAdjWHHSize
	*MV adjusted (with household size continuous)
	/*
	capture noisily stcox i.`variable' $demogadjlist $comorbidadjlist i.imd i.hh_size, strata(utla_group) vce(cluster hh_id)
	capture noisily estimates store mvAdjWHHSizeCONT
	*/
	
	*helper variables
	sum eth16
	local maxeth16=r(max) 
	
	forvalues e=4/6 {
		if `e'==4 {
			file write tablecontents "*******Ethnicity: Indian******" _n
		}
		else if `e'==5 {
			file write tablecontents "*******Ethnicity: Pakistani******" _n
		}
		else if `e'==6 {
			file write tablecontents "*******Ethnicity: Bangladeshi*******" _n
		}
		cap noisily outputHRsforvar, variable(hhRiskCat67PLUS_5cats) catLabel(hhRiskCat67PLUS_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	
	cap file close tablecontents 
	cap log close
	*output excel
	*insheet using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.txt, clear
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}
