capture mkdir output
capture log close

log using "output/cps_analysis.log", replace text

cd "cps"
quietly do "process.do"
cd ".."

keep year month occ2010 dwocc ind dwind empstat labforce classwkr dwclass ///
    dwlostjob dwstat dwreas dwrecall dwnotice dwyears dwfulltime dwweekl dwwagel ///
    dwunion dwben dwexben dwhi earnweek hourwage uhrsworkt ahrsworkt ///
    durunemp whyunemp jtyears jtsame occly wkswork2 ///
    age sex race marst educ cinethp ciemail cihforwk cintjbsr telwrkpay telwrkhr ///
    wtfinl

keep if age >= 20 & age <= 65
keep if inlist(dwlostjob, 1, 2)
drop if (missing(occ2010) | occ2010 == 0) & (missing(dwocc) | dwocc == 0)

gen occ_for_merge = occ2010
replace occ_for_merge = dwocc if dwlostjob == 2 & !missing(dwocc) & dwocc > 0
drop if missing(occ_for_merge) | occ_for_merge == 0

replace earnweek  = . if earnweek  <= 0
replace hourwage  = . if hourwage  <= 0
replace dwweekl   = . if dwweekl   <= 0
replace dwwagel   = . if dwwagel   <= 0
replace uhrsworkt = . if uhrsworkt <= 0 | uhrsworkt > 168
replace ahrsworkt = . if ahrsworkt <= 0 | ahrsworkt > 168
replace dwyears   = . if dwyears   <= 0
replace jtyears   = . if jtyears   <= 0
replace durunemp  = . if durunemp  <= 0
replace telwrkhr  = . if telwrkhr  < 0

gen displaced    = (dwlostjob == 2)
gen re_employed  = (inlist(empstat, 10, 12))    if dwlostjob == 2
gen wage_change  = (earnweek - dwweekl) / dwweekl if dwlostjob == 2 & dwweekl > 0 & earnweek > 0
gen telework     = (telwrkpay == 1)              if !missing(telwrkpay)
gen internet_home = (cinethp == 1)               if !missing(cinethp)
gen work_computer = (cihforwk == 1)              if !missing(cihforwk)

gen white_collar_occ = (occ_for_merge <= 1240 | inrange(occ_for_merge, 2100, 2550)) ///
    if !missing(occ_for_merge) & occ_for_merge > 0

preserve
use "output/gss_sample.dta", clear
keep occ10 prestg10
drop if missing(prestg10) | missing(occ10)
collapse (mean) prestg10, by(occ10)
rename occ10 occ_for_merge
tempfile prestige_xwalk
save `prestige_xwalk'
restore

merge m:1 occ_for_merge using `prestige_xwalk', keep(1 3) nogenerate keepusing(prestg10)

preserve
import delimited "cps/occ2010_to_soc.csv", clear
rename occ2010 occ_for_merge
tempfile xwalk_cps
save `xwalk_cps'
restore

merge m:1 occ_for_merge using `xwalk_cps', keep(1 3) nogenerate keepusing(soc_code)

preserve
import excel "LMOE.xlsx", sheet("LM AIOE") cellrange(A2:C775) clear
rename (A B C) (soc_code occ_title lmoe_score)
keep soc_code lmoe_score
tempfile lmoe_exact
save `lmoe_exact'
restore

preserve
import excel "LMOE.xlsx", sheet("LM AIOE") cellrange(A2:C775) clear
rename (A B C) (soc_code occ_title lmoe_score)
keep soc_code lmoe_score
gen soc_prefix = substr(soc_code, 1, 5)
collapse (mean) lmoe_prefix = lmoe_score, by(soc_prefix)
tempfile lmoe_pfx
save `lmoe_pfx'
restore

merge m:1 soc_code using `lmoe_exact', keep(1 3) nogenerate keepusing(lmoe_score)
gen soc_prefix = substr(soc_code, 1, 5)
merge m:1 soc_prefix using `lmoe_pfx', keep(1 3) nogenerate keepusing(lmoe_prefix)
replace lmoe_score = lmoe_prefix if missing(lmoe_score)
drop lmoe_prefix soc_prefix

merge m:1 soc_code using "output/onet_occ.dta", keep(1 3) nogenerate ///
    keepusing(working_w_computers task_routine_cog task_nrc_analytic ///
    task_interpersonal task_manual degree_automation repeat_tasks ///
    email_use time_sitting time_pressure indoors_controlled ///
    skill_cognitive skill_social skill_tech ///
    knowledge_computers knowledge_math knowledge_english job_zone)

drop soc_code

drop if missing(lmoe_score)

