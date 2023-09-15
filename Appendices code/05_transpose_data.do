global path "C:\home\dv\PROJECTS\STATA"	

	use "$path\InFiles\funda_ceq_nld.dta", clear
	destring gvkey, replace
	drop if ceq==.
	duplicates report gvkey datadate
	
	sum ceq
	gen n=_n
	expand(12)
	sum ceq

	bysort n: gen m_=_n
	gen year=year(datadate)
	gen month=month(datadate)
	replace month=month+m_+4
	replace year=year+2 if month>24
	replace month=month-24 if month>24
	replace year=year+1 if month>12
	replace month=month-12 if month>12

	duplicates report gvkey year month
	gsort gvkey year month -datadate
	duplicates drop gvkey year month, force
	keep gvkey year month ceq
	save "$path\OutFiles\ceq_monthly_nld.dta", replace

	use "$path\OutFiles\monthlyret_nld.dta", clear
	sum year month ret
	joinby gvkey year month using "$path\OutFiles\ceq_monthly_nld.dta", unmatched(master)
	drop _merge
	sum gvkey retm lagmv ceq
	save "$path\OutFiles\monthlyret_nld_ceq.dta", replace

	