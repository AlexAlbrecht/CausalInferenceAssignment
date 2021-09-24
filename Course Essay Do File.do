/******************************************************************************\
* Data: 			 European Social Survey, 2010-2018
* Title:        	 ESS setup for constructing an index of SWD   
* Author:            Alexander Albrecht       							       
* This version:   	 19.04.2021 	          
														  */                             


*------------------------------------------------------------------------------*
*    		  				  												   *
*								Preliminaries								   *	
*																			   *
*------------------------------------------------------------------------------*

clear all 
global path1 `""C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets""'
set more off
numlabel, add
cd $path1
set scheme plottig 
ssc install xttest2 
ssc install coefplot
*------------------------------------------------------------------------------*
*								Setup of data set							   *	
*------------------------------------------------------------------------------*

//Using the ESS Cumulative Wizard on the Website, I can customize my dataset in the way that I want. For my analysis, I am only focussing on Germany. To better catch the effect of the inflow of refugees after the European Refugee crisis, I included rounds 5-9 (2010-2018) in my dataset. From this dataset, I then can construct an index of TPI on a NUTS-1 Level. Then, I can match the refugee inflow per year in that state with the index and see whether there is any relationship.

*------------------------------------------------------------------------------*
*    		  				  												   *
*				Cleaning and Preparing the Refugee Dataset					   *	
*																			   *
*------------------------------------------------------------------------------*
//This Dataset can be obtained from the Federal German Office of Statistics. You can find it here: https://www-genesis.destatis.de/genesis//online?operation=table&code=12531-0020&bypass=true&levelindex=0&levelid=1618841480945#abreadcrumb

clear
import delimited "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Asylum Seekers per State 2008-2018.csv"
keep zeit _auspraegung_code _auspraegung_label v13 bev030__schutzsuchende__anzahl

//Renaming Variables
rename bev030__schutzsuchende__anzahl Asylumseekers
rename _auspraegung_label state
rename v13 gender
label var Asylumseekers "Number of Asylumseekers per State"

//Generation year2 variable
gen year=.
replace year = 2008 if zeit == "31.12.2008"
replace year = 2009 if zeit == "31.12.2009"
replace year = 2010 if zeit == "31.12.2010"
replace year = 2011 if zeit == "31.12.2011"
replace year = 2012 if zeit == "31.12.2012"
replace year = 2013 if zeit == "31.12.2013"
replace year = 2014 if zeit == "31.12.2014"
replace year = 2015 if zeit == "31.12.2015"
replace year = 2016 if zeit == "31.12.2016"
replace year = 2017 if zeit == "31.12.2017"
replace year = 2018 if zeit == "31.12.2018"
drop if zeit == "31.12.2019"

//Generate year2 because ESS is conducted only every 2 years
gen year2 =. 
replace year2 = 2010 if year == 2009 | year == 2010
replace year2 = 2012 if year == 2011 | year == 2012
replace year2 = 2014 if year == 2013 | year == 2014
replace year2 = 2016 if year == 2015 | year == 2016
replace year2 = 2018 if year == 2017 | year == 2018

rename year year_old
rename year2 year
drop if year_old == 2008
keep if gender == "Insgesamt"


//Generate NUTS-1 Abbreviations
gen nuts1=""
replace nuts1 = "DE1" if state == "Baden-Württemberg"
replace nuts1 = "DE2" if state == "Bayern"
replace nuts1 = "DE3" if state == "Berlin"
replace nuts1 = "DE4" if state == "Brandenburg"
replace nuts1 = "DE5" if state == "Bremen"
replace nuts1 = "DE6" if state == "Hamburg"
replace nuts1 = "DE7" if state == "Hessen"
replace nuts1 = "DE8" if state == "Mecklenburg-Vorpommern"
replace nuts1 = "DE9" if state == "Niedersachsen"
replace nuts1 = "DEA" if state == "Nordrhein-Westfalen"
replace nuts1 = "DEB" if state == "Rheinland-Pfalz"
replace nuts1 = "DEC" if state == "Saarland"
replace nuts1 = "DED" if state == "Sachsen"
replace nuts1 = "DEE" if state == "Sachsen-Anhalt"
replace nuts1 = "DEF" if state == "Schleswig-Holstein"
replace nuts1 = "DEG" if state == "Thüringen"

//Generate Male to Female ratio by each year
// idea to get the female ratio: egen female_ratio = display(Asylumseekers if gender=="weiblich" / Asylumseekers if gender == "Insgesamt"), by(state, year) 
//by state year, sort: gen female = Asylumseekers if gender == "weiblich"
//by state year, sort: gen Insgesamt = Asylumseekers if gender == "Insgesamt"
//by state year, sort: gen female_ratio = female / Insgesamt
//I cannot find a good solution to calculate female to male ration per state and year. Until then, I just keep the "Insgesamt" observations and drop the rest. 

egen Refugees = mean(Asylumseekers), by(state year)
replace Refugees = round(Refugees)
drop if year_old == 2009 | year_old == 2011 | year_old == 2013 | year_old == 2015 |  year_old == 2017
drop year_old Asylumseekers zeit _auspraegung_code

label var nuts1 "NUTS-1 State Code"
label var year "Year to match with ESS Data"
label var Refugees "2-year mean number of refugees per state"

save "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Asylumseekers_cleaned.dta", replace

*------------------------------------------------------------------------------*
*    		  				  												   *
*				Cleaning and Preparing Nuts-1 Controlls					   	   *	
*																			   *
*------------------------------------------------------------------------------*
//I obtain the Nuts-1 Controlls for my dataset directly from ESS: https://www.europeansocialsurvey.org/data/multilevel/guide/bulk.html. 
//Merging ESS with NUTS-1 Controlls
use "Round 9 Nuts 1_DE.dta", clear
keep if cntry == "DE"
save "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Round 9 Nuts 1_DE.dta", replace 

*------------------------------------------------------------------------------*
*    		  				  												   *
*				Cleaning and Preparing Satisfaction with Merkel Dataset	   	   *	
*																			   *
*------------------------------------------------------------------------------*
clear
import excel "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\11_Arbeit_Merkel.xlsx", sheet("Tabelle4") firstrow
drop year_old good bad
//Calculating 2 year averages by hand
//2010: .6161111
//2011-2012: (.6333333 + .7472222) / 2 = 0.6902776
//2013-2014: (.7938095 +  .8058824) / 2 = 0.79984595
//2015-2016: (.7694444 + .6766667) / 2 = 0.72805555
//2017-2018: (.7504762 + .6333333) / 2 = 0.6940475
gen swm=.
replace swm = 0.6161111 if year == 2010
replace swm = 0.6902776 if year == 2011 | year == 2012
replace swm = 0.79984595 if year == 2013 | year == 2014
replace swm = 0.72805555 if year == 2015 | year == 2016
replace swm = 0.6940475 if year == 2017 | year == 2018

drop if year == 2011 | year == 2013 | year == 2015 | year == 2017 

save "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Arbeit_Merkel.dta", replace 


*------------------------------------------------------------------------------*
*    		  				  												   *
*							Merging the Datasets				   	 		   *	
*																			   *
*------------------------------------------------------------------------------*

use "ESS4-9DE", clear 
rename cregion nuts1
drop if essround == 4
merge m:m nuts1 using "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Round 9 Nuts 1_DE.dta"
drop _merge


//Prepparation of ESS Data to merge with prepared RefugeeInflow Data
gen year=. 

replace year = 2010 if essround == 5
replace year = 2012 if essround == 6
replace year = 2014 if essround == 7 
replace year = 2016 if essround == 8
replace year = 2018 if essround == 9

merge m:m nuts1 year using "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Asylumseekers_cleaned.dta"
drop if _merge == 2 
drop _merge

//merge with Satisfaction with Merkel Dataset

merge m:m year using "C:\Users\User\OneDrive\Alex_s Zeug\King's\Causal Inference\Course Essay\Datasets\Arbeit_Merkel.dta"
drop _merge

*------------------------------------------------------------------------------*
*    		  				  												   *
*					Cleaning and Preparing the Merged Dataset	  	 		   *	
*																			   *
*------------------------------------------------------------------------------*

**************************************
** Administrative variables and identifiers:
**************************************

lab var cntry "Country"
lab var cname "Title of cumulative dataset"
lab var cedition "Edition of cumulative dataset"
lab var cproddat "Production date of cumulative dataset"
lab var name "Title of dataset"
lab var essround "ESS round"
lab var edition "Edition"
lab var idno "Respondent's identification number"

**************************************
** Weights:
**************************************

lab var dweight "Design weight" /* In general design weights were computed for 
each country as follows.
1.w = 1/(PROB1*...*PROBk)  is a  nx1 vector of weights ; 
k depends on the number of stages of the sampling design.
2. All weights were rescaled in a way that the sum of the final weights equals n, 
i.e. Rescaled weights = n*w/sum(w). */

lab var pspwght "Post Stratification weight" /*The ESS post-stratification 
weights have been constructed using information about age, gender, education and 
region. The ESS post-stratification weights also adjust for unequal selection 
probabilities (design weights). A raking procedure has been used in the 
production of the post-stratification weights. */

lab var pweight "Population size weight" /* The Population size weight (PWEIGHT) 
corrects for population size when combining two or more country's data, and is 
calculated as PWEIGHT=[Population aged 15 years and over]/[(Net sample in data file)*10 000] */

**************************************
*Creating the Refugee-to-Pop variable* 
**************************************
//Creating a refugee-to-pop ration for each state with the population of the state fixed to 2012 to account for endogeneity.

by state, sort: gen ref_to_pop = Refugees / n1_tpopsz_2010
gen ref_to_pop2 = ref_to_pop * 100 
label var ref_to_pop "Refugee to Population Ratio"

**************************************
*Creating Former GDR Dummy 			 * 
**************************************

by state, sort: gen former_gdr = 1 if state == "Sachsen" | state == "Sachsen-Anhalt" | state == "Brandenburg" | state == "Thüringen" | state == "Mecklenburg-Vorpommern"
replace former_gdr = 0 if former_gdr==. 
replace former_gdr = . if state == "Berlin"
label var former_gdr "Dummy if state was a member of the former GDR"
**************************************
*Creating the SWD Index				 * 
**************************************

//Creating an SWD Index 
by state year, sort: egen swd = mean((stfeco + stfeco + stfgov) / 3)
sum swd 
// Standardize the Index
by state year, sort: gen swd2 = (swd - 5.567381) / .577567
sum swd2
drop swd
rename swd2 swd
label var swd "Satisfaction with Democracy Index"

**************************************
*Creating the Political Trust Index 	 * 
**************************************
by state year, sort: egen tpi = mean((trstprl + trstplc + trstplt + trstlgl + trstprt) / 5)
sum tpi
// Standardize the Index
by state year, sort: gen tpi2 = (tpi - 5.015717) / .4374078 
sum tpi2
drop tpi
rename tpi2 tpi
label var tpi "Trust in Political Institutions Index"

**************************************
*Graphic Analysis of TPI x Ref-to-Pop* 
**************************************

encode state, gen(state2)
gen state1=. 


replace state1 = 1 if state == "Berlin"
replace state1 = 2 if state == "Bayern"
replace state1 = 3 if state == "Saarland"
replace state1 = 4 if state == "Baden-Württemberg"
replace state1 = 5 if state == "Bremen"
replace state1 = 6 if state == "Hamburg"
replace state1 = 7 if state == "Hessen"
replace state1 = 8 if state == "Schleswig-Holstein"
replace state1 = 9 if state == "Niedersachsen"
replace state1 = 10 if state == "Nordrhein-Westfalen"
replace state1 = 11 if state == "Rheinland-Pfalz"
replace state1 = 12 if state == "Brandenburg"
replace state1 = 13 if state == "Sachsen"
replace state1 = 14 if state == "Sachsen-Anhalt"
replace state1 = 15 if state == "Mecklenburg-Vorpommern"
replace state1 = 16 if state == "Thüringen"

label define valuelabes 1 "Berlin" 2 "Bayern" 3 "Saarland" 4 "Baden-Württemberg" 5 "Bremen" 6 "Hamburg" 7 "Hessen" 8 "Schleswig-Holstein" 9 "Niedersachsen" 10 "Nordrhein-Westfalen" 11 "Rheinland-Pfalz" 12 "Brandenburg" 13 "Sachsen" 14 "Sachsen-Anhalt" 15 "Mecklemburg-Vorpommern" 16 "Thüringen"
label variable state1 valuelabes

tab state1
by state1, sort: egen mean_tpi = mean(tpi)
egen mean_tpi2 = mean(tpi)
tab mean_tpi2

twoway scatter mean_tpi state1 if state1 == 1, msymbol(circle_hollow) || scatter mean_tpi state1 if state1 < 12 & state1 != 1, msymbol(circle_hollow) || connected mean_tpi state1  if state1 < 12 & state1 != 1, msymbol(diamond) || scatter mean_tpi state1 if state1 > 11, msymbol(circle_hollow) || connected mean_tpi state1  if state1 > 11, msymbol(diamond) ||, legend(off)  ytitle("Political Trust Index") xtitle("State") yline(0) xlabel(1 "BE" 2 "BY" 3 "SL" 4 "BW" 5 "HB" 6 "HH" 7 "HE" 8 "SH" 9 "NI" 10 "NW" 11 "RP" 12 "BB" 13 "SN" 14 "ST" 15 "MV" 16 "TH")

//Scattering it against SWD

gen outlier=1 if ref_to_pop > 0.035 | tpi < -3
gen outlier_label = "Bremen 2018" if outlier==1 & ref_to_pop > 0.035
replace outlier_label = "Saarland 2010" if outlier == 1 & tpi < -3
twoway scatter tpi ref_to_pop2 if outlier==., msymbol(circle_hollow) || lfit tpi ref_to_pop2 if outlier==., ytitle("Political Trust Index") xtitle("Refugee-to-Population Ratio") legend(off)
twoway scatter tpi ref_to_pop2, msymbol(circle_hollow) mlabel(outlier_label) || lfit tpi ref_to_pop2, ytitle("Political Trust Index") xtitle("Refugee-to-Population Ratio") legend(off) 
twoway scatter tpi ref_to_pop2, msymbol(circle_hollow) mlabel (nuts1)|| lfit tpi ref_to_pop2, ytitle("Political Trust Index") xtitle("Refugee-to-Population Ratio") legend(off) 

**************************************
*Creating the Unemployment + GDP	 * 
**************************************
by year state, sort: gen unemployment_lagged =. 
replace unemployment_lagged = n1_loun_pc_une_2008 if year == 2010 
replace unemployment_lagged = n1_loun_pc_une_2010 if year == 2012 
replace unemployment_lagged = n1_loun_pc_une_2012 if year == 2014 
replace unemployment_lagged = n1_loun_pc_une_2014 if year == 2016 
replace unemployment_lagged = n1_loun_pc_une_2016 if year == 2018
label var unemployment_lagged "Unemployment per year lagged by 2 years"

by year state, sort: gen unemployment_lagged1 =. 
replace unemployment_lagged1 = n1_loun_pc_une_2009 if year == 2010 
replace unemployment_lagged1 = n1_loun_pc_une_2011 if year == 2012 
replace unemployment_lagged1 = n1_loun_pc_une_2013 if year == 2014 
replace unemployment_lagged1 = n1_loun_pc_une_2015 if year == 2016 
replace unemployment_lagged1 = n1_loun_pc_une_2017 if year == 2018
label var unemployment_lagged1 "Unemployment per year lagged by 1 years"

by year state, sort: gen unemployment_lagged3 =. 
replace unemployment_lagged3 = n1_loun_pc_une_2007 if year == 2010 
replace unemployment_lagged3 = n1_loun_pc_une_2009 if year == 2012 
replace unemployment_lagged3 = n1_loun_pc_une_2011 if year == 2014 
replace unemployment_lagged3 = n1_loun_pc_une_2013 if year == 2016 
replace unemployment_lagged3 = n1_loun_pc_une_2015 if year == 2018
label var unemployment_lagged3 "Unemployment per year lagged by 3 years"

by year state, sort: gen GDP_per_state =. 
replace GDP_per_state = n1_gdp_eurhab_2010 if year == 2010 
replace GDP_per_state = n1_gdp_eurhab_2012 if year == 2012 
replace GDP_per_state = n1_gdp_eurhab_2014 if year == 2014 
replace GDP_per_state = n1_gdp_eurhab_2016 if year == 2016 
replace GDP_per_state = n1_gdp_eurhab_2017 if year == 2018 
label var GDP_per_state "GDP per State"

by year state, sort: gen GDP_per_state_lagged =. 
replace GDP_per_state_lagged = n1_gdp_eurhab_2008 if year == 2010 
replace GDP_per_state_lagged = n1_gdp_eurhab_2010 if year == 2012 
replace GDP_per_state_lagged = n1_gdp_eurhab_2012 if year == 2014 
replace GDP_per_state_lagged = n1_gdp_eurhab_2014 if year == 2016 
replace GDP_per_state_lagged = n1_gdp_eurhab_2016 if year == 2018 
label var GDP_per_state_lagged "GDP per State lagged by 2 years"

by year state, sort: gen GDP_per_state_lagged1 =. 
replace GDP_per_state_lagged1 = n1_gdp_eurhab_2009 if year == 2010 
replace GDP_per_state_lagged1 = n1_gdp_eurhab_2011 if year == 2012 
replace GDP_per_state_lagged1 = n1_gdp_eurhab_2013 if year == 2014 
replace GDP_per_state_lagged1 = n1_gdp_eurhab_2015 if year == 2016 
replace GDP_per_state_lagged1 = n1_gdp_eurhab_2017 if year == 2018 
label var GDP_per_state_lagged1 "GDP per State lagged by 1 years"

by year state, sort: gen GDP_per_state_lagged3 =. 
replace GDP_per_state_lagged3 = n1_gdp_eurhab_2007 if year == 2010 
replace GDP_per_state_lagged3 = n1_gdp_eurhab_2009 if year == 2012 
replace GDP_per_state_lagged3 = n1_gdp_eurhab_2011 if year == 2014 
replace GDP_per_state_lagged3 = n1_gdp_eurhab_2013 if year == 2016 
replace GDP_per_state_lagged3 = n1_gdp_eurhab_2015 if year == 2018 
label var GDP_per_state_lagged3"GDP per State lagged by 3 years"

*****************************************
*Creating Aggregated Individual Dummies * 
*****************************************
//Gender
gen gender2 = gndr - 1 
by year state, sort: egen gender_mean = mean(gender2)

//Age 
//Religion

//Income

//
by year former_gdr, sort: egen mean_former_gdr = mean(tpi) if former_gdr == 1
by year former_gdr, sort: egen mean_brd = mean(tpi) if former_gdr == 0 

twoway line mean_former_gdr year  || line mean_brd year, xline(2015) ytitle(TPI)
**************************************
*Preparing Data for Panel-Analysis	 * 
**************************************
by year state, sort: gen unique = _n==1
//count n and weight 
by state1, sort: egen weight = count(_n)
by year state1, sort: egen weight2 = count(_n)

//Collapse the dataset
drop if unique == 0

//Declaring Data to be Time Series
tsset state1 year, yearly delta(2)




*------------------------------------------------------------------------------*
*								Running the regression						   *	
*------------------------------------------------------------------------------*

//Model 1, only ref_to_pop
xtreg tpi ref_to_pop2 [pweight = weight] if outlier==., fe robust cluster(state1)
outreg2 using myreg.doc, replace ctitle(Model 1) adjr2
estimates store model1

//Model2, including unemployment_lagged 1
xtreg tpi ref_to_pop2 swm unemployment_lagged1 GDP_per_state_lagged1	 [pweight = weight] if outlier ==. , fe robust cluster(state1) //Robust standard Errors are included
outreg2 using myreg.doc, append ctitle(Model 3) adjr2
estimates store model2

//Model3, including controlls
xtreg tpi ref_to_pop2 swm unemployment_lagged GDP_per_state_lagged	 [pweight = weight] if outlier ==. , fe robust cluster(state1) //Robust standard Errors are included
outreg2 using myreg.doc, append ctitle(Model 2) adjr2
estimates store model3

//Model4, including unemployment_lagged 1
xtreg tpi ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged3	 [pweight = weight] if outlier ==. , fe robust cluster(state1) //Robust standard Errors are included
outreg2 using myreg.doc, append ctitle(Model 4) adjr2
estimates store model4

//Model5, Using the significant things 
xtreg tpi ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1	 [pweight = weight] if outlier ==. , fe robust cluster(state1) //Robust standard Errors are included
outreg2 using myreg.doc, append ctitle(Model 5) adjr2
estimates store model5

xtreg tpi ref_to_pop2 swm unemployment_lagged3 gender2 [pweight = weight] if outlier ==., fe robust cluster(state1)


//Creating the coefplot
coefplot model1 model2 model3 model4 model5, vertical drop(unemployment_lagged unemployment_lagged1 unemployment_lagged2 unemployment_lagged3 _cons	GDP_per_state_lagged1 GDP_per_state_lagged GDP_per_state_lagged3 swm) xtitle("Refugee-to-Population ratio") xlabel("") ytitle("Effect Size") title("Effect Size of Refugee to population ration using alternative lag specification") legend(label(2 "No lag GDP & Unemploy") label(4 "GDP & Unemploy lag1") label(6 "GDP & Unemploy lag2") label(8 "GDP & Unemploy lag3") label(10 "GDP lag1 & Unemploy lag3"))

//Normal regression to show marginsplot
reg tpi i.state1 ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1 gender2 [pweight = weight] if outlier ==. , robust cluster(state1)
margins state1
marginsplot, xlabel(1 "BE" 2 "BY" 3 "SL" 4 "BW" 5 "HB" 6 "HH" 7 "HE" 8 "SH" 9 "NI" 10 "NW" 11 "RP" 12 "BB" 13 "SN" 14 "ST" 15 "MV" 16 "TH") xtitle("State") title("Predictive Margins of state with 95% CI") 

//Running it with only i.former_gdr
reg tpi i.former_gdr ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1 i.gndr   [pweight = weight] if outlier ==. , robust 
outreg2 using myreg2.doc, replace ctitle(Former_GDR) adjr2
margins i.former_gdr
marginsplot


*------------------------------------------------------------------------------*
*							Post Regression Diagnosis						   *	
*------------------------------------------------------------------------------*

//Multicollinearity?
reg tpi i.state1 ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1  [pweight = weight] if outlier ==. , robust cluster(state1)
vif
//The only seemingly problematic variable is GDP, which should however stay in the euquation due to the theoretical importance, as elaborated in the essay. 
//Heteroskedasticity?
xtreg tpi ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1 [pweight = weight], fe 
xttest2
reg tpi i.state1 ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1, 
hettest 
//yes, we have Heteroskedasticity. Therefore, we include robust standard errors and cluster them on the state-level
//Outliers
reg tpi i.state1 ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1
predict d, cooksd
list state year d                                                           // An observation is an outlier if the D > (4 / N) 
list state year d if d>4/(e(N)) & e(sample)
//Using Cooks'D for outliers would remove 8 observations from my sample, which would be equal to 10% ob my observations. Therefore, I rather use graphical approach and exclude only two observations: Saarland 2010 and Bremen 2018. 

//Endogeneity
reg tpi i.state1 ref_to_pop2 swm unemployment_lagged3 GDP_per_state_lagged1  [pweight = weight] if outlier ==. , robust cluster(state1)
ovtest
estat endogenous
//Not Significant, we can exclude a model mispecification.

