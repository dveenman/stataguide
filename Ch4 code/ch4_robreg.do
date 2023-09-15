global path "C:\home\dv\PROJECTS\STATA"	

////////////////////////////////////////////
// BIAS ILLUSTRATION
////////////////////////////////////////////
	clear
	set seed 1234
	set obs 1000
	
	gen x=rnormal()
	gen y=x+rnormal()

	reg y x
	
	replace x=x*10 if _n<=100
	reg y x
	avplots
	graph export "$path\Doc\fig_outlier.pdf", as(pdf) name("Graph") replace
	
	rreg y x	
	robreg mm y x
	robreg mm y x, eff(95)
	robreg mm y x, eff(70)

	reg y x
		margins, dydx(*) saving(file0, replace)
	qreg y x
		margins, dydx(*) saving(file1, replace)
	rreg y x
		margins, dydx(*) saving(file2, replace)
	robreg mm y x, eff(95)
		margins, dydx(*) saving(file3, replace)
	robreg mm y x, eff(90)
		margins, dydx(*) saving(file4, replace)
	robreg mm y x, eff(85)
		margins, dydx(*) saving(file5, replace)
	robreg mm y x, eff(70)
		margins, dydx(*) saving(file6, replace)
	robreg mm y x, eff(50)	
		margins, dydx(*) saving(file7, replace)
	robreg s y x
		margins, dydx(*) saving(file8, replace)

	combomarginsplot file0 file1 file2 file3 file4 file5 file6 file7 file8, ///
		labels("OLS" "Median" "RREG" "MM95" "MM90" "MM85" "MM70" "MM50" "S") ///
		xtitle("Estimator") ///
		ytitle("Coefficient estimate and 95% confidence interval") ///
		title("")
	graph export "$path\Doc\fig_outlier_estimations.pdf", as(pdf) name("Graph") replace
	

////////////////////////////////////////////
// STANDARD ERRORS
////////////////////////////////////////////
	clear
	set seed 1234
	set obs 1000
	gen firm=ceil(_n/10)
	bys firm: gen year=_n
	
	gen x=rnormal() if year==1
	replace x=x[_n-1] if year>1
	replace x=x+rnormal()
	gen e=rnormal() if year==1
	replace e=e[_n-1] if year>1
	replace e=e+rnormal()
	gen y=x+e
	replace x=x*10 if _n<=100

	reg y x
	reg y x, cluster(firm)

	robreg mm y x, eff(70) 
	robreg mm y x, eff(70) cluster(firm)
	
	robreg mm y x, eff(70) 
	predict w70, weights
	reg y x [aw=w70], cluster(firm)
	
	robreg mm y x, eff(70) cluster(firm)
	roboot y x, nboot(9999) eff(70) seed(1234) cluster(firm)


////////////////////////////////////////////
// EFFICIENCY ILLUSTRATION
////////////////////////////////////////////
	clear
	set seed 1234
	set obs 1000
	
	gen x=rnormal()
	gen y=x+exp(rnormal())

	reg y x
	avplots
	
	robreg m y x, eff(95) biw
	predict wt1, weights
	sum wt1, d
	pwcorr wt wt1 
	
	robreg mm y x

	reg y x, r
		margins, dydx(*) saving(file0, replace)
	robreg q y x
		margins, dydx(*) saving(file1, replace)
	robreg m y x, eff(95)
		margins, dydx(*) saving(file2, replace)		
	robreg mm y x, eff(95)
		margins, dydx(*) saving(file3, replace)
	robreg mm y x, eff(90)
		margins, dydx(*) saving(file4, replace)
	robreg mm y x, eff(85)
		margins, dydx(*) saving(file5, replace)
	robreg mm y x, eff(70)
		margins, dydx(*) saving(file6, replace)
	robreg mm y x, eff(50)	
		margins, dydx(*) saving(file7, replace)
	robreg s y x
		margins, dydx(*) saving(file8, replace)

	combomarginsplot file0 file1 file2 file3 file4 file5 file6 file7 file8, ///
		labels("OLS" "Median" "M95" "MM95" "MM90" "MM85" "MM70" "MM50" "S") ///
		xtitle("Estimator") ///
		ytitle("Coefficient estimate and 95% confidence interval") ///
		title("") ///
		yscale(range(.8 1.1)) ///
		ylabel(0.8(0.1)1.1)
	graph export "$path\Doc\fig_outlier_estimations2.pdf", as(pdf) name("Graph") replace
		
		
		
		
