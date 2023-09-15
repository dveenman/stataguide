global path "C:\home\dv\PROJECTS\STATA"

****************************************************************************	
****************************************************************************		
* 1. Prepare file with actual reported quarterly earnings data:
****************************************************************************	
****************************************************************************	
	use "$path\InFiles\actu_epsus.dta", clear
	rename *, lower
	// Keep only quarterly earnings:
	keep if pdicity=="QTR"
	keep if measure=="EPS"
	drop if value==.
	gduplicates report ticker pends
	gduplicates tag ticker pends, gen(dupid)
	gsort dupid ticker pends
	keep if curr_act=="USD"
	gduplicates report ticker pends
	keep ticker pends value anndats
	ren pends fpedats
	ren value actual
	sort ticker fpedats
	save "$path\OutFiles\actualq.dta", replace

****************************************************************************	
****************************************************************************		
* 2. Prepare the individual-analyst quarterly forecast data:
****************************************************************************	
****************************************************************************	
	use "$path\InFiles\detu_epsus.dta", clear
	keep if report_curr=="USD"
	// Keep only those quarterly forecasts for the current or next quarter:
	keep if fpi=="6" | fpi=="7"
	// Drop ambiguous analyst codes:
	drop if analys==0
	drop if analys==1
	// Manage duplicate forecasts by same analyst for same firm on one day:
	gen n=_n
	gduplicates report analys ticker fpedats anndats
	gegen gr=group(analys ticker fpedats anndats)
	gegen count=count(gr),by(gr)
	gegen anntims2=group(anntims)
	gegen revtims2=group(revtims)
	gegen acttims2=group(acttims)	
	gsort count gr fpi -anntims2 -revdats -revtims2 -actdats -acttims2 n
	gduplicates drop analys ticker fpedats anndats, force
	ren anndats anndats_d
	sum value
	// Keep each analyst's latest forecast only:
	gsort ticker fpedats analys -anndats_d
	gduplicates drop ticker fpedats analys, force
	sum value
	// Attach actual earnings file:
	gsort ticker fpedats
	joinby ticker fpedats using "$path\OutFiles\actualq.dta", unmatched(master)
	drop _merge
	drop if actual==.
	drop if anndats==.
	drop if anndats_d>=anndats
	drop if anndats<=fpedats
	// Drop late EAs and stale forecasts at EA date
	drop if anndats>fpedats+120
	drop if anndats_d<anndats-120
	sum value
	keep ticker fpedats anndats* actual value analys estimator
	sort ticker fpedats analys
	save "$path\OutFiles\ibes_individual.dta", replace
	
	use "$path\OutFiles\ibes_individual.dta", clear
	// Compute forecast consensus:
	egen mean=mean(value), by(ticker fpedats)
	drop if mean==.
	duplicates drop ticker fpedats, force
	// Compute earnings surprises:
	replace actual=100*actual
	replace actual=round(actual)
	replace mean=100*mean
	replace mean=round(mean)
	gen surp=actual-mean
	sum surp,d
	tabstat surp if abs(surp)<=10, by(surp) stats(N)
	hist surp if abs(surp)<=10
	keep ticker surp fpedats anndats
	save "$path\OutFiles\consensus_surprise.dta", replace
	
	
	
	