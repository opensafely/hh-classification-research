/*==========================================================================================================================================

DO FILE NAME: global.do

AUTHOR:	Kevin Wing				
VERSION:				[eg v1.0]
DATE VERSION CREATED: 			
				
		
DATABASE: GPRD				[cprd]	

PROJECT: 
-Dave Leon/Roz care homes

DESCRIPTION OF FILE: 
- Sets up global files paths
								
DATASETS USED: 
- None
									
DO FILES NEEDED: 
None

CODELISTS NEEDED: 


DATASETS CREATED: 
None
=============================================================================================================================================================================*/

clear


*LOCAL (FOR DUMMY DATA)
/*
global Projectdir "/Users/kw/Documents"

*global codes "$Projectdir\00_codes"
global outputData "$Projectdir/draftSTATAoutput/households"
global dummyData "$Projectdir/output"

*set up ado filepath
sysdir
sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles"
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles"

set more off, perm
*/


***SERVER (FOR LIVE DATA)***
global Projectdir "E:\cohorts\households-research"

*global codes "$Projectdir\00_codes"
global outputData "$Projectdir/output"

*set up ado filepath
sysdir
sysdir set PLUS "$Projectdir\analysis\adofiles"
sysdir set PERSONAL "$Projectdir\analysis\adofiles"

set more off, perm














*cd "$doDir\TORCHdofiles_v$version"

