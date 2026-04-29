capture mkdir output
capture log close

log using "output/analysis.log", replace text

use "gss/2024/GSS2024.dta", clear
keep year occ10 wrkstat joblose jobfind aiworry intskill satjob ///
    prestg10 indus10 conrinc realrinc hrs1 hrs2 ///
    age sex race educ degree marital childs region ///
    wrkslf unemp compuse union1 class finrela
tempfile gss24
save `gss24'

use "gss/2022/GSS2022.dta", clear
keep year occ10 wrkstat joblose jobfind satjob ///
    prestg10 indus10 conrinc realrinc hrs1 hrs2 ///
    age sex race educ degree marital childs region ///
    wrkslf unemp compuse union1 class finrela
tempfile gss22
save `gss22'

use "gss/2021/GSS2021.dta", clear
keep year occ10 wrkstat joblose jobfind satjob ///
    prestg10 indus10 conrinc realrinc hrs1 hrs2 ///
    age sex race educ degree marital childs region ///
    wrkslf unemp compuse union1 class finrela
append using `gss22'
append using `gss24'

keep if inlist(wrkstat, 1, 2)
drop if missing(occ10) | occ10 == 0

replace joblose  = . if !inlist(joblose,  1, 2, 3, 4)
replace jobfind  = . if !inlist(jobfind,  1, 2, 3)
replace aiworry  = . if !inlist(aiworry,  1, 2, 3, 4, 5)
replace intskill = . if !inlist(intskill, 1, 2, 3, 4, 5)
replace satjob   = . if !inlist(satjob,   1, 2, 3, 4)
replace conrinc  = . if conrinc  <= 0
replace realrinc = . if realrinc <= 0
replace hrs1     = . if hrs1     <= 0 | hrs1 > 168
replace hrs2     = . if hrs2     <= 0 | hrs2 > 168
replace prestg10 = . if prestg10 <= 0
replace unemp    = . if !inlist(unemp,   1, 2)
replace union1   = . if !inlist(union1,  1, 2, 3, 4)
replace class    = . if !inlist(class,   1, 2, 3, 4)
replace finrela  = . if !inlist(finrela, 1, 2, 3, 4, 5)
replace marital  = . if !inlist(marital, 1, 2, 3, 4, 5)
replace degree   = . if degree < 0 | degree > 4

gen computer_use = (compuse == 1)  if inlist(compuse, 1, 2)
gen ever_unemp   = (unemp   == 1)  if inlist(unemp,   1, 2)
gen self_emp     = (wrkslf  == 2)  if inlist(wrkslf,  1, 2, 3)
gen union_member = inlist(union1, 1, 2, 3) if inlist(union1, 1, 2, 3, 4)

preserve
import delimited "cps/occ2010_to_soc.csv", clear
rename occ2010 occ10
tempfile xwalk
save `xwalk'
restore

merge m:1 occ10 using `xwalk', keep(1 3) nogenerate keepusing(soc_code)

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
label define wc_lbl 0 "Blue-Collar" 1 "White-Collar"
label values white_collar wc_lbl

save "output/gss_sample.dta", replace

di "========================================="
di "SAMPLE 1 (GSS): N = " _N
di "========================================="

sum lmoe_score prestg10 conrinc realrinc hrs1 hrs2 age educ childs
sum working_w_computers task_routine_cog task_nrc_analytic task_interpersonal task_manual
sum degree_automation repeat_tasks email_use time_sitting time_pressure indoors_controlled
sum skill_cognitive skill_social skill_tech knowledge_computers knowledge_math knowledge_english job_zone

tab year
tab wrkstat
tab sex
tab race
tab degree
tab marital
tab region
tab class
tab finrela
tab union1
tab white_collar
tab satjob
tab joblose
tab jobfind
tab aiworry
tab intskill
tab computer_use
tab ever_unemp
tab self_emp
tab union_member

hist lmoe_score, normal freq color(navy%70) ///
    title("Distribution of AI Exposure Score", size(medlarge)) ///
    xtitle("Language Modeling Exposure Score") ///
    graphregion(color(white)) ///
    name(h_lmoe, replace)
graph export "output/hist_lmoe.png", replace width(1200)

hist degree_automation, normal freq color(navy%70) ///
    title("Distribution of Degree of Automation", size(medlarge)) ///
    xtitle("Degree of Automation (O*NET)") ///
    graphregion(color(white)) ///
    name(h_autom, replace)
graph export "output/hist_automation.png", replace width(1200)

hist task_routine_cog, normal freq color(navy%70) ///
    title("Distribution of Routine Cognitive Task Intensity", size(medlarge)) ///
    xtitle("Task Index") ///
    graphregion(color(white)) ///
    name(h_rc, replace)
graph export "output/hist_routine_cog.png", replace width(1200)

hist prestg10, normal freq color(navy%70) ///
    title("Distribution of Occupational Prestige", size(medlarge)) ///
    xtitle("Prestige Score (0-100)") ///
    graphregion(color(white)) ///
    name(h_prestige, replace)
graph export "output/hist_prestige.png", replace width(1200)

