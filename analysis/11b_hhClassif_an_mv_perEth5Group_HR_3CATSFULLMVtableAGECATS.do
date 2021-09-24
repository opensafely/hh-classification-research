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

global demogadjlist i.ageCatfor67Plus i.male i.obese4cat i.smoke i.rural_urbanFive
*list of comorbidities for adjustment
global comorbidadjlist i.coMorbCat	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				strate `variable' 
				**cox regressiona**
				*crude (only utla matched)
				stcox i.`variable', strata(utla_group) vce(cluster hh_id)
				estimates store crude
				*age-adjusted
				stcox i.`variable' age1 age2 age3, strata(utla_group) vce(cluster hh_id)
				estimates store ageAdj
				*MV adjusted (without household size)
				stcox i.`variable' $demogadjlist $comorbidadjlist i.imd, strata(utla_group) vce(cluster hh_id)
				estimates store mvAdj
				*MV adjusted (with household size)
				capture noisily stcox i.`variable' $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
				capture noisily estimates store mvAdjWHHSize
				
				

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
					*get HRs for each regression analysis
					*crude 
					estimates restore crude
					cap lincom `i'.`variable', eform
					local hr_crude = r(estimate)
					local lb_crude = r(lb)
					local ub_crude = r(ub)
					*age adjusted
					estimates restore ageAdj
					cap lincom `i'.`variable', eform
					local hr_ageAdj = r(estimate)
					local lb_ageAdj = r(lb)
					local ub_ageAdj = r(ub)
					*mv adjusted
					estimates restore mvAdj
					cap lincom `i'.`variable', eform
					local hr_mvAdj = r(estimate)
					local lb_mvAdj = r(lb)
					local ub_mvAdj = r(ub)
					*mv adjusted with hh size
					capture noisily estimates restore mvAdjWHHSize
					cap noisily lincom `i'.`variable', eform
					capture noisily local hr_mvAdjWHHSize = r(estimate)
					capture noisily local lb_mvAdjWHHSize = r(lb)
					capture noisily local ub_mvAdjWHHSize = r(ub)

					*get variable name
					local lab: variable label `variable'
					*file write tablecontents  _tab  (`i') _n
					*get category name
					local category: label `catLabel' `i'
					display "Category label: `category'"
					
					*write each row, variable label in the first one only
					if `i'==`min' {
						file write tablecontents  ("`lab'") _tab ("`category'") _tab  (`n_people') _tab (`event')  _tab (`person_years') _tab %3.2f (`rate') _tab %4.2f (`hr_crude')  " (" %4.2f (`lb_crude') "-" %4.2f (`ub_crude') ")" _tab %4.2f (`hr_ageAdj')  " (" %4.2f (`lb_ageAdj') "-" %4.2f (`ub_ageAdj') ")" _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")" _tab %4.2f (`hr_mvAdjWHHSize')  " (" %4.2f (`lb_mvAdjWHHSize') "-" %4.2f (`ub_mvAdjWHHSize') ")"  _n
					}
					else {
						file write tablecontents  _tab ("`category'") _tab  (`n_people') _tab (`event')  _tab (`person_years') _tab %3.2f (`rate') _tab %4.2f (`hr_crude')  " (" %4.2f (`lb_crude') "-" %4.2f (`ub_crude') ")" _tab %4.2f (`hr_ageAdj')  " (" %4.2f (`lb_ageAdj') "-" %4.2f (`ub_ageAdj') ")" _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")" _tab %4.2f (`hr_mvAdjWHHSize')  " (" %4.2f (`lb_mvAdjWHHSize') "-" %4.2f (`ub_mvAdjWHHSize') ")"  _n
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
	log using "./logs/11b_hhClassif_tablecontent_HR_3CATSFULLMVtableAGECATS_`outcome'_`dataset'", text replace
	
	*open table
	file open tablecontents using ./output/11b_hhClassif_tablecontents_HRtable_3CATSFULLMVtableAGECATS_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("N") _tab ("Events") _tab ("Person years follow up") _tab ("Rate (per 100 000 person years)") _tab ("Crude") _tab ("Age adjusted") _tab ("MV adjusted") _tab ("MV adjusted incl HH size") _n
	
	forvalues e=1/5 {
		use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3_ethnicity_`e'`dataset'.dta, clear
		if `e'==1 {
			file write tablecontents "Ethnicity: White" _n
		}
		else if `e'==2 {
			file write tablecontents "Ethnicity: South Asian" _n
		}
		else if `e'==3 {
			file write tablecontents "Ethnicity: Black" _n
		}
		else if `e'==4 {
			file write tablecontents "Ethnicity: Mixed" _n
		}
		else if `e'==5 {
			file write tablecontents "Ethnicity: Other" _n
		}
		display "ETHNICITY: `e'"
		*include version with broad exposure categories (all variables)
		*hhrisk exposure 3 categories
		cap noisily outputHRsforvar, variable(hhRiskCatExp_4cats) catLabel(hhRiskCat67PLUS_4cats) min(1) max(4) ethnicity(`e') outcome(`outcome')
		*age (3 splines)
		*cap noisily outputHRsforvar, variable(age1) catLabel(age1) min(0) max(0) ethnicity(`e') outcome(`outcome')
		*cap noisily outputHRsforvar, variable(age2) catLabel(age2) min(0) max(0) ethnicity(`e') outcome(`outcome')
		*cap noisily outputHRsforvar, variable(age3) catLabel(age3) min(0) max(0) ethnicity(`e') outcome(`outcome')
		*age
		cap noisily outputHRsforvar, variable(ageCatfor67Plus) catLabel(ageCatfor67Plus) min(0) max(4) ethnicity(`e') outcome(`outcome')
		*sex
		cap noisily outputHRsforvar, variable(male) catLabel(male) min(0) max(1) ethnicity(`e') outcome(`outcome')
		*obesity
		cap noisily outputHRsforvar, variable(obese4cat) catLabel(obese4cat) min(1) max(4) ethnicity(`e') outcome(`outcome')
		*smoking
		cap noisily outputHRsforvar, variable(smoke) catLabel(smoke) min(1) max(3) ethnicity(`e') outcome(`outcome')
		*rural urban
		cap noisily outputHRsforvar, variable(rural_urbanFive) catLabel(rural_urbanFive) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*comorbidities
		cap noisily outputHRsforvar, variable(coMorbCat) catLabel(coMorbCat) min(0) max(2) ethnicity(`e') outcome(`outcome')
		*imd
		cap noisily outputHRsforvar, variable(imd) catLabel(imd) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*hh size
		cap noisily outputHRsforvar, variable(hh_total_cat) catLabel(hh_total_cat) min(1) max(3) ethnicity(`e') outcome(`outcome')
		file write tablecontents _n
	}
	cap file close tablecontents 
	cap log close
	*output excel
	*insheet using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.txt, clear
	*export excel using ./output/hhClassif_tablecontents_HRtable_`outcome'_`dataset'.xlsx, replace
}

