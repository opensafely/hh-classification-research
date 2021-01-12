/*==========================================================================================================================================

DO FILE NAME: master.do

======================================================================================================================================================================================*/
*update the number version based on which version of my do files I am on

*LOCAL:
*cd /Users/kw/Documents/GitHub/households-research/analysis

*SERVER:
cd E:\cohorts\households-research\analysis


*set up my global file paths
run global.do

*TO DO LIST*
/*
1. After I have repeated for exposed to SAL, then I will need to go back and check some of the errors related to end_uts in the unexposed and exposed cohorts
2. Also, it looks like I might be missing some Therapy records, as in do file 04, I only seem to search one of the extracted Therapy files but there are 2?
Need to check this and redo if necessary.
*/




*********************Data importing and management steps******************************
/*need to think about these quite carefully, as in order to get an index date, I need to go through
and apply the INCLUSION criteria first, so I know which date to look back from for the EXCLUSION criteria
*/




*********************Data analysis steps**********************************************
/*NOTE: AFTER NIHR REPORT HAS BEEN DONE, I NEED TO REDO THE DATA MANAGEMENT SO THAT I DON'T BASE EVERYTHING
OFF AN INDEX DATE OF COPD DIAGNOSIS, BUT INSTEAD DO THE FOLLOWING:
1. Select those with a COPD diagnosis - create variable COPDdate (earliest COPD diagnosis)
2. Remove all people who are only ever over 80 during the study period
3. Remove all people who are only ever under 40 during the study period
4. Mark the date when the person reaches 40 - create variable attain40yrs
5. Mark the date when the person reaches 80 - create variable attain80yrs
6. Mark the earliest date when the person's lung function is (FEV1<60% predicted, FEV1/FVC ratio <70%) 
7. Mark the earliest date when the person is indicated to be either an ex or a current smoker (smokeDate)  
8. Select the latest date of 1., 4., 6. and 7., ensuring that this is not greater than 5, and assign this as the INDEX DATE
9. Repeat eligibility periods then occur after this date (based on FP/SAL and oral corticosteroid exposure)

*/

***********NOTE - WILL NEED REVISED AFTER NIHR REPORT TO SET THE INDEX DATE AS THE LATEST DATE OF THE 4 INCL CRITERIA*********

*NOTE: use "label data" to label stata file contents!
00a_nihrCOPD_HBs_cr.do /*Gets all the health behaviours for the cohort*/
00b_nihrCOPD_OxyTherCodelist_cr.do /*Creates the oxygen therapy codelist*/
00c_nihrCOPD_studyInterferenceCodelist_cr.do /*Creates the "things that interfere with a study" codelist (disease causing death, or serious mental disorders)*/
01_nihrCOPD_cohort_wAGE_cr.do /*Adds age and gender information data and removes those who never reached 40 or were only ever only 80 during follow-up*/
02_nihrCOPD_cohort_wSMOKE_cr.do /*Adds the earliest date that the person was recorded as being a current or ex smoker, then removes those who were never ex or current smokers*/
03_nihrCOPD_cohort_wSPIROMETRY_cr.do /*Adds spirometry data, finds earliest date that person meets requirements, removes those who never meet these requirements. ALSO CREATES INDEX DATE.*/
04_nihrCOPD_cohort_WOExcls /*Removes people with exclusions relating to previous lung conditions, asthma, substance abuse, oxyg ther, & conditions that would interfere with trial*/
05_nihrCOPD_cohort_PREVEXP_records_cr.do /*Creates files containing all and all previous therapy records for (1) FPSAL and (2) ICS for the cohort, and removes these people from the cohort*/
06_nihrCOPD_cohort_WOonICSTher_cr.do /*Removes people who are currently on ICS therapy (defined as continuous use for greater
than 6 weeks, with courses of oral corticosteroids separated by a period of less than 7 days considered as continuous use*/
07_nihrCOPD_cohort_WOFPSALPrior4weeks_cr /*Removes people with any previous exposure to study drug (FP/SAL). This is basically
the final cohort, needs people who had exacerbations within "run-in" period removed, but I need HES data for this. 16/10/2017
sent form and lists to Ian to send to ISAC*/


09_nihrCOPD_feasibilityCountsForBMJOpenProtocol_an.do /*obtains estimates of participant numbers for BMJOpen protocol*/
