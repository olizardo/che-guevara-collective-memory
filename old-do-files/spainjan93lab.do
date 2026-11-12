use "Z:\spain\spainjan93.dta", clear
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
save "Z:\spain\spainjan93_red.dta",replace
keep  a1-a64 year id latinperson* gender-finc
save "Z:\spain\spainjan93_red.dta",replace

