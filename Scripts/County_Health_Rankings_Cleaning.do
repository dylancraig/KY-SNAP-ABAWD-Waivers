// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/County_Health_Rankings_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: County_Health_Rankings_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean County Health Rankings & Roadmaps data.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: County_Health_Rankings_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean County Health Rankings & Roadmaps data."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder    "$base_path/Raw_Data/County_Health_Rankings_Roadmaps_Data"
local output_folder "$base_path/Data_Outputs/County_Health_Rankings_Roadmaps_Data"
local files : dir "`raw_folder'" files "*.xls*"

// ------------------------ Step 2: Process Excel Files -------------
tempfile master
clear
save `master', emptyok replace

foreach file of local files {
    di "Processing file: `file'"
    local filepath "`raw_folder'/`file'"

    // Extract year from filename
    local year = ""
    if regexm("`file'", "([0-9]{4})") {
        local year = regexs(1)
    }
    else {
        di "Skipping file `file' - year not found in filename."
        continue
    }

    // Import sheet
    capture import excel "`filepath'", sheet("Additional Measure Data") cellrange(A2) firstrow clear
    if _rc {
        di "Error importing file: `file'. Skipping."
        continue
    }

    // Add year column
    gen Year = "`year'"

    // Force string consistency
    ds
    foreach var of varlist `r(varlist)' {
        tostring `var', replace force
    }

    // Append to master
    append using `master', force
    save `master', replace
}

use `master', clear
di "All files successfully processed and appended."

// ------------------------ Step 3: Clean and Format ----------------
destring Population, replace
gen Ann_RuralPop = RuralResidents
replace Ann_RuralPop = Rural if missing(Ann_RuralPop)
replace Ann_RuralPop = ruralresidents if missing(Ann_RuralPop)
destring Ann_RuralPop, replace

gen Ann_RuralPopPerc = (Ann_RuralPop / Population) * 100 if Population > 0
replace Ann_RuralPopPerc = . if Population <= 0 | missing(Population)

gen Ann_FoodInsecurePerc = .
destring DK CM CO AK AB AQ Year, replace

replace Ann_FoodInsecurePerc = DK if Year == 2024
replace Ann_FoodInsecurePerc = CM if inlist(Year, 2020, 2021, 2023)
replace Ann_FoodInsecurePerc = CO if Year == 2022
replace Ann_FoodInsecurePerc = AK if Year == 2018
replace Ann_FoodInsecurePerc = AB if Year == 2017
replace Ann_FoodInsecurePerc = AQ if Year == 2019

label variable Ann_RuralPopPerc "Annual Percent Rural Population"
label variable Ann_FoodInsecurePerc "Annual Percent Food Insecure"

// Keep relevant vars
keep County Year Population Ann_RuralPopPerc Ann_FoodInsecurePerc

rename County COUNTY
replace COUNTY = upper(trim(COUNTY))
drop if COUNTY == ""
label variable COUNTY "County Name"

// ------------------------ Step 4: Expand to Monthly ---------------
gen Month = .
expand 12
bysort COUNTY Year (Month): replace Month = _n

gen MonthFormatted = string(Month, "%02.0f")
drop Month
rename MonthFormatted Month

sort COUNTY Year Month
order COUNTY Year Month Ann_FoodInsecurePerc Ann_RuralPopPerc Population

destring Year, replace
destring Month, replace
replace COUNTY = proper(lower(COUNTY))

// ------------------------ Step 5: Save Cleaned Data ---------------
save "`output_folder'/Cleaned_FoodInsecurity_Data.dta", replace
di "County Health Rankings data successfully cleaned and saved."

// Close log
log close

// Export log to PDF
translate "`log_path'" "$base_path/Log_Files/County_Health_Rankings_Cleaning.pdf", replace
