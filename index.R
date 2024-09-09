library(tidyverse)
library(aider)
library(readxl)

options(scipen = 10)

convert_excel_date_long <- function(date){
  as.Date(date, format = '%d/%m/%Y')
}

remove_comma_function <- function(x){
  str_remove_all(x, ',')
}

euro_rate <- 0.8476

#Load historic AR balance
#load('../../data/data_science_nextgear/outputs/ar_balance_raw_historic.rda')



#Need to create a method for determining the previous month credit limit
# current_month <- floor_date(Sys.Date(), 'month')
# previous_month <- floor_date(current_month -1, 'month')


reference_files_2023_gbp <- c("../../data/data_science_nextgear/ar_balance/historic gdp/LOANPORT-NEXTGEAR_GBP_31.12.23.csv",
                              "../../data/data_science_nextgear/ar_balance/historic gdp/LOANPORT-NEXTGEAR_IRL_GBP_31.12.23.csv")




reference_files_2023_eur <- c("../../data/data_science_nextgear/ar_balance/historic eur/LOANPORT-NEXTGEAR_IRL_EUR_31.12.23.csv")






#################################
#### Customer Reference Data ####
#################################

# Version using amended version
salesforce_files <- file.info(list.files('../../data/data_science_nextgear/active_live_report/all_dealers', full.names = TRUE)) %>% rownames_to_column(var = 'file_name') %>% arrange(desc(mtime)) %>% slice(1)

salesforce_raw <- read_csv(salesforce_files[ 1, 1 ]) %>%
  #Clean up names
  janitor::clean_names()

dealer_sales_reference_data_for_utilisation <- salesforce_raw %>%
  rename(limit = credit_limit,
         limit_currency = credit_limit_currency) %>%
  #change live date format
  mutate(account_live_date = as.Date(account_live_date, format = '%d/%m/%Y')) %>%
  rename(region = pace_region) %>%
  mutate(credit_end_date = convert_excel_date_long(end_date)) %>%
  select(-end_date) %>%
  arrange(wfs_ref, desc(credit_end_date)) %>%
  group_by(wfs_ref) %>%
  mutate(ref = row_number()) %>%
  ungroup() %>%
  filter(ref == 1) %>%
  select(-ref) %>%
  distinct(., .keep_all = TRUE) %>%
  #calculate limit as GDP
  mutate(credit_limit_gbp = case_when(
    limit_currency == "EUR" ~ limit * euro_rate,
    limit_currency == "GBP" ~ limit
  ))

dealer_sales_reference_data_for_utilisation_subset <- 
  dealer_sales_reference_data_for_utilisation %>%
  select(wfs_ref,
         account_name,
         account_owner_full_name,
         account_support_executive_full_name,
         product,
         account_live_date,
         business_address_postcode,
         region,
         capital_repayment_percent)


##########################################
#### Dealer status and credit history ####
##########################################


load('../../data/data_science_nextgear/outputs/daily_dealer_status_and_credit_history.rda')


##########################
#### Utilisation Data ####
##########################


#Same code as used to calculate AR balance
ar_balance_files_gdp <- file.info(list.files('../../data/data_science_nextgear/ar_balance/gdp', full.names = TRUE)) %>% rownames_to_column(var = 'file_name')

ar_balance_files_eur <- file.info(list.files('../../data/data_science_nextgear/ar_balance/eur', full.names = TRUE)) %>% rownames_to_column(var = 'file_name')

extract_ar_balance_files <- function(file){
  
  "../../data/data_science_nextgear/ar_balance/gdp/LOANPORT-NEXTGEAR_GBP_1693782000000_32157.csv"
  
  #Get extraction date
  extraction_date_ <- suppressMessages(suppressWarnings(as.character(read_csv(file)[1,1])))
  
  #Code to correct non-standard dates from source system
  
  extraction_date_ <- str_replace_all(extraction_date_, "Sept", "Sep")
  
  extraction_date_as_date <- case_when(
    nchar(extraction_date_) == 11 ~ 
      as.Date(extraction_date_, format = '%d-%b-%Y'),
    nchar(extraction_date_) == 9 ~ 
      as.Date(extraction_date_, format = '%d-%b-%y'),
    nchar(extraction_date_) == 10 ~ 
      as.Date(extraction_date_, format = '%d-%m-%Y'),
    nchar(extraction_date_) == 8 ~ 
      as.Date(extraction_date_, format = '%d-%m-%y')
    
  )
  
  #Get data
  data <- suppressMessages(suppressWarnings(read_csv(file, skip = 2, 
                                                     guess_max = 70000)))
  
  data %>%
    mutate(#currency = currency_,
      extraction_date = extraction_date_as_date,
      `Loan Reference` = as.character(`Loan Reference`),
      `Dealer Rate Spread` = as.numeric(`Dealer Rate Spread`), 
      #total_outstanding_amount = as.character(`Total Outstanding Amount`),
      #outstanding_utilised_amount = as.character(`Outstanding Utilised Amount`),
      file_name = file)
  
  
}

