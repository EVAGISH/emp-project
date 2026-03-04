cd "/Users/eashan.vagish/Documents/econ3120/empproj"
log using "gss_describe.log", replace text

di "===== GSS 2024 FULL VARIABLE LIST ====="
use "gss/2024/GSS2024.dta", clear
describe

log close
