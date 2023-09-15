clear
set seed 1234

// Create dataset of 5000 obs of 100 groups (e.g., industries) with 50 obs each:
	set obs 5000
	gen n=_n
	gen group=ceil(n/50)
	sort group n
	by group: gen j=_n

// Create independent variables:
	* The x and f variables are determined by a common factor z within each group:
	gen z=rnormal() if j==1
	egen zfixed=mean(z), by(group)
	gen x=zfixed+rnormal()
	gen f=rnormal() if j==1
	egen ffixed=mean(f), by(group)
	replace f=ffixed+zfixed
	pwcorr x f

// Create outcome variable:
	gen y=x+f+rnormal()

// Regressing y on x leads to a biased coefficient:
	reg y x

// Controlling for f fixes this (but we cannot observe f!):
	reg y x f

// LSDV:	
	reg y i.group x

// Demeaned x and y:	
	egen meany=mean(y), by(group)
	gen yadj=y-meany
	egen meanx=mean(x), by(group)
	gen xadj=x-meanx
	reg yadj xadj
	
// Fixed effects work:
	areg y x, absorb(group)
	reg y x, absorb(group)
	reghdfe y x, absorb(group)
	
	gen inter=meany-meanx*_b[x]
	sum inter

	areg y x, absorb(group) cluster(group)
	reghdfe y x, absorb(group) cluster(group)
	