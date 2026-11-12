clear
infile using "Z:\spain\spainjan91.dict"

ren c7 latinperson1
ren c9 latinperson2
ren c11 latinperson3
lab define latinperson 1 "Fidel Castro" 2 "Carlos Menem" 3 "Pinochet" 4 "Perón" 5 "Raúl Alfonsín" 6 "Eva Perón" 7 "Simón Bolivar" 8 "Mario Vargas Llosa" 9 "Octavio Paz" 10 "Diego Armando Maradona" 11 "Ortega" 12 "C. Arias" 13 "Violeta Chamorro" 14 "San Martín" 15 "Gabriel García Márquez" 16 "Jorge Luis Borges" 17 "Mario Benedetti" 18 "Che Guevara" 19 "Videla" 20 "Carlos Gardel" 21 "El Puma" 22 "Madres Plaza de Mayo" 23 "Sócrates" 24 "Roberto Carlos" 25 "Pelé" 26 "Allende" 27 "Pizarro" 28 "Julio Cortazar" 29 "Somoza" 30 "Miguel de la Madrid" 31 "Sanguineti" 32 "Martín Fierro" 33 "Pablo Neruda" 34 "Machado" 35 "Carlos Mata" 36 "Los Panchos" 37 "Noriega" 38 "Vázquez Figueroa" 39 "Blasco Ibáñez" 40 "Mercedes Sosa" 41 " Patricio Alwyn" 42 "Palito Ortega" 43 "Forges" 44 "Isabel Allende" 45 "Robert Redfort" 46 "Jorge Negrete" 47 "Rubén Darío" 48 "E. Mendoza" 49 "General Ribadaria" 50 "Betancourt" 51 "Cristal/ Janeth Rodríguez" 52 "Ferdinand Marcos" 53 "Isabel Perón" 54 "Di Stefano" 55 "Miguel Delibes" 56 "Pérez de Cuellar" 57 "Roa Bastos" 58 "Valdano" 59 "Victor Jara" 60 "Padre Romero" 61 "Corazón Aquino" 62 "Gaviria" 63 "Aguinaldo Rayón" 64 "Silvio Santos" 65 "Salinas de Gortari" 66 " Alan García" 67 "General Sucre" 68 "Oscar Arias" 69 "Fujimori" 70 "Pancho Villa" 71 "Andrés Bello" 73 "Virgilio Barco" 74 "Joan Baez" 75 "Batista" 76 " Violeta Parra" 77 "Rubén Blades" 78 "Gato Barbieri" 79 "Los tres  Sudamericanos" 80 "Hugo Sánchez" 81 "Gabriela Mistral" 82 "Sandino" 83 "Lila Muirillo" 84 "Carlos Andrés Pérez" 85 "Eden Pastora" 86 "Padrino" 87 "El inca Garcilaso" 88 "Imperio Argentina" 90 "Atagualpa" 92 "Genistera" 93 "Onetti" 94 "Mario Moreno Cantinflas" 95 "De la Cruz" 96 "Mandela" 97 "Otros" 98 "Ninguno" 99 "DK/NA"

for var latinperson1-latinperson3:  lab val X latinperson
lab var age "years of age"
lab var gender "gender"
lab define gender 1 "male" 2 "female"
lab val gender gender
save "Z:\spain\spainjan91.dta",replace
