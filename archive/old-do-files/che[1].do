clear
*/recoding 1993 data*/
use "N:\Private\spain\spainjan93.dta", clear
ren  b49 latinperson1
ren  b51 latinperson2
gen year=1993
ren e9 gender
ren e10 age
ren e12 marital
ren e13 relhead
ren e14 hhsize
ren e15 occ
ren e17 headocc
ren e19 paocc
ren e21 educ
ren e22 paeduc
ren e23 relig
ren e24 howrelig
ren e25 polviews
ren e26 class
ren e27 ethid
ren e28 placeborn
ren e30 reg15
ren e32 region
ren e34 commun
ren e36 citysize
ren e37 finc

gen id=_n
keep year id latinperson* gender-finc 
save "N:\Private\spain\spainjan93_red.dta",replace


*/generating composite data set with sociodemographic variables only*/
use "N:\Private\spain\spainjan91.dta", clear
gen year=1991
gen id=_n
keep year id latinperson1 latinperson2 latinperson3 gender-finc 
save "N:\Private\spain\spainjan91_red.dta",replace
use "N:\Private\spain\spainjan92.dta", clear
gen year=1992
gen id=_n
keep year id latinperson1 latinperson2 gender-finc
save "N:\Private\spain\spainjan92_red.dta",replace
use "N:\Private\spain\spainjan91_red.dta", clear

forvalues i=92(1)93 {
	append using "N:\Private\spain\spainjan`i'_red.dta"
}
gen cohort=year-age
egen cohortcat=cut(cohort),at(1880(10)1980)
recode cohortcat 1890/1900=1910
recode educ 9=2,g(educrec)
recode polviews 1/2=1 3=2 4/6=3 7/9=4,g(polviewscat)
recode polviews 7/8=3,g(polviewsord)
gen vasco=commun>14&commun<17
recode ethid 1/2=1 3=2 4/5=3 6/7=3,g(ethidcat)
*recode choice 2/3=2,g(choicebin)
gen yearord=year-1992
gen left=polviews<3
recode ethid 6/7=3,g(ethidord)
lab var ethidord "Ethnic I.D."
lab var educ "Respondent's Education"
*/generating four category cohort variable*/	
recode cohort 1880/1935=1 1936/1954=2 1955/1964=3 1965/1975=4,g(cohortcat4)	
lab def cohortcat4 1 "1890/1935" 2 "1936/1955" 3 "1955/1964" 4 "1965/1975"
lab val cohortcat4 cohortcat4

lab define commun  1	Andalucía 2	Aragón 3	Asturias 4	Baleares 5	Cataluña 6	Canarias 7	Cantabria 8	León 9 La_Mancha 10	Extremadura 11	Galicia 12	Rioja 13	Madrid 14	Murcia 15	Navarra 16	Pais_Vasco 17	Valenciana 
lab val commun commun

compress
save "N:\Private\spain\spainlatin.dta",replace
gen idnum=_n
reshape long latinperson,i(idnum) j(choice)
drop if latinperson>97
gen che=latinperson==18
gen castro=latinperson==1
gen bolivar=latinperson==7
gen allende=latinperson==26
gen peron=latinperson==4
gen pinocohortt=latinperson==3
gen marquez=latinperson==15
gen llosa=latinperson==8

