set seed 1234
clear
local n=5000
set obs `n'
gen n=_n
gen b1=.
gen b2=.
gen se1=.
gen se2=.
gen sig1=0 if n<=`n'
gen sig2=0 if n<=`n'
forvalues i=1(1)`n'{
	qui gen double x=rnormal()
	qui gen double y=x+abs(x)*rnormal()
	qui reg y x
	qui replace b1=_b[x] if n==`i'
	qui replace se1=_se[x] if n==`i'
	qui local t=(_b[x]-1)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig1=1 if `p'<=0.05 & n==`i'	
	qui reg y x, r
	qui replace b2=_b[x] if n==`i'
	qui replace se2=_se[x] if n==`i'
	qui local t=(_b[x]-1)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig2=1 if `p'<=0.05 & n==`i'	
	qui keep n b1 b2 se1 se2 sig1 sig2
	di `i' " / " `n'
}

sum b1 b2 se1 se2 sig1 sig2

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          b1 |      5,000    1.000118    .0244742   .9160714   1.083236
          b2 |      5,000    1.000118    .0244742   .9160714   1.083236
         se1 |      5,000    .0141347    .0002455   .0132134   .0150223
         se2 |      5,000    .0244537    .0008664   .0216258   .0292998
        sig1 |      5,000        .264    .4408434          0          1
-------------+---------------------------------------------------------
        sig2 |      5,000       .0508     .219611          0          1
*/

set seed 1234
clear
local n=5000
set obs `n'
gen n=_n
gen b1=.
gen b2=.
gen se1=.
gen se2=.
gen sig1=0 if n<=`n'
gen sig2=0 if n<=`n'
forvalues i=1(1)`n'{
	qui gen double x=rnormal()
	qui gen double y=x+rnormal()
	qui reg y x
	qui replace b1=_b[x] if n==`i'
	qui replace se1=_se[x] if n==`i'
	qui local t=(_b[x]-1)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig1=1 if `p'<=0.05 & n==`i'	
	qui reg y x, r
	qui replace b2=_b[x] if n==`i'
	qui replace se2=_se[x] if n==`i'
	qui local t=(_b[x]-1)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig2=1 if `p'<=0.05 & n==`i'	
	qui keep n b1 b2 se1 se2 sig1 sig2
	di `i' " / " `n'
}

sum b1 b2 se1 se2 sig1 sig2

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          b1 |      5,000    1.000017    .0141878   .9522513   1.046322
          b2 |      5,000    1.000017    .0141878   .9522513   1.046322
         se1 |      5,000    .0141412    .0001989   .0134908   .0148087
         se2 |      5,000    .0141357    .0002833   .0131112   .0151595
        sig1 |      5,000       .0488    .2154712          0          1
-------------+---------------------------------------------------------
        sig2 |      5,000       .0484    .2146314          0          1
*/
