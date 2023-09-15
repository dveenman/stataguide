global path "C:\home\dv\PROJECTS\STATA"	

timer clear
timer on 1

	use "$path\InFiles\crspdaily.dta", clear
	drop if ret==.
	drop if vwretd==.
	gen year=year(date)
	egen id=group(permno year)
	egen count=count(ret), by(id)
	sum count
	drop if count<100
	gen nonzero=1 if ret!=0
	egen countnz=count(nonzero), by(id)
	drop if countnz==0
	drop nonzero countnz
	
	****************************************************************************************************
	*Calculate r2 with simple market model
	egen meanx=mean(vwretd), by(id)
	egen meany=mean(ret), by(id)
	gen diffx=vwretd-meanx
	gen diffxx=diffx*diffx
	gen diffy=ret-meany
	gen diffyy=diffy*diffy
	gen diffxy=diffx*diffy
	egen sumdiffxx=sum(diffxx), by(id)
	replace sumdiffxx=sumdiffxx*(1/(count-1))
	egen sumdiffxy=sum(diffxy), by(id)
	replace sumdiffxy=sumdiffxy*(1/(count-1))
	gen beta=sumdiffxy/sumdiffxx
	gen alpha=meany-beta*meanx
	gen res=ret-alpha-beta*vwretd
	gen resres=res*res
	egen tss=sum(diffyy), by(id)
	egen rss=sum(resres), by(id)
	gen r2=1-(rss/tss)
	sum beta r2
	replace r2=.00001 if r2<.00001
	keep permno date year id beta r2 ret vwretd*
	****************************************************************************************************
	
	****************************************************************************************************
	*Calculate r2 with simple market model + lagged market variable
	drop if vwretdm1==.
	egen count=count(ret), by(id)
	egen meanx1=mean(vwretd), by(id)
	egen meanx2=mean(vwretdm1), by(id)
	egen meany=mean(ret), by(id)
	gen diffx1=vwretd-meanx1
	gen diffx2=vwretdm1-meanx2
	gen diffx1x1=diffx1*diffx1
	gen diffx1x2=diffx1*diffx2
	gen diffx2x2=diffx2*diffx2
	gen diffy=ret-meany
	gen diffyy=diffy*diffy
	gen diffx1y=diffx1*diffy
	gen diffx2y=diffx2*diffy
	egen sumdiffx2x2=sum(diffx2x2), by(id)
	egen sumdiffx1y=sum(diffx1y), by(id)
	egen sumdiffx1x2=sum(diffx1x2), by(id)
	egen sumdiffx2y=sum(diffx2y), by(id)
	egen sumdiffx1x1=sum(diffx1x1), by(id)
	gen beta1=((sumdiffx2x2*sumdiffx1y)-(sumdiffx1x2*sumdiffx2y))/((sumdiffx1x1*sumdiffx2x2)-(sumdiffx1x2*sumdiffx1x2))
	gen beta2=((sumdiffx1x1*sumdiffx2y)-(sumdiffx1x2*sumdiffx1y))/((sumdiffx1x1*sumdiffx2x2)-(sumdiffx1x2*sumdiffx1x2))
	gen alpha=meany-beta1*meanx1-beta2*meanx2
	gen res=ret-alpha-beta1*vwretd-beta2*vwretdm1
	egen idvol=sd(res), by(id)
	gen resres=res*res
	egen rss=sum(resres),by(id)
	egen tss=sum(diffyy),by(id)
	gen r22=1-(rss/tss)
	replace r22=.00001 if r22<.00001
	****************************************************************************************************

	duplicates drop permno year, force
	keep permno year beta* r2* 
	save "$path\OutFiles\firmyears_r2.dta", replace

timer off 1	
timer list
