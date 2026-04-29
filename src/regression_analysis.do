capture log close
log using "output/regression_analysis.log", replace text
set more off

use "output/gss_sample.dta", clear

gen joblose_r = 5 - joblose if !missing(joblose)
gen female    = (sex == 2) if !missing(sex)
gen black     = (race == 2) if !missing(race)
gen other_race = (race == 3) if !missing(race)
gen ln_income = ln(conrinc) if conrinc > 0
gen yr2022    = (year == 2022)
gen yr2024    = (year == 2024)
gen lmoe_x_wc = lmoe_score * white_collar

di _n(3)
di "MODEL 1: GSS Perceived Job Loss Risk (OLS)"

reg joblose_r lmoe_score, robust
estimates store A1

reg joblose_r lmoe_score age female black other_race ///
    i.degree ln_income hrs1 union_member self_emp yr2022 yr2024, robust
estimates store A2

reg joblose_r lmoe_score white_collar lmoe_x_wc age female black other_race ///
    i.degree ln_income hrs1 union_member self_emp yr2022 yr2024, robust
estimates store A3

estimates table A1 A2 A3, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

di _n(3)
di "ADVANCED METHOD 1: Ordered Probit — Perceived Job Loss Risk"

oprobit joblose_r lmoe_score white_collar lmoe_x_wc age female black other_race ///
    i.degree ln_income hrs1 union_member self_emp yr2022 yr2024, robust
estimates store A4_oprobit

margins, dydx(lmoe_score white_collar lmoe_x_wc) predict(outcome(4))
margins, dydx(lmoe_score white_collar lmoe_x_wc) predict(outcome(3))
margins, dydx(lmoe_score white_collar lmoe_x_wc) predict(outcome(2))
margins, dydx(lmoe_score white_collar lmoe_x_wc) predict(outcome(1))

di _n(3)
di "MODEL 2: CPS Displacement — Linear Probability Model"

use "output/cps_sample.dta", clear

gen female     = (sex == 2) if !missing(sex)
gen black      = (race == 200) if !missing(race)
gen other_race = (!inlist(race, 100, 200)) if !missing(race)
gen educ_hs   = (educ == 73)
gen educ_some = inrange(educ, 80, 100)
gen educ_ba   = (educ == 111)
gen educ_grad = inrange(educ, 123, 125)
gen lmoe_x_wc = lmoe_score * white_collar

reg displaced lmoe_score [pw=wtfinl], robust
estimates store C1

reg displaced lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store C2

reg displaced lmoe_score white_collar lmoe_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store C3

estimates table C1 C2 C3, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

di _n(3)
di "ADVANCED METHOD 2: Probit — Realized Displacement"

probit displaced lmoe_score white_collar lmoe_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store C4_probit

margins, dydx(lmoe_score white_collar lmoe_x_wc age female black ///
    educ_hs educ_some educ_ba educ_grad)

di _n(3)
di "MODEL 3: CPS Wage Change After Displacement (OLS)"

preserve

keep if displaced == 1 & re_employed == 1 & !missing(wage_change)
keep if inrange(wage_change, -1, 2)

di "Wage change sample: N = " _N
sum wage_change, detail

reg wage_change lmoe_score [pw=wtfinl], robust
estimates store D1

reg wage_change lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad ///
    dwyears [pw=wtfinl], robust
estimates store D2

reg wage_change lmoe_score white_collar lmoe_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad ///
    dwyears [pw=wtfinl], robust
estimates store D3

estimates table D1 D2 D3, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

restore

di _n(3)
di "SUBGROUP: CPS Displacement — Blue-Collar Only"

reg displaced lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad ///
    [pw=wtfinl] if white_collar == 0, robust
estimates store C_blue

di _n(3)
di "SUBGROUP: CPS Displacement — White-Collar Only"

reg displaced lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad ///
    [pw=wtfinl] if white_collar == 1, robust
estimates store C_white

estimates table C_blue C_white, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

di _n(3)
di "POSITION ABOLISHED: Probit — Structural Displacement"

preserve

keep if displaced == 1 & !missing(dwreas)

gen pos_abolished = (dwreas == 2) if !missing(dwreas)
tab dwreas
sum pos_abolished

probit pos_abolished lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store E1

probit pos_abolished lmoe_score white_collar lmoe_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store E2

margins, dydx(lmoe_score white_collar lmoe_x_wc)

estimates table E1 E2, star(0.10 0.05 0.01) stats(N r2_p) b(%9.4f)

restore

di _n(3)
di "RE-EMPLOYMENT: Probit — Among Displaced Workers"

preserve

keep if displaced == 1

probit re_employed lmoe_score age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store R1

probit re_employed lmoe_score white_collar lmoe_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store R2

margins, dydx(lmoe_score white_collar lmoe_x_wc)

estimates table R1 R2, star(0.10 0.05 0.01) stats(N r2_p) b(%9.4f)

restore

di _n(3)
di "JOB FINDING DIFFICULTY: GSS (OLS)"

use "output/gss_sample.dta", clear

gen jobfind_r = 4 - jobfind if !missing(jobfind)
gen female    = (sex == 2) if !missing(sex)
gen black     = (race == 2) if !missing(race)
gen other_race = (race == 3) if !missing(race)
gen ln_income = ln(conrinc) if conrinc > 0
gen yr2022    = (year == 2022)
gen yr2024    = (year == 2024)
gen lmoe_x_wc = lmoe_score * white_collar

reg jobfind_r lmoe_score, robust
estimates store F1

reg jobfind_r lmoe_score age female black other_race ///
    i.degree ln_income hrs1 union_member self_emp yr2022 yr2024, robust
estimates store F2

reg jobfind_r lmoe_score white_collar lmoe_x_wc age female black other_race ///
    i.degree ln_income hrs1 union_member self_emp yr2022 yr2024, robust
estimates store F3

estimates table F1 F2 F3, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

di _n(3)
di "ROUTINE COGNITIVE TASK INDEX: CPS Displacement"

use "output/cps_sample.dta", clear

gen female     = (sex == 2) if !missing(sex)
gen black      = (race == 200) if !missing(race)
gen other_race = (!inlist(race, 100, 200)) if !missing(race)
gen educ_hs   = (educ == 73)
gen educ_some = inrange(educ, 80, 100)
gen educ_ba   = (educ == 111)
gen educ_grad = inrange(educ, 123, 125)
gen tcr_x_wc = task_routine_cog * white_collar

reg displaced task_routine_cog [pw=wtfinl], robust
estimates store T1

reg displaced task_routine_cog age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store T2

reg displaced task_routine_cog white_collar tcr_x_wc age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store T3

estimates table T1 T2 T3, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

di _n(3)
di "DEGREE OF AUTOMATION AS CONTROL: CPS Displacement"

gen lmoe_x_wc = lmoe_score * white_collar

reg displaced lmoe_score white_collar lmoe_x_wc degree_automation age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store G1

reg displaced lmoe_score white_collar lmoe_x_wc degree_automation ///
    task_routine_cog age female ///
    black other_race educ_hs educ_some educ_ba educ_grad [pw=wtfinl], robust
estimates store G2

estimates table G1 G2, star(0.10 0.05 0.01) stats(N r2) b(%9.4f)

log close
