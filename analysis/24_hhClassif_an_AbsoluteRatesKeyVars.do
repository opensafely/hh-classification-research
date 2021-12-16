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


prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				strate `variable' 
		
				forvalues i=`min'/`max' {
					display 
					*get overall number
					cou if `variable' == `i'
					*get number of events
					cou if `variable' == `i' & _d == 1
					local event = r(N)
					*get person time and rate
					bysort `variable': egen total_follow_up = total(_t)
					su total_follow_up if `variable' == `i'
					local n_people = r(N)
					local person_days = r(mean)
					local person_years=`person_days'/365.25
					local rate = 100000*(`event'/`person_years')

					*get variable name
					local lab: variable label `variable'
					*file write tablecontents  _tab  (`i') _n
					*get category name
					local category: label `catLabel' `i'
					display "Category label: `category'"
					
					*write each row, variable label in the first one only
					if `i'==`min' {
						file write tablecontents  ("`lab'") _n 
						file write tablecontents _tab ("`category'") _tab  (`n_people') _tab (`event')  _tab (`person_years') _tab %3.2f (`rate')  _n
					}
					else {
						file write tablecontents  _tab ("`category'") _tab  (`n_people') _tab (`event')  _tab (`person_years') _tab %3.2f (`rate')  _n
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
foreach outcome in covidHospOrDeath {
	
	* Open a log file
	capture log close
	log using "./logs/24_hhClassif_an_AbsoluteRatesKeyVars_`outcome'_`dataset'", text replace
	
	*open table
	file open tablecontents using ./output/24_hhClassif_an_AbsoluteRatesKeyVars_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("N") _tab ("Events") _tab ("Person years follow up") _tab ("Rate (per 100 000 person years)") _n
	
	forvalues e=1/2 {
		if `e'==1 {
			file write tablecontents "Ethnicity: White" _n
		}
		else if `e'==2 {
			file write tablecontents "Ethnicity: South Asian" _n
		}
		display "ETHNICITY: `e'"
		*all data for specific ethnicity
		use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
		keep if eth5==`e'
		*imd
		cap noisily outputHRsforvar, variable(imd) catLabel(imd) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*household composition
		cap noisily outputHRsforvar, variable(hhRiskCat67PLUS_5cats) catLabel(hhRiskCat67PLUS_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*hh size
		cap noisily outputHRsforvar, variable(hh_total_cat) catLabel(hh_total_cat) min(1) max(3) ethnicity(`e') outcome(`outcome')
		*comorbidities (for reference)
		cap noisily outputHRsforvar, variable(coMorbCat) catLabel(coMorbCat) min(0) max(2) ethnicity(`e') outcome(`outcome')
		*only IMD=5 for specific ethnicity
		keep if imd==5
		file write tablecontents "Results for IMD==5" _n
		*household composition absolute rates where IMD category==5
		cap noisily outputHRsforvar, variable(hhRiskCat67PLUS_5cats) catLabel(hhRiskCat67PLUS_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*household size absolute rates where IMD category==5
		cap noisily outputHRsforvar, variable(hh_total_cat) catLabel(hh_total_cat) min(1) max(3) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	cap file close tablecontents 
	cap log close
	*output excel
	*insheet using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.txt, clear
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}
