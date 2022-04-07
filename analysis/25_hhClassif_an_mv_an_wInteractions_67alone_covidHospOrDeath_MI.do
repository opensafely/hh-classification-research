

/* code I used to test some of this
local dataset `1' 


cap log close
log using "./logs/25_hhClassif_an_mv_an_wInteractions_67alone_covidHospOrDeath_MI_`dataset'", text replace

use ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_STSET_covidHospOrDeathCase_`dataset'.dta, clear
*check there are 10 imputations!
tab _mi_m

*test code - works!
*mi estimate, dots eform: stcox male##i.eth5 coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id) nolog 	

mi estimate, dots eform: stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.obese4cat##i.eth5 i.ageCatfor67Plus##i.eth5 i.smoke i.rural_urbanFive i.male i.coMorbCat strata(utla_group) vce(cluster hh_id) nolog 

log close
*/

***********************


	

prog drop _all

prog define outputHRsforvar
	syntax, variable(string) catLabel(string) min(real) max(real) ethnicity(real) outcome(string) 

	*calculation of rates
				
				*get total count of people by for each ethnicity
				count if eth5==`ethnicity'
				local total = r(N)				

				forvalues i=`min'/`max' {
					*mv adjusted
					*estimates restore mvAdj
					estimates use "./output/MI_RESULTS"
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
					if `i'==1 {
						*write the total
						file write tablecontents "(Ethnicity="(`ethnicity') ")" _n
						file write tablecontents "(N="(`total') ")" _n
						file write tablecontents  _tab ("`category'") _tab "1"  _n
					}
					else {
						file write tablecontents _tab ("`category'") _tab %4.2f (`hr_mvAdj')  " (" %4.2f (`lb_mvAdj') "-" %4.2f (`ub_mvAdj') ")"  _n
					}
			
					*drop total_follow_up

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

foreach outcome in covidHospOrDeath {
   
	* Open a log file
	capture log close
	log using "./logs/25_hhClassif_an_mv_an_wInteractions_67alone_covidHospOrDeath_MI_W2", text replace
	
	*open dataset
	*use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	use ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_STSET_covidHospOrDeathCase_W2.dta, clear
	
	*open table
	file open tablecontents using ./output/25_hhClassif_an_mv_an_wInteractions_67alone_covidHospOrDeath_W2.txt, t w replace
	
	*write table title and column headers
	file write tablecontents "Wave: `dataset', Outcome: `outcome'" _n
	file write tablecontents _tab _tab ("MV adjusted - imputed"") _n
	
	**REGRESSIONS**
	*MV adjusted (with household size categorical)
	*capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 $demogadjlistWInts i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	*capture noisily estimates store mvAdjWHHSize	
	
	mi estimate, saving ("./output/MI_RESULTS", replace) dots eform: stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.obese2cat##i.eth5 i.ageCatfor67PlusTWOCATS##i.eth5 i.smoke i.rural_urbanFive i.male i.coMorbCat strata(utla_group) vce(cluster hh_id) nolog 
	
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
}



