log using "output/gss_coverage.log", replace text

use "gss/2024/GSS2024.dta", clear
keep if inlist(wrkstat, 1, 2)
drop if missing(occ10) | occ10 == 0

di "=== 2024 employed sample, N = " _N " ==="
di ""
di "--- OUTCOME / MAIN VARS ---"
foreach v in joblose jobfind satjob aiworry intskill unemp conrinc hrs1 {
    quietly count if !missing(`v')
    di "`v': `r(N)' non-missing out of " _N
}
di ""
di "--- CONTROLS / DEMOGRAPHICS ---"
foreach v in prestg10 age educ degree sex race marital wrkslf compuse webmob indus10 class union union1 realrinc {
    quietly count if !missing(`v')
    di "`v': `r(N)' non-missing out of " _N
}

di ""
di "--- joblose value distribution ---"
tab joblose, missing
di "--- jobfind value distribution ---"
tab jobfind, missing
di "--- satjob value distribution ---"
tab satjob, missing
di "--- aiworry value distribution ---"
tab aiworry, missing
di "--- intskill value distribution ---"
tab intskill, missing
di "--- compuse value distribution ---"
tab compuse, missing
di "--- union value distribution ---"
tab union, missing
di "--- degree value distribution ---"
tab degree, missing
di "--- class value distribution ---"
tab class, missing

log close
