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
gen left=polviews<3
recode ethid 6/7=3,g(ethidord)
*/generating four category cohort variable*/	
recode cohort 1880/1935=1 1936/1954=2 1955/1964=3 1965/1975=4,g(cohortcat4)	
lab def cohortcat4 1 "1890/1935" 2 "1936/1955" 3 "1955/1964" 4 "1965/1975"
lab val cohortcat4 cohortcat4

lab define commun  1	Andalucía 2	Aragón 3	Asturias 4	Baleares 5	Cataluña 6	Canarias 7	Cantabria 8	León 9 La_Mancha 10	Extremadura 11	Galicia 12	Rioja 13	Madrid 14	Murcia 15	Navarra 16	Pais_Vasco 17	Valenciana 
lab val commun commun

compress
gen idnum=_n
reshape long latinperson,i(idnum) j(choice)
gen choicebin=choice>1
drop if latinperson==.
gen che=latinperson==18
gen castro=latinperson==1
gen bolivar=latinperson==7
gen allende=latinperson==26
gen peron=latinperson==4
gen pinochet=latinperson==3
gen marquez=latinperson==15
gen llosa=latinperson==8
gen maradona=latinperson==10
gen evita=latinperson==6
drop if latinperson>97
save "N:\Private\Che_Guevara_Coll_Mem\che.dta",replace

twoway fpfit che cohort,estcmd(logit)||fpfit castro cohort,estcmd(logit)|| ///
fpfit bolivar cohort,estcmd(logit)||fpfit peron cohort,estcmd(logit) ylab(,nogrid) ytitle("") yline(1) ///
legend(label(1 "Che Guevara") label(2 "Fidel Castro") label(3 "Simon Bolivar") label(4 "Juan Peron")) xlab(1900(5)1980,angle(45))



est drop _all
local i=1
foreach var of varlist che castro bolivar  peron marquez llosa {
	qui xi3:logistic `var' r.cohortcat i.choice i.year
	est store mod`i'
	local i=`i'+1
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop( _Ichoice_2 _Ichoice_3 _Iyear_1992 _Iyear_1993) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(25)  style(fixed) legend 

est drop _all
qui xi3:logistic che r.cohortcat i.year if choice==1
est store mod1
qui xi3:logistic che r.cohortcat i.year if choice>1 
est store mod2
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) drop( _Iyear_1992 _Iyear_1993) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(25)  style(fixed) legend 



twoway connected  cheline castroline  cohortcat,sort ylab(,nogrid) yline(1) ///
msize(large large) mcolor(black gray) msym(diamond diamond) ///
legend(pos(6) label(1 "Che Guevara") label(2 "Fidel Castro")) ///
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
	qui xi3:logistic che e.cohortcat `vars`i''
	postgr3 cohortcat,nodraw gen(cheline`i')
	qui sum cheline`i',meanonly
	replace cheline`i'=cheline`i'/r(mean)
	est store mod`i'
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 




twoway fpfit che cohort if polviews<4,estcmd(logit)||fpfit che cohort if polviews>3&polviews<5,estcmd(logit)|| ///
fpfit che cohort if polviews>4&polviews<9,estcmd(logit)||fpfit che cohort if polviews==9,estcmd(logit) ///
ylab(,nogrid) ytitle("") title("Che Guevara") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))

twoway fpfit castro cohort if polviews<4||fpfit castro cohort if polviews==4|| ///
fpfit castro cohort if polviews>4&polviews<9||fpfit castro cohort if polviews==9, ///
ylab(,nogrid) ytitle("") title("Fidel Castro") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))

twoway fpfit peron cohort if polviews<4||fpfit peron cohort if polviews==4|| ///
fpfit peron cohort if polviews>4&polviews<9||fpfit peron cohort if polviews==9, ///
ylab(,nogrid) ytitle("") title("Peron") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))

twoway fpfit pinochet cohort if polviews<4||fpfit pinochet cohort if polviews==4|| ///
fpfit pinochet cohort if polviews>4&polviews<9||fpfit pinochet cohort if polviews==9, ///
ylab(,nogrid) ytitle("") title("pinochet") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))

twoway fpfit che cohort if educ<2,estcmd(logit)||fpfit che cohort if educ==2,estcmd(logit)|| ///
fpfit che cohort if educ>2&educ<6,estcmd(logit)||fpfit che cohort if educ>5&educ<9,estcmd(logit) ///
ylab(,nogrid) ytitle("") title("Che Guevara") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))

twoway fpfit che cohort if class<3,estcmd(logit)||fpfit che cohort if class==3,estcmd(logit)|| ///
fpfit che cohort if class>3&class<8,estcmd(logit) ylab(,nogrid) ytitle("") title("Che Guevara") ///
legend(label(1 "Left") label(2 "Center") label(3 "Right") label(4 "Non Political")) xlab(1900(5)1980,angle(45))


twoway fpfit che cohort if pvasco==1||fpfit che cohort if pvasco==0



est drop _all
forval i=2(1)4  {
	qui xi3:logistic che educ left vasco if cohortcat4==`i',cluster(reg15)
	est store mod`i'
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 

est drop _all
local mod i.gender left vasco localid educrec
forval i=1(1)4  {
		qui xi3:logistic che `mod' if cohortcat4==`i'
		est store mod`i'
	}

estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend 


local vars1 
local vars2 educrec
local vars3 educrec left
local vars4 educrec left 
est drop _all
forval i=1(1)4 {
	qui xi3:logit che e.cohortcat `vars`i''
	est store mod`i'
}
estout mod*,unstack  cells(b(star fmt(%9.4f)) t(par fmt(%9.2f))) ///
stats(chi2  N,fmt(%9.2f  %9.0f) star(chi2)) ///
starlevels(+ 0.105 * 0.055 ** 0.015) label  varwidth(15)  style(fixed) legend