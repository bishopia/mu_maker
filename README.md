# mu_maker
converts tecan plate reader output from raw excel time series to treatment specific mus

### usage
1. clone this repo
2. add folder of input files into local clone. maker this folder contains both tecan excel files AND a "treatment map" that specifies which well corresponds to which treatment. they must be unique treatments (e.g. "treatment_replicate", like "CONTROL_1" or "LOWPHOS_2", etc.). See example input data subdirectory for example.
3. open R and open most recent script in script folder
4. set working directory to repo folder, not script folder
5. fill out manual entry section at top of the script.
6. run script
7. ouput should include two csv dataframes, one with blank-corrected log RFUs for each measurement, and another with mu estimates for each treatment_replicate.
8. output also will contain folder of plots, one per treatment_replicate, showing the corrected log RFU values over time as well as the fitted mu.
