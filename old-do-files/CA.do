gen firstname=b49 if b51~=.
foreach num of numlist 1(1)49 {
gen temp=0 if b49!=.&b51~=.
replace temp=1 if b49==`num'
qui sum temp,meanonly
local a=r(mean)
if `a'<=0.03 {
replace firstname=97 if b49==`num' 
}
drop temp
}
lab val firstname b49

gen secondname=b51
foreach num of numlist 1(1)49 {
gen temp=0 if b49!=.&b51~=.
replace temp=1 if b51==`num'
qui sum temp,meanonly
local a=r(mean)
if `a'<=0.03 {
replace secondname=97 if b51==`num' 
}
drop temp
}
lab val secondname b51

gen polviews= e25
recode polviews 1/2=1 3/5=2 6/7=3
lab def polviews 1 "LEFT" 2 "CENTER" 3 "RIGHT"
lab val polviews polviews

gen educ=e21
recode educ  3/5=2 6=3 7/8=4
lab def educ 0 "NO FORMAL EDUC." 1 "PRIMARY" 2 "HIGH SCHOOL/SOME COLLEGE" 3 "COLLEGE" 4 "GRADUATE"
lab val educ educ

mca educ polviews firstname,d(2) 

gen clockrand = int(uniform()*12)+1
scatter  var222 var223,mlab(var219) ylab(,nogrid) yline(0) xline(0) ylab(-.75(.25).75) xlab(-1(.25)1.5) mlabvpos(var221) plotr(margin(r+10)) ms(none)

scatter  var227 var228,mlab(var224) ylab(,nogrid) yline(0) xline(0) ylab(-.75(.25).75) xlab(-.5(.25).75) mlabvpos(var225) plotr(margin(r+4)) ms(none)

gen mu1=.
gen mu2=.
gen t=""
gen p=.
gen lab=""

local a=1
foreach var of varlist  polviews educ age female  relig citysize inc {
replace lab="`var'" in `a'
qui ttest `var',by(che)
replace mu1=r(mu_1) in `a'
replace mu2=r(mu_2) in `a'
local j: di %9.2f  r(t) 
disp `j'
if `j'>=1.96|`j'<=-1.96 {
local t="`j'*"
}
else {
local t="`j'"
}
replace t="`t'" in `a'
local a=`a'+1
}
format mu* %9.2f
list lab mu1 mu2 t in 1/8

gen che=(b49==18|b51==18) if b49~=.

recode polviews .=2,g(polviews2)

drop pinochet
gen pinochet=(b49==3|b51==3) if b49~=.
gen castro=(b49==1|b51==1) if b49~=.
gen menem=(b49==2|b51==2) if b49~=.
gen bolivar=(b49==7|b51==7) if b49~=.
gen llosa=(b49==8|b51==8) if b49~=.
gen marquez=(b49==15|b51==15) if b49~=.

drop political
gen political=b49<8|(b49>10&b49<15)|b49==24|b49==26|b49==28|b49==30|(b49>32&b49<41)|(b49>47&b49<50) if b49~=.
gen arts=(b49>7&b49<11)|(b49>14&b49<17)|(b49>19&b49<22)|b49==25|(b49>30&b49<33)|(b49>41&b49<48) if b49~=.
gen lit=(b49>7&b49<10)|(b49>14&b49<17)|b49==32|b49==45 if b49~=.

gen polage=age*polviews
gen polopin=c78*c79
gen femgeo=female*geoid
local mod college age polviews2 female relig2 c78
mktab (che castro pinochet menem bolivar marquez llosa political lit ent=`mod'), ///
screen e(chi2,N) cmd(logit)

mlogit b49 college age polviews2 female relig2 c79,b(18)