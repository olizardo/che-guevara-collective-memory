do "Z:\Che_Guevara_Coll_Mem\che_dataproc.do"

drop *pred*
local i=1
foreach var of varlist che castro bolivar peron {
	qui xi3:fracpoly logit `var' cohort10 year numchoices
	postgr3 Icoho__1,asis(Icoho__1 Icoho__2) nodraw gen(`var'pred)
	test Icoho__1 Icoho__2
	replace chi2=r(chi2) in `i'
	replace p=r(p) in `i'
	local i=`i'+1

}
format chi2 p %9.3f
list lab chi2 p in 1/4,clean
twoway connected  chepred castropred bolivarpred peronpred cohort10,sort xlab(1910(10)1970) ylab(,nogrid) ytitle("") ///
legend(label(1 "Che Guevara") label(2 "Fidel Castro") label(3 "Simon Bolivar") label(4 "Juan Peron")) xsize(6) ysize(5) ///
msize(large large large large)

qui xi3:logit castro cohort10*cohort10 numchoices  yearvar valuescal educsc1 polviewssc1,cluster(idnum)
est store mod`i'
local i=`i'+1
qui xi3:logit peron cohort10 numchoices  yearvar valuescal educsc1 polviewssc1,cluster(idnum)
est store mod`i'

drop *pred*
est drop _all
local i=1
foreach specification in "numchoices  yearvar " "numchoices  yearvar  tradfac postmat" ///
"numchoices  yearvar tradfac postmat educrec" "numchoices  yearvar tradfac postmat educrec left"  {
	qui logit che cohort `specification' ,cluster(idnum)
	est store mod`i'
	*postgr3 cohort10,nodraw gen(cohortpred`i')	
	local i=`i'+1
}

estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) drop() ///
stats(chi2 aic  N,fmt(%9.2f  %9.0f) star(chi2)) starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 


lab var cohort10 "Birth Cohort"
lab var teduc "Years of Education"
lab var numchoices "Number of Choices"
lab var year "Survey Year"
lab var  _Ipolcat_2 "Political Orientation (Moderate)
lab var  _Ipolcat_3 "Political Orientation (Right)
lab var  _Ipolcat_4 "Political Orientation (Other)
lab var tradfac1 "Traditional Values Factor Score"
lab var postmatfac1 "Post-Materialism Factor Score"


twoway connected cohortpred1 cohortpred2 cohortpred3 cohortpred4 cohort10,sort xlab(1910(10)1970) ylab(,nogrid) ytitle("") ///
legend(label(1 "Model 1") label(2 "Model 2") label(3 "Model 3") label(4 "Model 4")) ///
xsize(6.5) ysize(5) yline(.0489335,lc(gray) lp(dash)) text(.051 1930 "Expected Probability") msize(large large large large)

drop castropol*
xi3:logit castro cohort10 numchoices year teduc  i.polcat*cohort10,cluster(idnum) 
postgr3 cohort10,by(polcat) gen(castropol)
twoway connected  castropol1 castropol2 cohort10,sort xlab(1910(10)1970) ylab(0(.05).2,nogrid) ytitle("") ///
legend(label(1 "Leftists") label(2 "Moderates")) xsize(6) ysize(5) msize(large large) title("Fidel Castro") 
