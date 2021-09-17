# mu_maker
this repo converts tecan plate reader output from raw excel time series to treatment specific mus. ideally one would clone this repo locally, start a new Rstudio project using that cloned directory, load renv file to get the exact dependency environment i've used, and then run the script with your own set of raw files.

## required inputs
1. raw tecan excel files (see example in test_data_input/). these files should have a bunch of header data, then a line for wells followed by mean well RFU values then by well stdev values. Only the excel files you want to analyze should be in the folder and they should have the same name except for the last bit before the filename suffix, which should be the timepoint (again, see example in test_data_input/). 
2. well map file. this is an excel file you produce where the first column is the well_id (e.g. A1, A2, etc.), and subsequent columns are vectors of names for each well for that plate. These should be unique treatment_replicate strings (e.g. "treatment_replicate", like "CONTROL_1" or "LOWPHOS_2", etc.). The names of each of these columns should be the timepoint in decimal days ("0", "1", "2", "2.7", "4", etc.) They don't have to start at zero but they should be in order and correspond to the raw excel files you're attempting to analyze. See test_data_input/ for examples. 

## usage
1. at the terminal/command line, clone this repo into local directory of your choosing: `git clone https://github.com/bishopia/mu_maker.git`.
2. add folder of input files into local clone. maker this folder contains both of the required input files listed above.
3. open Rstudio
4. If you haven't already, install renv (`install.packages(renv)`).
5. Go to top right corner of Rstudio and click start new project environment. Choose existing directory and select the cloned directory you just downloaded in the first step.
6. once the new project is loaded, run the following to load up the proper and contained dependency environment: `renv::restore()`. Click yes or y twice to get that set up.
7. Confirm at the console that you are in the correct working directory: `getwd()`. You should be in the cloned repo and not in the subdirectory with your input files.
8. navigate to the repo scripts subdirectory and open the most recent R script.
9. fill out manual entry section at top of the script.
10. run script
11. ouput should include two csv dataframes, one with blank-corrected log RFUs for each measurement, and another with mu estimates for each treatment_replicate.
12. output also will contain folder of plots, one per treatment_replicate, showing the corrected log RFU values over time as well as the fitted mu.
13. go to top right corner of Rstudio and close project. 
