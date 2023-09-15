set seed 3
clear
local n=1000
set obs `n'
gen n=_n
gen firm=ceil(_n/10)
bysort firm: gen year=_n

gen x=rnormal() if year==1
replace x=x[_n-1] if year>1
replace x=x+rnormal()
gen e=rnormal() if year==1
replace e=e[_n-1] if year>1
replace e=e+rnormal()
gen y=e

reg y x
scalar b0=_b[x]
scalar t0=r(table)[3,1]

gen bboot=.
forvalues i=1(1)1000{
	qui preserve
	qui bsample, cluster(firm)
	qui reg y x
	qui restore
	qui replace bboot=_b[x] if n==`i'
	di `i'
}

sum bboot
scalar seboot=r(sd)
scalar zboot=b0/seboot
di "Original t-value: " t0 
di "Z-stat based on cluster-bootstrapped standard error: " zboot

reg y x, cluster(firm)

reg y x, vce(bootstrap, reps(1000) cluster(firm))
//bootstrap, reps(1000) cluster(firm): reg y x
