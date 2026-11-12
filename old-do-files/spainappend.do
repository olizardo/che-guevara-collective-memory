use "C:\Omar\spain\spaindec92.dta", clear
foreach name in "jan93" "march93" "april93" "may93"  "june93" "nov93"  "oct93" "feb94" "march94" "april94" "may94" "june94"  "oct94" "dec94"  "feb95"  "march95" "april95"  "may95" "april96" {
append using "C:\Omar\Spain\spain`name'.dta",keep(a* e1* e2* e3*)
}
drop b* c* d* actcult avail e39

gen year=.
replace year=1992 if a1==22
replace year=1993 if a1>22&a1<33
replace year=1994 if a1>30&a1<42
replace year=1995 if a1>40&a1<51
replace year=1996 if a1==51


ren e10 age
lab var age "Respondent's Age"
gen cohort=year-age
egen cohortcat=cut(cohort),at(1900(5)1995)
ren a51 geoid
lab var geoid "Subjective Citizenship"
tab geoid,g(geo)
graph dot geo7,over(cohortcat)
sort cohortcat
qby cohortcat:egen geo7mean=mean(geo7)
qby cohortcat:egen geo4mean=mean(geo4)
qby cohortcat:egen geo1mean=mean(geo1)
gen postnat=geoid>4&geoid<8 if geoid~=.
qby cohortcat:egen postnatmean=mean(postnat)
line geo1mean geo4mean postnatmean cohortcat,ylab(0(.05).55) xlab(1900(5)1975,angle(90))



drop e38 e39

"feb93"
"march96"

drop b1-d48

"nov92" 
"oct92"

disp "`name'"
