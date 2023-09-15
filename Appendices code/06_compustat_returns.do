global path "C:\home\dv\PROJECTS\STATA"	

	// Data preparation:
	use "$path\InFiles\compdaily_nld.dta", clear
	keep if fic=="NLD"
	keep if exchg==104
	keep if curcdd=="EUR"
	destring gvkey, replace
	duplicates report gvkey datadate
	drop if iid==""
	drop if prirow==""
	keep if iid==prirow
	drop iid prirow
	duplicates report gvkey datadate

	gen year=year(datadate)
	gen month=month(datadate)
	sort gvkey year month datadate
	// Count number of active firms per day
	gen nonzero=1 if prccd!=prccd[_n-1] & gvkey==gvkey[_n-1]
	egen count=count(nonzero), by(datadate)
	// Count number of firms available per month
	sort year month gvkey
	egen firmmonth=group(year month gvkey)
	egen min=min(firmmonth), by(year month)
	replace firmmonth=firmmonth+1-min
	egen totalfirms=max(firmmonth), by(year month)
	// Compare counts:
	gen ratio=count/totalfirms
	sum ratio,d
	sort ratio datadate
	drop if ratio<.1
	drop firmmonth min totalfirms count nonzero ratio
	sort gvkey datadate
	
	gsort gvkey -datadate
	gen splitday=1 if split!=.
	replace split=1 if split==.
	replace split=split[_n-1]*split[_n] if gvkey[_n]==gvkey[_n-1]
	sort gvkey datadate
	replace split=split[_n+1] if splitday==1
	drop splitday
	gen prccd_adj=prccd/split
	gen div_adj=div/split
	save "$path\OutFiles\compdaily_nld_splitadj.dta", replace

	// Compute return variable:
	use "$path\OutFiles\compdaily_nld_splitadj.dta", clear
	egen firmid=group(gvkey)
	egen timeid=group(datadate)
	tsset firmid timeid
	replace div_adj=0 if div_adj==.
	gen retdaily=(d.prccd_adj+div_adj)/l.prccd_adj
	sum retdaily, d
	save "$path\OutFiles\dailyret_nld.dta", replace

	// Cleaning:
	use "$path\OutFiles\dailyret_nld.dta", clear
	egen minp=min(prccd), by(gvkey year month)
	sort gvkey year month datadate
	by gvkey year month: gen d=_n
	gen lagminp=minp[_n-1] if d==1 & gvkey==gvkey[_n-1]
	egen lagminp2=max(lagminp), by(gvkey year month)
	drop if lagminp2<1
	sum retdaily, d
	tsset
	gen filter=1 if retdaily>1 & ((1+l.retdaily)*(1+retdaily)-1)<.2
	replace filter=1 if l.retdaily>1 & ((1+l.retdaily)*(1+retdaily)-1)<.2
	sum retdaily l.retdaily if filter==1
	replace retdaily=. if filter==1
	replace retdaily=. if f.filter==1
	replace retdaily=. if retdaily>2
	keep gvkey year month datadate retdaily monthend prccd* div_adj cshoc
	sum retdaily, d
	save "$path\OutFiles\dailyret_nld_clean.dta", replace
	
	// Creating monthly returns:
	use "$path\OutFiles\dailyret_nld_clean.dta", clear
	sort gvkey year month datadate
	egen maxd=max(datadate), by(gvkey year month)
	replace monthend=1 if datadate==maxd
	egen divsum=sum(div_adj), by(gvkey year month)
	keep if monthend==1
	egen ym=group(year month)
	tsset gvkey ym
	gen retm=(d.prccd_adj+divsum)/l.prccd_adj
	sum retm, d
	gen mv=prccd*cshoc
	gen lagmv=l.mv
	drop if retm==.
	drop if mv==.
	drop if lagmv==.
	keep if year(datadate)>2000 & year(datadate)<2022
	keep gvkey year month retm mv lagmv
	sort gvkey year month
	save "$path\OutFiles\monthlyret_nld.dta", replace

	use "$path\OutFiles\monthlyret_nld.dta", clear
	sum retm, d
	
	
	
	
	
