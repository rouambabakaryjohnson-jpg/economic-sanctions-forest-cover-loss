clear all
set mem 5g
set maxvar  120000

cd "C:\M2FP\ASSISTANT DE RECHERCHE CERDI\00 Sanction FP\Bases de données\Deforestation"




*=========================== Stylized facts ===========================*


*=========================== Figure 2===========================*
clear all
use data_sancdeforestall_end.dta, clear

preserve

* Comptabiliser le nombre de pays sous différents types de sanctions chaque année
collapse (sum) sanctions trade financial, by(year)

* Dessiner des lignes pour les différents types de sanctions
twoway (line sanctions year, lwidth(medium) lcolor(blue) lpattern(solid) ///
           legend(label(1 "Economic sanctions"))) ///
       (line trade year, lwidth(medium) lcolor(red) lpattern(solid) ///
           legend(label(2 "Trade sanctions"))) ///
       (line financial year, lwidth(medium) lcolor(green) lpattern(solid) ///
           legend(label(3 "Financial sanctions"))) ///
       , ///
       ytitle("Number of sanctioned countries") ///
       xtitle("Year") ///
       legend(order(1 2 3) position(6) region(lstyle(none)))
*graph export "$graphs\Graph_Evolution_of_Eco_Sanc.png", replace
restore

*=========================== Figure 3===========================*
clear all
use data_sancdeforestall_end.dta, clear

preserve

collapse (mean) global_deforest sanctions, by(isocode)
twoway (scatter global_deforest sanctions, msize(small)) ///
       (lfit global_deforest sanctions), ///
       legend(off) ///
       xtitle("Share of study years subject to economic sanctions") ///
       ytitle("Average annual forest-cover loss rate")
*graph export "$graphs\Graph_scatte_plot_2.png", replace

restore

*=========================== Figure 4===========================*
clear all
use data_sancdeforestall_end.dta, clear

preserve

gen global_deforest_scaled = round(global_deforest, 0.01)

graph bar (mean) global_deforest_scaled, over(sanctions, label) ///
    ytitle("Forest cover loss rate") ///
    note("Economic sanctions") ///
    name(graph1, replace) ///
    blabel(bar, size(small) color(black) position(above) format(%9.2f)) /// 
    bar(1, lcolor(brown) color(brown)) ///
    bar(2, lcolor(brown) color(brown))
*graph export "$graphs\Average_deforestation_Eco_Sanc.png", replace

* Effectuer un t-test entre les groupes
ttest global_deforest, by(sanctions)

restore


*=========================== Table 12 ===========================*

// Pour des statistiques descriptives plus détaillées (moyenne, écart type, percentiles, etc.) 
* Générer les statistiques descriptives et les stocker
asdoc summarize sanctions trade financial us_sanctions eu_sanctions un_sanctions uni_sanctions multi_sanctions Success_part_sanc Success_total_sanc Failed_sanc global_deforest gdpcapgrw traope fdi polititerr  ext_conflict population br_coup gdpcap_ihs forestrent agri_km2_ihs Cereal_çyield_ihs, save(stat.doc) replace



// Covariate balance: Descriptive statistics before weighting Treated versus untreated country-year observations


***************************** Regressions Tables ******************************

*=========================== Table 1===========================*
*========= Column 1, 2 and 3 =========
clear all
use data_sancdeforestall_end.dta, clear
global controls_main gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup
label var gdpcapgrw    "GDP per capita growth"
label var traope       "Trade openness"
label var fdi          "Foreign direct investment"
label var polititerr   "Political terror"
label var ext_conflict "External Conflict"
label var population_ihs "Population (IHS)"
label var br_coup      "Number of coups"

gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
quietly ebalance sanctions $controls_main i.year if complete ==1, g(weight) tolerance(0.52) 

count if sanctions==1 & complete==1
local N_t = r(N)
count if sanctions==0 & complete==1
local N_c = r(N)

tempfile tbl
tempname mem
postutil clear
postfile `mem' str28 variable str1 panel double treat control using "`tbl'", replace