hist conrinc, normal freq color(navy%70) ///
    title("Distribution of Respondent Income", size(medlarge)) ///
    xtitle("Income (Constant Dollars)") ///
    graphregion(color(white)) ///
    name(h_income, replace)
graph export "output/hist_income.png", replace width(1200)

hist hrs1, normal freq color(navy%70) ///
    title("Distribution of Hours Worked Last Week", size(medlarge)) ///
    xtitle("Hours Worked") ///
    graphregion(color(white)) ///
    name(h_hrs, replace)
graph export "output/hist_hours.png", replace width(1200)

hist age, normal freq color(navy%70) ///
    title("Distribution of Age", size(medlarge)) ///
    xtitle("Age (Years)") ///
    graphregion(color(white)) ///
    name(h_age, replace)
graph export "output/hist_age.png", replace width(1200)

hist educ, normal freq color(navy%70) ///
    title("Distribution of Years of Education", size(medlarge)) ///
    xtitle("Years of Education") ///
    graphregion(color(white)) ///
    name(h_educ, replace)
graph export "output/hist_educ.png", replace width(1200)

twoway ///
    (hist lmoe_score if white_collar == 0, color("25 65 110"%60) bin(20)) ///
    (hist lmoe_score if white_collar == 1, color("180 30 30"%60) bin(20)), ///
    legend(label(1 "Blue-Collar") label(2 "White-Collar") pos(1) ring(0) size(small)) ///
    title("AI Exposure by Collar Type", size(medlarge)) xtitle("LMOE Score") ///
    graphregion(color(white)) ///
    name(h_lmoe_collar, replace)
graph export "output/hist_lmoe_collar.png", replace width(1200)

twoway ///
    (hist task_routine_cog if white_collar == 0, color("25 65 110"%60) bin(20)) ///
    (hist task_routine_cog if white_collar == 1, color("180 30 30"%60) bin(20)), ///
    legend(label(1 "Blue-Collar") label(2 "White-Collar") pos(1) ring(0) size(small)) ///
    title("Routine Cognitive Task Intensity by Collar Type", size(medlarge)) xtitle("Task Index") ///
    graphregion(color(white)) ///
    name(h_rc_collar, replace)
graph export "output/hist_routine_cog_collar.png", replace width(1200)

twoway ///
    (hist degree_automation if white_collar == 0, color("25 65 110"%60) bin(20)) ///
    (hist degree_automation if white_collar == 1, color("180 30 30"%60) bin(20)), ///
    legend(label(1 "Blue-Collar") label(2 "White-Collar") pos(1) ring(0) size(small)) ///
    title("Degree of Automation by Collar Type", size(medlarge)) xtitle("Degree of Automation") ///
    graphregion(color(white)) ///
    name(h_autom_collar, replace)
graph export "output/hist_automation_collar.png", replace width(1200)

graph bar (percent), over(joblose, nolabel) over(white_collar) ///
    bar(1, color("180 30 30")  lcolor(white)) ///
    bar(2, color("220 100 50") lcolor(white)) ///
    bar(3, color("60 130 200") lcolor(white)) ///
    bar(4, color("25 65 110")  lcolor(white)) ///
    title("Job Loss Risk by Collar Type", size(medlarge)) ///
    ytitle("Percent") ///
    legend(label(1 "Very Likely") label(2 "Fairly Likely") ///
        label(3 "Not Too Likely") label(4 "Not Likely") ///
        rows(1) pos(6) size(small)) ///
    graphregion(color(white)) ///
    asyvars showyvars ///
    name(bar_joblose_collar, replace)
graph export "output/bar_joblose_collar.png", replace width(1400)

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
ttest conrinc,             by(white_collar)
ttest hrs1,                by(white_collar)
ttest prestg10,            by(white_collar)
ttest joblose,             by(white_collar)
ttest jobfind,             by(white_collar)
ttest satjob,              by(white_collar)

ttest joblose if inlist(year, 2022, 2024), by(year)
ttest jobfind if inlist(year, 2022, 2024), by(year)
ttest satjob  if inlist(year, 2022, 2024), by(year)

ttest joblose if inlist(year, 2022, 2024) & white_collar == 0, by(year)
ttest joblose if inlist(year, 2022, 2024) & white_collar == 1, by(year)

graph bar (percent), over(joblose, nolabel) over(year) ///
    bar(1, color("180 30 30")  lcolor(white)) ///
    bar(2, color("220 100 50") lcolor(white)) ///
    bar(3, color("60 130 200") lcolor(white)) ///
    bar(4, color("25 65 110")  lcolor(white)) ///
    title("Job Loss Risk by Year (2022 vs 2024)", size(medlarge)) ///
    ytitle("Percent") ///
    legend(label(1 "Very Likely") label(2 "Fairly Likely") ///
        label(3 "Not Too Likely") label(4 "Not Likely") ///
        rows(1) pos(6) size(small)) ///
    graphregion(color(white)) ///
    asyvars showyvars ///
    name(bar_joblose_year, replace)
graph export "output/bar_joblose_year.png", replace width(1400)

log close