cap drop *line
est drop _all
local i=1
foreach var of varlist che castro bolivar  peron  {
	qui xi3:logistic `var' i.cohort10 i.choice i.year
	postgr3 cohort10,nodraw gen(`var'line)
	qui sum `var'line,meanonly
	replace `var'line=`var'line/r(mean)
	est store mod`i'
	local i=`i'+1
	*test  _Icohortcat_1950 _Icohortcat_1960 _Icohortcat_1970
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop(_cons _Ichoice_2 _Ichoice_3 _Iyear_1992 _Iyear_1993) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

twoway fpfit cheline cohort, ///
lw(vthick) lp(solid) lc(gs14) legend(off) ///
estopts(degree(2))  ///
||scatter  cheline cohort10, ///
sort ylab(.5(.25)1.5,glw(vthin) glc(gs14)) yline(1) ///
msize(vlarge) mfc(white) ///
mcolor(black) msym(circle) ///
legend(pos(6) label(1 "cohort Guevara")) ///
xlab(1910(10)1970) saving("N:\Private\graph1.gph",replace)  xtitle("Cohort") ytitle("Odds of Remembering") 

twoway connected  cheline castroline  cohortcat,sort ylab(,nogrid) yline(1) ///
msize(large large) mcolor(black gray) msym(diamond diamond) ///
legend(pos(6) label(1 "cohort Guevara") label(2 "Fidel Castro")) ///
xlab(1910(10)1970) saving("N:\Private\graph1.gph",replace) nodraw xtitle("Cohort") ytitle("Odds of Remembering")

twoway connected  bolivarline peronline  cohortcat,sort ylab(,nogrid) yline(1) ///
msize(large large) mcolor(black gray) msym(diamond diamond) ///
legend(pos(6) label(1 "Simon Bolivar") label(2 "Peron")) ///
xlab(1910(10)1970) saving("N:\Private\graph2.gph",replace) nodraw xtitle("Cohort") ytitle("Odds of Remembering")


twoway connected marquezline llosaline cohortcat,sort ylab(,nogrid) yline(1) ///
msize(large large) mcolor(black gray) msym(diamond diamond) ///
legend(pos(6) label(1 "Marquez") label(2 "Llosa")) ///
xlab(1910(10)1970) saving("N:\Private\graph3.gph",replace) nodraw xtitle("Cohort") ytitle("Odds of Remembering")

graph combine "N:\Private\graph1.gph"  "N:\Private\graph2.gph",rows(3) xsize(4) ysize(7)

drop *line*
local vars1 
local vars2 educ
local vars3 educ left
local vars4 educ left vasco
est drop _all
local i=1
forval i=1(1)4 {
	qui xi3:logistic che e.cohortcat `vars`i'' i.year i.choice,cluster(region)
	postgr3 cohortcat,nodraw gen(cohortline`i')
	qui sum cohortline`i',meanonly
	replace cohortline`i'=cohortline`i'/r(mean)
	est store mod`i'
	
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 




est drop _all
forval i=1(1)4 {
	qui xi3:logistic che i.gender educ left vasco i.ethidcat i.year i.choice if cohortcat4==`i',cluster(region)
	est store mod`i'
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop(_cons  _Iyear_1992 _Iyear_1993 _Ichoice_2 _Ichoice_3) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

local int1 left*vasco
local int2 ethidord*vasco
local int3 educ*vasco
local int4 left*female
local int5 ethidord*female
local int6 educ*female
est drop _all
forval j=1(1)6 {
	forval i=2(1)4  {
		qui xi3:logistic che educ left vasco `int`j'' i.year i.choice if cohortcat4==`i',cluster(region)
		est store mod`i'`j'
	}
}

forval j=1(1)6 {
	if `j'<4 {
		local drops educ left vasco  ethidord  _cons  _Iyear_1992 _Iyear_1993 _Ichoice_2 _Ichoice_3
	}
	else if `j'>3 {
		local drops female educ left vasco  ethidord _cons  _Iyear_1992 _Iyear_1993 _Ichoice_2 _Ichoice_3
	}
	estout mod2`j' mod3`j' mod4`j',unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
	stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop(`drops') ///
	starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 
}

*/analysis by mention*/
cap drop *line*
est drop _all
forval i=0(1)1  {
	qui xi3:logistic che r.cohortcat i.year if choicebin==`i'
	est store mod`i'
	postgr3 cohortcat,nodraw gen(cohortline`i')
	qui sum cohortline`i',meanonly
	replace cohortline`i'=cohortline`i'/r(mean)
	est store mod`i'
	testparm  _Icohortcat_*

}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop(_cons  _Iyear_1992 _Iyear_1993) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

twoway connected  cohortline1 cohortline2 cohortcat,sort ylab(,nogrid) yline(1) ///
msize(large large) mcolor(black gray) msym(diamond diamond) ///
legend(pos(6) label(1 "First Mention") label(2 "Second Mention")) ///
xlab(1910(10)1970)  xtitle("Cohort") ytitle("Odds of Remembering") 


twoway fpfit che cohort if gender==1||fpfit che cohort if gender==2,ylab(,nogrid) legend(label(1 "Men") label(2 "Women"))
twoway fpfit che cohort if vasco==1||fpfit che cohort if vasco==0,ylab(,nogrid) legend(label(1 "Basque") label(2 "Not Basque"))
twoway fpfit che cohort if polviews<4 ||fpfit che cohort if polviews==4||fpfit che cohort if polviews>4 & polviews<8|| ///
fpfit che cohort if polviews==9,ylab(,nogrid) legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Other"))
twoway fpfit che cohort if educ>6 ||fpfit che cohort if educ<7& educ<9,
ylab(,nogrid) legend(label(1 "College") label(2 "Less Than College"))
twoway fpfit che cohort if ethidord<3 ||fpfit che cohort if ethidord==3||fpfit che cohort if ethidord>3 & ethidord~=., ///
ylab(,nogrid) legend(label(1 "Regional Identity") label(2 "Mixed Identity") label(3 "National Identity"))
