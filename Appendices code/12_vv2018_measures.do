global path "C:\home\dv\PROJECTS\STATA"

	// Remove some duplicates because of multiple announcements in one month; keep most recent only: 
	use "$path\OutFiles\consensus_surprise.dta", clear
	gen y=year(anndats)
	gen m=month(anndats)
	gsort ticker y m -anndats -fpedats
	duplicates drop ticker y m, force
	keep ticker y m surp fpedats anndats
	save "$path\OutFiles\consensus_surprise_clean.dta", replace

	use "$path\InFiles\crspm_ibes.dta", clear
	keep ticker year month
	// Create new year and month variables for previous month:
	gen y=year
	gen m=month-1
	replace y=y-1 if m<1
	replace m=m+12 if m<1
	// Expand the dataset to have the [-35,0] month period for each firm-month:
	gen n=_n
	expand(36)
	sort n
	by n: gen m_=_n
	gen eventm=1 if m_==1
	replace m=m+1-m_
	replace y=y-1 if m<1
	replace m=m+12 if m<1
	replace y=y-1 if m<1
	replace m=m+12 if m<1
	replace y=y-1 if m<1
	replace m=m+12 if m<1
	drop m_ n
	// Attach earnings surprise data:
	sort ticker y m eventm
	duplicates drop ticker y m, force
	joinby ticker y m using "$path\OutFiles\consensus_surprise_clean.dta", unmatched(master)
	drop _merge
	sum year surp
	// Create variable to store cumulative info on previous pessimism:
	sort ticker y m eventm
	duplicates drop ticker y m, force
	egen tid=group(ticker)
	egen ym=group(y m)
	tsset tid ym
	gen count=1 if surp!=. & surp!=0
	gen pess=0 if surp<0
	replace pess=1 if surp!=. & surp>0
	sum pess	
	gen p1=0
	gen c1=0
	// Create variables to store previous 12 quarterly surprises:
	forvalues i=1(1)12{
		gen surpm`i'=.
	}
	// Create variable for checking the fiscal quarter end and announcement date:
	gen surpdate=.
	gen surpdateann=.
	forvalues i=1(1)36{
		qui replace p1=p1+l`i'.pess if l`i'.pess!=. & c1<12
		qui replace surpm1=l`i'.surp if surpm1==. & l`i'.surp!=. & c1<1
		forvalues u=1(1)11{
			qui local q=`u'+1
			qui replace surpm`q'=l`i'.surp if surpm`q'==. & l`i'.surp!=. & c1==`u'
		}
		qui replace surpdate=l`i'.fpedats if surpdate==. & l`i'.fpedats!=. & c1<1
		qui replace surpdateann=l`i'.anndats if surpdateann==. & l`i'.anndats!=. & c1<1
		qui replace c1=c1+l`i'.count if l`i'.count!=. & c1<12
		di `i'
	}
	// Require at least 4 quarterly earnings surprises:
	tabstat c1, by(c1) stats(N)
	drop if c1<4
	// Create consensus pessimism measure:
	gen pess_consensus=p1/c1
	sum pess_consensus
	keep if eventm==1
	keep ticker y m pess_consensus surpm* surpdate*
	format surpdate* %d
	forvalues i=1(1)12{
		replace surpm`i'=surpm`i'/100
	}
	gen year=y
	gen month=m
	replace month=month+1
	replace year=year+1 if month>12
	replace month=month-12 if month>12
	drop y m
	save "$path\OutFiles\pess_consensus.dta", replace
	****************************************
	
****************************************************************************	
* Step A: Create a file with unique analyst-ticker-year-month combinations
	use "$path\OutFiles\ibes_individual.dta", clear
	// Remove some duplicates because of multiple announcements in one month; keep most recent only: 
	gen y=year(anndats)
	gen m=month(anndats)
	gen invdats=1000000/anndats
	gen invdats2=1000000/fpedats
	sort analys ticker y m invdats invdats2
	duplicates drop analys ticker y m, force
	// Create surprise and individual pessimism variables:
	replace actual=100*actual
	replace actual=round(actual)
	replace value=100*value
	replace value=round(value)
	gen pessimist=0 if value!=. & value>actual
	replace pessimist=1 if actual!=. & actual>value
	sum pessimist
	// Now assume analyst has been active 6 months before a specific EA to create a panel of analyst-year-months:
	gen year=year(anndats)
	gen month=month(anndats)
	keep analys ticker year month pessimist anndats anndats_d fpedats
	forvalues i=1(1)6{
		gen m_`i'=`i'
	}
	gen id=_n
	reshape long m_, i(id) j(n)
	replace anndats=. if m_>1
	replace pessimist=. if m_>1
	replace month=month+1-n
	replace year=year-1 if month<1
	replace month=month+12 if month<1
	sort analys ticker year month anndats
	duplicates drop analys ticker year month, force
	gen m=month
	gen y=year
	egen ym=group(y m)
	sort analys ym
	keep analys ticker y m ym pessimist anndats 
	// Make sure that each analyst covers at least 2 firms
	sort analys ticker
	by analys: gen nr=_n
	tsset analys nr
	egen tickerid=group(ticker)
	gen nr2=nr if tickerid!=l.tickerid
	drop tickerid
	egen count=count(nr2), by(analys)
	sum count,d
	drop if count<2
	keep analys ticker y m pessimist anndats
	// Create variable for unique analysts and unique analyst-year-month combinations:
	egen ym=group(y m)
	sort analys ym ticker
	egen aid=group(analys)
	egen aidym=group(analys ym)
	sort aidym
	// Create date variable for later verification of no overlap with return month:
	gen hulpdate=mdy(m,1,y) 
	replace hulpdate=hulpdate-1
	format hulpdate %d
	gen cp=.
	gen tot=.
	gen maxd=.
	compress
	save "$path\OutFiles\ibes_individual_pess.dta", replace

