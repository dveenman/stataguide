set seed 1234
clear
local n=1000
local nboot=100
local sims=1000 // Note: should not be bigger than n here
set obs `n'
gen n=_n
gen firm=ceil(_n/10)
bysort firm: gen year=_n

capture program drop panelframe
program define panelframe
	qui gen x=rnormal() if year==1
	qui replace x=x[_n-1] if year>1
	qui replace x=x+rnormal()
	qui gen e=rnormal() if year==1
	qui replace e=e[_n-1] if year>1
	qui replace e=e+rnormal()
	qui gen y=e	
end

capture program drop bootprogram
program define bootprogram
	syntax, nb(integer)
	tempvar bboot
	qui gen `bboot'=.
	forvalues i=1(1)`nb'{
		qui preserve
		qui bsample, cluster(firm)
		qui reg y x
		qui restore
		qui replace `bboot'=_b[x] if n==`i'
	}
	qui sum `bboot'
	scalar seboot=r(sd)
end

gen b=.
gen se_1=.
gen se_2=.
gen se_3=.
gen sig_1=0 if n<=`sims'
gen sig_2=0 if n<=`sims'
gen sig_3=0 if n<=`sims'
forvalues j=1(1)`sims'{
	// Create dataset:
	panelframe
	// Basic regression:
	qui reg y x
	scalar b0=_b[x]
	qui replace b=_b[x] if n==`j'
	qui replace se_1=_se[x] if n==`j'
	qui replace sig_1=1 if r(table)[4,1]<=0.05 & n==`j'
	// Basic regression with clustered SEs:
	qui reg y x, cluster(firm)
	qui replace se_2=_se[x] if n==`j'
	qui replace sig_2=1 if r(table)[4,1]<=0.05 & n==`j'
	local df_r=e(df_r)
	// Bootstrapped clustered SEs:
	bootprogram, nb(`nboot')
	qui replace se_3=seboot if n==`j'
	local t=b0/seboot
	local p=2*ttail(`df_r', abs(`t'))
	qui replace sig_3=1 if `p'<=0.05 & n==`j'	
	drop y x e
	di `j'
}

sum b se_* sig_*

/*

. sum b se_* sig_*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
           b |      1,000    .0006283    .0562508  -.1367834    .198946
        se_1 |      1,000    .0316782    .0017903   .0266349   .0371801
        se_2 |      1,000    .0558253    .0064997     .03763   .0778802
        se_3 |      1,000    .0554843    .0075367   .0350296   .0866635
       sig_1 |      1,000        .276    .4472405          0          1
-------------+---------------------------------------------------------
       sig_2 |      1,000        .048    .2138732          0          1
       sig_3 |      1,000        .051    .2201078          0          1

