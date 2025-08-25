# KY-SNAP-ABAWD-Waivers

This project builds a **county–year–month** panel (2017–2024) to study **SNAP Able-Bodied Adults Without Dependents (ABAWD)** work requirement waivers in Kentucky.  
Processing is done in **Stata** (cleaning → merge → analysis) with optional **R** for visualizations.

---

## 📂 Project Structure
- `Raw_Data/` – Source datasets (ACS, Census Bureau, BLS LAUS/QCEW, County Health Rankings, CHFS, Waiver status)
- `Scripts/` – Stata `.do` files and `Data_Visualization.R`
- `Data_Outputs/` – Cleaned datasets, merged panel, collapsed outputs
- `Log_Files/` – Logs and exported PDFs
- `Visualizations/` – Regression tables, plots, and maps
- `Docs/` – Reports and supporting documentation

---

## ⚙️ Workflow Overview
1. **Cleaning scripts** (`*_Cleaning.do`) process each dataset, standardize keys, and expand annual values to monthly where needed.  
2. **Merge**: `Data_Cleaning.do` combines all cleaned files into `Final_Cleaned_Data.dta`.  
3. **Analysis**: `Data_Analysis.do` runs regressions, summary tables, and produces a collapsed dataset.  
4. **Visualization**: `Data_Visualization.R` generates maps and time-trend plots.

---

## 🚀 Running the Project
There are **two main entry points**:

### 1. Stata
- Open `Scripts/Master_Script.do`
- **Edit the global at the top** to point to the project folder  
  *(e.g., `C:/Users/Name/Documents/KY-SNAP-ABAWD-Waivers/`)*
- Run it → executes all cleaners, merges, and analysis  
- Outputs:
  - `Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta`
  - `Data_Outputs/Final_Collapsed_Data/Collapsed_Waiver_Status_Data.dta`
  - Regression tables in `Visualizations/`

### 2. R
- Open `Scripts/Data_Visualization.R`
- **Edit the global at the top** to point to the project folder  
- Run it → generates maps and plots using the Stata outputs

---

## 🧾 Key Scripts
- `Master_Script.do` → Main driver (runs everything in Stata)
- `Data_Cleaning.do` → Merges all cleaned datasets
- `Data_Analysis.do` → Summary statistics, regressions, collapsed file
- `Data_Visualization.R` → Optional R visuals
- `*_Cleaning.do` → One for each raw dataset (ACS, Census, LAUS, QCEW, CHFS, Waiver status, County Health Rankings)

---

## ✅ Quick Check
After running:
- `Final_Cleaned_Data.dta` should exist in `Data_Outputs/Final_Cleaned_Data/`
- `Collapsed_Waiver_Status_Data.dta` should exist in `Data_Outputs/Final_Collapsed_Data/`
- Logs should be in `Log_Files/`
- Visuals (tables/plots) should be in `Visualizations/`
