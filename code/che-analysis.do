do "N:\Private\Che_Guevara_Coll_Mem\che-dataproc-latest.do"

*for var  sppostmat1 sppostmat2 sppostmat3:recode X 14=.
*for var  wrldpostmat1 wrldpostmat2 wrldpostmat3:recode X 12=.

for var  sppostmat1 sppostmat2 sppostmat3:gen Xbin=(X==1|X==3|X==4|X==8)
for var  wrldpostmat1 wrldpostmat2 wrldpostmat3:gen Xbin=(X==1|X==2|X==4|X==9)
egen postmat=rsum( sppostmat1bin sppostmat2bin sppostmat3bin)

foreach var of varlist sppostmat* wrldpostmat*  {
	qui ca `var' cohort10,norm(row)
	qui predict ca`var',rowscore(1)
	}
qui egen postmatscal=rsum2(ca*wrld* ca*sp*),allmiss

foreach var of varlist tradval1-tradval10 educrec polviews  {
	qui ca `var' cohort10,norm(row)
	qui predict ca`var',rowscore(1)
	}
for var casppostmat1 casppostmat1:replace X=X*-1
qui factor  cawrldpostmat3 cawrldpostmat2 cawrldpostmat1 casppostmat3 casppostmat2 casppostmat1,pcf
qui predict postmatfac

qui polychoric tradval2bin-tradval7bin

for var  tradval1- tradval10:gen Xbin=X<=2
qui tetrachoric tradval2bin-tradval7bin
mat tetracorr=r(corr)
qui factormat tetracorr,pcf n(3985) 
qui predict tradfacbin
qui factor catradval2-catradval7,pcf
qui predict tradfac
qui ca region ethid,norm(row)
qui predict caregid,rowscore(1)
center cohort cohort5 cohort10 
egen tradvalscal=rsum2(catradval2-catradval7),allmiss

for var postmatfac tradfac capolviews:replace X=X*-1
gen miss=0
for var c_cohort10  yearvar numchoices tradfac postmatfac  educrec polcat caregid:replace miss=1 if X==.

egen postmatscalbin=rsum2(sppost*bin),allmiss


*/generating cohort curves*/
qui xi3:mlogit figure ccohort10*ccohort10 educrec yearvar numchoices i.choice
forval i=1(1)11 {
	postgr3 ccohort10,outcome(`i') asis(ccohort10  _IccXcc) nodraw gen(cohortfig`i',replace) gen(cohortprob`i')
	}
local i=1
foreach name in "Fidel Castro"	"Carlos Menem" "Pinochet"	"Perón"	"Raúl Alfonsín" "Simón Bolivar"	///
 "Mario Vargas Llosa"	 "Diego Armando Maradona" 	"Gabriel García Márquez"	 "Che Guevara"	 "Otros" {
 	twoway connected cohortfig`i' cohort10,sort ylab(,nogrid) scheme(s1color) xlab(1910(10)1970,angle(45))  msize(large) ///
 	msym(diamond) legend(cols(1)) xsize(4.75) ysize(8) title("`name'") saving( "N:\Private\Che_Guevara_Coll_Mem\gr`i'.gph",replace) ///
 	ytitle("Predicted Probability") xtitle("Cohort") nodraw
 	local i=`i'+1
 }
 graph combine "N:\Private\Che_Guevara_Coll_Mem\gr1.gph"  ///
 					"N:\Private\Che_Guevara_Coll_Mem\gr4.gph" ///
 					"N:\Private\Che_Guevara_Coll_Mem\gr7.gph" ///
 					"N:\Private\Che_Guevara_Coll_Mem\gr8.gph" ///
 					"N:\Private\Che_Guevara_Coll_Mem\gr9.gph" ///
 					"N:\Private\Che_Guevara_Coll_Mem\gr10.gph",cols(2) ysize(8) xsize(6)


*/creating table of cohort significances
capture gen name=""
capture gen chi2lin=.
capture gen plin=.
capture gen chi2curv=.
capture gen pcurv=.
capture for var *lin *curv:replace X==.
qui xi3:mlogit figure ccohort10*ccohort10 yearvar numchoices i.choice
local i=1
foreach name in "Fidel Castro"	"Carlos Menem" "Pinochet"	"Perón"	"Raúl Alfonsín" "Simón Bolivar"	///
 "Mario Vargas Llosa"	 "Diego Armando Maradona" 	"Gabriel García Márquez"	 "Che Guevara"	 {
 qui test [`i']ccohort10
 replace chi2lin=r(chi2) in `i'
 replace plin=r(p) in `i'
 capture qui test [`i']_IccXcc
 capture replace chi2curv=r(chi2) in `i'
 capture replace pcurv=r(p) in `i'
 replace name="`name'" in `i'
 local i=`i'+1
 }
format  chi2lin plin chi2curv pcurv %9.3f
list name chi2lin plin chi2curv pcurv in 1/10,sep(0)



local i=1 
foreach spec in "ccohort10 yearvar numchoices" "ccohort10  yearvar numchoices postmat tradfac" ///
"ccohort10  yearvar numchoices postmat tradfac educrec" ///
"ccohort10*educrec  yearvar numchoices  postmat tradfac  left regid" {
xi3:mfp logit che `spec',cluster(id) aic
est store mod`i'
local i=`i'+1
}

estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

foreach var of varlist tradfac postmat educrec  {
	qui ca `var' cohort10,norm(row)
	qui predict ca`var',rowscore(1)
}

capture drop *__*
foreach var of varlist educrec polviewsrec tradfac caregid postmat yearvar numchoices {
	qui fracpoly logit che `var',degree(1)
}
replace Ieduc__1=Ieduc__1*-1

est drop _all
local i=1 
foreach spec in 	"c_cohort yearvar numchoices" ///
						"c_cohort  yearvar numchoices tradfacbin postmatscalbin" ///
						"c_cohort  yearvar numchoices tradfacbin postmatscalbin  Ieduc__1" ///
						"c_cohort  yearvar numchoices tradfacbin postmatscalbin  Ieduc__1 i.polcat caregid" {
						 xi3:logit che `spec' if miss~=1&latinperson>5,cluster(id)
						est store mod`i'
						local i=`i'+1
						}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

foreach var of varlist tradfac postmat educrec  {
	qui ca `var' cohort10,norm(row)
	qui predict ca`var',rowscore(1)
	}
save "N:\Private\Che_Guevara_Coll_Mem\che_final.dta",replace