sum prestg10, detail
gen white_collar = (prestg10 >= r(p50)) if !missing(prestg10)

save "output/cps_sample.dta", replace

di "========================================="
di "SAMPLE 2 (CPS DWS): N = " _N
di "among these, displaced = "
count if displaced == 1
di "========================================="

sum lmoe_score prestg10 earnweek hourwage dwweekl dwwagel dwyears jtyears ///
    uhrsworkt ahrsworkt durunemp age wage_change
sum working_w_computers task_routine_cog task_nrc_analytic task_interpersonal task_manual
sum degree_automation repeat_tasks email_use time_sitting time_pressure indoors_controlled
sum skill_cognitive skill_social skill_tech knowledge_computers knowledge_math knowledge_english job_zone

tab year
tab month
tab sex
tab race
tab marst
tab empstat
tab labforce
tab classwkr
tab white_collar
tab displaced
tab dwstat
tab dwreas
tab dwrecall
tab dwnotice
tab dwunion
tab dwben
tab dwexben
tab dwhi
tab dwfulltime
tab dwclass
tab whyunemp
tab jtsame
tab telework
tab internet_home
tab work_computer

hist lmoe_score, normal freq ///
    title("Distribution of AI Exposure Score (CPS)") ///
    xtitle("Language Modeling Exposure Score") ///
    name(c_lmoe, replace)
graph export "output/cps_hist_lmoe.png", replace width(1200)

hist degree_automation, normal freq ///
    title("Distribution of Degree of Automation (CPS)") ///
    xtitle("Degree of Automation (O*NET)") ///
    name(c_autom, replace)
graph export "output/cps_hist_automation.png", replace width(1200)

hist earnweek, normal freq ///
    title("Distribution of Current Weekly Earnings (CPS)") ///
    xtitle("Weekly Earnings (USD)") ///
    name(c_earn, replace)
graph export "output/cps_hist_earnings.png", replace width(1200)

hist wage_change if dwlostjob == 2 & inrange(wage_change, -1, 2), normal freq ///
    title("Distribution of Wage Change After Displacement") ///
    xtitle("(Current - Lost) / Lost Earnings") ///
    name(c_wchg, replace)
graph export "output/cps_hist_wage_change.png", replace width(1200)

hist dwyears if dwlostjob == 2, normal freq ///
    title("Distribution of Tenure at Lost Job") ///
    xtitle("Years") ///
    name(c_tenure, replace)
graph export "output/cps_hist_tenure.png", replace width(1200)

hist age, normal freq ///
    title("Distribution of Age (CPS)") ///
    xtitle("Age (Years)") ///
    name(c_age, replace)
graph export "output/cps_hist_age.png", replace width(1200)

twoway ///
    (hist lmoe_score if white_collar == 0, color(navy%50) bin(20)) ///
    (hist lmoe_score if white_collar == 1, color(maroon%50) bin(20)), ///
    legend(label(1 "Blue-Collar") label(2 "White-Collar")) ///
    title("AI Exposure by Collar Type (CPS)") xtitle("LMOE Score") ///
    name(c_lmoe_collar, replace)
graph export "output/cps_hist_lmoe_collar.png", replace width(1200)

twoway ///
    (hist lmoe_score if displaced == 0, color(navy%50) bin(20)) ///
    (hist lmoe_score if displaced == 1, color(maroon%50) bin(20)), ///
    legend(label(1 "Not Displaced") label(2 "Displaced")) ///
    title("AI Exposure: Displaced vs Non-Displaced") xtitle("LMOE Score") ///
    name(c_lmoe_disp, replace)
graph export "output/cps_hist_lmoe_displaced.png", replace width(1200)

ttest lmoe_score,          by(white_collar)
ttest degree_automation,   by(white_collar)
ttest working_w_computers, by(white_collar)
ttest task_routine_cog,    by(white_collar)
ttest task_nrc_analytic,   by(white_collar)
ttest task_interpersonal,  by(white_collar)
ttest task_manual,         by(white_collar)
ttest skill_cognitive,     by(white_collar)
ttest skill_social,        by(white_collar)
ttest skill_tech,          by(white_collar)
ttest knowledge_computers, by(white_collar)
ttest job_zone,            by(white_collar)
ttest earnweek,            by(white_collar)
ttest uhrsworkt,           by(white_collar)

ttest lmoe_score,          by(displaced)
ttest degree_automation,   by(displaced)
ttest task_routine_cog,    by(displaced)
ttest task_nrc_analytic,   by(displaced)
ttest task_interpersonal,  by(displaced)
ttest task_manual,         by(displaced)
ttest skill_cognitive,     by(displaced)
ttest job_zone,            by(displaced)

log close
