library(tidyverse)
library(janitor)
library(googlesheets4)
library(rvest)
library(tigris)

### BEFORE RUNNING THIS FILE, MANUALLY CHANGE *DATE ANNOUNCED* in cases & deaths
### AND MANUALLY CHANGE RANGE in cases & deaths

# enter your email here 
gs4_auth(email = "lsherman@newsobserver.com")

# pull the sheet down to your machine
county_counts <- read_sheet("https://docs.google.com/spreadsheets/d/1uZK6NxHffsoyr8Vkt4aj-RE7JxwnNkqKXCySN2bK8R8/edit#gid=773363602", sheet="NC", skip = 2) %>% 
  select(Case, State, County, State, `Date announced`, `Confirmed by NCDHHS`) %>% # only grabbing columns i need
  clean_names() %>% # reformatting column names
  filter(case > 0) #filtering to only grab cases and not empty rows of data

# count the number of cases per county
sums <- county_counts %>% 
  count(county, state) %>% 
  rename(n_o_cases = "n") %>% 
  select(county, n_o_cases) %>% 
  mutate(n_o_cases = as.numeric(n_o_cases))

# after converting dhhs data to csv, import
dhhs_nums <- read_csv("DHHS county case count 5-29.csv") %>% # change the name of the csv you grab here
  clean_names() %>% 
  rename(dhhs_cases = "cases") %>%
  rename(dhhs_deaths = "deaths")

sum(dhhs_nums$dhhs_cases)

# pulls in all counties so we aren't just pulling from our list and theirs 
all <- fips_codes %>% 
  filter(state == "NC") %>% 
  mutate(county = str_replace(county, " County", ""))

# joins so we also include counties with no cases
allcounties <- right_join(dhhs_nums, all, by = "county") %>% 
  select(county, dhhs_cases, dhhs_deaths)

# join dhhs numbers + no case counties with ours
case_compare <- right_join(sums, allcounties, by = "county") %>% 
  select(-dhhs_deaths) %>% 
  mutate(n_o_cases = str_replace_na(n_o_cases, replacement = "0")) %>% 
  mutate(n_o_cases = as.double(n_o_cases)) %>% 
  mutate(case_difference = n_o_cases - dhhs_cases) %>% 
  arrange(county)
  
# filter for all the cases that we don't have
case_difference <- case_compare %>% 
  filter(case_difference < 0) %>% 
  select(county, case_difference) %>% 
  mutate(case_difference = abs(case_difference))

# create a new row for each case we don't have
#### MANUALLY ADD TODAY'S DATE
case_difference_paste <- case_difference %>% 
  group_by(county) %>%
  complete(case_difference = full_seq(1:case_difference, 1)) %>% 
  select(county) %>% 
  mutate(date_announced = "5/29/2020") %>% 
  mutate(source_of_announcement = "DHHS") %>% 
  mutate(confirmed = "Yes")

# grab the spreadsheet so you can write to it
cases <- gs4_get("https://docs.google.com/spreadsheets/d/1uZK6NxHffsoyr8Vkt4aj-RE7JxwnNkqKXCySN2bK8R8/edit#gid=773363602")

#### VERY IMPORTANT. BEFORE YOU RUN THIS, CHANGE THE RANGE 
cases %>%
  range_write(case_difference_paste, sheet = "NC", col_names = F, range = "C25769")

# import deaths spreadsheet
deaths <- read_sheet("https://docs.google.com/spreadsheets/d/1uZK6NxHffsoyr8Vkt4aj-RE7JxwnNkqKXCySN2bK8R8/edit#gid=773363602", sheet="NC Deaths") %>% 
  clean_names() %>% 
  select(case, name, county, date_announced, source, dhhs_confirmed, notes)

# count deaths by county
death_sum <- deaths %>% 
  count(county) %>% 
  rename(n_o_count = "n")

# compare our death count to dhhs
death_compare <- right_join(death_sum, allcounties, by = "county") %>% 
  select(county, dhhs_deaths, n_o_count) %>% 
  mutate(dhhs_deaths = str_replace_na(dhhs_deaths, replacement = "0")) %>% 
  mutate(n_o_count = str_replace_na(n_o_count, replace = "0")) %>% 
  mutate(dhhs_deaths = as.double(dhhs_deaths)) %>% 
  mutate(n_o_count = as.double(n_o_count)) %>% 
  mutate(death_diff = n_o_count - dhhs_deaths)

# filter for cases we're missing 
deaths_difference <- death_compare %>% 
  filter(death_diff < 0) %>% 
  mutate(death_diff = abs(death_diff))

# create new row for each case we don't have
#### MANUALLY ADD TODAY'S DATE
death_diff_compare <- deaths_difference %>% 
  group_by(county) %>%
  complete(death_diff = full_seq(1:death_diff, 1)) %>% 
  select(county) %>% 
  mutate(date_announced = "5/29/2020") %>% 
  mutate(source_of_announcement = "DHHS")

#### VERY IMPORTANT. BEFORE YOU RUN THIS, CHANGE THE RANGE 
cases %>%
  range_write(death_diff_compare, sheet = "NC Deaths", col_names = F, range = "C870")