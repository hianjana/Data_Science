#########################################################################################################
# Install all the required packages                     
#########################################################################################################

install.packages("sqldf")
install.packages("lubridate")
install.packages("bizdays")
install.packages("dplyr")
install.packages("timeDate")
install.packages("mondate")
install.packages("dummies")

#########################################################################################################
# Call all the required libraries                     
#########################################################################################################

library(dplyr)
library(plyr)
library(lubridate)
library(sqldf)
library(bizdays)
library(timeDate)
library(mondate)
library(dummies)
library(reshape)

#########################################################################################################
#                          Data preparation
#########################################################################################################
# Set work directory and read all the input files                        
#########################################################################################################

setwd("C:/Users/hianj/Documents/My studies/15_Leroy Merlin/data")

dfAssociationBtwnArticles = read.csv("./agg_associations.csv", header = TRUE, sep = ";")
dfSalesAggregated = read.csv("./agg_sales.csv", header = TRUE, sep = ";", quote = "\"")
dfCommercialOperations =  read.csv("./commercial_operations.csv", header = TRUE, sep = ",", quote = "\"")
dfProductClassifications =  read.csv("./dim_art.csv", header = TRUE, sep = ";", quote = "\"")
dfProductInFront =  read.csv("./products_in_front.csv", header = TRUE, sep = ",", quote = "\"")
dfSales =  read.csv("./sales.csv", header = TRUE, sep = ",", quote = "\"")
dfStock2015 = read.csv("./stock_15.csv", header = TRUE, sep = ",", quote = "\"")
dfStock2016 = read.csv("./stock_16.csv", header = TRUE, sep = ",", quote = "\"")
dfStock2017 = read.csv("./stock_17.csv", header = TRUE, sep = ",", quote = "\"")
dfWebAddBasket = read.csv("./web_add_basket.csv", header = TRUE, sep = ";", quote = "\"")
dfWebAddBasketBoulogne = read.csv("./web_add_basket_Boulogne.csv", header = TRUE, sep = ";", quote = "\"")
dfWebClick = read.csv("./web_click.csv", header = TRUE, sep = ";", quote = "\"")
dfWebClickBoulogne = read.csv("./web_click_Boulogne.csv", header = TRUE, sep = ";", quote = "\"")

#########################################################################################################
# Standardize the column names
#########################################################################################################

colnames(dfAssociationBtwnArticles)   = c("Product_SKU", "Asso_Prdt_SKU", "No_Of_Associations", "Avg_Qty_Tran1", "Avg_Asso_Qty_Trans2")
colnames(dfSalesAggregated)           = c("Product_SKU", "No_Of_Transactions")
#Drop the 4th column as it is redundant
dfCommercialOperations[4]             = NULL
colnames(dfCommercialOperations)      = c("Operation_Id", "Discount_Start_Dt", "Discount_End_Dt", "Product_SKU", "Price", "Price_After_Discount")
colnames(dfProductClassifications)    = c("Product_SKU", "Product_Desc", "Aisle_No", "Aisle_Desc", "Sub_Aisle_No", "Sub_Aisle_Desc",
                                          "Type_No", "Type_Desc", "Sub_Type_No", "Sub_Type_Desc", "Top_100")
colnames(dfProductInFront)            = c("End_Display_Id", "End_Display_Type", "Aisle_No", "Display_Start_Dt", "Display_End_Dt", 
                                          "Composition_Start_Dt", "Composition_End_Dt",  "Product_SKU")
colnames(dfSales)                     = c("Store_No", "Sales_Dt",  "Product_SKU", "Quantity_Sold", "Amount_In_Euros")
colnames(dfStock2015)                 = c("Product_SKU", "Stock_Dt", "Stock_Qty")
colnames(dfStock2016)                 = c("Product_SKU", "Stock_Dt", "Stock_Qty")
colnames(dfStock2017)                 = c("Product_SKU", "Stock_Dt", "Stock_Qty")
colnames(dfWebAddBasket)              = c("Click_Dt", "Product_SKU", "Added_To_Basket")
colnames(dfWebAddBasketBoulogne)      = c("Click_Dt", "Store_No", "Product_SKU", "Added_To_Basket")
colnames(dfWebClick)                  = c("Visited_Dt", "Product_SKU", "No_Of_Clicks")
colnames(dfWebClickBoulogne)          = c("Visited_Dt", "Product_SKU", "Store_No", "No_Of_Clicks")

########################################################################################################
# Create a calendar which excludes Sunday from business days
# Currently no public holidays are being considered
########################################################################################################

create.calendar("LMFrance", holidays = integer(0), weekdays=c("sunday"))

#########################################################################################################
# Combine the stock data for all the years
# Sort on Product_SKU, Stock_Dt (ascending)
# If Stock_Qty is 'NA', then replace it with 0
#########################################################################################################

dfStockData                                               = rbind(dfStock2015, dfStock2016, dfStock2017)
dfStockDataSrt                                            = dfStockData[order(dfStockData$Product_SKU, dfStockData$Stock_Dt),]
dfStockDataSrt$Stock_Qty[is.na(dfStockDataSrt$Stock_Qty)] = 0

dfStockDataSub                                            = subset(dfStockDataSrt, Stock_Qty > 0)

#########################################################################################################
# Subset the sales data to remove all the redundant records which has 0 quantity sold
#########################################################################################################

dfSalesSub = subset(dfSales, Quantity_Sold > 0)

#########################################################################################################
# Sort dfProductInFront on the following and store in dfProductInFrontSrt:
#   Product_SKU, Composition_Start_Dt, Composition_End_Dt, End_Display_Id, End_Display_Type
#
# If Composition_End_Dt is 'NA' in dfProductInFront, then replace it with today's date
#########################################################################################################

# To make a sort order
dfProductInFrontSrt                     = dfProductInFront[order(dfProductInFront$Product_SKU, 
                                                                 dfProductInFront$Composition_Start_Dt, 
                                                                 dfProductInFront$Composition_End_Dt,
                                                                 dfProductInFront$End_Display_Id, 
                                                                 dfProductInFront$End_Display_Type),]
# To change date to character
dfProductInFrontSrt$Composition_End_Dt  = as.character(dfProductInFrontSrt$Composition_End_Dt)

# Replace NA value of Composition_End_Dt with current system date
dfProductInFrontSrt$Composition_End_Dt[is.na(dfProductInFrontSrt$Composition_End_Dt)] = as.character(Sys.Date())

#########################################################################################################
# Count the different type of displays the product was placed during the display period
# Also the duration between each display is captured here. This table has a summary of 
# all the product displays happened so far.
#########################################################################################################

dfDisplaySummary                            = dfProductInFrontSrt %>% 
  group_by(Product_SKU,Composition_Start_Dt, Composition_End_Dt) %>% tally()
colnames(dfDisplaySummary)[4]               = "Count_Diff_Disp_Types"

dfDisplaySummary$Duration                   = bizdays(dfDisplaySummary$Composition_Start_Dt,
                                                      dfDisplaySummary$Composition_End_Dt,
                                                      'LMFrance') + 1

dfDisplaySummary$Duration                   = as.numeric(dfDisplaySummary$Duration)

#########################################################################################################
# Create a subset of sales data of only those products which were part of a front display at least once
# This subset is: dfSalesPrdtsDisplayed
#########################################################################################################

dfSalesPrdtsDisplayed                       = inner_join(dfProductInFrontSrt, dfSalesSub, by = "Product_SKU")
reqCols                                     = c("Product_SKU", "Sales_Dt", "Quantity_Sold", "Amount_In_Euros", 
                                                "Composition_Start_Dt", "Composition_End_Dt")
dfSalesPrdtsDisplayed                       = dfSalesPrdtsDisplayed[, reqCols]

# Change all the date columns to Date format
dfSalesPrdtsDisplayed$Sales_Dt              = as.Date(dfSalesPrdtsDisplayed$Sales_Dt)
dfSalesPrdtsDisplayed$Composition_Start_Dt  = as.Date(dfSalesPrdtsDisplayed$Composition_Start_Dt)
dfSalesPrdtsDisplayed$Composition_End_Dt    = as.Date(dfSalesPrdtsDisplayed$Composition_End_Dt)

#########################################################################################################
# Create a subset of sales data only if the sale happened during a front display
#########################################################################################################

dfSalesDuringFrontDisplay   = subset(dfSalesPrdtsDisplayed, 
                                     Sales_Dt >= Composition_Start_Dt & Sales_Dt <= Composition_End_Dt)

#########################################################################################################
#                                     Base Table Creation 
#########################################################################################################
#########################################################################################################
# Calculate the sum of quantity sold when product was on a front display
#########################################################################################################

dfBaseTblDispSales           = aggregate(dfSalesDuringFrontDisplay$Quantity_Sold, 
                                         by=list(dfSalesDuringFrontDisplay$Product_SKU,
                                                 dfSalesDuringFrontDisplay$Composition_Start_Dt,
                                                 dfSalesDuringFrontDisplay$Composition_End_Dt),
                                         FUN=sum)

colnames(dfBaseTblDispSales) = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Qty_Sold_Display")

#########################################################################################################
# Calculate duration of front display in days
# If the front display started and ended on the same day, the duration will be calculated as 1.
#########################################################################################################

dfBaseTblDispSales$Duration_Of_Disp              = bizdays(dfBaseTblDispSales$Composition_Start_Dt,
                                                           dfBaseTblDispSales$Composition_End_Dt,
                                                           'LMFrance') + 1

dfBaseTblDispSales$Duration_Of_Disp              = as.numeric(dfBaseTblDispSales$Duration_Of_Disp)

#########################################################################################################
# Calculate the average quantity sold when product was on front display
#########################################################################################################

dfBaseTblDispSales$Avg_Qty_Sold_Disp = round(dfBaseTblDispSales$Sum_Qty_Sold_Disp/ dfBaseTblDispSales$Duration_Of_Disp, digits = 2)

#########################################################################################################
# Identify Anterior_Dt. This is the Front Display Start Dt - (Duration of the display * 2)
#########################################################################################################

dfBaseTblDispSales$Anterior_Dt  = dfBaseTblDispSales$Composition_Start_Dt - 
  (dfBaseTblDispSales$Duration_Of_Disp * 2)

# Reorder columns
dfBaseTblDispSales              = dfBaseTblDispSales[c("Product_SKU", "Anterior_Dt", 
                                                       "Composition_Start_Dt", "Composition_End_Dt", 
                                                       "Sum_Qty_Sold_Display", "Duration_Of_Disp", 
                                                       "Avg_Qty_Sold_Disp")]

# Sort by Product SKU, Composition Start Date and Composition End Date
dfBaseTblDispSales              = dfBaseTblDispSales[order(dfBaseTblDispSales$Product_SKU, 
                                                           dfBaseTblDispSales$Composition_Start_Dt, 
                                                           dfBaseTblDispSales$Composition_End_Dt),]
dfBaseTblDispSalesScore = dfBaseTblDispSales

filterdate = as.Date("2016-11-24")
dfBaseTblDispSales = dfBaseTblDispSales[which(dfBaseTblDispSales$Anterior_Dt < filterdate),]
#########################################################################################################
# Create a subset of sales data only if the sale happened is not during a front display
#########################################################################################################

# Change all the date columns to character format
dfSalesPrdtsDisplayed$Sales_Dt      = as.character(dfSalesPrdtsDisplayed$Sales_Dt)
dfSalesDuringFrontDisplay$Sales_Dt  = as.character(dfSalesDuringFrontDisplay$Sales_Dt)

