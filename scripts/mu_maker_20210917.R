#script to transform plate reader xlsx files to structured dataframe, estimate mu, plot and export data

#ian bishop
#17 Sept 2021

###---import libraries
library(tidyverse)
library(lubridate)
library(readxl)
library(writexl)
library(zoo)

########################
###---Manual Input---###
########################

#name of well translation datasheet: which well corresponds to which culture/strain/treatment
well_map_dir <- "./test_data_input"
well_map_filename <- "well_map.xlsx"
well_map_path <- paste(well_map_dir, "/", well_map_filename, sep="")

#path to plate reader excel files
plate_reader_file_path <- "./test_data_input"

#define how many adjacent points to fit moving lm window to
moving_window_point_number <- 3

#define matrix header column line
#e.g. if "Well    A1    A2   A3    etc is in line 54, assign 54 as value here
matrix_header_line <- 54



##########################################################
###---Convert raw fluorescence to combined dataframe---###
##########################################################

#make list of files
files <- list.files(path=plate_reader_file_path, pattern="\\d.xlsx$")
files

#vector of well
well_map <- read_excel(well_map_path)

#initialize cumulative data frame
cumulative_df <- NA

#run loop to excise well label and mean RFU values, as well as blank information
for (k in 1:length(files)) {

  #grab file from list
  file <- files[k]
  
  #create relative path string for this file
  rel_path <- paste("./test_data_input/", file, sep="")
  
  #blanks
  blank_wells <- well_map[which(well_map[,k+1]=="BLANK"),]$well
  
  #import df
  df <- suppressMessages(read_excel(path=rel_path,  skip = matrix_header_line-2))
  
  #fix imported df
  df <- t(df[1:2,2:ncol(df)])
  df <- data.frame(well=as.character(df[,1]), RFU=round(as.numeric(df[,2])))
  
  #mean blank value
  blank_mean <- mean(df[df$well %in% blank_wells,]$RFU)
  
  #subtract blank_mean from other values; start with all wells, drop irrelevant wells later
  df$RFU_blanked <- round(df$RFU - blank_mean)
  
  #day factor
  df$day <- as.numeric(names(well_map)[k+1])
  
  #add well ID; rename
  df2 <- df %>% left_join(well_map[,c(1,k+1)])
  names(df2)[ncol(df2)] <- "id"
  
  #add df2 values for this file to cumulative df for all files
  cumulative_df <- rbind(cumulative_df, df2)

}

#drop irrelevant wells
cumulative_df <- cumulative_df[complete.cases(cumulative_df$id),]

#rename columns
names(cumulative_df) <- c("read_well", "RFU_raw", "RFU_blanked", "day", "id")

#remove rows where corrected RFU is less than or equal to 0
# cumulative_df <- cumulative_df %>% filter(RFU_blanked>0)
#remove BLANK rows
cumulative_df <- cumulative_df %>% filter(id!="BLANK")

#add log RFU
cumulative_df <- cumulative_df %>% mutate(logRFU = log(RFU_blanked))

#export dataframe to xlsx
write_xlsx(cumulative_df, "output/corrected_RFU_series.xlsx")



###################################################
###---Calculate rolling window slope estimate---###
###################################################

#cumulative_df<-read.csv(file.choose())

#split df out into list by id
ls <- cumulative_df %>%
  group_by(id) %>%
  filter(n() >= 3) %>%
  # filter(id!="BLANK") %>%
  group_split()

#create new df to write output to
z_out <- data.frame(intercept=NA, mu=NA, rsqr=NA, id=NA)

#define how many adjacent points to fit moving lm window to
k <- moving_window_point_number

#for loop to capture highest slope per id
for (i in seq_along(ls)) {
    
  #select time and var columns from ls element
  z <- ls[[i]] %>% select(day, logRFU)
  
  #calculate linear regressions coefs
  tmp_df1 <- rollapply(z, width = k,
                       function(x) coef(lm(logRFU ~ day, data = as.data.frame(x))),
                       by.column = FALSE, align = "right")
  tmp_df2 <- rollapply(z, width = k,
                       function(x) summary(lm(logRFU ~ day, data = as.data.frame(x)))$r.squared,
                       by.column = FALSE, align = "right")
  
  #create temp df and sort desc by slope
  tmps <- data.frame(intercept = tmp_df1[,1], mu = tmp_df1[,2], rsqr = tmp_df2) %>% arrange(-mu)
  
  #output k point regression with greatest slope, include intercept, rsqred, percent diff from next largest slope, and id
  z_out[i,1:3] <- as.numeric(c(tmps[1,1], tmps[1,2], tmps[1,3]))
  z_out[i,4] <- as.character(unique(ls[[i]]$id))
  
  tmp_df1 <- NULL
  tmp_df2 <- NULL
  tmps <- NULL
  z <- NULL
  
}

#export growth rate estimate dataframe to xlsx
write_xlsx(z_out, paste0("output/gr_estimates_k", k, ".xlsx"))

# create plot object
plots_wLines <- cumulative_df %>%
  left_join(z_out[,c("id", "mu", "intercept")], by="id") %>%
  group_by(id) %>%
  nest() %>%
  mutate(plot = map(data,  ~ ggplot(., aes(x = day, y = logRFU)) + ggtitle(id) + ylab("ln(RFU)") + geom_point() + geom_abline(aes(intercept=intercept, slope=mu))),
         filename=paste0(id, ".tiff")) %>%
  ungroup() %>%
  select(filename, plot)

#create plot directory
suppressWarnings(dir.create(paste0("output/plots_wLines_k", k)))

#create plots
# pwalk(plots_wLines, ggsave, path =  paste0("output/plots_wLines_k", k))
