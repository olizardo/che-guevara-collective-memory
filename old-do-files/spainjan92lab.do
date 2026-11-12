clear 
infile using "Z:\spain\spainjan92.dict"

ren b73 latinperson1
ren b75 latinperson2
lab define latinperson 1 "Fidel Castro" 2 "Carlos Menem" 3 "Pinochet" 4 "Perón" 5 "Raúl Alfonsín" 6 "Eva Perón" 7 "Simón Bolivar" 8 "Mario Vargas Llosa" 9 "Octavio Paz" 10 "Diego Armando Maradona" 11 "Ortega" 12 "C. Arias" 13 "Violeta Chamorro" 14 "San Martín" 15 "Gabriel García Márquez" 16 "Jorge Luis Borges " 17 "Mario Benedetti" 18 "Che Guevara" 19 "Videla" 20 "Carlos Gardel" 21 "El Puma" 22 "Roberto Carlos" 23 "Cesar Rincon" 24 "Perez de Cuellar" 25 "Pelé" 26 "Fujimori" 27 "A. Cristianini" 28 "Alain Garcia" 29 "Torrijos" 30 "Carlos Andres Perez" 31 "Jorge Negrete" 32 "Pablo Neruda" 33 "Noriega" 34 "Isabel Allende" 35 "Pancho Villa" 36 "Salvador Allende" 37 "Amado Nervo" 38 "Alejo Carpentier" 39 "B Bethancourt" 40 "Corazon Aquino" 41"Nacha Guevara" 42 "Carlos Mata" 43 "Jeanette Rodriguez" 44 "P Alwyn" 45 "Ruben Dario" 46 "Hugo Sanchez" 47 "Juan Guerra" 97 "Otros" 98 "Ninguno" 99 "DK/NA"

for var latinperson1-latinperson2:  lab val X latinperson
lab var age "years of age"
lab var gender "gender"
lab define gender 1 "male" 2 "female"
lab val gender gender
save "Z:\spain\spainjan92.dta",replace