#To subtract dfSalesDuringFrontDisplay from dfSalesPrdtsDisplayed
dfSalesNoDisplay                    = sqldf("select Product_SKU, Sales_Dt, Quantity_Sold from dfSalesPrdtsDisplayed 
                                            except 
                                            select Product_SKU, Sales_Dt, Quantity_Sold from dfSalesDuringFrontDisplay")

#########################################################################################################
# Identify all the sales which happened during no display
#########################################################################################################

dfSalesAnterior                       = inner_join(dfBaseTblDispSales, dfSalesNoDisplay, by = "Product_SKU")
dfSalesAnterior$Composition_Start_Dt  = as.Date(dfSalesAnterior$Composition_Start_Dt)
dfSalesAnterior$Sales_Dt              = as.Date(dfSalesAnterior$Sales_Dt)

#########################################################################################################
# Subset only those records which are between the Anterior_Dt and the front display start date
#########################################################################################################

dfSalesAnteriorSub  =  subset(dfSalesAnterior, Sales_Dt >= Anterior_Dt & Sales_Dt < Composition_Start_Dt)


# To keep only required columns
reqCols             = c("Product_SKU", "Anterior_Dt", "Composition_Start_Dt", 
                        "Composition_End_Dt", "Sales_Dt", "Quantity_Sold")
dfSalesAnteriorSub  = dfSalesAnteriorSub[, reqCols]

#########################################################################################################
# Calculate the sum of quantity sold between the Anterior_Dt and the Composition_Start_Dt (display start date)
# only if the sale happened without being in front display
#########################################################################################################

dfSalesAnteriorSum            = aggregate(dfSalesAnteriorSub$Quantity_Sold, 
                                          by=list(dfSalesAnteriorSub$Product_SKU,
                                                  dfSalesAnteriorSub$Anterior_Dt,
                                                  dfSalesAnteriorSub$Composition_Start_Dt),
                                          FUN=sum)

colnames(dfSalesAnteriorSum)  = c("Product_SKU", "Anterior_Dt", "Composition_Start_Dt", "Sum_Qty_Sold_Anterior")

#########################################################################################################
# **** Calculation of anterior period duration ***
#########################################################################################################
# Calculate the actual duration of anterior period after reducing number of days which had any displays
#########################################################################################################

# Create a subset with only Anterior_Dt and Composition_Start_Dt
reqCols                                   = c("Product_SKU", "Anterior_Dt","Composition_Start_Dt","Composition_End_Dt")
dfAnteriorPeriod                          = dfBaseTblDispSales[, reqCols]
colnames(dfAnteriorPeriod)[3]             = "Display_Start_Dt"
colnames(dfAnteriorPeriod)[4]             = "Display_End_Dt"

# Combine Anterior period data with the displays
dfAnteriorDisplays                        = inner_join(dfAnteriorPeriod, dfDisplaySummary, by = "Product_SKU")
dfAnteriorDisplays$Duration               = NULL
dfAnteriorDisplays$Count_Diff_Disp_Types  = NULL
colnames(dfAnteriorDisplays)[5]           = "Other_Display_Start_Dt"
colnames(dfAnteriorDisplays)[6]           = "Other_Display_End_Dt"
dfAnteriorDisplays$Other_Display_Start_Dt = as.Date(dfAnteriorDisplays$Other_Display_Start_Dt)
dfAnteriorDisplays$Other_Display_End_Dt   = as.Date(dfAnteriorDisplays$Other_Display_End_Dt)
dfAnteriorDisplays$Duration_Anterior      = bizdays(dfAnteriorDisplays$Anterior_Dt,
                                                    dfAnteriorDisplays$Display_Start_Dt,
                                                    'LMFrance')

dfAnteriorDisplays = unique(dfAnteriorDisplays)

# To sort records on Product_SKU, Anterior starts date and Front display start date
# Front display start date is equivalent to anterior end date
dfAnteriorDisplays                        = dfAnteriorDisplays[order(dfAnteriorDisplays$Product_SKU, 
                                                                     dfAnteriorDisplays$Anterior_Dt, 
                                                                     dfAnteriorDisplays$Display_Start_Dt),]

# If anterior period has other displays falling within the same time, assign Other_Disp_Present = 1

dfAnteriorDisplays$Other_Disp_Present     = ifelse(
  # Other display started and ended during anterior period
  (dfAnteriorDisplays$Other_Display_Start_Dt > dfAnteriorDisplays$Anterior_Dt &
     dfAnteriorDisplays$Other_Display_End_Dt   < dfAnteriorDisplays$Display_Start_Dt) |
    # Other display started before the start of anterior and ended during anterior 
    (dfAnteriorDisplays$Other_Display_Start_Dt < dfAnteriorDisplays$Anterior_Dt &
       dfAnteriorDisplays$Other_Display_End_Dt   > dfAnteriorDisplays$Anterior_Dt &
       dfAnteriorDisplays$Other_Display_End_Dt   < dfAnteriorDisplays$Display_Start_Dt) |
    # Other display started during anterior period but ended after anterior period   
    (dfAnteriorDisplays$Other_Display_Start_Dt > dfAnteriorDisplays$Anterior_Dt &
       dfAnteriorDisplays$Other_Display_Start_Dt < dfAnteriorDisplays$Display_Start_Dt &  
       dfAnteriorDisplays$Other_Display_End_Dt   > dfAnteriorDisplays$Display_Start_Dt) |
    # Other display started before the start of anterior and ended after the end of anterior 
    (dfAnteriorDisplays$Other_Display_Start_Dt < dfAnteriorDisplays$Anterior_Dt &
       dfAnteriorDisplays$Other_Display_End_Dt   > dfAnteriorDisplays$Display_Start_Dt),
  1, 0
)

#########################################################################################################
# Function to calculate number of affected days due to other displays during anterior period
# If other display started before the start of anterior start date then,
#   Affected days is calcluated as: Number of days between anterior start date and end of other display.
# If other display started during the anterior period then,
#   Affected days is calcluated as: Number of days between other display start and end dates.
#########################################################################################################

for (i in 1:nrow(dfAnteriorDisplays)) {
  if(dfAnteriorDisplays$Other_Disp_Present[i] == 0) {
    dfAnteriorDisplays$Affected_Days[i] = 0
  }
  else {
    if (dfAnteriorDisplays$Other_Display_Start_Dt[i] < dfAnteriorDisplays$Anterior_Dt[i] & 
        dfAnteriorDisplays$Other_Display_End_Dt[i]   > dfAnteriorDisplays$Anterior_Dt[i] & 
        dfAnteriorDisplays$Other_Display_End_Dt[i]   < dfAnteriorDisplays$Display_Start_Dt[i]) {
      
      dfAnteriorDisplays$Affected_Days[i]  = bizdays(dfAnteriorDisplays$Anterior_Dt[i],
                                                     dfAnteriorDisplays$Other_Display_End_Dt[i],
                                                     'LMFrance') + 1
    }
    else {
      if (dfAnteriorDisplays$Other_Display_Start_Dt[i] > dfAnteriorDisplays$Anterior_Dt[i] &
          dfAnteriorDisplays$Other_Display_End_Dt[i]   < dfAnteriorDisplays$Display_Start_Dt[i]) {
        
        dfAnteriorDisplays$Affected_Days[i]  = bizdays(dfAnteriorDisplays$Other_Display_Start_Dt[i],
                                                       dfAnteriorDisplays$Other_Display_End_Dt[i],
                                                       'LMFrance') + 1   
      }
      else {
        if (dfAnteriorDisplays$Other_Display_Start_Dt[i] > dfAnteriorDisplays$Anterior_Dt[i] &
            dfAnteriorDisplays$Other_Display_Start_Dt[i] < dfAnteriorDisplays$Display_Start_Dt[i] &  
            dfAnteriorDisplays$Other_Display_End_Dt[i]   > dfAnteriorDisplays$Display_Start_Dt[i]) {
          
          dfAnteriorDisplays$Affected_Days[i]  = bizdays(dfAnteriorDisplays$Other_Display_Start_Dt[i],
                                                         dfAnteriorDisplays$Display_Start_Dt[i],
                                                         'LMFrance') + 1   
        }
        else {
          if(dfAnteriorDisplays$Other_Display_Start_Dt[i] < dfAnteriorDisplays$Anterior_Dt[i] &
             dfAnteriorDisplays$Other_Display_End_Dt[i]  > dfAnteriorDisplays$Display_Start_Dt[i]) {
            
            dfAnteriorDisplays$Affected_Days[i]  = dfAnteriorDisplays$Duration_Anterior[i]
            
          }
        }
      }
      
    }
  }
}


# To sort  Product SKU, anterior period on descending order for number of affected days during to 
# other displays. Hence, the display with the longest duration which ahs affected the anterior period
# will come on top.

dfAnteriorDisplays                        = dfAnteriorDisplays[order(dfAnteriorDisplays$Product_SKU, 
                                                                     dfAnteriorDisplays$Anterior_Dt, 
                                                                     dfAnteriorDisplays$Display_Start_Dt,
                                                                     -dfAnteriorDisplays$Affected_Days),]

dfAnteriorWithOtherDisplays               = aggregate(dfAnteriorDisplays$Affected_Days, 
                                                      by=list(dfAnteriorDisplays$Product_SKU,
                                                              dfAnteriorDisplays$Anterior_Dt,
                                                              dfAnteriorDisplays$Display_Start_Dt),
                                                      FUN=max)

colnames(dfAnteriorWithOtherDisplays)     = c("Product_SKU", "Anterior_Dt", "Composition_Start_Dt", "Other_Display_Days")


#########################################################################################################
# Merge the base table with the total sales calculated during anterior period
#########################################################################################################

dfBaseMerge               = left_join(dfBaseTblDispSales, dfSalesAnteriorSum, 
                                      by = c("Product_SKU", "Anterior_Dt", "Composition_Start_Dt"))

#########################################################################################################
# If there was no sale when the product was not on a display, then Sum_Qty_Sold_Anterior = 0.
# This could be due to 2 reasons:
#         1) There was actually no sale during the anterior period
#           or
#        2) The sale during anterior period was due to another front display that was active at that time.
#########################################################################################################

dfBaseMerge$Sum_Qty_Sold_Anterior[is.na(dfBaseMerge$Sum_Qty_Sold_Anterior)] = 0

#########################################################################################################
# Combine base table and anterior duration
#########################################################################################################

dfBaseMergeAnterDuration    = left_join(dfBaseMerge, dfAnteriorWithOtherDisplays, 
                                        by = c("Product_SKU", "Anterior_Dt", "Composition_Start_Dt"))

# If Other_Display_Days = NA, it indicates that no other displays were found for that product. 
# So replace NA with 0
dfBaseMergeAnterDuration$Other_Display_Days[is.na(dfBaseMergeAnterDuration$Other_Display_Days)] = 0

dfBaseMergeAnterDuration$Anterior_Duration_Orig = bizdays(dfBaseMergeAnterDuration$Anterior_Dt,
                                                          dfBaseMergeAnterDuration$Composition_Start_Dt,
                                                          'LMFrance') + 1

# Reduce the number of days when displays where there from the full duration of anterior period
dfBaseMergeAnterDuration$Anterior_Duration = dfBaseMergeAnterDuration$Anterior_Duration_Orig -
  dfBaseMergeAnterDuration$Other_Display_Days

#########################################################################################################
# Filter out those records which never had a sale while it was not on a  front display
#########################################################################################################

dfBaseMergeSub = subset(dfBaseMergeAnterDuration, Anterior_Duration > 0)

#########################################################################################################
# Calculate the average quantity sold when product was on front display
#########################################################################################################

dfBaseMergeSub$Avg_Qty_Sold_Anterior = round(dfBaseMergeSub$Sum_Qty_Sold_Anterior/ dfBaseMergeSub$Anterior_Duration, digits = 2)

#########################################################################################################
# Filter out all the records which had no sale during anterior period
#########################################################################################################

dfBaseTable  = subset(dfBaseMergeSub, Avg_Qty_Sold_Anterior > 0)

#########################################################################################################
# Target: Change in rate of quantity sold 
#          = Average quantity sold after display - 
#            Average quantity sold while not on any display
#########################################################################################################

dfBaseTable$Target = round(((dfBaseTable$Avg_Qty_Sold_Disp - dfBaseTable$Avg_Qty_Sold_Anterior)
                            / dfBaseTable$Avg_Qty_Sold_Anterior) * 100, digits = 2)

#########################################################################################################
#Predictor 1 - Season just before the start of Anterior date
#########################################################################################################

dfSeason1 = data.frame(Month=c(3,4,5),Season='Printemps', stringsAsFactors=F)
dfSeason2 = data.frame(Month=c(6,7,8),Season='Ete', stringsAsFactors=F)
dfSeason3 = data.frame(Month=c(9,10,11),Season='Automne', stringsAsFactors=F)
dfSeason4 = data.frame(Month=c(12,1,2),Season='Hiver', stringsAsFactors=F)
dfSeasons = rbind(dfSeason1, dfSeason2, dfSeason3, dfSeason4)
dfSeasons = dfSeasons[order(dfSeasons$Month),]

dfBaseTable$Month_Of_Disp  = month(dfBaseTable$Anterior_Dt - 1)
dfBaseTable                = inner_join(dfBaseTable, dfSeasons, by = c("Month_Of_Disp" = "Month"))
dfBaseTable$Month_Of_Disp  = NULL

d1 = dummy(dfBaseTable$Season, sep=":",drop=TRUE)
colnames(d1) = sapply(colnames(d1),function(x) gsub(".*:", "", x))	
dfBaseTable= cbind(dfBaseTable,d1)
dfBaseTable$Season = NULL

#########################################################################################################
# Predictor 2 - Number of front displays before the Anterior date
#########################################################################################################

dfDisplaySummary$Composition_Start_Dt   = as.Date(dfDisplaySummary$Composition_Start_Dt)
dfDisplaySummary$Composition_End_Dt     = as.Date(dfDisplaySummary$Composition_End_Dt)

colnames(dfDisplaySummary)              = c("Product_SKU", "Display_Start_Dt", "Display_End_Dt", "Count_Diff_Disp_Types","Duration_of_Disp")

dfBaseTempTbl                           = inner_join(dfBaseTable, dfDisplaySummary, by = "Product_SKU")
dfBaseTblSub                            = subset(dfBaseTempTbl, Display_Start_Dt < Anterior_Dt)
dfBaseTblSub$Count_Diff_Disp_Types      = NULL

dfBaseFDCount                           = dfBaseTblSub %>% 
  group_by(Product_SKU,Composition_Start_Dt, Composition_End_Dt) %>% tally()
colnames(dfBaseFDCount)[4]              = "No_Of_Disp_Before_Anterior"

dfBaseTable                           = left_join(dfBaseTable, dfBaseFDCount, by = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt"))
dfBaseTable$No_Of_Disp_Before_Anterior[is.na(dfBaseTable$No_Of_Disp_Before_Anterior)]         = 0

#########################################################################################################
# Stock predictors 
#########################################################################################################
#Create a base table just with stock details
dfStockBase                     = inner_join(dfBaseTable, dfStockDataSrt, by = "Product_SKU")
reqCols                         = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Anterior_Dt", "Stock_Dt", "Stock_Qty")
dfStockBase                     = dfStockBase[, reqCols]

#########################################################################################################
# Predictor 3 - Total stock for 0-3 months from Anterior_Dt
#########################################################################################################

dfStockBase$Start_0_3_months    = as.Date(mondate(dfStockBase$Anterior_Dt) - 3, format="%Y-%m-%d")
dfStockBase$Stock_Dt            = as.Date(dfStockBase$Stock_Dt)


#To get a subset of stock data which was between the period of 0-3 months from the Anterior_Dt
dfStock3mths                    = subset(dfStockBase, Stock_Dt < Anterior_Dt & Stock_Dt >= Start_0_3_months)
dfStock3mthsSum                 = aggregate(dfStock3mths$Stock_Qty, 
                                            by=list(dfStock3mths$Product_SKU,
                                                    dfStock3mths$Composition_Start_Dt,
                                                    dfStock3mths$Composition_End_Dt),
                                            FUN=sum)
colnames(dfStock3mthsSum)       = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Stock_0_3")

# Merge the sum of stock for 3 months with the base table
dfBaseTable                     = left_join(dfBaseTable, dfStock3mthsSum, by = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt"))
dfBaseTable$Sum_Stock_0_3       = round(dfBaseTable$Sum_Stock_0_3, digits = 0)

#########################################################################################################
# Predictor 4 - Total stock for 4-6 months from Anterior_Dt
#########################################################################################################

dfStockBase$Start_4_6_months    = as.Date(mondate(dfStockBase$Anterior_Dt) - 6, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 4-6 months from the Anterior_Dt
dfStock4to6mths                 = subset(dfStockBase, Stock_Dt < Start_0_3_months & Stock_Dt >= Start_4_6_months)

dfStock4to6mthsSum              = aggregate(dfStock4to6mths$Stock_Qty, 
                                            by=list(dfStock4to6mths$Product_SKU,
                                                    dfStock4to6mths$Composition_Start_Dt,
                                                    dfStock4to6mths$Composition_End_Dt),
                                            FUN=sum)
colnames(dfStock4to6mthsSum)    = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Stock_4_6")

# Merge the sum of stock for 4 to 6 months with the base table
dfBaseTable                     = left_join(dfBaseTable, dfStock4to6mthsSum, by = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt"))
dfBaseTable$Sum_Stock_4_6       = round(dfBaseTable$Sum_Stock_4_6, digits = 0)

#########################################################################################################
# Predictor 5 - Total stock for 7-9 months from Anterior_Dt
#########################################################################################################

dfStockBase$Start_7_9_months    = as.Date(mondate(dfStockBase$Anterior_Dt) - 9, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 7-9 months from the Anterior_Dt
dfStock7to9mths                 = subset(dfStockBase, Stock_Dt < Start_4_6_months & Stock_Dt >= Start_7_9_months)

dfStock7to9mthsSum              = aggregate(dfStock7to9mths$Stock_Qty, 
                                            by=list(dfStock7to9mths$Product_SKU,
                                                    dfStock7to9mths$Composition_Start_Dt,
                                                    dfStock7to9mths$Composition_End_Dt),
                                            FUN=sum)
colnames(dfStock7to9mthsSum)       = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Stock_7_9")

# Merge the sum of stock for 7 to 9 months with the base table
dfBaseTable                     = left_join(dfBaseTable, dfStock7to9mthsSum, by = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt"))
dfBaseTable$Sum_Stock_7_9       = round(dfBaseTable$Sum_Stock_7_9, digits = 0)

#########################################################################################################
# Predictor 6 - Total stock for 10-12 months from Anterior_Dt
#########################################################################################################

dfStockBase$Start_10_12_months  = as.Date(mondate(dfStockBase$Anterior_Dt) - 12, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 7-9 months from the Anterior_Dt
dfStock10to12mths              = subset(dfStockBase, Stock_Dt < Start_7_9_months & Stock_Dt >= Start_10_12_months)

dfStock10to12mthsSum           = aggregate(dfStock10to12mths$Stock_Qty, 
                                           by=list(dfStock10to12mths$Product_SKU,
                                                   dfStock10to12mths$Composition_Start_Dt,
                                                   dfStock10to12mths$Composition_End_Dt),
                                           FUN=sum)
colnames(dfStock10to12mthsSum) = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Stock_10_12")

# Merge the sum of stock for 10 to 12 months with the base table
dfBaseTable                     = left_join(dfBaseTable, dfStock10to12mthsSum, by = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt"))
dfBaseTable$Sum_Stock_10_12     = round(dfBaseTable$Sum_Stock_10_12, digits = 0)

#########################################################################################################
# Replace NAs to 0
#########################################################################################################

dfBaseTable$Sum_Stock_0_3[is.na(dfBaseTable$Sum_Stock_0_3)]   = 0
dfBaseTable$Sum_Stock_4_6[is.na(dfBaseTable$Sum_Stock_4_6)]   = 0
dfBaseTable$Sum_Stock_7_9[is.na(dfBaseTable$Sum_Stock_7_9)]   = 0
dfBaseTable$Sum_Stock_10_12[is.na(dfBaseTable$Sum_Stock_10_12)]   = 0

#########################################################################################################
# Create and Merge classification related predictors
#########################################################################################################
btr <- dfBaseTable

#Create a temporary table that subset of Product Classification Table containing 
#all the product present in Boulogne Store
aaa <- na.omit(subset(dfProductClassifications, 
                      (dfProductClassifications$Product_SKU 
                       %in% unique(dfSalesSub$Product_SKU))))

#Creation of variable based on category of product.
#a is a temporary object that serves as a storage. The process is applied repetitively

#PARAMETER answering the question: "How many differents unique COD_SRAY at COD_RAY level?"

#Subsetting the temporary working table keeping only Aisle and Sub_Aisle
a <- aaa[,c(3,5)]

#Using duplicated function to keep all the existing combinaisons 
a<-a[!duplicated(a),]

#Adding a row that is used to count
a[,length(a)] <- 1 

#Temporary object that retains the name
a_names <- colnames(a)

#Aggregate by the Aisle category so that it counts the combinaisons per Aisle
a<- aggregate.data.frame(a, by=list(a$Aisle_No), FUN = sum)

#Remove duplicated row
a <- a[,-2]
colnames(a) <- a_names
colnames(a)[length(a)] <- "Variety_Aisle_No_FR"

#Link this information to the new basetable for product parameter FR
PP_FR <- merge.data.frame(aaa,a, by=c("Aisle_No"), all.x = TRUE)



#PARAMETER: "How many differents unique COD_TYP at COD_SRAY level?"
#Descending 1 hierarchical level (taking in account the combinaison COD_RAY &COD_SRAY)
a <- aaa[,c(3,5,7)]
a<-a[!duplicated(a),]
a[,(length(a))] <- 1 
a_names <- colnames(a)
a<- aggregate.data.frame(a, by=list(a$Aisle_No,a$Sub_Aisle_No), FUN = sum)
a <- a[,-c(3,4)]
colnames(a) <- a_names
colnames(a)[length(a)] <- "Variety Sub_Aisle_No_FR"

#Link this to the new table for product parameter FR
PP_FR <- merge.data.frame(PP_FR,a, by=c("Aisle_No","Sub_Aisle_No"), all.x = TRUE)



#PARAMETER: "How many differents unique COD_STYP at COD_TYP level?"
a <- aaa[,c(3,5,7,9)]
a<-a[!duplicated(a),]
a[,length(a)] <- 1 
a_names <- colnames(a)
a<- aggregate.data.frame(a, by=list(a$Aisle_No, a$Sub_Aisle_No, a$Type_No), FUN = sum)
a <- a[,-c(4:6)]
colnames(a) <- a_names
colnames(a)[length(a)] <- "Variety_Type_No_FR"

#Link this to the new table for product parameter FR
PP_FR <- merge.data.frame(PP_FR,a, by=c("Aisle_No","Sub_Aisle_No", "Type_No"), all.x = TRUE)



#PARAMETER: "How many differents unique SKU at COD_STYP level?"
a<- aaa[,c(3,5,7,9,1)]
a<-a[!duplicated(a),]
a[,length(a)] <- 1 
a_names <- colnames(a)
a<- aggregate.data.frame(a, by=list(a$Aisle_No, a$Sub_Aisle_No, 
                                    a$Type_No, a$Sub_Type_No), FUN = sum)
a <- a[,-c(5:8)]
colnames(a) <- a_names
colnames(a)[length(a)] <- "Variety_Sub_Type_No_FR_Product_SKU"

#Link this to the new table for product parameter FR
PP_FR <- merge.data.frame(PP_FR,a, by=c("Aisle_No","Sub_Aisle_No", "Type_No", "Sub_Type_No"), all.x = TRUE)



#PARAMETER: "How many SKU labelled as Top_100 at COD_STYP level?"
a <- aaa[,c(3,5,7,9,11)]
a_names <- colnames(a)
a<- aggregate.data.frame(a, by=list(a$Aisle_No, a$Sub_Aisle_No, 
                                    a$Type_No, a$Sub_Type_No), FUN = sum)  
a <- a[,-c(5:8)]
colnames(a) <- a_names
colnames(a)[length(a)] <- "TOP_100_PER_STYP"

#Link this to the new table for product parameter FR
PP_FR <- merge.data.frame(PP_FR,a, by=c("Aisle_No","Sub_Aisle_No", "Type_No", "Sub_Type_No"), all.x = TRUE)



#PARAMETER: "What is the COD_TYP of the SKU?" with dummy creation
aaadf <- data.frame( c(3,10,13), c(1,0,0),c(0,1,0),c(0,0,1))
colnames(aaadf) <- c("Aisle_No","Aisle_No_3","Aisle_No_10","Aisle_No_13")
PP_FR <- merge.data.frame(PP_FR,aaadf, by=c("Aisle_No"), all.x = TRUE)


#Dummy variable saying if the Product_SKU has another product that is TOP_HYPER_100
#on a Sub_Type_No level

#PARAMETER: "My product SKU is Top_Hyper 100, do I have another product SKU 
#that is also Top_Hyper 100 on a COD_STYP level?"

#Subset the working table keeping only SKU product labelled Top_100
a <- subset.data.frame(aaa,aaa$Top_100==1)
#Finding which rows have duplicated (in a position based) 
b <- a[,-c(1,2)]
b <- duplicated.data.frame(b)
#Binding the result of TRUE / FALSE to the SKU products for future merging
a <- cbind(a,b)
a <- a[,c(1,12)]

#Link this to the new table for product parameter FR
PP_FR <- merge.data.frame(PP_FR,a, by=c("Product_SKU"), all.x = TRUE)
PP_FR$b <- replace(PP_FR$b, is.na(PP_FR$b), 0)
colnames(PP_FR)[20]<-"Top_100_rivalry"

############################################################
btr<-left_join(btr,PP_FR[,c(1,12:20)],by="Product_SKU")

btr<-btr[-which(is.na(btr$Top_100_rivalry)),]

###########################################################################################################
# Weather stuff & holidays
############################################################################################################
#temperature
#get temperatures for Lille from 2012-06-01 (EXTERNAL CSV FILE PROVIDED)
temp <-  read.csv("temp.csv", header = TRUE, sep = ",", quote = "\"")
temp <- temp[,-1]

#filtering out datetime, temperature and weather code columns
temp = temp[,c(2,5,23)]

temp$valid = as.Date(temp$valid)

#number of bad weather days
temp$badweather <- ifelse(grepl("RA|DZ|IC|PL|SN|GR|FZ|TS|SH",temp$presentwx),1,0)

#number of weekend days
temp$weekends <- ifelse(isWeekend(temp$valid)==TRUE,1,0)

#aggregating to a single temperature and number of bad weather days for a date
avgtemp = aggregate(temp$tmpf,
                    by=list(as.Date(temp$valid)),
                    FUN=mean)

colnames(avgtemp)<-c("Date","avgtemp")

badweather = aggregate(temp$badweather,
                       by=list(as.Date(temp$valid)),
                       FUN=sum)

colnames(badweather)<-c("Date","badweather")

weekends = aggregate(temp$weekends,
                     by=list(as.Date(temp$valid)),
                     FUN=mean)

colnames(weekends)<-c("Date","weekends")

temp$valid = as.Date(temp$valid)
dates = data.frame(unique(temp$valid))
colnames(dates)<-c("Date")

weatherstuff = inner_join(dates,weekends, by="Date")
weatherstuff = inner_join(weatherstuff,badweather, by="Date")
weatherstuff = inner_join(weatherstuff,avgtemp, by="Date")

#France holidays

EasterMonday = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "EasterMonday"))
FRAscension = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRAscension"))
FRBastilleDay = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRBastilleDay"))
FRArmisticeDay = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRArmisticeDay"))
FRFetDeLaVictoire1945 = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRFetDeLaVictoire1945"))
FRAllSaints = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRAllSaints"))
FRArmisticeDay = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRArmisticeDay"))
FRAssumptionVirginMary = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "FRAssumptionVirginMary"))
PentecostMonday = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "PentecostMonday"))
NewYearsDay = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "NewYearsDay"))
GBMayDay = as.Date(holiday(year = unique(year(temp$valid)), Holiday = "GBMayDay"))

tooling = c("2016-11-26","2016-10-08","2016-09-09","2016-06-25","2016-06-15","2016-05-25","2016-04-30","2016-04-23","2016-04-13","2016-03-19")
electricite = c("2016-10-21","2016-09-17","2016-08-12","2016-06-17","2016-05-18","2016-03-26")
eclairage = c("2016-09-23","2016-05-04","2016-04-08")

tooling = as.Date(tooling)
electricite = as.Date(electricite)
eclairage = as.Date(eclairage)

holidaylist = c("EasterMonday","FRAscension","FRBastilleDay","FRArmisticeDay","FRFetDeLaVictoire1945","FRAllSaints","FRArmisticeDay","FRAssumptionVirginMary","PentecostMonday","NewYearsDay","GBMayDay")

weatherstuff$EasterMonday = ifelse(weatherstuff$Date %in% EasterMonday ,1,0)
weatherstuff$FRAscension = ifelse(weatherstuff$Date %in% FRAscension ,1,0)
weatherstuff$FRBastilleDay = ifelse(weatherstuff$Date %in% FRBastilleDay ,1,0)
weatherstuff$FRArmisticeDay = ifelse(weatherstuff$Date %in% FRArmisticeDay ,1,0)
weatherstuff$FRFetDeLaVictoire1945 = ifelse(weatherstuff$Date %in% FRFetDeLaVictoire1945 ,1,0)
weatherstuff$FRAllSaints = ifelse(weatherstuff$Date %in% FRAllSaints ,1,0)
weatherstuff$FRArmisticeDay = ifelse(weatherstuff$Date %in% FRArmisticeDay ,1,0)
weatherstuff$FRAssumptionVirginMary = ifelse(weatherstuff$Date %in% FRAssumptionVirginMary ,1,0)
weatherstuff$PentecostMonday = ifelse(weatherstuff$Date %in% PentecostMonday ,1,0)
weatherstuff$NewYearsDay = ifelse(weatherstuff$Date %in% NewYearsDay ,1,0)
weatherstuff$GBMayDay = ifelse(weatherstuff$Date %in% GBMayDay ,1,0)
weatherstuff$tooling = ifelse(weatherstuff$Date %in% tooling ,1,0)
weatherstuff$electricite = ifelse(weatherstuff$Date %in% electricite ,1,0)
weatherstuff$eclairage = ifelse(weatherstuff$Date %in% eclairage ,1,0)

#remove NAs in weatherstuff
weatherstuff<-subset(weatherstuff,!weatherstuff$avgtemp=="NA")

a=ncol(btr)
for(i in 1:nrow(btr)){
  zzz<-subset(weatherstuff[,1:4],
              (weatherstuff$Date<btr$Anterior_Dt[i]
               &weatherstuff$Date>=(btr$Anterior_Dt[i]-90)))
  
  btr[i,a+1]<-round(sum(zzz$avgtemp)/nrow(zzz),1)
  btr[i,a+2]<-sum(zzz$weekends)
  btr[i,a+3]<-round(sum(zzz$badweather)/nrow(zzz),2)
}
colnames(btr)[a+1]<-"Avg_temp_0_3"
colnames(btr)[a+2]<-"Weekends_0_3"
colnames(btr)[a+3]<-"badweather_0_3"


a=ncol(btr)
for(i in 1:nrow(btr)){
  zzz<-subset(weatherstuff[,1:4],
              (weatherstuff$Date<(btr$Anterior_Dt[i]-90)
               &weatherstuff$Date>=(btr$Anterior_Dt[i]-180)))
  
  btr[i,a+1]<-round(sum(zzz$avgtemp)/nrow(zzz),1)
  btr[i,a+2]<-sum(zzz$weekends)
  btr[i,a+3]<-round(sum(zzz$badweather)/nrow(zzz),2)
}
colnames(btr)[a+1]<-"Avg_temp_4_6"
colnames(btr)[a+2]<-"Weekends_4_6"
colnames(btr)[a+3]<-"badweather_4_6"

a=ncol(btr)
for(i in 1:nrow(btr)){
  zzz<-subset(weatherstuff[,1:4],
              (weatherstuff$Date<(btr$Anterior_Dt[i]-180)
               &weatherstuff$Date>=(btr$Anterior_Dt[i]-270)))
  
  btr[i,a+1]<-round(sum(zzz$avgtemp)/nrow(zzz),1)
  btr[i,a+2]<-sum(zzz$weekends)
  btr[i,a+3]<-round(sum(zzz$badweather)/nrow(zzz),2)
}
colnames(btr)[a+1]<-"Avg_temp_7_9"
colnames(btr)[a+2]<-"Weekends_7_9"
colnames(btr)[a+3]<-"badweather_7_9"

a=ncol(btr)
for(i in 1:nrow(btr)){
  zzz<-subset(weatherstuff[,1:4],
              (weatherstuff$Date<(btr$Anterior_Dt[i]-270)
               &weatherstuff$Date>=(btr$Anterior_Dt[i]-360)))
  
  btr[i,a+1]<-round(sum(zzz$avgtemp)/nrow(zzz),1)
  btr[i,a+2]<-sum(zzz$weekends)
  btr[i,a+3]<-round(sum(zzz$badweather)/nrow(zzz),2)
}
colnames(btr)[a+1]<-"Avg_temp_10_12"
colnames(btr)[a+2]<-"Weekends_10_12"
colnames(btr)[a+3]<-"badweather_10_12"

#basetable name: dfBaseTable
dfBaseTable<-btr

#########################################################################################################
# Table with SKU's and start of anterior date
#########################################################################################################

dfSales2 = dfSales
dfSales2$Store_No = NULL 
dfSales2$Sales_Dt = as.Date(dfSales2$Sales_Dt, format = "%Y-%m-%d")

####Get table with all periods: 0-3 months, 4-6 months, 7-9 months, 10-12 months
Periods = data.frame(dfBaseTable$Product_SKU, dfBaseTable$Anterior_Dt)
colnames(Periods) = c("Product_SKU", "Anterior_Dt")
Periods$Mnt_0_Dt = Periods$Anterior_Dt - 1
Periods$Mnt_3_Dt = Periods$Anterior_Dt - 90
Periods$Mnt_4_Dt = Periods$Anterior_Dt - 91
Periods$Mnt_6_Dt = Periods$Anterior_Dt - 180
Periods$Mnt_7_Dt = Periods$Anterior_Dt - 181
Periods$Mnt_9_Dt = Periods$Anterior_Dt - 270
Periods$Mnt_10_Dt = Periods$Anterior_Dt - 271
Periods$Mnt_12_Dt = Periods$Anterior_Dt - 360

####Merge Periods with all sales on SKU level 
Prices = merge.data.frame(Periods, dfSales2, by= "Product_SKU" , all.x = TRUE, all.y = TRUE)
Prices = Prices[-which(is.na(Prices$Anterior_Dt)),]

#### Get average price per period:
detach("package:plyr",unload=TRUE)

Price_3 = Prices %>% 
  filter(Sales_Dt <= Mnt_0_Dt & Sales_Dt >= Mnt_3_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_3 = round(Amount/Quantity,2),Quantity_3=Quantity,Amount_3 = Amount)%>%
  select(-(Quantity:Amount))

Price_6 = Prices %>% 
  filter(Sales_Dt <= Mnt_4_Dt & Sales_Dt >= Mnt_6_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_6 = round(Amount/Quantity,2),Quantity_6=Quantity,Amount_6 = Amount)%>%
  select(-(Quantity:Amount))

Price_9 = Prices %>% 
  filter(Sales_Dt <= Mnt_7_Dt & Sales_Dt >= Mnt_9_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_9 = round(Amount/Quantity,2),Quantity_9=Quantity,Amount_9 = Amount)%>%
  select(-(Quantity:Amount))

Price_12 = Prices %>% 
  filter(Sales_Dt <= Mnt_10_Dt & Sales_Dt >= Mnt_12_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_12 = round(Amount/Quantity,2),Quantity_12=Quantity,Amount_12 = Amount)%>%
  select(-(Quantity:Amount))


#### Get sales before each period:
Price_before_3 = Prices %>% 
  filter(Sales_Dt < Mnt_3_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_3 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_6 = Prices %>% 
  filter(Prices$Sales_Dt < Prices$Mnt_6_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_6 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_9 = Prices %>% 
  filter(Prices$Sales_Dt < Prices$Mnt_9_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_9 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_12 = Prices %>% 
  filter(Prices$Sales_Dt < Prices$Mnt_12_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_12 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

#### Merge data frames per month and get predictor of increase in price x months before display:
price_info_3 = merge(Price_3, Price_before_3, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_3$Price_3_increase = ifelse(price_info_3$Price_3 > price_info_3$Price_before_3, 1,0)
price_info_3$Price_3_increase[which(is.na(price_info_3$Price_3_increase))]=0
price_info_3$Price_before_3 = NULL

price_info_6 = merge(Price_6, Price_before_6, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_6$Price_6_increase = ifelse(price_info_6$Price_6 > price_info_6$Price_before_6, 1,0)
price_info_6$Price_6_increase[which(is.na(price_info_6$Price_6_increase))]=0
price_info_6$Price_before_6 = NULL

price_info_9 = merge(Price_9, Price_before_9, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_9$Price_9_increase = ifelse(price_info_9$Price_9 > price_info_9$Price_before_9, 1,0)
price_info_9$Price_9_increase[which(is.na(price_info_9$Price_9_increase))]=0
price_info_9$Price_before_9 = NULL

price_info_12 = merge(Price_12, Price_before_12, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_12$Price_12_increase = ifelse(price_info_12$Price_12 > price_info_12$Price_before_12, 1,0)
price_info_12$Price_12_increase[which(is.na(price_info_12$Price_12_increase))]=0
price_info_12$Price_before_12 = NULL

#### Get min and max price per SKU
#Total amount and Quantity columns added for the new predictors
Price_SKU = Prices %>%
  filter(Sales_Dt<Anterior_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt, Sales_Dt) %>% 
  summarise (Amount = sum(Amount_In_Euros), Quantity = sum(Quantity_Sold))%>%
  mutate(Price = round(Amount/Quantity,2),Amount=Amount,Quantity=Quantity)%>%
  filter(!(Price<0 | is.infinite(Price)))%>%
  group_by(Product_SKU, Anterior_Dt)%>%
  summarise(Min_Price = min(Price), Max_Price= max(Price), 
            Avg_price = mean(Price),Avg_quantity=mean(Quantity),Avg_amount=mean(Amount),Sum_quantity = sum(Quantity), Sum_Amount = sum(Amount))


dfBaseTable<-merge(dfBaseTable,price_info_3,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTable<-merge(dfBaseTable,price_info_6,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTable<-merge(dfBaseTable,price_info_9,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTable<-merge(dfBaseTable,price_info_12,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTable<-merge(dfBaseTable,Price_SKU,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)

dfBaseTable<-dfBaseTable[-which(is.na(dfBaseTable$Avg_price)),]
dfBaseTable$Price_3<-ifelse((is.na(dfBaseTable$Price_3)|is.infinite(dfBaseTable$Price_3)),dfBaseTable$Avg_price,dfBaseTable$Price_3)
dfBaseTable$Price_6<-ifelse((is.na(dfBaseTable$Price_6)|is.infinite(dfBaseTable$Price_6)),dfBaseTable$Price_3,dfBaseTable$Price_6)
dfBaseTable$Price_9<-ifelse((is.na(dfBaseTable$Price_9)|is.infinite(dfBaseTable$Price_9)),dfBaseTable$Price_6,dfBaseTable$Price_9)
dfBaseTable$Price_12<-ifelse((is.na(dfBaseTable$Price_12)|is.infinite(dfBaseTable$Price_12)),dfBaseTable$Price_9,dfBaseTable$Price_12)

dfBaseTable$Quantity_3<-ifelse((is.na(dfBaseTable$Quantity_3)|is.infinite(dfBaseTable$Quantity_3)),dfBaseTable$Avg_quantity,dfBaseTable$Quantity_3)
dfBaseTable$Quantity_6<-ifelse((is.na(dfBaseTable$Quantity_6)|is.infinite(dfBaseTable$Quantity_6)),dfBaseTable$Quantity_3,dfBaseTable$Quantity_6)
dfBaseTable$Quantity_9<-ifelse((is.na(dfBaseTable$Quantity_9)|is.infinite(dfBaseTable$Quantity_9)),dfBaseTable$Quantity_6,dfBaseTable$Quantity_9)
dfBaseTable$Quantity_12<-ifelse((is.na(dfBaseTable$Quantity_12)|is.infinite(dfBaseTable$Quantity_12)),dfBaseTable$Quantity_9,dfBaseTable$Quantity_12)

dfBaseTable$Amount_3<-ifelse((is.na(dfBaseTable$Amount_3)|is.infinite(dfBaseTable$Amount_3)),dfBaseTable$Avg_amount,dfBaseTable$Amount_3)
dfBaseTable$Amount_6<-ifelse((is.na(dfBaseTable$Amount_6)|is.infinite(dfBaseTable$Amount_6)),dfBaseTable$Amount_3,dfBaseTable$Amount_6)
dfBaseTable$Amount_9<-ifelse((is.na(dfBaseTable$Amount_9)|is.infinite(dfBaseTable$Amount_9)),dfBaseTable$Amount_6,dfBaseTable$Amount_9)
dfBaseTable$Amount_12<-ifelse((is.na(dfBaseTable$Amount_12)|is.infinite(dfBaseTable$Amount_12)),dfBaseTable$Amount_9,dfBaseTable$Amount_12)

dfBaseTable$Price_3_increase<-ifelse(is.na(dfBaseTable$Price_3_increase),0,dfBaseTable$Price_3_increase)
dfBaseTable$Price_6_increase<-ifelse(is.na(dfBaseTable$Price_6_increase),0,dfBaseTable$Price_6_increase)
dfBaseTable$Price_9_increase<-ifelse(is.na(dfBaseTable$Price_9_increase),0,dfBaseTable$Price_9_increase)
dfBaseTable$Price_12_increase<-ifelse(is.na(dfBaseTable$Price_12_increase),0,dfBaseTable$Price_12_increase)

#######################################################################################
#campaign related predictors
#
########################################################################################

#GOAL: Create PARAMETERS based on marketing campaign issued for each SKU Product
#with a timeline of one year to before getting put on front displayed

#a will represent a temporary basetable which will hold all the parameters before merging
# with the basetable for modelling

#Retain all Commercial Operation for which the Modelling Table has SKU on. (reduce computational time)
a <- subset(dfCommercialOperations[,c(2:6)], 
            dfCommercialOperations$Product_SKU %in% dfBaseTable$Product_SKU)

#Merge all observations appearing on the modelling table with the marketing campaign information 
a <- na.omit(merge(a, dfBaseTable[,c(1:3)], by="Product_SKU", all=TRUE))

#Convert in Date format
a$Discount_Start_Dt <- as.Date(a$Discount_Start_Dt)
a$Discount_End_Dt <- as.Date(a$Discount_End_Dt)
a$Anterior_Dt <- as.Date(a$Anterior_Dt)

#Valid commercial operation should operated for the following timeline:
# [1 Year, Put on Displayed]
a <- subset(a, (a$Anterior_Dt > a$Discount_Start_Dt & 
                  (a$Discount_Start_Dt > a$Anterior_Dt - 365)) )


#GOAL: Separate the count of Commercial Operation depending on fi price has changed or not.

#Create temporary Variable for future count of number of Commercial Operation with reduction
#PARAMETER: "Number of Commercial Operation with Reduction made"
a[,ncol(a)+1] <- 0
colnames(a)[ncol(a)] <- "Nb_ComOP_Reduction"
a[,ncol(a)] <- ifelse(a$Price==a$Price_After_Discount,0,1)

#PARAMETER: "Number of Commercial Operation without Reduction made"
a[,ncol(a)+1] <- 0
colnames(a)[ncol(a)] <- "Nb_ComOP_No_Reduction"
a[,ncol(a)] <- ifelse(a$Price==a$Price_After_Discount,1,0)


#Counting nb of days of Commercial Operation with and without reduction
a[,ncol(a)+1] <- 0
colnames(a)[ncol(a)] <- "Date_Calcul"
#Create the last date taking in account the timeline
a[,ncol(a)] <- ifelse(a$Anterior_Dt >= a$Discount_End_Dt, 
                      a$Discount_End_Dt, a$Anterior_Dt)
a$Date_Calcul <- as.Date(a$Date_Calcul, origin="1970-01-01")

#PARAMETER: Nb of day of a Commercial Operation with reduction
a[,ncol(a)+1] <- 0
colnames(a)[ncol(a)] <- "Day_ComOP_Reduction"
a[,ncol(a)] <- ifelse(a$Nb_ComOP_Reduction==1,
                      a$Date_Calcul - a$Discount_Start_Dt,0)

#PARAMETER: Nb of day of a Commercial Operation without reduction
a[,ncol(a)+1] <- 0
colnames(a)[ncol(a)] <- "Day_ComOP_No_Reduction"
a[,ncol(a)] <- ifelse(a$Nb_ComOP_No_Reduction==1,
                      a$Date_Calcul - a$Discount_Start_Dt,0)


#Aggregation by Product_SKU using SQL since Aggregate function produce stange output
a <- a[,c(1,8,9,11,12)]
a_names <- colnames(a)

a <- sqldf('Select Product_SKU, sum(Nb_ComOP_Reduction), sum(Nb_ComOP_No_Reduction),
           sum(Day_ComOP_Reduction), sum(Day_ComOP_No_Reduction)
           from a GROUP BY a.Product_SKU')

colnames(a) <- a_names 


#PARAMETER: "Average length (in days) per commercial operation with Reduction"
a[,ncol(a)+1] <- round(a$Day_ComOP_Reduction/a$Nb_ComOP_Reduction)
colnames(a)[ncol(a)] <- "Day_Avg_ComOP_Reduction"
a[,ncol(a)] <- replace(a[,ncol(a)], a[,ncol(a)]=="NaN",0)

#PARAMETER: "Average length (in days) per commercial operation without Reduction"
a[,ncol(a)+1] <- round(a$Day_ComOP_No_Reduction/a$Nb_ComOP_No_Reduction)
colnames(a)[ncol(a)] <- "Day_Avg_ComOP_No_Reduction"
a[,ncol(a)] <- replace(a[,ncol(a)], a[,ncol(a)]=="NaN",0)


#Merge with BaseTable
btrr <- merge.data.frame(a,dfBaseTable, by="Product_SKU", all.y=TRUE)

#Replace all NA value by 0 meaning there were no Commercial Operation for this SKU
btrr$Nb_ComOP_Reduction <- replace(btrr$Nb_ComOP_Reduction, 
                                   is.na(btrr$Nb_ComOP_Reduction), 0)
btrr$Nb_ComOP_No_Reduction <- replace(btrr$Nb_ComOP_No_Reduction, 
                                      is.na(btrr$Nb_ComOP_No_Reduction), 0)
btrr$Day_ComOP_Reduction <- replace(btrr$Day_ComOP_Reduction, 
                                    is.na(btrr$Day_ComOP_Reduction), 0)
btrr$Day_ComOP_No_Reduction <- replace(btrr$Day_ComOP_No_Reduction, 
                                       is.na(btrr$Day_ComOP_No_Reduction), 0)
btrr$Day_Avg_ComOP_Reduction <- replace(btrr$Day_Avg_ComOP_Reduction, 
                                        is.na(btrr$Day_Avg_ComOP_Reduction), 0)
btrr$Day_Avg_ComOP_No_Reduction <- replace(btrr$Day_Avg_ComOP_No_Reduction, 
                                           is.na(btrr$Day_Avg_ComOP_No_Reduction), 0)

dfBaseTable<-btrr

####################################################################################
#product_asso
#
########################################################################################
a <- dfAssociationBtwnArticles

#GOAL: Create PARAMETERS Based on the association of product SKU.

#Create a temporary dataset that contains all the product sold in the basetable
a <- subset(dfAssociationBtwnArticles, 
            (dfAssociationBtwnArticles$Product_SKU %in% dfBaseTable$Product_SKU
             &dfAssociationBtwnArticles$Asso_Prdt_SKU %in% dfSales$Product_SKU))

b <- dfProductClassifications
colnames(b)[1] <- "SKU_asso"
colnames(a)[2] <- "SKU_asso"


#Assign if the associated Product SKU is labeled as target_100 or not
a <- merge.data.frame(a,b[,c(1,11)], 
                      by=c("SKU_asso"), all.x=TRUE)
colnames(a)[length(a)] <- "Qte_Asso_Top_100"


#PARAMETER: "How many differents unique associations (combinaisons) exist for this SKU?"
a[,ncol(a)+1] <- 1
colnames(a)[ncol(a)] <- "Qte_Association"


#GOAL: Separate the number (counting of quantity) of association based on 
#if the associated product is labeled Top_100 or not

#PARAMETER: "How many Quantity of association when Associated product is not a Top_100?"
a[,ncol(a)+1] <- ifelse(a$Qte_Asso_Top_100==0,a$No_Of_Associations,0)
colnames(a)[ncol(a)] <- "Nb_Asso"
#PARAMETER: "How many Quantity of association when Associated product is a Top_100?"
a[,ncol(a)+1] <- ifelse(a$Qte_Asso_Top_100==1,a$No_Of_Associations,0)
colnames(a)[ncol(a)] <- "Nb_Asso_Top_100"

#Aggregate using SQL
a <- a[,c(2,3,6:9)]
a_names <- colnames(a)
a <- sqldf('Select Product_SKU, sum(No_Of_Associations), sum(Qte_Asso_Top_100),
           sum(Qte_Association), sum(Nb_Asso), sum(Nb_Asso_Top_100)
           from a GROUP BY a.Product_SKU')
colnames(a) <- a_names 

#PARAMETER: "What is the ratio of Quantity of association based on the overall quantity?"
a[,ncol(a)+1] <- round((a$Nb_Asso_Top_100 / a$No_Of_Associations),2)
colnames(a)[ncol(a)] <- "Ratio_Nb_Asso_Top_100"

#PARAMETER: "What is the ratio of unique combinaison based on the total combinaison?"
a[,ncol(a)+1] <- round((a$Qte_Asso_Top_100 / a$Qte_Association),2)
colnames(a)[ncol(a)] <- "Ratio_Qte_Association"

#merge with dfBasetable
btrr <- merge.data.frame(a,dfBaseTable,by="Product_SKU", all.y = TRUE)

#Replace NA value by 0 meaning there were no associated combinaison for this SKU
btrr$No_Of_Associations <- replace(btrr$No_Of_Associations, 
                                   is.na(btrr$No_Of_Associations), 0)
btrr$Qte_Asso_Top_100 <- replace(btrr$Qte_Asso_Top_100, 
                                 is.na(btrr$Qte_Asso_Top_100), 0)
btrr$Qte_Association <- replace(btrr$Qte_Association, 
                                is.na(btrr$Qte_Association), 0)
btrr$Nb_Asso <- replace(btrr$Nb_Asso, 
                        is.na(btrr$Nb_Asso), 0)
btrr$Nb_Asso_Top_100 <- replace(btrr$Nb_Asso_Top_100, 
                                is.na(btrr$Nb_Asso_Top_100), 0)
btrr$Ratio_Nb_Asso_Top_100 <- replace(btrr$Ratio_Nb_Asso_Top_100, 
                                      is.na(btrr$Ratio_Nb_Asso_Top_100), 0)
btrr$Ratio_Qte_Association <- replace(btrr$Ratio_Qte_Association, 
                                      is.na(btrr$Ratio_Qte_Association), 0)

dfBaseTable<-btrr


##############################################
# two more predictors about front display
#
#############################################
##################Sales during FD vs. not during FD########
#Get all FD and its sales, plus anterior date
ALL_FD = merge(dfDisplaySummary, Prices, by = "Product_SKU")

ALL_FD <- ALL_FD[,-c(7:14)]
colnames(ALL_FD)[5] = "Duration"

#Filter out any display that occurred after Anterior Date, Get just sales that occurred during FD
#Aggregate on FD dates
#Total amount and Quantity columns added for the new predictors
Sales_During_FD = ALL_FD %>% 
  filter(Display_End_Dt < Anterior_Dt & Sales_Dt <= Display_End_Dt  & Sales_Dt >= Display_Start_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Total_Duration = mean(Duration), Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>% 
  mutate (Avg_Amount_FD = round(Amount/Total_Duration, 4), Avg_Qty_FD = round(Quantity/Total_Duration,4),Total_Amount_FD=round(Amount,2), Total_Duration_FD=round(Total_Duration))

Sales_During_FD<-Sales_During_FD[,-c(3,4,5)]

btrr<-merge.data.frame(dfBaseTable,Sales_During_FD,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)

#New predictors for change in quantity/amount between front display and non-front display before the anterior period
btrr$Total_Amount_FD=ifelse(is.na(btrr$Total_Amount_FD),0,btrr$Total_Amount_FD)
btrr$Total_Duration_FD=ifelse(is.na(btrr$Total_Duration_FD),0,btrr$Total_Duration_FD)

btrr$Avg_Amount_FD=ifelse(is.na(btrr$Avg_Amount_FD),0,btrr$Avg_Amount_FD)
btrr$Avg_Qty_FD=ifelse(is.na(btrr$Avg_Qty_FD),0,btrr$Avg_Qty_FD)

btrr$Total_Amount_UFD=btrr$Sum_Amount-btrr$Total_Amount_FD
btrr$Total_Duration_UFD=as.numeric((btrr$Anterior_Dt-as.Date("2015-01-02"))-btrr$Total_Duration_FD)
btrr$Avg_Sales_UFD = btrr$Total_Amount_UFD/btrr$Total_Duration_UFD
btrr$Diff_Sales_FD_UFD = btrr$Avg_Amount_FD-btrr$Avg_Sales_UFD
btrr$Diff_Percent_Sales_FD = btrr$Diff_Sales_FD_UFD/btrr$Avg_Sales_UFD*100
btrr$Diff_Sales_FD_UFD=ifelse(btrr$Diff_Sales_FD_UFD<=0,0,btrr$Diff_Sales_FD_UFD)
btrr$Diff_Percent_Sales_FD=ifelse(btrr$Diff_Percent_Sales_FD<=0,0,btrr$Diff_Percent_Sales_FD)
btrr$Diff_Percent_Sales_FD=ifelse(is.na(btrr$Diff_Percent_Sales_FD),0,btrr$Diff_Percent_Sales_FD)

dfBaseTable=btrr

###########################################################################################

#----modeling  part ----
library(pROC)
library(ROCR)
library(rpart)

####basetable import####
basetable<-btrr[,-c(2,16:25,68)]
basetable=basetable[-which(is.infinite(basetable$Diff_Percent_Sales_FD)),]

##############winsorization to replace outliers############
lim <- quantile(basetable$Target, probs=c(0.1, .90))
basetable$Target = ifelse(basetable$Target < lim[1], lim[1],basetable$Target)
basetable$Target = ifelse(basetable$Target > lim[2], lim[2],basetable$Target)

hist(basetable$Target)

########train & test set##########
#Create 2 sets from the final: TRAIN(70%) TEST(30%): sample code from online
spec = c(train = .7, test = .3)
g = sample(cut(
  seq(nrow(basetable)), 
  nrow(basetable)*cumsum(c(0,spec)),
  labels = names(spec)
))
res = split(basetable, g)

#Create the corresponding datasets
train<-as.data.frame(res$train)
test<-as.data.frame(res$test)


########use pearson value to filter variables################
vars = names(train[,-c(1,15)])
selected = c()
for(v in vars){
  pvalue= (cor.test(train[,v],train$Target,method="pearson"))$p.value
  if(pvalue<0.1){
    selected = c(selected,v)
  }
}

trainselected = train[,c(selected,"Target","Product_SKU")]
testselected = test[,c(selected,"Target","Product_SKU")]

#build linear regression model on trainselected 
lrmodel=lm(trainselected$Target~.-Product_SKU,data = trainselected,na.action = na.omit)

xulllr=step(lrmodel,data=trainselected,direction = "forward")
#run the model on testselected

predict_test = predict(xulllr, newdata = testselected)
ev_test_linear = cbind(predict_test, testselected$Target)
ev_test_linear<-as.data.frame(ev_test_linear)
colnames(ev_test_linear) = c("predict","target")

predict_train = predict(xulllr, newdata = trainselected)
ev_train_linear = cbind(predict_train, trainselected$Target)
ev_train_linear<-as.data.frame(ev_train_linear)
colnames(ev_train_linear) = c("predict","target")


#check summary of model
summary(lrmodel)
cor<-as.data.frame(cor(train,method="pearson"))
mean(ev_test_linear$predict)
mean(ev_train_linear$predict)
#########mape##########
mape <- function(y, yhat) {
  mean(abs((y - yhat)/y)) 
}

ev_train_linear_1<-subset(ev_train_linear,!ev_train_linear$target==0)
mape(ev_train_linear_1$target,ev_train_linear_1$predict)


hist(basetable$Target)

step(lm(Target~.,data=train),direction="both")

#plot the result (accuracy)
plot(ev_test_linear$target,ev_test_linear$predict,col="blue")
abline(lm(testselected$Target~.,data = testselected), col = "red")
plot(lm(target ~ predict,data=ev_test_linear),col="blue")


#######################################################################################
#SCORING#

#########################################################################################################
# Subset the sales data after filter date from the sales table (even for products never kept in front display)
#########################################################################################################

dfSalesScore  = subset(dfSales, as.Date(Sales_Dt) > filterdate)

# To keep only required columns
reqCols             = c("Product_SKU", "Sales_Dt", "Quantity_Sold")
dfSalesScore  = dfSalesAnteriorSub[, reqCols]

#########################################################################################################
# Calculate the sum of quantity sold between filter date and latest date
#########################################################################################################
dfSalesScore$startdate = filterdate + 30
dfSalesScore$latestdate = filterdate + 60

dfSalesScore            = aggregate(dfSalesScore$Quantity_Sold, 
                                    by=list(dfSalesScore$Product_SKU,
                                            dfSalesScore$startdate,
                                            dfSalesScore$latestdate),
                                    FUN=sum)

colnames(dfSalesScore)  = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Sum_Qty_Sold")

dfSalesScore$Duration_Of_Disp              = bizdays(dfSalesScore$Composition_Start_Dt,
                                                     dfSalesScore$Composition_End_Dt,
                                                     'LMFrance') + 1

dfSalesScore$Duration_Of_Disp              = as.numeric(dfSalesScore$Duration_Of_Disp)

dfSalesScore$Anterior_Dt  = dfSalesScore$Composition_Start_Dt - 30

#########################################################################################################
# Predictor 1 - Season just before the start of Anterior date
#########################################################################################################
dfBaseTableScore = dfSalesScore

dfSeason1 = data.frame(Month=c(3,4,5),Season='Printemps', stringsAsFactors=F)
dfSeason2 = data.frame(Month=c(6,7,8),Season='Ete', stringsAsFactors=F)
dfSeason3 = data.frame(Month=c(9,10,11),Season='Automne', stringsAsFactors=F)
dfSeason4 = data.frame(Month=c(12,1,2),Season='Hiver', stringsAsFactors=F)
dfSeasons = rbind(dfSeason1, dfSeason2, dfSeason3, dfSeason4)
dfSeasons = dfSeasons[order(dfSeasons$Month),]

dfBaseTableScore$Month_Of_Disp  = month(dfBaseTableScore$Anterior_Dt - 1)
dfBaseTableScore                = inner_join(dfBaseTableScore, dfSeasons, by = c("Month_Of_Disp" = "Month"))
dfBaseTableScore$Month_Of_Disp  = NULL

dfBaseTableScore$Ete = 0
dfBaseTableScore$Hiver = 0
dfBaseTableScore$Printemps = 0

d1 = dummy(dfBaseTableScore$Season,sep=":",drop=TRUE)
colnames(d1) = sapply(colnames(d1),function(x) gsub(".*:", "", x))	
dfBaseTableScore= cbind(dfBaseTableScore,d1)
dfBaseTableScore$Season = NULL

#########################################################################################################
# Predictor 2 - Number of front displays before the Anterior date
#########################################################################################################
dfBaseTblScoreSub                            = subset(dfBaseTblDispSalesScore, Anterior_Dt < filterdate)
dfBaseScoreFDCount                           = NULL
dfBaseScoreFDCount                           = dfBaseTblScoreSub %>% 
  group_by(Product_SKU) %>% tally()
colnames(dfBaseScoreFDCount)[2]              = "No_Of_Disp_Before_Anterior"

dfBaseTableScore                           = left_join(dfBaseTableScore, dfBaseScoreFDCount, by = c("Product_SKU"))

dfBaseTableScore$No_Of_Disp_Before_Anterior[is.na(dfBaseTableScore$No_Of_Disp_Before_Anterior)]         = 0

#########################################################################################################
# Stock predictors 
#########################################################################################################
#Create a base table just with stock details
dfStockBaseScore                     = inner_join(dfBaseTableScore, dfStockDataSrt, by = "Product_SKU")
reqCols                              = c("Product_SKU", "Composition_Start_Dt", "Composition_End_Dt", "Anterior_Dt", "Stock_Dt", "Stock_Qty")
dfStockBaseScore                     = dfStockBaseScore[, reqCols]

#########################################################################################################
# Predictor 3 - Total stock for 0-3 months from Anterior_Dt
#########################################################################################################

dfStockBaseScore$Start_0_3_months    = as.Date(mondate(dfStockBaseScore$Anterior_Dt) - 3, format="%Y-%m-%d")
dfStockBaseScore$Stock_Dt            = as.Date(dfStockBaseScore$Stock_Dt)


#To get a subset of stock data which was between the period of 0-3 months from the Anterior_Dt
dfStock3mthsScore                    = subset(dfStockBaseScore, Stock_Dt < Anterior_Dt & Stock_Dt >= Start_0_3_months)
dfStock3mthsSumScore                 = aggregate(dfStock3mthsScore$Stock_Qty, 
                                                 by=list(dfStock3mthsScore$Product_SKU),
                                                 FUN=sum)
colnames(dfStock3mthsSumScore)       = c("Product_SKU", "Sum_Stock_0_3")

# Merge the sum of stock for 3 months with the base table
dfBaseTableScore                     = left_join(dfBaseTableScore, dfStock3mthsSumScore, by = c("Product_SKU"))
dfBaseTableScore$Sum_Stock_0_3       = round(dfBaseTableScore$Sum_Stock_0_3, digits = 0)
#########################################################################################################
# Predictor 4 - Total stock for 4-6 months from Anterior_Dt
#########################################################################################################

dfStockBaseScore$Start_4_6_months    = as.Date(mondate(dfStockBaseScore$Anterior_Dt) - 6, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 4-6 months from the Anterior_Dt
dfStock4to6mthsScore                 = subset(dfStockBaseScore, Stock_Dt < Start_0_3_months & Stock_Dt >= Start_4_6_months)

dfStock4to6mthsSumScore              = aggregate(dfStock4to6mthsScore$Stock_Qty, 
                                                 by=list(dfStock4to6mthsScore$Product_SKU),
                                                 FUN=sum)
colnames(dfStock4to6mthsSumScore)    = c("Product_SKU", "Sum_Stock_4_6")

# Merge the sum of stock for 4 to 6 months with the base table
dfBaseTableScore                     = left_join(dfBaseTableScore, dfStock4to6mthsSumScore, by = c("Product_SKU"))
dfBaseTableScore$Sum_Stock_4_6       = round(dfBaseTableScore$Sum_Stock_4_6, digits = 0)

#########################################################################################################
# Predictor 5 - Total stock for 7-9 months from Anterior_Dt
#########################################################################################################

dfStockBaseScore$Start_7_9_months    = as.Date(mondate(dfStockBaseScore$Anterior_Dt) - 9, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 7-9 months from the Anterior_Dt
dfStock7to9mthsScore                 = subset(dfStockBaseScore, Stock_Dt < Start_4_6_months & Stock_Dt >= Start_7_9_months)

dfStock7to9mthsSumScore              = aggregate(dfStock7to9mthsScore$Stock_Qty, 
                                                 by=list(dfStock7to9mthsScore$Product_SKU),
                                                 FUN=sum)
colnames(dfStock7to9mthsSumScore)       = c("Product_SKU", "Sum_Stock_7_9")

# Merge the sum of stock for 7 to 9 months with the base table
dfBaseTableScore                     = left_join(dfBaseTableScore, dfStock7to9mthsSumScore, by = c("Product_SKU"))
dfBaseTableScore$Sum_Stock_7_9       = round(dfBaseTableScore$Sum_Stock_7_9, digits = 0)

#########################################################################################################
# Predictor 6 - Total stock for 10-12 months from Anterior_Dt
#########################################################################################################

dfStockBaseScore$Start_10_12_months  = as.Date(mondate(dfStockBaseScore$Anterior_Dt) - 12, format="%Y-%m-%d")

# To get a subset of stock data which was between the period of 7-9 months from the Anterior_Dt
dfStock10to12mthsScore              = subset(dfStockBaseScore, Stock_Dt < Start_7_9_months & Stock_Dt >= Start_10_12_months)

dfStock10to12mthsSumScore           = aggregate(dfStock10to12mthsScore$Stock_Qty, 
                                                by=list(dfStock10to12mthsScore$Product_SKU),
                                                FUN=sum)
colnames(dfStock10to12mthsSumScore) = c("Product_SKU", "Sum_Stock_10_12")

# Merge the sum of stock for 10 to 12 months with the base table
dfBaseTableScore                     = left_join(dfBaseTableScore, dfStock10to12mthsSumScore, by = c("Product_SKU"))
dfBaseTableScore$Sum_Stock_10_12     = round(dfBaseTableScore$Sum_Stock_10_12, digits = 0)

#########################################################################################################
# Replace NAs to 0
#########################################################################################################

dfBaseTableScore$Sum_Stock_0_3[is.na(dfBaseTableScore$Sum_Stock_0_3)]   = 0
dfBaseTableScore$Sum_Stock_4_6[is.na(dfBaseTableScore$Sum_Stock_4_6)]   = 0
dfBaseTableScore$Sum_Stock_7_9[is.na(dfBaseTableScore$Sum_Stock_7_9)]   = 0
dfBaseTableScore$Sum_Stock_10_12[is.na(dfBaseTableScore$Sum_Stock_10_12)]   = 0

#########################################################################################################
# Create and Merge classification related predictors
# Robert's 9 predictors
#########################################################################################################

btrScore <- dfBaseTableScore

# Linking the product parameters to the base table

btrScore<-left_join(btrScore,PP_FR[,c(1,12:20)],by="Product_SKU")

btrScore<-btrScore[-which(is.na(btrScore$Top_100_rivalry)),]

###########################################################################################################
# weather stuff & holidays
############################################################################################################

#Creating weather related predictors for the three months before front display

ascore=ncol(btrScore)
for(iscore in 1:nrow(btrScore)){
  zzzscore<-subset(weatherstuff[,1:4],
                   (weatherstuff$Date<btrScore$Anterior_Dt[iscore]
                    &weatherstuff$Date>=(btrScore$Anterior_Dt[iscore]-90)))
  
  btrScore[iscore,ascore+1]<-round(sum(zzzscore$avgtemp)/nrow(zzzscore),1)
  btrScore[iscore,ascore+2]<-sum(zzzscore$weekends)
  btrScore[iscore,ascore+3]<-round(sum(zzzscore$badweather)/nrow(zzzscore),2)
}
colnames(btrScore)[ascore+1]<-"Avg_temp_0_3"
colnames(btrScore)[ascore+2]<-"Weekends_0_3"
colnames(btrScore)[ascore+3]<-"badweather_0_3"

#Creating weather related predictors from 4 to 6 months before front display

ascore=ncol(btrScore)
for(iscore in 1:nrow(btrScore)){
  zzzscore<-subset(weatherstuff[,1:4],
                   (weatherstuff$Date<(btrScore$Anterior_Dt[iscore]-90)
                    &weatherstuff$Date>=(btrScore$Anterior_Dt[iscore]-180)))
  
  btrScore[iscore,ascore+1]<-round(sum(zzzscore$avgtemp)/nrow(zzzscore),1)
  btrScore[iscore,ascore+2]<-sum(zzzscore$weekends)
  btrScore[iscore,ascore+3]<-round(sum(zzzscore$badweather)/nrow(zzzscore),2)
}
colnames(btrScore)[ascore+1]<-"Avg_temp_4_6"
colnames(btrScore)[ascore+2]<-"Weekends_4_6"
colnames(btrScore)[ascore+3]<-"badweather_4_6"

#Creating weather related predictors from 7 to 9 months before front display

ascore=ncol(btrScore)
for(iscore in 1:nrow(btrScore)){
  zzzscore<-subset(weatherstuff[,1:4],
                   (weatherstuff$Date<(btrScore$Anterior_Dt[iscore]-180)
                    &weatherstuff$Date>=(btrScore$Anterior_Dt[iscore]-270)))
  
  btrScore[iscore,ascore+1]<-round(sum(zzzscore$avgtemp)/nrow(zzzscore),1)
  btrScore[iscore,ascore+2]<-sum(zzzscore$weekends)
  btrScore[iscore,ascore+3]<-round(sum(zzzscore$badweather)/nrow(zzzscore),2)
}
colnames(btrScore)[ascore+1]<-"Avg_temp_7_9"
colnames(btrScore)[ascore+2]<-"Weekends_7_9"
colnames(btrScore)[ascore+3]<-"badweather_7_9"

#Creating weather related predictors from 10 to 12 months before front display

ascore=ncol(btrScore)
for(iscore in 1:nrow(btrScore)){
  zzzscore<-subset(weatherstuff[,1:4],
                   (weatherstuff$Date<(btrScore$Anterior_Dt[iscore]-270)
                    &weatherstuff$Date>=(btrScore$Anterior_Dt[iscore]-360)))
  
  btrScore[iscore,ascore+1]<-round(sum(zzzscore$avgtemp)/nrow(zzzscore),1)
  btrScore[iscore,ascore+2]<-sum(zzzscore$weekends)
  btrScore[iscore,ascore+3]<-round(sum(zzzscore$badweather)/nrow(zzzscore),2)
}
colnames(btrScore)[ascore+1]<-"Avg_temp_10_12"
colnames(btrScore)[ascore+2]<-"Weekends_10_12"
colnames(btrScore)[ascore+3]<-"badweather_10_12"

#basetable name: dfBaseTableScore
dfBaseTableScore<-btrScore

#########################################################################################################
# table with SKU's and start of anterior date
#########################################################################################################

####Get table with all periods: 0-3 months, 4-6 months, 7-9 months, 10-12 months
PeriodsScore = data.frame(dfBaseTableScore$Product_SKU, dfBaseTableScore$Anterior_Dt)
colnames(PeriodsScore) = c("Product_SKU", "Anterior_Dt")
PeriodsScore$Mnt_0_Dt = PeriodsScore$Anterior_Dt - 1
PeriodsScore$Mnt_3_Dt = PeriodsScore$Anterior_Dt - 90
PeriodsScore$Mnt_4_Dt = PeriodsScore$Anterior_Dt - 91
PeriodsScore$Mnt_6_Dt = PeriodsScore$Anterior_Dt - 180
PeriodsScore$Mnt_7_Dt = PeriodsScore$Anterior_Dt - 181
PeriodsScore$Mnt_9_Dt = PeriodsScore$Anterior_Dt - 270
PeriodsScore$Mnt_10_Dt = PeriodsScore$Anterior_Dt - 271
PeriodsScore$Mnt_12_Dt = PeriodsScore$Anterior_Dt - 360

####Merge Periods with all sales on SKU level 
PricesScore = merge.data.frame(PeriodsScore, dfSales2, by= "Product_SKU" , all.x = TRUE, all.y = TRUE)
PricesScore = PricesScore[-which(is.na(PricesScore$Anterior_Dt)),]

#### Get average price per period:

Price_3_Score = PricesScore %>% 
  filter(Sales_Dt <= Mnt_0_Dt & Sales_Dt >= Mnt_3_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_3 = round(Amount/Quantity,2),Quantity_3=Quantity,Amount_3 = Amount)%>%
  select(-(Quantity:Amount))

Price_6_Score = PricesScore %>% 
  filter(Sales_Dt <= Mnt_4_Dt & Sales_Dt >= Mnt_6_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_6 = round(Amount/Quantity,2),Quantity_6=Quantity,Amount_6 = Amount)%>%
  select(-(Quantity:Amount))

Price_9_Score = PricesScore %>% 
  filter(Sales_Dt <= Mnt_7_Dt & Sales_Dt >= Mnt_9_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_9 = round(Amount/Quantity,2),Quantity_9=Quantity,Amount_9 = Amount)%>%
  select(-(Quantity:Amount))

Price_12_Score = PricesScore %>% 
  filter(Sales_Dt <= Mnt_10_Dt & Sales_Dt >= Mnt_12_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_12 = round(Amount/Quantity,2),Quantity_12=Quantity,Amount_12 = Amount)%>%
  select(-(Quantity:Amount))

#### Get sales before each period:
Price_before_3_Score = PricesScore %>% 
  filter(Sales_Dt < Mnt_3_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_3 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_6_Score = PricesScore %>% 
  filter(PricesScore$Sales_Dt < PricesScore$Mnt_6_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_6 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_9_Score = PricesScore %>% 
  filter(PricesScore$Sales_Dt < PricesScore$Mnt_9_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_9 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

Price_before_12_Score = PricesScore %>% 
  filter(PricesScore$Sales_Dt < PricesScore$Mnt_12_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt) %>% 
  summarise (Quantity = sum(Quantity_Sold), Amount = sum(Amount_In_Euros))%>%
  mutate(Price_before_12 = round(Amount/Quantity,2))%>%
  select(-(Quantity:Amount))

#### Merge data frames per month and get predictor of increase in price x months before display:
price_info_3_score = merge(Price_3_Score, Price_before_3_Score, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_3_score$Price_3_increase = ifelse(price_info_3_score$Price_3 > price_info_3_score$Price_before_3, 1,0)
price_info_3_score$Price_3_increase[which(is.na(price_info_3_score$Price_3_increase))]=0
price_info_3_score$Price_before_3 = NULL

price_info_6_score = merge(Price_6_Score, Price_before_6_Score, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_6_score$Price_6_increase = ifelse(price_info_6_score$Price_6 > price_info_6_score$Price_before_6, 1,0)
price_info_6_score$Price_6_increase[which(is.na(price_info_6_score$Price_6_increase))]=0
price_info_6_score$Price_before_6 = NULL

price_info_9_score = merge(Price_9_Score, Price_before_9_Score, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_9_score$Price_9_increase = ifelse(price_info_9_score$Price_9 > price_info_9_score$Price_before_9, 1,0)
price_info_9_score$Price_9_increase[which(is.na(price_info_9_score$Price_9_increase))]=0
price_info_9_score$Price_before_9 = NULL

price_info_12_score = merge(Price_12_Score, Price_before_12_Score, by = c("Product_SKU", "Anterior_Dt"), all.x = TRUE)
price_info_12_score$Price_12_increase = ifelse(price_info_12_score$Price_12 > price_info_12_score$Price_before_12, 1,0)
price_info_12_score$Price_12_increase[which(is.na(price_info_12_score$Price_12_increase))]=0
price_info_12_score$Price_before_12 = NULL

#### Get min and max price per SKU
#Total amount and Quantity columns added for the new predictors
Price_SKU_Score = PricesScore %>%
  filter(Sales_Dt<Anterior_Dt) %>% 
  group_by (Product_SKU, Anterior_Dt, Sales_Dt) %>% 
  summarise (Amount = sum(Amount_In_Euros), Quantity = sum(Quantity_Sold))%>%
  mutate(Price = round(Amount/Quantity,2),Amount=Amount,Quantity=Quantity)%>%
  filter(!(Price<0 | is.infinite(Price)))%>%
  group_by(Product_SKU, Anterior_Dt)%>%
  summarise(Min_Price = min(Price), Max_Price= max(Price), 
            Avg_price = mean(Price),Avg_quantity=mean(Quantity),Avg_amount=mean(Amount),Sum_quantity = sum(Quantity), Sum_Amount = sum(Amount))


dfBaseTableScore<-merge(dfBaseTableScore,price_info_3_score,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTableScore<-merge(dfBaseTableScore,price_info_6_score,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTableScore<-merge(dfBaseTableScore,price_info_9_score,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTableScore<-merge(dfBaseTableScore,price_info_12_score,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)
dfBaseTableScore<-merge(dfBaseTableScore,Price_SKU_Score,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)

dfBaseTableScore<-dfBaseTableScore[-which(is.na(dfBaseTableScore$Avg_price)),]
dfBaseTableScore$Price_3<-ifelse((is.na(dfBaseTableScore$Price_3)|is.infinite(dfBaseTableScore$Price_3)),dfBaseTableScore$Avg_price,dfBaseTableScore$Price_3)
dfBaseTableScore$Price_6<-ifelse((is.na(dfBaseTableScore$Price_6)|is.infinite(dfBaseTableScore$Price_6)),dfBaseTableScore$Price_3,dfBaseTableScore$Price_6)
dfBaseTableScore$Price_9<-ifelse((is.na(dfBaseTableScore$Price_9)|is.infinite(dfBaseTableScore$Price_9)),dfBaseTableScore$Price_6,dfBaseTableScore$Price_9)
dfBaseTableScore$Price_12<-ifelse((is.na(dfBaseTableScore$Price_12)|is.infinite(dfBaseTableScore$Price_12)),dfBaseTableScore$Price_9,dfBaseTableScore$Price_12)

dfBaseTableScore$Quantity_3<-ifelse((is.na(dfBaseTableScore$Quantity_3)|is.infinite(dfBaseTableScore$Quantity_3)),dfBaseTableScore$Avg_quantity,dfBaseTableScore$Quantity_3)
dfBaseTableScore$Quantity_6<-ifelse((is.na(dfBaseTableScore$Quantity_6)|is.infinite(dfBaseTableScore$Quantity_6)),dfBaseTableScore$Quantity_3,dfBaseTableScore$Quantity_6)
dfBaseTableScore$Quantity_9<-ifelse((is.na(dfBaseTableScore$Quantity_9)|is.infinite(dfBaseTableScore$Quantity_9)),dfBaseTableScore$Quantity_6,dfBaseTableScore$Quantity_9)
dfBaseTableScore$Quantity_12<-ifelse((is.na(dfBaseTableScore$Quantity_12)|is.infinite(dfBaseTableScore$Quantity_12)),dfBaseTableScore$Quantity_9,dfBaseTableScore$Quantity_12)

dfBaseTableScore$Amount_3<-ifelse((is.na(dfBaseTableScore$Amount_3)|is.infinite(dfBaseTableScore$Amount_3)),dfBaseTableScore$Avg_amount,dfBaseTableScore$Amount_3)
dfBaseTableScore$Amount_6<-ifelse((is.na(dfBaseTableScore$Amount_6)|is.infinite(dfBaseTableScore$Amount_6)),dfBaseTableScore$Amount_3,dfBaseTableScore$Amount_6)
dfBaseTableScore$Amount_9<-ifelse((is.na(dfBaseTableScore$Amount_9)|is.infinite(dfBaseTableScore$Amount_9)),dfBaseTableScore$Amount_6,dfBaseTableScore$Amount_9)
dfBaseTableScore$Amount_12<-ifelse((is.na(dfBaseTableScore$Amount_12)|is.infinite(dfBaseTableScore$Amount_12)),dfBaseTableScore$Amount_9,dfBaseTableScore$Amount_12)

dfBaseTableScore$Price_3_increase<-ifelse(is.na(dfBaseTableScore$Price_3_increase),0,dfBaseTableScore$Price_3_increase)
dfBaseTableScore$Price_6_increase<-ifelse(is.na(dfBaseTableScore$Price_6_increase),0,dfBaseTableScore$Price_6_increase)
dfBaseTableScore$Price_9_increase<-ifelse(is.na(dfBaseTableScore$Price_9_increase),0,dfBaseTableScore$Price_9_increase)
dfBaseTableScore$Price_12_increase<-ifelse(is.na(dfBaseTableScore$Price_12_increase),0,dfBaseTableScore$Price_12_increase)

#######################################################################################
# Commercial Operations related predictors
########################################################################################

ascore <- subset(dfCommercialOperations[,c(2:6)], 
                 dfCommercialOperations$Product_SKU %in% dfBaseTableScore$Product_SKU)


ascore <- na.omit(merge(ascore, dfBaseTableScore[,c(1:3)], by="Product_SKU", all=TRUE))

ascore$Discount_Start_Dt <- as.Date(ascore$Discount_Start_Dt)
ascore$Discount_End_Dt <- as.Date(ascore$Discount_End_Dt)
ascore$Anterior_Dt <- as.Date(ascore$Anterior_Dt)
ascore <- subset(ascore, (ascore$Anterior_Dt > ascore$Discount_Start_Dt & 
                            (ascore$Discount_Start_Dt > ascore$Anterior_Dt - 365)) )
#Create Variable counting nb of Commercial Operation with reduction and without.
ascore[,ncol(ascore)+1] <- 0
colnames(ascore)[ncol(ascore)] <- "Nb_ComOP_Reduction"
ascore[,ncol(ascore)] <- ifelse(ascore$Price==ascore$Price_After_Discount,0,1)

ascore[,ncol(ascore)+1] <- 0
colnames(ascore)[ncol(ascore)] <- "Nb_ComOP_No_Reduction"
ascore[,ncol(ascore)] <- ifelse(ascore$Price==ascore$Price_After_Discount,1,0)

#Counting nb of days of Commercial Operation with and without reduction
#Counting which is the lastest day
ascore[,ncol(ascore)+1] <- 0
colnames(ascore)[ncol(ascore)] <- "Date_Calcul"
ascore[,ncol(ascore)] <- ifelse(ascore$Anterior_Dt >= ascore$Discount_End_Dt, 
                                ascore$Discount_End_Dt, ascore$Anterior_Dt)
ascore$Date_Calcul <- as.Date(ascore$Date_Calcul, origin="1970-01-01")


ascore[,ncol(ascore)+1] <- 0
colnames(ascore)[ncol(ascore)] <- "Day_ComOP_Reduction"
ascore[,ncol(ascore)] <- ifelse(ascore$Nb_ComOP_Reduction==1,
                                ascore$Date_Calcul - ascore$Discount_Start_Dt,0)

ascore[,ncol(ascore)+1] <- 0
colnames(ascore)[ncol(ascore)] <- "Day_ComOP_No_Reduction"
ascore[,ncol(ascore)] <- ifelse(ascore$Nb_ComOP_No_Reduction==1,
                                ascore$Date_Calcul - ascore$Discount_Start_Dt,0)

#Aggregation by Product_SKU using SQL since Aggregate function produce strange output

ascore <- ascore[,c(1,8,9,11,12)]
a_names_score <- colnames(ascore)

ascore <- sqldf('Select Product_SKU, sum(Nb_ComOP_Reduction), sum(Nb_ComOP_No_Reduction),
                sum(Day_ComOP_Reduction), sum(Day_ComOP_No_Reduction)
                from ascore GROUP BY ascore.Product_SKU')

colnames(ascore) <- a_names_score 

#Calculate Average day per operation
ascore[,ncol(ascore)+1] <- round(ascore$Day_ComOP_Reduction/ascore$Nb_ComOP_Reduction)
colnames(ascore)[ncol(ascore)] <- "Day_Avg_ComOP_Reduction"
ascore[,ncol(ascore)] <- replace(ascore[,ncol(ascore)], ascore[,ncol(ascore)]=="NaN",0)

ascore[,ncol(ascore)+1] <- round(ascore$Day_ComOP_No_Reduction/ascore$Nb_ComOP_No_Reduction)
colnames(ascore)[ncol(ascore)] <- "Day_Avg_ComOP_No_Reduction"
ascore[,ncol(ascore)] <- replace(ascore[,ncol(ascore)], ascore[,ncol(ascore)]=="NaN",0)


#Merging the predictors with Scoring BaseTable

btrrScore <- merge.data.frame(ascore,dfBaseTableScore, by="Product_SKU", all.y=TRUE)

btrrScore$Nb_ComOP_Reduction <- replace(btrrScore$Nb_ComOP_Reduction, 
                                        is.na(btrrScore$Nb_ComOP_Reduction), 0)
btrrScore$Nb_ComOP_No_Reduction <- replace(btrrScore$Nb_ComOP_No_Reduction, 
                                           is.na(btrrScore$Nb_ComOP_No_Reduction), 0)
btrrScore$Day_ComOP_Reduction <- replace(btrrScore$Day_ComOP_Reduction, 
                                         is.na(btrrScore$Day_ComOP_Reduction), 0)
btrrScore$Day_ComOP_No_Reduction <- replace(btrrScore$Day_ComOP_No_Reduction, 
                                            is.na(btrrScore$Day_ComOP_No_Reduction), 0)
btrrScore$Day_Avg_ComOP_Reduction <- replace(btrrScore$Day_Avg_ComOP_Reduction, 
                                             is.na(btrrScore$Day_Avg_ComOP_Reduction), 0)
btrrScore$Day_Avg_ComOP_No_Reduction <- replace(btrrScore$Day_Avg_ComOP_No_Reduction, 
                                                is.na(btrrScore$Day_Avg_ComOP_No_Reduction), 0)

dfBaseTableScore<-btrrScore

####################################################################################
#product_associations
########################################################################################
ascore <- dfAssociationBtwnArticles

ascore <- subset(dfAssociationBtwnArticles, 
                 (dfAssociationBtwnArticles$Product_SKU %in% dfBaseTableScore$Product_SKU
                  &dfAssociationBtwnArticles$Asso_Prdt_SKU %in% dfSales$Product_SKU))

bscore <- dfProductClassifications
colnames(bscore)[1] <- "SKU_asso"
colnames(ascore)[2] <- "SKU_asso"

#Assign if Product Associated is a target_100 or not
ascore <- merge.data.frame(ascore,bscore[,c(1,11)], 
                           by=c("SKU_asso"), all.x=TRUE)
colnames(ascore)[length(ascore)] <- "Qte_Asso_Top_100"

#Number of Different association
ascore[,ncol(ascore)+1] <- 1
colnames(ascore)[ncol(ascore)] <- "Qte_Association"

#Separate Nb of Association when associated with a target 100 or not
ascore[,ncol(ascore)+1] <- ifelse(ascore$Qte_Asso_Top_100==0,ascore$No_Of_Associations,0)
colnames(ascore)[ncol(ascore)] <- "Nb_Asso"

ascore[,ncol(ascore)+1] <- ifelse(ascore$Qte_Asso_Top_100==1,ascore$No_Of_Associations,0)
colnames(ascore)[ncol(ascore)] <- "Nb_Asso_Top_100"

#Aggregate using SQL

ascore <- ascore[,c(2,3,6:9)]
a_names <- colnames(ascore)
ascore <- sqldf('Select Product_SKU, sum(No_Of_Associations), sum(Qte_Asso_Top_100),
                sum(Qte_Association), sum(Nb_Asso), sum(Nb_Asso_Top_100)
                from ascore GROUP BY ascore.Product_SKU')
colnames(ascore) <- a_names 

#Ratio
ascore[,ncol(ascore)+1] <- round((ascore$Nb_Asso_Top_100 / ascore$No_Of_Associations),2)
colnames(ascore)[ncol(ascore)] <- "Ratio_Nb_Asso_Top_100"

ascore[,ncol(ascore)+1] <- round((ascore$Qte_Asso_Top_100 / ascore$Qte_Association),2)
colnames(ascore)[ncol(ascore)] <- "Ratio_Qte_Association"

#merge with dfBasetableScore
btrrScore <- merge.data.frame(ascore,dfBaseTableScore,by="Product_SKU", all.y = TRUE)
btrrScore$No_Of_Associations <- replace(btrrScore$No_Of_Associations, 
                                        is.na(btrrScore$No_Of_Associations), 0)
btrrScore$Qte_Asso_Top_100 <- replace(btrrScore$Qte_Asso_Top_100, 
                                      is.na(btrrScore$Qte_Asso_Top_100), 0)
btrrScore$Qte_Association <- replace(btrrScore$Qte_Association, 
                                     is.na(btrrScore$Qte_Association), 0)
btrrScore$Nb_Asso <- replace(btrrScore$Nb_Asso, 
                             is.na(btrrScore$Nb_Asso), 0)
btrrScore$Nb_Asso_Top_100 <- replace(btrrScore$Nb_Asso_Top_100, 
                                     is.na(btrrScore$Nb_Asso_Top_100), 0)
btrrScore$Ratio_Nb_Asso_Top_100 <- replace(btrrScore$Ratio_Nb_Asso_Top_100, 
                                           is.na(btrrScore$Ratio_Nb_Asso_Top_100), 0)
btrrScore$Ratio_Qte_Association <- replace(btrrScore$Ratio_Qte_Association, 
                                           is.na(btrrScore$Ratio_Qte_Association), 0)

dfBaseTableScore<-btrrScore

####################################################################################
# Predictors related to front display. It will be zero in case of scoring base table
#
####################################################################################
##################Sales during FD vs. not during FD########
#Get all FD and its sales, plus anterior date

btrrScore<-merge.data.frame(dfBaseTableScore,Sales_During_FD,by=c("Product_SKU","Anterior_Dt"),all.x=TRUE)

#New predictors for change in quantity/amount between front display and non-front display before the anterior period
btrrScore$Total_Amount_FD=ifelse(is.na(btrrScore$Total_Amount_FD),0,btrrScore$Total_Amount_FD)
btrrScore$Total_Duration_FD=ifelse(is.na(btrrScore$Total_Duration_FD),0,btrrScore$Total_Duration_FD)

btrrScore$Avg_Amount_FD=ifelse(is.na(btrrScore$Avg_Amount_FD),0,btrrScore$Avg_Amount_FD)
btrrScore$Avg_Qty_FD=ifelse(is.na(btrrScore$Avg_Qty_FD),0,btrrScore$Avg_Qty_FD)

btrrScore$Total_Amount_UFD=btrrScore$Sum_Amount-btrrScore$Total_Amount_FD
btrrScore$Total_Duration_UFD=as.numeric((btrrScore$Anterior_Dt-as.Date("2015-01-02"))-btrrScore$Total_Duration_FD)
btrrScore$Avg_Sales_UFD = btrrScore$Total_Amount_UFD/btrrScore$Total_Duration_UFD
btrrScore$Diff_Sales_FD_UFD = btrrScore$Avg_Amount_FD-btrrScore$Avg_Sales_UFD
btrrScore$Diff_Percent_Sales_FD = btrrScore$Diff_Sales_FD_UFD/btrrScore$Avg_Sales_UFD*100
btrrScore$Diff_Sales_FD_UFD=ifelse(btrrScore$Diff_Sales_FD_UFD<=0,0,btrrScore$Diff_Sales_FD_UFD)
btrrScore$Diff_Percent_Sales_FD=ifelse(btrrScore$Diff_Percent_Sales_FD<=0,0,btrrScore$Diff_Percent_Sales_FD)
btrrScore$Diff_Percent_Sales_FD=ifelse(is.na(btrrScore$Diff_Percent_Sales_FD),0,btrrScore$Diff_Percent_Sales_FD)

dfBaseTableScore=btrrScore

# Removing the undesired columns before using the model to score
basetableScore<-btrrScore[,-c(2,16,17)]

# Scoring using the trained model
Scores = predict(xulllr, newdata = basetableScore)
Scores = cbind(basetableScore$Product_SKU,Scores)
colnames(Scores)[1] = ("Product_SKU")
colnames(Scores)[2] = ("Increase_Qty_Sales")

dfScores = data.frame(Scores)

#########################################################################################################
# Fetch all the details of the products present in the Scores file
#########################################################################################################

# To get product details
dfScoreDetails                        = inner_join(dfScores, dfProductClassifications, by = "Product_SKU")

# To get sales details
dfLatestSales                         = inner_join(dfScoreDetails, dfSalesSub, by = "Product_SKU")

# Create a subset with only the required columns
reqdCols                              = c("Product_SKU", "Quantity_Sold", "Amount_In_Euros", "Sales_Dt")
dfLatestSalesSub                      = dfLatestSales[, reqdCols]
dfLatestSalesSub$Sales_Dt             = as.Date(dfLatestSalesSub$Sales_Dt)

# To sort on Product_SKU, Sales_Dt in descending order
dfLatestSalesSub                      = dfLatestSalesSub[order(dfLatestSalesSub$Product_SKU, dfLatestSalesSub$Sales_Dt, decreasing = TRUE),]

# Get the latest Quantity_Sold, Amount_In_Euros per Product_SKU 
dfLatestSalesQtyAmt                   = aggregate(dfLatestSalesSub, list(dfLatestSalesSub$Product_SKU), FUN=head, 1)
dfLatestSalesQtyAmt$Group.1           = NULL
dfLatestSalesQtyAmt$Sales_Dt          = NULL
colnames(dfLatestSalesQtyAmt)         = c("Product_SKU", "Latest_Qty_Sold", "Latest_Amt_Sold")

# Combine the latest quantity and sales amount details with the product details and also calculate the increase of amount in euros
dfProductsScored                      = inner_join(dfScoreDetails,dfLatestSalesQtyAmt, by = "Product_SKU")
reqdCols                              = c("Product_SKU", "Product_Desc", "Aisle_No", "Aisle_Desc", "Latest_Qty_Sold", "Latest_Amt_Sold", "Increase_Qty_Sales")
dfProductsScored                      = dfProductsScored[, reqdCols]
dfProductsScored$Increase_Amt_Euro    = dfProductsScored$Latest_Amt_Sold * dfProductsScored$Increase_Qty_Sales

#########################################################################################################
# To find the best products to associate to a given product
#########################################################################################################

dfAssociationBtwnArticles         = dfAssociationBtwnArticles[order(dfAssociationBtwnArticles$Product_SKU),]
dfAssociationBtwnArticles$Change  = dfAssociationBtwnArticles$Avg_Asso_Qty_Trans2 -
  dfAssociationBtwnArticles$Avg_Qty_Tran1
dfAssoSub                         = subset(dfAssociationBtwnArticles, Change > 0 )

# To sort on Product_SKU, Change in descending order
dfAssoSub                         = dfAssoSub[order(dfAssoSub$Product_SKU, dfAssoSub$Change, decreasing = TRUE),]
reqdCols                          = c("Product_SKU", "Asso_Prdt_SKU", "Change")
dfAssoSub                         = dfAssoSub[, reqdCols]

# Fetch the top 3 associations for any Product_SKU
dfTop3Associations                = dfAssoSub %>%  group_by(Product_SKU) %>% slice(1:3)

# Give a ranking for the associated products
dfTop3AssoRanks                   = transform(dfTop3Associations, Ranking= ave(Change,Product_SKU,FUN=function(x) order(x,decreasing=T)))
dfTop3AssoRanks$Change            = NULL

# Transpose to get the 3 associated products for each Product_SKU in one record
dfTop3AssoTransposed              = cast(dfTop3AssoRanks, Product_SKU ~ Ranking, value = 'Asso_Prdt_SKU')
colnames(dfTop3AssoTransposed)    = c("Product_SKU", "Recomm_Prdt1", "Recomm_Prdt2", "Recomm_Prdt3")

#########################################################################################################
# Combine the scored products with the top 3 products to associate with them
#########################################################################################################

dfScoredProducts                  = left_join(dfProductsScored, dfTop3AssoTransposed, by = "Product_SKU")

#########################################################################################################
# Write the final scored data to a file
#########################################################################################################

write.table(dfScoredProducts, "./Recommendations.csv", sep = "|", row.names = TRUE, quote = FALSE, eol = "\n")