// Step B: Calculate analyst pessimism measure over past 12 months
	// For every combination of analyst and year-month, we look back at all individual 
	//    forecast errors based on earnings releases in the previous 12 months;
	//    in the process, split the files up in smaller chunks to speed up the process
	use "$path\OutFiles\ibes_individual_pess.dta", clear
	local y=5
	sum aid
	local h=ceil(r(max)/`y')
	local g=r(max)
	forvalues a=1(1)`h'{
		qui use "$path\OutFiles\ibes_individual_pess.dta" if aid>(`a'-1)*`y' & aid<=`a'*`y', clear
		qui sum aid
		local f=r(min)
		local k=r(max)
		forvalues i=`f'(1)`k'{
			qui sum aidym if aid==`i'
			local m=r(min)
			local n=r(max)
			forvalues j=`m'(1)`n'{
				qui sum hulpdate if aid==`i' & aidym==`j'
				qui local d=r(min)
				qui sum pessimist if aid==`i' & aidym<`j' & anndats>=`d'-365 & anndats<`d'
				qui replace tot=r(N) if aid==`i' & aidym==`j'
				qui replace cp=r(sum) if aid==`i' & aidym==`j'
				qui sum anndats if aid==`i' & aidym<`j' & anndats>=`d'-365 & anndats<`d'
				qui replace maxd=r(max) if aid==`i' & aidym==`j'
			}
			di `a' ":::" `h' "   ++++++++" "   " `i' "//\\" `g'
		}
		qui save "$path\OutFiles\Temp\ibes_individual_pess_`a'.dta", replace
	}
	use "$path\OutFiles\ibes_individual_pess.dta", clear
	local y=5
	sum aid
	local h=ceil(r(max)/`y')
	local g=r(max)
	use "$path\OutFiles\Temp\ibes_individual_pess_1.dta", clear
	forvalues a=2(1)`h'{
		qui append using "$path\OutFiles\Temp\ibes_individual_pess_`a'.dta"
		di `a' " / " `h'
	}
	keep analys ticker y m tot cp maxd 
	drop if tot==.
	drop if tot==0
	gen pessclean=cp/tot
	sort analys ticker y m
	// Aggregate by firm-year-month
	egen pess_individual=mean(pessclean), by(ticker y m)
	egen md=max(maxd), by(ticker y m)
	duplicates drop ticker y m, force
	sum pess_individual
	keep ticker y m pess_individual md 
	compress
	sort ticker y m
	gen year=y
	gen month=m
	replace month=month+1
	replace year=year+1 if month>12
	replace month=month-12 if month>12
	drop y m
	save "$path\OutFiles\pess_individual.dta", replace

****************************************************************************	
****************************************************************************		
* 5. Combine data:
****************************************************************************	
****************************************************************************		
	use "$path\InFiles\crspm_ibes.dta", clear
	sum ret
	// Attach consensus pessimism measure
	joinby ticker year month using "$path\OutFiles\pess_consensus.dta", unmatched(master)
	drop _merge
	sum ret pess_consensus
	// Attach individual pessimism measure
	joinby ticker year month using "$path\OutFiles\pess_individual.dta", unmatched(master)
	drop _merge
	sum ret pess_consensus pess_individual
	drop if pess_consensus==.
	drop if pess_individual==.
	// Verify that prior pessimism data really measured before start of the month:
	gen datehulp=mdy(month(date),1,year(date))
	gen diff=datehulp-surpdateann
	sum diff,d
	drop diff
	gen diff=datehulp-md
	sum diff,d
	drop diff
	save "$path\OutFiles\crspm_ibes_pess_measures.dta", replace


