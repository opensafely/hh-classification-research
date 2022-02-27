*************************************************************************
*Do file: 08_hhClassif_an_mv_analysis_perethnicity_16Group_HR_table.do
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
capture noisily stcox i.hhRiskCatExp_4cats##i.ethnicity_16 i.imd##i.ethnicity_16 i.smoke##i.ethnicity_16 i.obese4cat##i.ethnicity_16 i.hh_total_cat##i.ethnicity_16 i.rural_urbanFive##i.ethnicity_16 i.ageCatfor67Plus##i.ethnicity_16 i.male##i.ethnicity_16 i.coMorbCat##i.ethnicity_16, strata(utla_group) vce(cluster hh_id)
*/


global demogadjlistWInts i.imd##i.ethnicity_16 i.ageCatfor67Plus##i.ethnicity_16 i.obese4cat##i.ethnicity_16 i.rural_urbanFive i.smoke i.male i.coMorbCat
*list of comorbidities for adjustment
*global comorbidadjlistWInts i.coMorbCat##i.ethnicity_16	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

				*get total count of people by for each ethnicity
				count if ethnicity_16==`ethnicity'
				local total = r(N)				

				forvalues i=`min'/`max' {
					display 
					*get overall number for each category
					cou if `variable' == `i' & ethnicity_16==`ethnicity'
					*get number of events
					cou if `variable' == `i' & _d == 1 & ethnicity_16==`ethnicity'
					local event = r(N)
					*get person time and rate and counts
					bysort `variable': egen total_follow_up = total(_t) if ethnicity_16==`ethnicity'
					su total_follow_up if ethnicity_16==`ethnicity'
					local n_people_All = r(N)
					su total_follow_up if `variable' == `i' & ethnicity_16==`ethnicity'
					local n_people = r(N)
					local person_days = r(mean)
					local person_years=`person_days'/365.25
					local rate = 100000*(`event'/`person_years')
					local percent=100*(`n_people'/`n_people_All')
					*get HRs for each regression analysis
					*mv adjusted
					estimates restore mvAdj
					*cap lincom `i'.`variable', eform
					capture noisily lincom `i'.`variable' + `i'.`variable'#`ethnicity'.ethnicity_16, eform
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
					if `i'==1 {
						*write the total
						file write tablecontents "(Ethnicity="(`ethnicity') ")" _n
						file write tablecontents "(N="(`total') ")" _n
						file write tablecontents  _tab ("`category'") _tab (`n_people') (" (") %3.1f (`percent') (")") _tab (`event') _tab %3.0f (`person_years') _tab %3.0f (`rate') _tab "1"    _n
					}
					else {
					file write tablecontents  _tab ("`category'") _tab (`n_people') (" (") %3.1f (`percent') (")")  _tab (`event')  _tab %3.0f (`person_years') _tab %3.0f (`rate') _tab %4.2f  _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")"  _n
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
	log using "./logs/23_hhClassif_an_mv_analysis_ethnicity_16wInteractions_67alone_HR_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	*keep only the South Asian ethnicities - comment this out as want to keep all the ethnicities
	*keep if ethnicity_16>=4 & ethnicity_16<=6
	*tab ethnicity_16
	
	*open table
	file open tablecontents using ./output/23_hhClassif_an_mv_analysis_ethnicity_16wInteractions_67alone_HR_`outcome'_`dataset'.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("N (%)") _tab ("Events") _tab ("Person years follow up") _tab ("Rate (per 100 000 person years)") _tab ("MV adjusted") _n
	
	**REGRESSIONS**
	*only need to do the regressions once, so putting that code here and editing the outputHRsforvar program accordingly
	strate hhRiskCat67PLUS_5cats 
	
	*MV adjusted (without household size)
	stcox i.hhRiskCat67PLUS_5cats##i.ethnicity_16 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
	estimates store mvAdj
	*MV adjusted (with household size continuous)
	/*
	capture noisily stcox i.`variable' $demogadjlist $comorbidadjlist i.imd i.hh_size, strata(utla_group) vce(cluster hh_id)
	capture noisily estimates store mvAdjWHHSizeCONT
	*/
	
	*helper variables
	sum ethnicity_16
	local maxethnicity_16=r(max) 
	
	forvalues e=1/16 {
		if `e'==1 {
			file write tablecontents "*******Ethnicity: British or Mixed British******" _n
		}
		else if `e'==2 {
			file write tablecontents "*******Ethnicity: Irish******" _n
		}
		else if `e'==3 {
			file write tablecontents "*******Ethnicity: Other White*******" _n
		}
		else if `e'==4 {
			file write tablecontents "*******Ethnicity: White + Black Caribbean******" _n
		}
		else if `e'==5 {
			file write tablecontents "*******Ethnicity: White + Black African*******" _n
		}
		else if `e'==6 {
			file write tablecontents "*******Ethnicity: White + Asian******" _n
		}
		else if `e'==7 {
			file write tablecontents "*******Ethnicity: Other mixed******" _n
		}
		else if `e'==8 {
			file write tablecontents "*******Ethnicity: Indian or British Indian*******" _n
		}
		else if `e'==9 {
			file write tablecontents "*******Ethnicity: Pakistani or British Pakistani******" _n
		}
		else if `e'==10 {
			file write tablecontents "*******Ethnicity: Bangladeshi or British Bangladeshi*******" _n
		}
		else if `e'==11 {
			file write tablecontents "*******Ethnicity: Other Asian*******" _n
		}
		else if `e'==12 {
			file write tablecontents "*******Ethnicity: Caribbean******" _n
		}
		else if `e'==13 {
			file write tablecontents "*******Ethnicity: African******" _n
		}
		else if `e'==14 {
			file write tablecontents "*******Ethnicity: Other Black*******" _n
		}
		else if `e'==15 {
			file write tablecontents "*******Ethnicity: Chinese******" _n
		}
		else if `e'==16 {
			file write tablecontents "*******Ethnicity: Other*******" _n
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

