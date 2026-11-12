clear
*/processing 1993 data*/
use "N:\Private\spain\spainjan93_ren.dta", clear
gen year=1993
gen id=_n
keep  sppostmat1 sppostmat2 sppostmat3 wrldpostmat1 wrldpostmat2 wrldpostmat3 geoid passport tradval1-tradval10 ///
year id latinperson1 latinperson2 gender-finc  
save "N:\Private\spain\spainjan93_red.dta",replace


*/generating composite data set with sociodemographic variables only*/
use "N:\Private\spain\spainjan91.dta", clear
gen year=1991
gen id=_n
keep  sppostmat1 sppostmat2 sppostmat3 wrldpostmat1 wrldpostmat2 wrldpostmat3 geoid passport tradval1-tradval10 ///
year id latinperson1 latinperson2 latinperson3 gender-finc 
save "N:\Private\spain\spainjan91_red.dta",replace
use "N:\Private\spain\spainjan92.dta", clear
gen year=1992
gen id=_n
keep  sppostmat1 sppostmat2 sppostmat3 wrldpostmat1 wrldpostmat2 wrldpostmat3 geoid passport tradval1-tradval10 ///
year id latinperson1 latinperson2 gender-finc 
save "N:\Private\spain\spainjan92_red.dta",replace

use "N:\Private\spain\spainjan91_red.dta", clear
forvalues i=92(1)93 {
	append using "N:\Private\spain\spainjan`i'_red.dta"
	}
gen cohort=year-age
egen cohort10=cut(cohort),at(1880(10)1980)
egen cohort5=cut(cohort),at(1880(5)1980)
recode cohort10 1890/1900=1910
recode educ 9=2,g(educrec)
recode polviews .=10
recode polviews 9/10=4,g(polviewsrec)
recode polviews 1/2=1 3/4=2 5/7=3 9/10=4,g(polcat)
lab define polcat 1 "left" 2 "moderate" 3 "right" 4 "no opinion"
lab val polcat polcat
gen teduc=((educrec+1)^-2)*-1
gen vasco=commun>14&commun<17
recode ethid 1/2=1 3=2 4/5=3 6/7=3,g(ethidcat)
gen left=polviews<3
recode ethid 6/7=3,g(ethidord)
recode educ .=9
gen yearvar=year-1991



*/generating four category cohort variable*/	
recode cohort 1880/1935=1 1936/1954=2 1955/1964=3 1965/1975=4,g(cohortcat4)	
lab def cohortcat4 1 "1890/1935" 2 "1936/1955" 3 "1955/1964" 4 "1965/1975"
lab val cohortcat4 cohortcat4

lab define commun  1	Andalucía 2	Aragón 3	Asturias 4	Baleares 5	Cataluña 6	Canarias 7	///
Cantabria 8	León 9 La_Mancha 10	Extremadura 11	Galicia 12	Rioja 13	Madrid 14	Murcia 15	///
Navarra 16	Pais_Vasco 17	Valenciana 
lab val commun commun

lab define sppost ///
1 "Reduce social inequalities" ///
2 "Fight against drugs" ///
3 "Gurantee civic liberties" ///
4 "Protect the environment" ///
5 "Gurantee economic growth" ///
6 "Fight terrorism" ///
7 "Reduce strikes" ///
8 "Fight against immorality and corruption in society" ///
9 "Increase social welfare programs" ///
10 "Fight crime" ///
11 "Slow down price increases" ///
12 "Guarantee Spain's international security" ///
13 "None" ///
14 "Don't Know"

for var sppost*:lab val X sppost

lab define wrldpost ///
1 "Reduce differences between rich and poor countries" ///
2 "Slow down world population growth" ///
3 "Stop immigration from poor countries into rich countries" ///
4 "Protect the environment" ///
5 "Guarantee the availability of cheap and abundant energy" ///
6 "Guarantee the spread of democracy in all countries" ///
7 "Fight poverty in all countries" ///
8 "Prevent wars at all costs" ///
9 "Reduce the power of large multinational corporations" ///
10 "Fight against drug trafficking" ///
11 "None" ///
12 "Don't Know"
for var wrldpost*:lab val X wrldpost
gen postmat=0
for var  sppostmat1 sppostmat2 sppostmat3:replace postmat=postmat+1 if X==1|X==3|X==4
for var  wrldpostmat1 wrldpostmat2 wrldpostmat3:replace postmat=postmat+1 if X==1|X==2|X==4|X==9
for var  tradval1- tradval10:gen Xbin=X<=2
qui tetrachoric tradval2bin-tradval7bin
mat tetracorr=r(corr)
qui factormat tetracorr,pcf n(3985) fac(1)
predict tradfac
ca region ethid,norm(row)
predict regid,rowscore(1)
save "N:\Private\Che_Guevara_Coll_Mem\che_prem.dta",replace

compress
gen idnum=_n
reshape long latinperson,i(idnum) j(choice)
gen choicebin=choice>1
sort idnum
gen counter=1
qby idnum:gen numchoices=sum(counter)
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
qui tab latinperson,g(person)
gen figure=.
replace figure=.
forval i=1(1)95 {
	qui sum person`i',meanonly
	local mean=r(mean)
	replace figure=`i' if `mean'>=0.03 & latinperson==`i'
}
replace figure=97 if figure==.
lab val figure latinperson
char figure[omit] 96
qui tab figure,g(fig)
gen idij=_n
reshape long fig,i(idij) j(pchoice)
char pchoice[omit] 11
capture lab define pchoice 1 "Fidel Castro"	2 "Carlos Menem" 3 "Pinochet"	4 "Perón"	5 "Raúl Alfonsín" 6	"Simón Bolivar"	///
7 "Mario Vargas Llosa"	8 "Diego Armando Maradona" 9	"Gabriel García Márquez"	10 "Che Guevara"	11 "Otros"
lab val pchoice pchoice
foreach var of varlist cohort cohort5 cohort10 {
	qui sum `var',det
	gen c`var'=`var'-r(p50)
	}

