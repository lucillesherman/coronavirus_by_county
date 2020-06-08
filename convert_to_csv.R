library(tidyverse)
library(pdftools)

county_counts <- pdf_text("DHHS county case count 6-7.pdf") %>% 
  readr::read_lines()
df <- county_counts[c(4:48, 63:106, 115:125)] %>% 
  str_squish() %>%
  str_replace_all(",", "") %>% 
  strsplit(split = " ")

clean_df <- as.data.frame(do.call(rbind, df)) %>% 
  select(-V4) 

clean_df <- clean_df %>% 
  rename(county = "V1") %>% 
  rename(cases = "V2") %>% 
  rename(deaths = "V3")

     