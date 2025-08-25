// Define log file path
local log_path "$base_path/Log_Files/QCEW_County_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: QCEW_County_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean QCEW county-level employment and wages data.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: QCEW_County_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean QCEW county-level employment and wages data."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder    "$base_path/Raw_Data/QCEW_County_Data"
local file          "Employment and Wages by Industry.xlsx"
local output_folder "$base_path/Data_Outputs/QCEW_County_Data"

// ------------------------ Step 2: Import Excel File ----------------
di "Processing: `file'"
local filepath "`raw_folder'/`file'"
import excel "`filepath'", sheet("WEEKLY WAGES") firstrow clear

// ------------------------ Step 3: Keep Necessary Variables ---------
keep Area Year Quarter AllIndustries

// ------------------------ Step 4: Drop Observations ----------------
di "Dropping observations where Year is less than 2017."
drop if Year < 2017
drop in 1/319

// ------------------------ Step 5: Expand Quarter to Months ---------
expand 3
sort Area Year Quarter
gen Month = ""
bysort Area Year (Quarter): replace Month = "01" if Quarter == 1 & mod(_n,3)==1
bysort Area Year (Quarter): replace Month = "02" if Quarter == 1 & mod(_n,3)==2
bysort Area Year (Quarter): replace Month = "03" if Quarter == 1 & mod(_n,3)==0
bysort Area Year (Quarter): replace Month = "04" if Quarter == 2 & mod(_n,3)==1
bysort Area Year (Quarter): replace Month = "05" if Quarter == 2 & mod(_n,3)==2
bysort Area Year (Quarter): replace Month = "06" if Quarter == 2 & mod(_n,3)==0
bysort Area Year (Quarter): replace Month = "07" if Quarter == 3 & mod(_n,3)==1
bysort Area Year (Quarter): replace Month = "08" if Quarter == 3 & mod(_n,3)==2
bysort Area Year (Quarter): replace Month = "09" if Quarter == 3 & mod(_n,3)==0
bysort Area Year (Quarter): replace Month = "10" if Quarter == 4 & mod(_n,3)==1
bysort Area Year (Quarter): replace Month = "11" if Quarter == 4 & mod(_n,3)==2
bysort Area Year (Quarter): replace Month = "12" if Quarter == 4 & mod(_n,3)==0
drop Quarter

// ------------------------ Step 6: Final Adjustments ----------------
order Area Year Month AllIndustries
rename AllIndustries Quart_Wkly_Wage
rename Area COUNTY
label variable Quart_Wkly_Wage "Quarterly Median Weekly Wage for All Industries"
destring Month, replace
destring Year, replace
replace COUNTY = proper(lower(COUNTY))

// ------------------------ Step 7: Save Final Dataset ----------------
save "`output_folder'/Cleaned_QCEW_Data.dta", replace
di "Final dataset successfully saved to `output_folder'."

// Close the log
log close

// Convert .log to .pdf
translate "`log_path'" "$base_path/Log_Files/QCEW_County_Cleaning.pdf", replace
