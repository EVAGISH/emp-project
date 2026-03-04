cd "/Users/eashan.vagish/Documents/econ3120/empproj"
log using "output/gss_vars_check.log", replace text

use "gss/2021/GSS2021.dta", clear
di "=== 2021: key vars ==="
foreach v in aiworry intskill joblose jobfind unemp satjob compuse union union1 wrkslf degree marital indus10 webmob class rincome realrinc {
    capture confirm var `v'
    if !_rc {
        di "`v': YES"
    }
    else {
        di "`v': NO"
    }
}

use "gss/2022/GSS2022.dta", clear
di "=== 2022: key vars ==="
foreach v in aiworry intskill joblose jobfind unemp satjob compuse union union1 wrkslf degree marital indus10 webmob class rincome realrinc {
    capture confirm var `v'
    if !_rc {
        di "`v': YES"
    }
    else {
        di "`v': NO"
    }
}

use "gss/2024/GSS2024.dta", clear
di "=== 2024: key vars ==="
foreach v in aiworry intskill joblose jobfind unemp satjob compuse union union1 wrkslf degree marital indus10 webmob class rincome realrinc {
    capture confirm var `v'
    if !_rc {
        di "`v': YES"
    }
    else {
        di "`v': NO"
    }
}

log close