# #Testing sep 4th 2023 date weirdness
# t <- extract_ar_balance_files( "../../data/data_science_nextgear/ar_balance/gdp/LOANPORT-NEXTGEAR_GBP_1693782000000_32157.csv")
# 
# t %>% count(extraction_date)
# 
# ar_balance_files_eur[,1][1]

#There are a load of files with 0KB size - sorted
#Issue with columns with rare events coming through as NA. Increased guess_max
# extraction_date_ <- suppressMessages(suppressWarnings(as.character(read_csv("../../data/data_science_nextgear/ar_balance/gdp/LOANPORT-NEXTGEAR_GBP_1688079600000_9805.csv")[1,1])))

#b <- extract_ar_balance_files("../../data/data_science_nextgear/ar_balance/gdp/LOANPORT-NEXTGEAR_GBP_1688079600000_9805.csv")

#glimpse(b %>% filter(`Loan Reference` == "719114"))

ar_balance_raw_gdp <- bind_rows(
  lapply(ar_balance_files_gdp[, 1], extract_ar_balance_files)
) %>%
  mutate(currency = "GDP")

ar_balance_raw_eur <- bind_rows(
  lapply(ar_balance_files_eur[, 1], extract_ar_balance_files)
) %>%
  mutate(currency = "EUR")


#Something weird going on with the 2023-09-04 extraction date
#For some reason, it has a different date format to all the others
ar_balance_raw <- bind_rows(
  ar_balance_raw_gdp,
  ar_balance_raw_eur
) %>%
  janitor::clean_names() #%>%
  # mutate(extraction_date = case_when(
  #   is.na(extraction_date) & file_name == "../../data/data_science_nextgear/ar_balance/gdp/LOANPORT-NEXTGEAR_GBP_1693782000000_32157.csv" ~ convert_to_date("2023-09-04"),
  #   TRUE ~ extraction_date
  # ))

#Output AR for latest day

################################################
#### If you want to save out the current data into historic, comment out and run this code (don't forget to move theinput files to the historic folders) ####

#ar_balance_raw_historic <- ar_balance_raw

#save(ar_balance_raw_historic, file = "../../data/data_science_nextgear/outputs/ar_balance_raw_historic.rda", compress = TRUE)

#################################################


cutoff_date <- max_(ar_balance_raw$extraction_date)

#daily_dealer_status_and_credit_history %>% filter(calendar_date == cutoff_date)



latest_ar_balance <- ar_balance_raw %>%
  mutate(acceptance_date = str_replace_all(acceptance_date, "Sept", "Sep"),
         due_date = str_replace_all(due_date, "Sept", "Sep")) %>%
  mutate(dealer_reference = word(dealer_reference, 1, sep = '-'),
         dealer_name = str_remove_all(dealer_name, " - 1"),
         acceptance_date = as.Date(acceptance_date, format = '%d-%b-%Y'),
         due_date = as.Date(due_date, format = '%d-%b-%Y')) %>%
  mutate(ar_balance_non_currency_adjusted = outstanding_utilised_amount + 
           total_outstanding_amount) %>%
  mutate(ar_balance_currency_adjusted = case_when(
    currency == "EUR" ~ ar_balance_non_currency_adjusted * euro_rate,
    currency == "GDP" ~ ar_balance_non_currency_adjusted
  )) %>%
  mutate(live_status_count = if_else(unit_status == "Live", 1, 0)) %>%
  filter(extraction_date == cutoff_date) %>%
  mutate(across(where(is.character), remove_comma_function ))





#### Add in 2023 reference data
#2023 reference files



ar_balance_raw_gbp_2023_reference <- bind_rows(
  lapply(reference_files_2023_gbp, extract_ar_balance_files)
) %>%
  mutate(currency = "GDP")

ar_balance_raw_eur_2023_reference <- bind_rows(
  lapply(reference_files_2023_eur, extract_ar_balance_files)
) %>%
  mutate(currency = "EUR")


#Something weird going on with the 2023-09-04 extraction date
#For some reason, it has a different date format to all the others
ar_balance_raw_2023 <- bind_rows(
  ar_balance_raw_gbp_2023_reference,
  ar_balance_raw_eur_2023_reference
) %>%
  janitor::clean_names()




ar_balance_2023 <- ar_balance_raw_2023 %>%
  mutate(acceptance_date = str_replace_all(acceptance_date, "Sept", "Sep"),
         due_date = str_replace_all(due_date, "Sept", "Sep")) %>%
  mutate(across(where(is.character), remove_comma_function )) %>%
  mutate(dealer_reference = word(dealer_reference, 1, sep = '-'),
         dealer_name = str_remove_all(dealer_name, " - 1"),
         acceptance_date = as.Date(acceptance_date, format = '%d-%b-%Y'),
         due_date = as.Date(due_date, format = '%d-%b-%Y')) %>%
  mutate(ar_balance_non_currency_adjusted = outstanding_utilised_amount + 
           total_outstanding_amount) %>%
  mutate(ar_balance_currency_adjusted = case_when(
    currency == "EUR" ~ ar_balance_non_currency_adjusted * euro_rate,
    currency == "GDP" ~ ar_balance_non_currency_adjusted
  )) %>%
  mutate(live_status_count = if_else(unit_status == "Live", 1, 0))


