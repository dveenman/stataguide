global path "C:\home\dv\PROJECTS\STATA"	

	use "$path\InFiles\ibes_statsumu_epsus.dta", clear
	ren fpedats pends
	keep ticker statpers pends medest
	sort ticker pends
	joinby ticker pends using "$path\InFiles\ibes_actu_epsus.dta", unmatched(master)
	drop _merge
	drop if medest==.
	drop if value==.
	drop if statpers>=anndats

	gsort ticker pends -statpers
	duplicates drop ticker pends, force
	
	gen valueround=round(100*value)
	gen forecastround=round(100*medest)
	gen ferror=valueround-forecastround

	tabstat ferror if abs(ferror)<=10,by(ferror) stats(N)
	hist ferror if abs(ferror)<=10

	gen meet=0
	replace meet=1 if ferror==0 | ferror==1

	gen fyear=year(pends)
	replace fyear=fyear-1 if month(pends)<6
	duplicates drop ticker fyear, force
	sort ticker fyear
	save "$path\OutFiles\meet.dta", replace

	use "$path\InFiles\comp_firmyears.dta", clear
	joinby ticker fyear using "$path\OutFiles\meet.dta", unmatched(master)
	drop _merge
	drop if at==.
	sum at meet
	drop if meet==.
	sort gvkey fyear
	save "$path\OutFiles\firmyears_meet.dta", replace


