clear
set obs 10000
set seed 2

gen firm=ceil(_n/10)
bys firm: gen year=_n

gen x1=rnormal()
gen x2=rnormal() if firm==1
gegen max=max(x2), by(year)
replace x2=max
drop max
gen x=x1+x2

gen e1=rnormal()
gen e2=rnormal() if firm==1
gegen max=max(e2), by(year)
replace e2=max
drop max
gen e=e1+e2
gen y=e

reg y x
reg y x, cluster(year) 
boottest x=0, seed(1234567)
	
wildbootstrap reg y x, cluster(year) rseed(1234567)  // Only in Stata 18
	