#Combine 2023 and latest AR balance
ar_latest_with_2023_reference <- bind_rows(
  latest_ar_balance,
  ar_balance_2023
)


write_table(ar_latest_with_2023_reference, '../../data/data_science_nextgear/outputs/latest_ar_balance.csv')

#save(ar_balance_raw, file = '../../data/data_science_nextgear/outputs/ar_balance_raw.rda', compress = TRUE)

#load('../../data/data_science_nextgear/outputs/ar_balance_raw.rda')

#All live customers

#Making sure I'm using all the revenue metrics

# ar_revenue_test <- ar_balance_raw %>%
#   filter(dealer_reference == "D027399-1") %>%
#   filter(extraction_date >= "2023-06-01" & extraction_date <= '2023-07-02')
# 
# a <- ar_balance_raw %>% filter(loan_identification == "WV1ZZZ7HZNH011911")
#ar_revenue_test %>% filter(total_outstanding_amount > 0)


# #Combine historic and current
# ar_historic_and_current <- bind_rows(
#   ar_balance_raw,
#   ar_balance_raw_historic
# )



ar_summary <- ar_balance_raw %>%
  mutate(dealer_reference = word(dealer_reference, 1, sep = '-'),
         dealer_name = str_remove_all(dealer_name, " - 1"),
         acceptance_date = as.Date(acceptance_date, format = '%d-%b-%Y'),
         due_date = as.Date(due_date, format = '%d-%b-%Y')) %>%
  mutate(ar_balance_non_currency_adjusted = outstanding_utilised_amount + 
           total_outstanding_amount) %>%
  mutate(ar_balance_currency_adjusted = case_when(
    currency == "EUR" ~ ar_balance_non_currency_adjusted * euro_rate,
    currency == "GDP" ~ ar_balance_non_currency_adjusted
  )) %>%
  mutate(live_status_count = if_else(unit_status == "Live", 1, 0)) %>%
  arrange(extraction_date, dealer_reference, dealer_name) %>%
  group_by(extraction_date, dealer_reference) %>%
  summarise(number_of_loans = n(),
            number_of_live_loans = sum_(live_status_count),
            ar_balance_non_currency_adjusted = sum_(ar_balance_non_currency_adjusted),
            ar_balance_currency_adjusted = sum_(ar_balance_currency_adjusted)) %>%
  ungroup() %>%
  mutate(across(where(is.character), remove_comma_function ))
  



#Actually, use this as a cut off rather than the file agg part


#ar_summary_historic <- ar_summary

#save(ar_summary_historic, file = '../../data/data_science_nextgear/outputs/ar_summary_historic.rda')


#Combine with historic summary
load('../../data/data_science_nextgear/outputs/ar_summary_historic.rda')

ar_summary_historic_and_current <- bind_rows(
  ar_summary,
  ar_summary_historic
  
)

#ar_summary_historic_and_current <- ar_summary

#ar_summary %>% count(dealer_reference, extraction_date) %>% arrange(-n) %>% slice(1:5)

#save(ar_summary, file = '../../data/data_science_nextgear/outputs/ar_summary.rda', compress = TRUE)

#load('../../data/data_science_nextgear/outputs/ar_summary.rda')
  
#Join ar_summary to live_daily_dealer

utilisation_data <- daily_dealer_status_and_credit_history %>%
  #filter(status_event == "Account live") %>%
  left_join(ar_summary_historic_and_current,
            by = c("calendar_date" = "extraction_date",
                   "dealer_reference" = "dealer_reference")) %>%
  mutate(include = case_when(
    status_event == "Account live" ~ 1,
    ar_balance_currency_adjusted > 0 ~ 1,
    TRUE ~ 0
  )) 

#Want to calculate

utilisation_data %>% filter(calendar_date == '2024-01-31') %>% filter(include == 1) %>% count()


stopifnot(nrow(utilisation_data) == nrow(daily_dealer_status_and_credit_history))

################
#### Output ####
################

#Subset date range
utilisation_extract_start_date <- convert_to_date('2023-07-01')
utilisation_extract_end_date <- Sys.Date()

# product_function <- function(string){
#   
#   case_when(
#     str_sub(string, 1, 1) == "I" ~ "Independent",
#     str_sub(string, 1, 1) == "H" ~ "Highline",
#     str_sub(string, 1, 1) == "M" ~ "Motorbike",
#     str_sub(string, 1, 1) == "F" ~ "Franchise",
#   )
# }



utilisation_data_subset <- utilisation_data %>%
  filter(include == 1) %>%
  select(-include) %>%
  filter(calendar_date >= utilisation_extract_start_date &
           calendar_date < utilisation_extract_end_date) %>%
  #Add the Dealer Reference stuff
  left_join(dealer_sales_reference_data_for_utilisation_subset,
            by = c("dealer_reference" = "wfs_ref"))



write_table(utilisation_data_subset, '../../data/data_science_nextgear/outputs/utilisation_data.csv')
