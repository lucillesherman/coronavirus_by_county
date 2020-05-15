from selenium import webdriver
from bs4 import BeautifulSoup
import requests
import csv

from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait 
from selenium.webdriver.support import expected_conditions as EC 
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.action_chains import ActionChains


option = webdriver.ChromeOptions()
option.add_argument(" - incognito")
browser = webdriver.Chrome(executable_path = "/Users/user/Desktop/nopolitics/coronavirus_counts/chromedriver 2", chrome_options=option)
browser.get("https://covid19.ncdhhs.gov/dashboard#by-counties-map")


results = browser.page_source
soup = BeautifulSoup(results, "html.parser")
table = soup.find_all("table")
countytable = table[3]
print(countytable)
count = 1

output = [["county", "dhhs_cases", "dhhs_deaths"]]

for row in countytable.find_all('tr'):
    list_of_cells = []
    for cell in row.find_all('td'):
        text = cell.text.strip()
        list_of_cells.append(text)
    output.append(list_of_cells)

import datetime
current_date = datetime.datetime.now()
filename = "dhhs_corona"+str(current_date.strftime("%Y-%m-%d%H:%M"))

outfile = open(filename + ".csv", "w")
writer = csv.writer(outfile)
writer.writerows(output)
browser.close()

