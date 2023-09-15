set seed 3
clear
local n=1000
set obs `n'
gen n=_n

gen double x=rnormal()
gen double y=abs(x)*rnormal()
reg y x
scalar b0=_b[x]
scalar t0=r(table)[3,1]

gen bboot=.
forvalues i=1(1)1000{
	qui preserve
	qui bsample
	qui reg y x
	qui restore
	qui replace bboot=_b[x] if n==`i'
	di `i'
}

sum bboot
scalar seboot=r(sd)
scalar zboot=b0/seboot
di "Original t-value: " t0 
di "Z-stat based on bootstrapped standard error: " zboot

reg y x, r

reg y x, vce(bootstrap, reps(1000))
//bootstrap, reps(1000): reg y x
