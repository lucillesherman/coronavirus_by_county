library(tidyverse)
library(pdftools)
library(googlesheets4)

# DR enter your email here 
gs4_auth(email = "draynor@newsobserver.com")

# DR pull the sheet down to your machine
dhhs_daily <- read_sheet("https://docs.google.com/spreadsheets/d/1yPEiMwTWV2lawwxaCU9GjAqoNmuXicGdBX0BHNuQE2c/edit#gid=1018303427", sheet="DHHS by day by county") %>% 
  
# change name
county_counts <- pdf_text("DHHS county case count 6-15.pdf") %>% 
  readr::read_lines()

df <- county_counts[c(4:48, 63:106, 115:125)] %>%
  str_squish() %>% 
  str_replace("New Hanover", "NewHanover") %>% 
  str_replace_all(",", "") %>% 
  strsplit(split = " ")

clean_df <- as.data.frame(do.call(rbind, df))

clean_df <- clean_df %>% 
  rename(county = "V1") %>% 
  rename(cases = "V2") %>% 
  rename(deaths = "V3") %>% 
  mutate(county = str_replace(county, "NewHanover", "New Hanover"))

# DR add date column with today's date
clean_df$date <- "6/15/2020"

# change date
write_csv(clean_df, "DHHS county case count 6-15.csv")

# DR grab the spreadsheet so you can write to it
daily_cases <- gs4_get("https://docs.google.com/spreadsheets/d/1yPEiMwTWV2lawwxaCU9GjAqoNmuXicGdBX0BHNuQE2c/edit#gid=1018303427")

# DR append to google sheet
daily_cases %>%
  range_write(clean_df, sheet = "DHHS by day by county", col_names = F, range = "A5789")
