/***************************************************
PROJECT: KY_SNAP_ABAWD_Waivers
FILE NAME: Master_Script.do
AUTHOR: Dylan Craig
DATE CREATED: November 26, 2024

PURPOSE:
- Run all data cleaning scripts, then run Data_Cleaning.do, then Data_Analysis.do.
- Use a single global (base_path) as the project root.

ASSUMPTIONS:
- These subfolders exist under <base_path>:
    Raw Data\
    Data Outputs\
    Log Files\
    Scripts\
***************************************************/

/*------------------------ Step 0: Reset --------------------------*/
capture log close
set more off

/*------------------------ Step 1: Set project root --------------------------*/
/* Set this to the project folder itself based on location of KY_SNAP_ABAWD_Waivers */
global base_path ""

di as txt "Starting Master Script Execution..."
di as txt "Project root: $base_path"

/*------------------------ Step 2: Run Data Cleaning Scripts -----------------*/
/* Cleaning for each dataset */
di as txt "Running individual data cleaning scripts..."

do "$base_path/Scripts/ACS_Education_Cleaning.do"
do "$base_path/Scripts/ACS_Population_Cleaning.do"
do "$base_path/Scripts/ACS_Poverty_Cleaning.do"
do "$base_path/Scripts/ACS_Race_Cleaning.do"

do "$base_path/Scripts/Census_Bureau_Population_Cleaning.do"
do "$base_path/Scripts/County_Health_Rankings_Cleaning.do"
do "$base_path/Scripts/Kentucky_County_ABAWD_Cleaning.do"
do "$base_path/Scripts/Kentucky_Waiver_Status_Cleaning.do"
do "$base_path/Scripts/LAUS_County_Cleaning.do"
do "$base_path/Scripts/QCEW_County_Cleaning.do"

di as result "All individual data cleaning scripts completed."

/*------------------------ Step 3: Data Cleaning -----------------------------*/
/* Consolidated cleaning and merging */
di as txt "Running Data_Cleaning.do..."
do "$base_path/Scripts/Data_Cleaning.do"
di as result "Data_Cleaning.do completed."

/*------------------------ Step 4: Data Analysis -----------------------------*/
/* Analysis and visualization */
di as txt "Running Data_Analysis.do..."
do "$base_path/Scripts/Data_Analysis.do"
di as result "Data_Analysis.do completed."

/*------------------------ Step 5: Finish -----------------------------------*/
di as result "Master Script Execution Completed!"
