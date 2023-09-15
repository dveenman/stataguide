clear
set obs 10000
set seed 18

gen firm=ceil(_n/10)
bys firm: gen year=_n

gen x1=rnormal()
gen x2=rnormal() if year==1
replace x2=x2[_n-1] if x2==.
gen x=x1+x2

gen e1=rnormal()
gen e2=rnormal() if year==1
replace e2=e2[_n-1] if e2==.
gen e=e1+e2
gen y=e

reghdfe y x, cluster(firm year) noab
cluster2 y x, fcluster(firm) tcluster(year)    // Install from http://www.kellogg.northwestern.edu/faculty/petersen/htm/papers/se/cluster2.ado
vce2way reg y x, cluster(firm year)            // Install via ssc inst vce2way
vcemway reg y x, cluster(firm year)	           // Install via ssc inst vcemway
reg y x, vce(cluster firm year)                // Possible in Stata 18 only
	
di invttail(9, 0.009)
di invttail(9999, 0.009)
di invttail(9, 0.0215)
	
	