foreach v in gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup {
    local pretty : variable label `v'
    if "`pretty'"=="" local pretty "`v'"
	
    * ----- Panel A : Before weighting 
    quietly summarize `v' if sanctions==1 & complete==1, meanonly
    local a_t = r(mean)
    quietly summarize `v' if sanctions==0 & complete==1, meanonly
    local a_c = r(mean)
    post `mem' ("`pretty'") ("A") (`a_t') (`a_c')

    * ----- Panel B : After weighting 
    quietly summarize `v' if sanctions==1 & complete==1, meanonly
    local b_t = r(mean)                            
    quietly summarize `v' [aw=weight] if sanctions==0 & complete==1, meanonly
    local b_c = r(mean)
    post `mem' ("`pretty'") ("B") (`b_t') (`b_c')
}

post `mem' ("Observations") ("A") (`N_t') (`N_c')
post `mem' ("Observations") ("B") (`N_t') (`N_c')
postclose `mem'
use "`tbl'", clear
gen double difference = control - treat
gen str12 treat_s  = cond(variable=="Observations", string(treat,   "%9.0f"), string(treat,   "%9.5f"))
gen str12 control_s= cond(variable=="Observations", string(control, "%9.0f"), string(control, "%9.5f"))
gen str12 difference_s    = cond(variable=="Observations", "",            string(difference,   "%9.5f"))


*========= Column 1 =========
preserve

*Panel A (Before weighting)
di as text "{bf:Panel A : Before weighting}"
list variable treat_s if panel=="A", noobs sep(0) abbrev(32)

*Panel B (After weighting )
di _n as text "{bf:Panel B : After weighting}"
list variable treat_s if panel=="B", noobs sep(0) abbrev(32)

restore


*========= Column 2 =========
preserve

*Panel A (Before weighting)
di as text "{bf:Panel A : Before weighting}"
list variable control_s if panel=="A", noobs sep(0) abbrev(32)

*Panel B (After weighting )
di _n as text "{bf:Panel B : After weighting}"
list variable control_s if panel=="B", noobs sep(0) abbrev(32)

restore


*========= Column 3 =========
preserve

*Panel A (Before weighting)
di as text "{bf:Panel A : Before weighting}"
list variable difference_s if panel=="A", noobs sep(0) abbrev(32)

*Panel B (After weighting )
di _n as text "{bf:Panel B : After weighting}"
list variable difference_s if panel=="B", noobs sep(0) abbrev(32)

restore


*========= Column 4 =========
clear all
use data_sancdeforestall_end.dta, clear
global controls_main gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup
label var gdpcapgrw    "GDP per capita growth"
label var traope       "Trade openness"
label var fdi          "Foreign direct investment"
label var polititerr   "Political terror"
label var ext_conflict "External Conflict"
label var population_ihs "Population (IHS)"
label var br_coup      "Number of coups"

*Panel A (Before weighting)
preserve

tempfile out
tempname mem
postfile `mem' str20 variable double pValue using "`out'", replace

foreach v in gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup {
    quietly ttest `v', by(sanctions) unequal
	local pretty : variable label `v'
    if "`pretty'"=="" local pretty "`v'"
    post `mem' ("`pretty'") (r(p))
}

postclose `mem'
use "`out'", clear
format pValue %10.3f    //
list variable pValue, noobs sep(0)

restore


*Panel A (Before weighting)
preserve

gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions $controls_main i.year if complete ==1, g(weight) tolerance(0.52) 

* Boucle de régressions avec poids analytiques et erreurs robustes
tempfile out
tempname mem
postfile `mem' str20 variable double coef se t pValue N r2 using "`out'", replace

foreach y in gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup {
    quietly regress `y' sanctions [aweight=weight], vce(robust)
    local b  = _b[sanctions]
    local se = _se[sanctions]
    local t  = `b'/`se'
    local p  = 2*ttail(e(df_r), abs(`t'))
    local pretty : variable label `y'
    if "`pretty'"=="" local pretty "`y'"
    post `mem' ("`pretty'") (`b') (`se') (`t') (`p') (e(N)) (e(r2))
}

postclose `mem'
use "`out'", clear
format pValue %10.3f
list variable pValue, noobs sep(0)

restore

*=========================== Table 2===========================*

***********************Entropy balancy*************************
*ssc install ebalance
clear all
use data_sancdeforestall_end.dta, clear

*****************************************First step*************************************************
gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

******************************************Second step************************************************
reg global_deforest sanctions [pweight=weight], ro
outreg2 using resultat_sanctions.xls, replace excel ctitle("Modèle de régression") label dec(3)

reg global_deforest sanctions i.year i.id [pweight=weight], ro
outreg2 using resultat_sanctions.xls, append excel ctitle("Modèle de régression") label dec(3)

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup [pweight=weight], ro
outreg2 using resultat_sanctions.xls, append excel ctitle("Modèle de régression") label dec(3)

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_sanctions.xls, append excel ctitle("Modèle de régression") label dec(3)





**********************
mean global_deforest

*les sanctions réduise le couvert forestier de 18% en moyenne dans les pays sanctionnées par rapport au pays non sanctionéé

display 0.0661901/0.4683482


**************************************** Robustness tests *********************



************************** avec eco_sanc_int_type
clear all
use data_sancdeforestall_end.dta, clear

global controls gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup
ebct $controls, treatvar(eco_sanc_int_type) out(global_deforest) est(drf) bootstrap reps(200) graph generate(var)
regress global_deforest eco_sanc_int_type gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=var_weight], robust
outreg2 using resultat_sanctions_int.xls, replace excel ctitle("Modèle de régression") label dec(3)