capture drop cohortchoice-cohortchoice11
qui xi3:clogit  fig i.pchoice*ccohort10*ccohort10 i.pchoice*yearvar i.pchoice*choice,group(idij)
postgr3 ccohort10,by(pchoice) asis( _Ipc1Xcc-_Ipc10XccXcc) nodraw gen(cohortchoice)


 	
 	
local i=1
foreach name in "Fidel Castro"	"Carlos Menem" "Pinochet"	"Perón"	"Raúl Alfonsín" "Simón Bolivar"	///
 "Mario Vargas Llosa"	 "Diego Armando Maradona" 	"Gabriel García Márquez"	 "Che Guevara"	 "Otros" {
 	lab var cohortchoice`i' "`name'"
 	twoway connected cohortchoice`i' cohort10 if fig==1,sort ylab(,nogrid) scheme(s1mono) xlab(1910(10)1970,angle(45))  msize(large) ///
 	msym(diamond) legend(cols(1)) xsize(4.75) ysize(8) title("`name'") saving( "N:\Private\Che_Guevara_Coll_Mem\gr`i'.gph",replace) ///
 	ytitle("Predicted Probability of Mention") xtitle("Cohort") nodraw
 	local i=`i'+1
 }
 graph combine "N:\Private\Che_Guevara_Coll_Mem\gr1.gph" "N:\Private\Che_Guevara_Coll_Mem\gr2.gph" ///
 "N:\Private\Che_Guevara_Coll_Mem\gr3.gph" "N:\Private\Che_Guevara_Coll_Mem\gr4.gph" "N:\Private\Che_Guevara_Coll_Mem\gr5.gph" ///
 "N:\Private\Che_Guevara_Coll_Mem\gr6.gph" "N:\Private\Che_Guevara_Coll_Mem\gr7.gph" "N:\Private\Che_Guevara_Coll_Mem\gr8.gph" ///
 "N:\Private\Che_Guevara_Coll_Mem\gr9.gph" "N:\Private\Che_Guevara_Coll_Mem\gr10.gph",cols(2) ysize(8) xsize(4.5)


qui xi3:clogit  fig i.pchoice*ccohort10*ccohort10 i.pchoice*yearvar i.pchoice*choice,group(idij)
capture gen name=""
capture gen chi2lin=.
capture gen plin=.
capture gen chi2curv=.
capture gen pcurv=.
capture for var *lin *curv:replace X==.
local i=1
foreach name in "Fidel Castro"	"Carlos Menem" "Pinochet"	"Perón"	"Raúl Alfonsín" "Simón Bolivar"	///
 "Mario Vargas Llosa"	 "Diego Armando Maradona" 	"Gabriel García Márquez"	 "Che Guevara"	 {
 qui test  _Ipc`i'Xcc
 replace chi2lin=r(chi2) in `i'
 replace plin=r(p) in `i'
 capture qui test  _Ipc`i'XccXcc
 capture replace chi2curv=r(chi2) in `i'
 capture replace pcurv=r(p) in `i'
 replace name="`name'" in `i'
 local i=`i'+1
 }
format  chi2lin plin chi2curv pcurv %9.3f
list name chi2lin plin chi2curv pcurv in 1/10,sep(0)

twoway connected   cohortchoice1 cohortchoice4 cohortchoice7 cohortchoice8 cohortchoice9 cohortchoice10  cohort10 if fig==1, ///
sort ylab(,nogrid) scheme(s2mono) xlab(1910(10)1970,angle(45))  msize(large) mc(black)  ///
legend(cols(1)) xsize(5.25) ysize(7) title("`name'") saving( "N:\Private\Che_Guevara_Coll_Mem\gr`i'.gph",replace) ///
ytitle("Predicted Probability of Mention") xtitle("Cohort") ///
legend(label (1 "Fidel Castro") label(2 "Peron") label(4 "Llosa") label(4 "Maradona") label(5 "Gabriel Marquez") label(6 "Che Guevara"))


 graph combine "N:\Private\Che_Guevara_Coll_Mem\gr1.gph"  "N:\Private\Che_Guevara_Coll_Mem\gr4.gph" "N:\Private\Che_Guevara_Coll_Mem\gr7.gph" ///
 "N:\Private\Che_Guevara_Coll_Mem\gr8.gph" "N:\Private\Che_Guevara_Coll_Mem\gr9.gph" "N:\Private\Che_Guevara_Coll_Mem\gr10.gph",cols(2) ysize(8) xsize(6)
 
 xi3: mfp logit  fig ccohort10*ccohort10 yearvar choice postmat tradfac if pchoice==10,cluster(id) aic
foreach spec in "fig ccohort10*ccohort10 yearvar choice" "ccohort10*ccohort10 yearvar choice postmat tradfac" ///
"ccohort10*ccohort10 yearvar choice postmat tradfac educrec" 
xi3:mfp logit `spec',cluster(id) aic
save "N:\Private\Che_Guevara_Coll_Mem\che_final.dta",replace