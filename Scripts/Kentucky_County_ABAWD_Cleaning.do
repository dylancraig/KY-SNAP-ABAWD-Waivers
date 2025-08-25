// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/Kentucky_County_ABAWD_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: Kentucky_County_ABAWD_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean Kentucky County ABAWD data from Excel files.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: Kentucky_County_ABAWD_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean Kentucky County ABAWD data from Excel files."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
clear all
local raw_folder "$base_path/Raw_Data/Kentucky_County_ABAWD_Data"
local files : dir "`raw_folder'" files "*.xlsx"

// ------------------------ Step 2: Read and Process Excel Files -----
foreach file of local files {
    di "Processing file: `file'"
    local filepath "`raw_folder'/`file'"

    // Extract month and year from filename
    local month = word("`file'", 1)
    local year  = substr("`file'", strpos("`file'", " ") + 1, 4)
    di "Extracted Month: `month', Year: `year'"

    // Determine header row
    if inlist(`year', 2017, 2021) {
        local row 10
    }
    else if inlist(`year', 2018, 2019, 2020, 2022, 2023, 2024) {
        local row 11
    }
    else {
        di "Skipping file `file' - year not in expected range."
        continue
    }

    // Import data
    import excel "`filepath'", sheet("KY_HBE_SNAPWorkRegistrantsandAB") cellrange(A`row') firstrow clear

    // Force variables to string for consistency
    ds
    foreach var of varlist `r(varlist)' {
        tostring `var', replace force
    }

    // Add Year and Month
    gen Year = "`year'"
    gen Month = "`month'"

    // Save intermediate .dta
    local savename = subinstr("`file'", ".xlsx", "", .)
    save "`raw_folder'/`savename'.dta", replace
    di "Processed `file'"
}

// ------------------------ Step 3: Combine All .dta Files ----------
local dtafiles : dir "`raw_folder'" files "*.dta"
clear
foreach file of local dtafiles {
    di "Appending file: `file'"
    append using "`raw_folder'/`file'", force
}

// ------------------------ Step 4: Format Variables ----------------
replace Month = lower(Month)
replace Month = "01" if Month == "january"
replace Month = "02" if Month == "february"
replace Month = "03" if Month == "march"
replace Month = "04" if Month == "april"
replace Month = "05" if Month == "may"
replace Month = "06" if Month == "june"
replace Month = "07" if Month == "july"
replace Month = "08" if Month == "august"
replace Month = "09" if Month == "september"
replace Month = "10" if Month == "october"
replace Month = "11" if Month == "november"
replace Month = "12" if Month == "december"

destring Month, replace force
destring Year, replace

// Destring numeric vars except COUNTY and REGION
ds
foreach var of varlist `r(varlist)' {
    if !inlist("`var'", "COUNTY", "REGION", "Month", "Year") {
        destring `var', replace force
    }
}

sort COUNTY Year Month
order COUNTY REGION Year Month

// ------------------------ Step 5: Standardize Variables -----------
gen Mnthly_WorkReg_16_59 = WORKREGISTERED16TO59
replace Mnthly_WorkReg_16_59 = WORKREG16TO59 if missing(Mnthly_WorkReg_16_59)
label variable Mnthly_WorkReg_16_59 "Monthly work-registered individuals aged 16-59"
drop WORKREGISTERED16TO59 WORKREG16TO59

rename ACTIVESNAP18TO49 Mnthly_ActiveSNAP_18_49
label variable Mnthly_ActiveSNAP_18_49 "Monthly active SNAP participants aged 18-49"

rename WORKREGISTERED18TO49 Mnthly_WorkReg_18_49
label variable Mnthly_WorkReg_18_49 "Monthly work-registered individuals aged 18-49"

rename WORKINGMORETHAN80HRS Mnthly_Working80Hrs
label variable Mnthly_Working80Hrs "Individuals working > 80 hrs/month"

rename DEPENDENTCHILD Mnthly_Dep_Child
label variable Mnthly_Dep_Child "Monthly dependent children count"

rename PREGNANCY Mnthly_Pregnancy
label variable Mnthly_Pregnancy "Monthly pregnancy status count"

rename WEPVES Mnthly_WEPVES
label variable Mnthly_WEPVES "Monthly WEP/VES participation"

rename ABAWDSNEEDINGTOCOMPLY Mnthly_ABAWD_Comply
label variable Mnthly_ABAWD_Comply "Monthly ABAWDs needing to comply with work reqs"

rename STLPARTICIPANTS Mnthly_STLP
label variable Mnthly_STLP "Monthly STLP participants count"

rename ACTIVESNAP18TO52 Mnthly_ActiveSNAP_18_52
label variable Mnthly_ActiveSNAP_18_52 "Monthly active SNAP participants aged 18-52"

rename WORKREGISTERED18TO52 Mnthly_WorkReg_18_52
label variable Mnthly_WorkReg_18_52 "Monthly work-registered individuals aged 18-52"

rename VETERAN Mnthly_Veteran
label variable Mnthly_Veteran "Monthly veteran status individuals count"

rename HOMELESS Mnthly_Homeless
label variable Mnthly_Homeless "Monthly homeless status individuals count"

rename FOSTERCARE Mnthly_FosterCare
label variable Mnthly_FosterCare "Monthly foster care status individuals count"

rename ACTIVESNAP18TO54 Mnthly_ActiveSNAP_18_54
label variable Mnthly_ActiveSNAP_18_54 "Monthly active SNAP participants aged 18-54"

rename WORKREGISTERED18TO54 Mnthly_WorkReg_18_54
label variable Mnthly_WorkReg_18_54 "Monthly work-registered individuals aged 18-54"

// ------------------------ Step 6: Clean Identifiers ----------------
replace COUNTY = proper(lower(trim(COUNTY)))
replace REGION = proper(lower(trim(REGION)))
drop if trim(COUNTY) == ""

// ------------------------ Step 7: Save Final Dataset ---------------
save "$base_path/Data_Outputs/Kentucky_County_ABAWD_Data/Cleaned_ABAWD_Data.dta", replace
di "Kentucky County ABAWD data successfully processed and saved."

// Close log
log close

// Export log to PDF
translate "`log_path'" "$base_path/Log_Files/Kentucky_County_ABAWD_Cleaning.pdf", replace