************************** avec eco_sanc_int_nse
clear all
use data_sancdeforestall_end.dta, clear

gen sanc_entities_cat = .

replace sanc_entities_cat = 0 if eco_sanc_int_nse == 0
replace sanc_entities_cat = 1 if eco_sanc_int_nse == 1
replace sanc_entities_cat = 2 if eco_sanc_int_nse == 2
replace sanc_entities_cat = 3 if eco_sanc_int_nse >= 3 & eco_sanc_int_nse <= 5
replace sanc_entities_cat = 4 if eco_sanc_int_nse >= 6 & eco_sanc_int_nse <= 13
replace sanc_entities_cat = 5 if eco_sanc_int_nse >= 14


global controls gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup
ebct $controls, treatvar(sanc_entities_cat) out(global_deforest) est(drf) bootstrap reps(200) graph generate(var)
regress global_deforest sanc_entities_cat gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=var_weight], robust
outreg2 using resultat_sanctions_int.xls, append excel ctitle("Modèle de régression") label dec(3)



************************** Alternative Measures of the Dependent Variable


clear all
use data_sancdeforestall_end.dta, clear

xtset id year
gen MM3_global_deforest = (L.global_deforest + global_deforest + F.global_deforest) / 3

gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

reg MM3_global_deforest sanctions [pweight=weight], ro
outreg2 using resultat_sanctionsAMDV.xls, replace excel ctitle("Modèle de régression") label dec(3)

reg MM3_global_deforest sanctions i.year i.id [pweight=weight], ro
outreg2 using resultat_sanctionsAMDV.xls, append excel ctitle("Modèle de régression") label dec(3)

reg MM3_global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup [pweight=weight], ro
outreg2 using resultat_sanctionsAMDV.xls, append excel ctitle("Modèle de régression") label dec(3)

reg MM3_global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_sanctionsAMDV.xls, append excel ctitle("Modèle de régression") label dec(3)


************************************************************
* ROBUSTNESS TESTS
************************************************************


************************************************************
* 1. Lagged Covariates
************************************************************

clear all
use data_sancdeforestall_end.dta, clear

xtset id year

gen gdpcapgrw_l1      = L.gdpcapgrw
gen traope_l1         = L.traope
gen fdi_l1            = L.fdi
gen polititerr_l1     = L.polititerr
gen ext_conflict_l1   = L.ext_conflict
gen population_ihs_l1 = L.population_ihs
gen br_coup_l1        = L.br_coup

gen complete = !missing(gdpcapgrw_l1, traope_l1, fdi_l1, polititerr_l1, ext_conflict_l1, population_ihs_l1, br_coup_l1)

ebalance sanctions gdpcapgrw_l1 traope_l1 fdi_l1 polititerr_l1 ext_conflict_l1 population_ihs_l1 br_coup_l1 i.year if complete == 1, g(weight) tolerance(0.52)

reg global_deforest sanctions gdpcapgrw_l1 traope_l1 fdi_l1 polititerr_l1 ext_conflict_l1 population_ihs_l1 br_coup_l1 i.year i.id [pweight=weight], ro
outreg2 using resultat_economic_sanctions_AS.xls, replace excel ctitle("Lagged covariates") label dec(3)


************************************************************
* 2. Placebo
************************************************************

clear all
use data_sancdeforestall_end.dta, clear

set seed 12345

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)

