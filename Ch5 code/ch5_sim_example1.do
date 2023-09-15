set seed 1234
clear
set obs 5000
gen double z=rnormal()
gen double x=.5*z+rnormal()
gen double y=.5*x+.5*z+rnormal()

gen double z_alt=.1+.3*rnormal()
sum z_alt

reg y x
reg y x z

// Assess bias in coefficient:
set seed 1234
clear
local n=5000
set obs `n'
gen n=_n
gen b1=.
gen b2=.
forvalues i=1(1)`n'{
	qui gen double z=rnormal()
	qui gen double x=.5*z+rnormal()
	qui gen double y=.5*x+.5*z+rnormal()
	qui reg y x
	qui replace b1=_b[x] if n==`i'	
	qui reg y x z
	qui replace b2=_b[x] if n==`i'
	qui keep n b1 b2
	di `i' " / " `n'
}
sum b1 b2

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          b1 |      5,000    .6999475    .0139404   .6570377   .7572708
          b2 |      5,000    .5001474     .014336   .4485804   .5555762
*/

ttest b1=.5
ttest b2=.5

/*
. ttest b1=.5

One-sample t test
------------------------------------------------------------------------------
Variable |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
      b1 |   5,000    .6999475    .0001971    .0139404     .699561     .700334
------------------------------------------------------------------------------
    mean = mean(b1)                                               t =  1.0e+03
H0: mean = .5                                    Degrees of freedom =     4999

    Ha: mean < .5               Ha: mean != .5                 Ha: mean > .5
 Pr(T < t) = 1.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 0.0000

. ttest b2=.5

One-sample t test
------------------------------------------------------------------------------
Variable |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
      b2 |   5,000    .5001474    .0002027     .014336      .49975    .5005449
------------------------------------------------------------------------------
    mean = mean(b2)                                               t =   0.7272
H0: mean = .5                                    Degrees of freedom =     4999

    Ha: mean < .5               Ha: mean != .5                 Ha: mean > .5
 Pr(T < t) = 0.7664         Pr(|T| > |t|) = 0.4671          Pr(T > t) = 0.2336
*/

// Assess type 1 error rate:
set seed 1234
clear
local n=5000
set obs `n'
gen n=_n
gen b1=.
gen b2=.
gen sig1=0 if n<=`n'
gen sig2=0 if n<=`n'
forvalues i=1(1)`n'{
	qui gen double z=rnormal()
	qui gen double x=.5*z+rnormal()
	qui gen double y=.5*x+.5*z+rnormal()
	qui reg y x
	qui replace b1=_b[x] if n==`i'
	qui local t=(_b[x]-0.5)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig1=1 if `p'<=0.05 & n==`i'	
	qui reg y x z
	qui replace b2=_b[x] if n==`i'
	qui local t=(_b[x]-0.5)/_se[x]
	qui local p=2*ttail(e(df_r), abs(`t'))
	qui replace sig2=1 if `p'<=0.05 & n==`i'	
	qui keep n b1 b2 sig1 sig2
	di `i' " / " `n'
}

sum sig1 sig2

/*

