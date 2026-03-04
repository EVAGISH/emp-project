import delimited "onet/Work Activities.txt", delimiter(tab) varnames(nonames) clear
drop in 1
rename v1 soc_raw
rename v2 element_id
rename v4 scale_id
rename v5 data_value
destring data_value, replace force
keep if scale_id == "IM"
gen soc_code = substr(soc_raw, 1, 7)

gen wc  = data_value if element_id == "4.A.3.b.1"
gen rc  = data_value if inlist(element_id, "4.A.2.a.2", "4.A.3.b.6", "4.A.4.c.1", "4.A.1.b.1")
gen nrc = data_value if inlist(element_id, "4.A.2.a.4", "4.A.2.b.1", "4.A.2.b.2", "4.A.2.b.3")
gen ip  = data_value if inlist(element_id, "4.A.4.a.4", "4.A.4.a.8", "4.A.4.b.3")
gen mn  = data_value if inlist(element_id, "4.A.3.a.1", "4.A.3.a.2", "4.A.3.a.3")

collapse (mean) working_w_computers=wc task_routine_cog=rc task_nrc_analytic=nrc ///
    task_interpersonal=ip task_manual=mn, by(soc_code)
tempfile onet_wa
save `onet_wa'

import delimited "onet/Work Context.txt", delimiter(tab) varnames(nonames) clear
drop in 1
rename v1 soc_raw
rename v2 element_id
rename v4 scale_id
rename v6 data_value
destring data_value, replace force
keep if scale_id == "CX"
gen soc_code = substr(soc_raw, 1, 7)

gen da  = data_value if element_id == "4.C.3.b.2"
gen rt  = data_value if element_id == "4.C.3.b.7"
gen em  = data_value if element_id == "4.C.1.a.2.h"
gen sit = data_value if element_id == "4.C.2.d.1.a"
gen tp  = data_value if element_id == "4.C.3.d.1"
gen ic  = data_value if element_id == "4.C.2.a.1.a"

collapse (mean) degree_automation=da repeat_tasks=rt email_use=em ///
    time_sitting=sit time_pressure=tp indoors_controlled=ic, by(soc_code)
tempfile onet_wc
save `onet_wc'

import delimited "onet/Skills.txt", delimiter(tab) varnames(nonames) clear
drop in 1
rename v1 soc_raw
rename v2 element_id
rename v4 scale_id
rename v5 data_value
destring data_value, replace force
keep if scale_id == "IM"
gen soc_code = substr(soc_raw, 1, 7)

gen cog = data_value if inlist(element_id, "2.A.1.a", "2.A.1.c", "2.A.2.a", "2.A.1.e")
gen ssk = data_value if inlist(element_id, "2.B.1.a", "2.B.1.b", "2.B.1.c", "2.B.1.d", "2.B.1.e", "2.B.1.f")
gen tch = data_value if inlist(element_id, "2.B.3.b", "2.B.3.e")

collapse (mean) skill_cognitive=cog skill_social=ssk skill_tech=tch, by(soc_code)
tempfile onet_sk
save `onet_sk'

import delimited "onet/Knowledge.txt", delimiter(tab) varnames(nonames) clear
drop in 1
rename v1 soc_raw
rename v2 element_id
rename v4 scale_id
rename v5 data_value
destring data_value, replace force
keep if scale_id == "IM"
gen soc_code = substr(soc_raw, 1, 7)

gen kc = data_value if element_id == "2.C.3.a"
gen km = data_value if element_id == "2.C.4.a"
gen ke = data_value if element_id == "2.C.7.a"

collapse (mean) knowledge_computers=kc knowledge_math=km knowledge_english=ke, by(soc_code)
tempfile onet_kn
save `onet_kn'

import delimited "onet/Job Zones.txt", delimiter(tab) varnames(nonames) clear
drop in 1
rename v1 soc_raw
rename v2 job_zone
destring job_zone, replace force
gen soc_code = substr(soc_raw, 1, 7)
collapse (mean) job_zone, by(soc_code)

merge 1:1 soc_code using `onet_wa', nogenerate
merge 1:1 soc_code using `onet_wc', nogenerate
merge 1:1 soc_code using `onet_sk', nogenerate
merge 1:1 soc_code using `onet_kn', nogenerate

save "output/onet_occ.dta", replace