bysort year: egen n_sanctions = total(sanctions * complete)

gen random_order = runiform()
gen placebo = 0

bysort year (random_order): replace placebo = 1 if _n <= n_sanctions & complete == 1

drop n_sanctions random_order

ebalance placebo gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete == 1, g(weight) tolerance(0.52)

reg global_deforest placebo gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_economic_sanctions_AS.xls, append excel ctitle("Placebo") label dec(3)


************************************************************
* 3. Excluding Global Financial Crisis
************************************************************

clear all
use data_sancdeforestall_end.dta, clear

drop if inrange(year, 2008, 2009)

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)

ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete == 1, g(weight) tolerance(0.52)

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro

outreg2 using resultat_economic_sanctions_AS.xls, append excel ctitle("Excluding GFC") label dec(3)


************************************************************
* 4. Excluding 2017-2020
************************************************************

clear all
use data_sancdeforestall_end.dta, clear

drop if inrange(year, 2017, 2020)

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)

ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete == 1, g(weight) tolerance(0.52)

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_economic_sanctions_AS.xls, append excel ctitle("Excluding 2017-2020") label dec(3)


	
*************************************variable de controle aditionnelle**************************

************inflation_ifm 

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, inflation_ifm)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup inflation_ifm i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup inflation_ifm i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, replace excel ctitle("Inflation") label dec(3)

************ggovgrodebt (Debt and Deforestation: A Review of Causes and Empirical Evidence)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, ggovgrodebt)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup ggovgrodebt i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup ggovgrodebt i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Public Debt") label dec(3)

************ggx_ngdp (Public spending, credit and natural capital: Does access to capital foster deforestation?) and (The effects of government spending on deforestation due to agricultural land expansion and CO2 related emissions)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, ggx_ngdp)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup ggx_ngdp i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup ggx_ngdp i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Public Spending") label dec(3)

************Corruption (The Impact of Corruption on Deforestation: A Cross-Country Evidence)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, Corruption)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Corruption i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Corruption i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Corruption") label dec(3)

************Law_and_Order (Deforestation and the Rule of Law in a Cross-Section of Countries)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, Law_and_Order)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Law_and_Order i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Law_and_Order i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Law and Order") label dec(3)

************EITI (Does transparency matter? Evaluating the Impacts of the Extractive Industries Transparency Initiative (EITI) on Deforestation in Resource-rich Developing Countries)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, EITI)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup EITI i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup EITI i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("EITI") label dec(3)



************extractive_rents (The effects of extractive industries rent on deforestation in developing countries)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, extractive_rents)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup extractive_rents i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup extractive_rents i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Extactive rents") label dec(3)

************popdensity 

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, br_coup, popdensity)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict br_coup popdensity i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict popdensity br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Population Density") label dec(3)


************Unemployment (Deforestation: correlations, possible causes and some implications )

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, Unemployment)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Unemployment i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup Unemployment i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Unemployment") label dec(3)


************aid (The effects of extractive industries rent on deforestation in developing countries)

clear all
use data_sancdeforestall_end.dta, clear

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup, aid)
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup aid i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup aid i.year i.id [pweight=weight], ro
outreg2 using resultat_controle_aditionnelle_sanctions.xls, append excel ctitle("Foreign Aid") label dec(3)



********************************** ALTERNATIVE ESTIMATION ***************************************

*************OLS
clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

reg global_deforest sanctions $covariables i.id i.year, ro
outreg2 using resultat_alternative_estimations_sanctions.xls, replace excel ctitle("OLS") label dec(3)


*************PROPENSITY SCORE MATCHING

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

******k-Nearest neighbors matching
bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com n(1) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com n(2) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com n(3) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com n(4) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com n(5) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

******Radius Matching
bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com radius caliper(0.01) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com radius caliper(0.05) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com radius caliper(0.001) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)

****** Kernel matching
bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com kernel kerneltype(normal) qui
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)	

******LLR
bootstrap r(att), reps(500): psmatch2 sanctions $covariables i.year, out(global_deforest) com llr
outreg2 using resultat_alternative_estimations_sanctions.xls, append excel ctitle("KNN-1") label dec(3)



**************************************** HETROGENEITE DES RESULTATS *********************

*********resource_rich "Resource rich countries — coded as 1 for a country when the sum of total natural‑resource rents exceeded 5 percent of GDP in at least one year between 2001 and 2022"

clear all
set more off
use data_sancdeforestall_end.dta, clear

bysort country: egen max_rr = max(cond(inrange(year, 2001, 2022), ressrents, .))
gen byte resource_rich = (max_rr > 5) if inrange(year, 2001, 2022)
drop max_rr
label variable resource_rich "Resource-rich country: total natural-resource rents exceeded 5% of GDP at least once between 2001 and 2022"

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions $covariables i.year i.id if resource_rich == 1  [pweight=weight], robust
outreg2 using resultat_heterogeneity_sanctions.xls, replace excel ctitle("resource-dependen") label dec(3)

reg global_deforest sanctions $covariables i.year i.id if resource_rich == 0 [pweight=weight], robust
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("non-resource-dependen") label dec(3)


************Emerging (1 if middle-income economy (The logarithm of GDP per capita > US$ 8.04433))
clear all
set more off
use data_sancdeforestall_end.dta, clear

summarize gdpcap_ihs, detail
local median_gdpcap = r(p50)
gen Emerging = .
replace Emerging = 1 if gdpcap_ihs > `median_gdpcap' & gdpcap_ihs < .
replace Emerging = 0 if gdpcap_ihs <= `median_gdpcap' & gdpcap_ihs < .
label variable Emerging "1 if middle-income economy"

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest sanctions $covariables i.year i.id if Emerging == 1 [pweight=weight], robust
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("middle-incom") label dec(3)

reg global_deforest sanctions $covariables i.year i.id if Emerging == 0 [pweight=weight], robust
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("low-incom") label dec(3)


************Trade sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance trade $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest trade $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, replace excel ctitle("Trade sanctions") label dec(3)


************Financial sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance financial $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest financial $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("financial sanctions") label dec(3)


************US sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance us_sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest us_sanctions $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("U.S. sanctions") label dec(3)


************EU sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance eu_sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest eu_sanctions $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("E.U. sanctions") label dec(3)

************UN sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance un_sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest un_sanctions $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("U.N. sanctions") label dec(3)

************Unilateral sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance uni_sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest uni_sanctions $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("Unilateral sanctions") label dec(3)

************Multilateral sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance multi_sanctions $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest multi_sanctions $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("Multilateral sanctions") label dec(3)

************Succes part sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance Success_part_sanc $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest Success_part_sanc $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("Success part sanctions") label dec(3)


************Succes total sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance Success_total_sanc $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest Success_total_sanc $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("Succes total sanctions") label dec(3)


************Failed sanctions

clear all
set more off
use data_sancdeforestall_end.dta, clear

global covariables gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup

gen complete = !missing(gdpcapgrw, traope, fdi, polititerr, ext_conflict, population_ihs, br_coup)
ebalance Failed_sanc $covariables i.year if complete ==1, g(weight) tolerance(0.52) 

reg global_deforest Failed_sanc $covariables i.year i.id [pweight=weight], ro
outreg2 using resultat_heterogeneity_sanctions.xls, append excel ctitle("Failed sanctions") label dec(3)



**************************************** CANAUX DE TRANSMISSION *********************


************gdpcap_ihs

clear all
use data_sancdeforestall_end.dta, clear

gen complete = 0
replace complete = 1 if traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

reg gdpcap_ihs sanctions traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_transmission_channels.xls, replace excel ctitle("GDP per capita") label dec(3)

************forestrent

drop complete
drop weight
gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

reg forestrent sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_transmission_channels.xls, append excel ctitle("forest rent") label dec(3)

************agri_km2_ihs

drop complete
drop weight
gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

reg agri_km2_ihs sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_transmission_channels.xls, append excel ctitle("Agricultural land") label dec(3)

************Cereal_çyield_ihs

drop complete
drop weight
gen complete = 0
replace complete = 1 if gdpcapgrw !=. & traope !=. & fdi !=. & polititerr !=. & ext_conflict !=. & population_ihs !=. & br_coup !=.
ebalance sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year if complete ==1, g(weight) tolerance(0.52) 

reg Cereal_çyield_ihs sanctions gdpcapgrw traope fdi polititerr ext_conflict population_ihs br_coup i.year i.id [pweight=weight], ro
outreg2 using resultat_transmission_channels.xls, append excel ctitle("Cereal yield") label dec(3)


















