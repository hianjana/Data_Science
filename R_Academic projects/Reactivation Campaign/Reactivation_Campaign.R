#Install all the required packages
install.packages("sqldf")
install.packages("gsubfn")
install.packages("proto")
install.packages("RSQLite")
install.packages("DBI")
install.packages("lubridate")
install.packages('rpart')
install.packages("C50")
install.packages("pROC")
install.packages("randomForest")
install.packages("ROCR")
install.packages("party")

#Call all the required libraries
library(sqldf)
library(dplyr)
library(lubridate)
library(rpart)
library(C50)
library(pROC)
library(randomForest)
library(memisc)
library(ROCR)
library(party)

## Part 1 - Basetable creation

# Read all the input files
dfselections = read.table("C:/Users/hianj/Documents/My studies/9-Descriptive and Predictive Analytics/Assignment/Data/selections.txt", header = TRUE)
dfdonors = read.table("C:/Users/hianj/Documents/My studies/9-Descriptive and Predictive Analytics/Assignment/Data/donors.txt", header = TRUE, fill = TRUE)

dfgifts = read.table("C:/Users/hianj/Documents/My studies/9-Descriptive and Predictive Analytics/Assignment/Data/gifts.txt", header = TRUE, fill = TRUE)
dfscore = read.table("C:/Users/hianj/Documents/My studies/9-Descriptive and Predictive Analytics/Assignment/Data/score.txt", header = TRUE)
dfcampaigns = read.table("C:/Users/hianj/Documents/My studies/9-Descriptive and Predictive Analytics/Assignment/Data/campaigns.txt", header = TRUE, sep="\t")

# Merge selections and gifts to create population using outer join
dfSelectGifts = merge(dfselections, dfgifts, by.dfselections = c("campId", "commId", "donorId"), all.x = TRUE)

#Create dfPopulation which has sum of amount given per donorId, campId
dfPopulation <- sqldf('SELECT campId, donorId, SUM(amount) AS Total_Amount FROM dfSelectGifts GROUP BY campId, donorId')

#Replace NAs to 0
dfPopulation[is.na(dfPopulation)] <- 0
dfSelectGifts[is.na(dfSelectGifts)] <- 0

# Transform the column Total_Amount from character to numeric
dfPopulation <- transform(dfPopulation, Total_Amount = as.numeric(Total_Amount))

# Merge dfPopulation with donors dataframe
dfBaseTable = merge(dfPopulation, dfdonors, by.dfPopulation = "donorId")

# Populate the column Target with 1 if it is greater than or equal to 30
dfBaseTable$Target[dfBaseTable$Total_Amount >= 30] <- 1

# Populate the column Target with 0 if it is lesser than 30
dfBaseTable$Target[dfBaseTable$Total_Amount < 30] <- 0

# Get unique campaign Id, commID and campaign date from campaigns dataframe
dfUniqueCampaigns <- sqldf('SELECT DISTINCT campId, date FROM dfcampaigns GROUP BY campId, commID')

# Merge dfBaseTable with dfUniqueCampaigns using campID
dfBaseTable <- merge(dfBaseTable, dfUniqueCampaigns, by = "campID")

# Rename 'date' to 'campDate' in Base table
colnames(dfBaseTable)[9] <- "campDate"

#Create dfPredictors by merging dfBaseTable and dfgifts
dfPredictors <- merge(dfBaseTable,dfgifts, by = "donorID", all.x = TRUE)

# Renaming columns in dfPredictors to make it meaningful
colnames(dfPredictors)[2] <- "campID"
colnames(dfPredictors)[10] <- "giftcampID"
colnames(dfPredictors)[11] <- "giftCommID"
colnames(dfPredictors)[12] <- "giftAmount"
colnames(dfPredictors)[13] <- "giftDate"

# Convert giftDate and campDate to character
dfPredictors <- transform(dfPredictors, giftDate = as.character(giftDate))
dfPredictors <- transform(dfPredictors, campDate = as.character(campDate))

# Convert giftDate and campDate from character to date
dfPredictors1 <- transform(dfPredictors, giftDate = as.Date(giftDate, "%d/%m/%Y"))
dfPredictors1 <- transform(dfPredictors1, campDate = as.Date(campDate, "%d%b%Y"))

# Create subset dfPredictorsSub from dfPredictors1 to have only records where gift date < campaign date
dfPredictorsSub <- subset(dfPredictors1, giftDate < campDate)

# Start to create predictors from dfPredictorsSub
# Predictor 1 - Min of giftAmount for all campaigns per donorId-campId
dfMinGift <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub GROUP BY donorID, campID')

# Predictor 2 - Max of giftAmount for all campaigns per donorId-campId
dfMaxGift <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub GROUP BY donorID, campID')

# Predictor 3 - Sum of giftAmount for all campaigns per donorId-campId
dfSumGift <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub GROUP BY donorID, campID')

# Predictor 4 - Number of gifts for all campaigns per donorId-campId
dfCountGift <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub GROUP BY donorID, campID')
colnames(dfCountGift)[1] <- "donorID"
colnames(dfCountGift)[2] <- "campID"
colnames(dfCountGift)[3] <- "countGifts"

# Predictor 5 - Mean of giftAmount for all campaigns per donorId-campId
dfMeanGift <- aggregate(dfPredictorsSub$giftAmount, by=list(dfPredictorsSub$donorID, dfPredictorsSub$campID),FUN=mean)
colnames(dfMeanGift)[1] <- "donorID"
colnames(dfMeanGift)[2] <- "campID"
colnames(dfMeanGift)[3] <- "meanGiftAmount"

# Predictor 6 - Median of giftAmount for all campaigns per donorId-campId
dfMedianGift <- aggregate(dfPredictorsSub$giftAmount, by=list(dfPredictorsSub$donorID, dfPredictorsSub$campID),FUN=median)
colnames(dfMedianGift)[1] <- "donorID"
colnames(dfMedianGift)[2] <- "campID"
colnames(dfMedianGift)[3] <- "medianGiftAmount"

# Predictor 7 - Latest gift date for all campaigns per donorID-campID
dfLatestgiftDate <- aggregate(dfPredictorsSub$giftDate, by=list(dfPredictorsSub$donorID, dfPredictorsSub$campID),FUN=max)
colnames(dfLatestgiftDate)[1] <- "donorID"
colnames(dfLatestgiftDate)[2] <- "campID"
colnames(dfLatestgiftDate)[3] <- "MaxGiftDate"

# Predictor 8 - First gift date for all campaigns per donorID-campID
dfFirstGiftDate <- aggregate(dfPredictorsSub$giftDate, by=list(dfPredictorsSub$donorID, dfPredictorsSub$campID),FUN=max)
colnames(dfFirstGiftDate)[1] <- "donorID"
colnames(dfFirstGiftDate)[2] <- "campID"
colnames(dfFirstGiftDate)[3] <- "MinGiftDate"

# Subsetting data for the latest 5 campaigns
dfLastFiveCampaigns <- dfPredictorsSub %>%
  group_by(donorID) %>%
  arrange(desc(giftDate)) %>%
  slice(1:5)

# Predictor 9 - Min of giftAmount for the latest 5 donations per donorID-campID
dfMinGiftLast5Dontns <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfLastFiveCampaigns GROUP BY donorID, campID')
colnames(dfMinGiftLast5Dontns)[1] <- "donorID"
colnames(dfMinGiftLast5Dontns)[2] <- "campID"
colnames(dfMinGiftLast5Dontns)[3] <- "minGiftLast5Dons"

# Predictor 10 - Max of giftAmount for the latest 5 donations per donorID-campID 
dfMaxGiftLast5Dontns <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfLastFiveCampaigns GROUP BY donorID, campID')
colnames(dfMaxGiftLast5Dontns)[1] <- "donorID"
colnames(dfMaxGiftLast5Dontns)[2] <- "campID"
colnames(dfMaxGiftLast5Dontns)[3] <- "maxGiftLast5Dons"

# Predictor 11 - Sum of giftAmount for the latest 5 donations per donorID-campID
dfSumGiftLast5Dontns <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfLastFiveCampaigns GROUP BY donorID, campID')
colnames(dfSumGiftLast5Dontns)[1] <- "donorID"
colnames(dfSumGiftLast5Dontns)[2] <- "campID"
colnames(dfSumGiftLast5Dontns)[3] <- "sumGiftLast5Dons"

# Predictor 12 - Mean of giftAmount for all campaigns per donorID-campID
dfMeanGiftLast5Dontns <- aggregate(dfLastFiveCampaigns$giftAmount, by=list(dfLastFiveCampaigns$donorID, dfLastFiveCampaigns$campID),FUN=mean)
colnames(dfMeanGiftLast5Dontns)[1] <- "donorID"
colnames(dfMeanGiftLast5Dontns)[2] <- "campID"
colnames(dfMeanGiftLast5Dontns)[3] <- "meanGiftAmount5dns"

# Predictor 13 - Median of giftAmount for all campaigns per donorID-campID
dfMedianGiftLast5Dontns <- aggregate(dfLastFiveCampaigns$giftAmount, by=list(dfLastFiveCampaigns$donorID,dfLastFiveCampaigns$campID),FUN=median)
colnames(dfMedianGiftLast5Dontns)[1] <- "donorID"
colnames(dfMedianGiftLast5Dontns)[2] <- "campID"
colnames(dfMedianGiftLast5Dontns)[3] <- "medianGiftAmount5dns"

# Predictor 14 - Latest gift date for all campaigns per donorID-campID
dfLatestgiftDateLast5Dontns <- aggregate(dfLastFiveCampaigns$giftDate, by=list(dfLastFiveCampaigns$donorID, dfLastFiveCampaigns$campID),FUN=max)
colnames(dfLatestgiftDateLast5Dontns)[1] <- "donorID"
colnames(dfLatestgiftDateLast5Dontns)[2] <- "campID"
colnames(dfLatestgiftDateLast5Dontns)[3] <- "LatestGiftDate5dns"

# Predictor 15 - First gift date for all campaigns per donorID-campID
dfFirstGiftDateLast5Dontns <- aggregate(dfLastFiveCampaigns$giftDate, by=list(dfLastFiveCampaigns$donorID, dfLastFiveCampaigns$campID),FUN=min)
colnames(dfFirstGiftDateLast5Dontns)[1] <- "donorID"
colnames(dfFirstGiftDateLast5Dontns)[2] <- "campID"
colnames(dfFirstGiftDateLast5Dontns)[3] <- "FirstGiftDate5dns"

# Added Latest Gift date for every donorId-campID
dfPredictorsSubMerged <- merge(dfPredictorsSub, dfLatestgiftDate, by.dfPredictorsSub = c("donorId", "campId"))

# Calculate the year difference between the giftDate per donorId to the MaxGiftDate
dfPredictorsSubMerged$yr_diff <-  as.period(new_interval(start = dfPredictorsSubMerged$giftDate, end = dfPredictorsSubMerged$MaxGiftDate))$year

# Subset those records for 0-3years
dfPredictorsSub3yrs <- subset(dfPredictorsSubMerged, yr_diff<=3)
# Subset those records for 0-5years
dfPredictorsSub5yrs <- subset(dfPredictorsSubMerged, yr_diff<=5)
# Subset those records for 0-10years
dfPredictorsSub10yrs <- subset(dfPredictorsSubMerged, yr_diff<=10)
# Subset those records for 0-20years
dfPredictorsSub20yrs <- subset(dfPredictorsSubMerged, yr_diff<=20)

# Predictor 16 - Min of giftAmount for 0-3 years per donorID-campID
dfMinGift3yrs <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub3yrs GROUP BY donorID, campID')
colnames(dfMinGift3yrs)[1] <- "donorID"
colnames(dfMinGift3yrs)[2] <- "campID"
colnames(dfMinGift3yrs)[3] <- "minGiftAmount3yrs"

# Predictor 17 - Max of giftAmount 0-3 years per donorID-campID
dfMaxGift3yrs <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub3yrs GROUP BY donorID, campID')
colnames(dfMaxGift3yrs)[1] <- "donorID"
colnames(dfMaxGift3yrs)[2] <- "campID"
colnames(dfMaxGift3yrs)[3] <- "maxGiftAmount3yrs"

# Predictor 18 - Sum of giftAmount 0-3 years per donorID-campID
dfSumGift3yrs <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub3yrs GROUP BY donorID, campID')
colnames(dfSumGift3yrs)[1] <- "donorID"
colnames(dfSumGift3yrs)[2] <- "campID"
colnames(dfSumGift3yrs)[3] <- "sumGiftAmount3yrs"

# Predictor 19 - Number of gifts 0-3 years per donorID-campID
dfCountGift3yrs <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub3yrs GROUP BY donorID, campID')
colnames(dfCountGift3yrs)[1] <- "donorID"
colnames(dfCountGift3yrs)[2] <- "campID"
colnames(dfCountGift3yrs)[3] <- "countGiftAmount3yrs"

# Predictor 20 - Mean of giftAmount 0-3 years per donorID-campID
dfMeanGift3yrs <- aggregate(dfPredictorsSub3yrs$giftAmount, by=list(dfPredictorsSub3yrs$donorID, dfPredictorsSub3yrs$campID),FUN=mean)
colnames(dfMeanGift3yrs)[1] <- "donorID"
colnames(dfMeanGift3yrs)[2] <- "campID"
colnames(dfMeanGift3yrs)[3] <- "meanGiftAmount3yrs"

# Predictor 21 - Median of giftAmount 0-3 years per donorID-campID
dfMedianGift3yrs <- aggregate(dfPredictorsSub3yrs$giftAmount, by=list(dfPredictorsSub3yrs$donorID, dfPredictorsSub3yrs$campID),FUN=median)
colnames(dfMedianGift3yrs)[1] <- "donorID"
colnames(dfMedianGift3yrs)[2] <- "campID"
colnames(dfMedianGift3yrs)[3] <- "medianGiftAmount3yrs"

# Predictor 22 - Latest gift date 0-3 years per donorID-campID
dfLatestgiftDate3yrs <- aggregate(dfPredictorsSub3yrs$giftDate, by=list(dfPredictorsSub3yrs$donorID, dfPredictorsSub3yrs$campID),FUN=max)
colnames(dfLatestgiftDate3yrs)[1] <- "donorID"
colnames(dfLatestgiftDate3yrs)[2] <- "campID"
colnames(dfLatestgiftDate3yrs)[3] <- "MaxGiftDate3yrs"

# Predictor 23 - First gift date 0-3 years per donorID-campID
dfFirstGiftDate3yrs <- aggregate(dfPredictorsSub3yrs$giftDate, by=list(dfPredictorsSub3yrs$donorID, dfPredictorsSub3yrs$campID),FUN=min)
colnames(dfFirstGiftDate3yrs)[1] <- "donorID"
colnames(dfFirstGiftDate3yrs)[2] <- "campID"
colnames(dfFirstGiftDate3yrs)[3] <- "MinGiftDate3yrs"

# Predictor 24 - Min of giftAmount for 0-5 years per donorID
dfMinGift5yrs <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub5yrs GROUP BY donorID, campID')
colnames(dfMinGift5yrs)[1] <- "donorID"
colnames(dfMinGift5yrs)[2] <- "campID"
colnames(dfMinGift5yrs)[3] <- "minGiftAmount5yrs"

# Predictor 25 - Max of giftAmount for 0-5 years  per donorID
dfMaxGift5yrs <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub5yrs GROUP BY donorID, campID')
colnames(dfMaxGift5yrs)[1] <- "donorID"
colnames(dfMaxGift5yrs)[2] <- "campID"
colnames(dfMaxGift5yrs)[3] <- "maxGiftAmount5yrs"

# Predictor 26 - Sum of giftAmount for 0-5 years per donorID
dfSumGift5yrs <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub5yrs GROUP BY donorID, campID')
colnames(dfSumGift5yrs)[1] <- "donorID"
colnames(dfSumGift5yrs)[2] <- "campID"
colnames(dfSumGift5yrs)[3] <- "sumGiftAmount5yrs"

# Predictor 27 - Number of gifts for 0-5 years per donorID
dfCountGift5yrs <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub5yrs GROUP BY donorID, campID')
colnames(dfCountGift5yrs)[1] <- "donorID"
colnames(dfCountGift5yrs)[2] <- "campID"
colnames(dfCountGift5yrs)[3] <- "countGiftAmount5yrs"

# Predictor 28 - Mean of giftAmount for 0-5 years per donorID
dfMeanGift5yrs <- aggregate(dfPredictorsSub5yrs$giftAmount, by=list(dfPredictorsSub5yrs$donorID, dfPredictorsSub5yrs$campID),FUN=mean)
colnames(dfMeanGift5yrs)[1] <- "donorID"
colnames(dfMeanGift5yrs)[2] <- "campID"
colnames(dfMeanGift5yrs)[3] <- "meanGiftAmount5yrs"

# Predictor 29 - Median of giftAmount for 0-5 years per donorID
dfMedianGift5yrs <- aggregate(dfPredictorsSub5yrs$giftAmount, by=list(dfPredictorsSub5yrs$donorID, dfPredictorsSub5yrs$campID),FUN=median)
colnames(dfMedianGift5yrs)[1] <- "donorID"
colnames(dfMedianGift5yrs)[2] <- "campID"
colnames(dfMedianGift5yrs)[3] <- "medianGiftAmount5yrs"

# Predictor 30 - Latest gift date for 0-5 years per donorID
dfLatestgiftDate5yrs <- aggregate(dfPredictorsSub5yrs$giftDate, by=list(dfPredictorsSub5yrs$donorID, dfPredictorsSub5yrs$campID),FUN=max)
colnames(dfLatestgiftDate5yrs)[1] <- "donorID"
colnames(dfLatestgiftDate5yrs)[2] <- "campID"
colnames(dfLatestgiftDate5yrs)[3] <- "MaxGiftDate5yrs"

# Predictor 31 - First gift date for 0-5 years per donorID
dfFirstGiftDate5yrs <- aggregate(dfPredictorsSub5yrs$giftDate, by=list(dfPredictorsSub5yrs$donorID, dfPredictorsSub5yrs$campID),FUN=min)
colnames(dfFirstGiftDate5yrs)[1] <- "donorID"
colnames(dfFirstGiftDate5yrs)[2] <- "campID"
colnames(dfFirstGiftDate5yrs)[3] <- "MinGiftDate5yrs"

# Predictor 32 - Min of giftAmount for 0-10 years per donorID-campID
dfMinGift10yrs <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub10yrs GROUP BY donorID, campID')
colnames(dfMinGift10yrs)[1] <- "donorID"
colnames(dfMinGift10yrs)[2] <- "campID"
colnames(dfMinGift10yrs)[3] <- "minGiftAmount10yrs"

# Predictor 33 - Max of giftAmount for 0-10 years  per donorID-campID
dfMaxGift10yrs <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub10yrs GROUP BY donorID, campID')
colnames(dfMaxGift10yrs)[1] <- "donorID"
colnames(dfMaxGift10yrs)[2] <- "campID"
colnames(dfMaxGift10yrs)[3] <- "maxGiftAmount10yrs"

# Predictor 34 - Sum of giftAmount for 0-10 years per donorID-campID
dfSumGift10yrs <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub10yrs GROUP BY donorID, campID')
colnames(dfSumGift10yrs)[1] <- "donorID"
colnames(dfSumGift10yrs)[2] <- "campID"
colnames(dfSumGift10yrs)[3] <- "sumGiftAmount10yrs"

# Predictor 35 - Number of gifts for 0-10 years per donorID-campID
dfCountGift10yrs <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub10yrs GROUP BY donorID, campID')
colnames(dfCountGift10yrs)[1] <- "donorID"
colnames(dfCountGift10yrs)[2] <- "campID"
colnames(dfCountGift10yrs)[3] <- "countGiftAmount10yrs"

# Predictor 36 - Mean of giftAmount for 0-10 years per donorID-campID
dfMeanGift10yrs <- aggregate(dfPredictorsSub10yrs$giftAmount, by=list(dfPredictorsSub10yrs$donorID, dfPredictorsSub10yrs$campID),FUN=mean)
colnames(dfMeanGift10yrs)[1] <- "donorID"
colnames(dfMeanGift10yrs)[2] <- "campID"
colnames(dfMeanGift10yrs)[3] <- "meanGiftAmount10yrs"

# Predictor 37 - Median of giftAmount for 0-10 years per donorID-campID
dfMedianGift10yrs <- aggregate(dfPredictorsSub10yrs$giftAmount, by=list(dfPredictorsSub10yrs$donorID, dfPredictorsSub10yrs$campID),FUN=median)
colnames(dfMedianGift10yrs)[1] <- "donorID"
colnames(dfMedianGift10yrs)[2] <- "campID"
colnames(dfMedianGift10yrs)[3] <- "medianGiftAmount10yrs"

# Predictor 38 - Latest gift date for 0-10 years per donorID-campID
dfLatestgiftDate10yrs <- aggregate(dfPredictorsSub10yrs$giftDate, by=list(dfPredictorsSub10yrs$donorID, dfPredictorsSub10yrs$campID),FUN=max)
colnames(dfLatestgiftDate10yrs)[1] <- "donorID"
colnames(dfLatestgiftDate10yrs)[2] <- "campID"
colnames(dfLatestgiftDate10yrs)[3] <- "MaxGiftDate10yrs"

# Predictor 39 - First gift date for 0-10 years per donorID-campID
dfFirstGiftDate10yrs <- aggregate(dfPredictorsSub10yrs$giftDate, by=list(dfPredictorsSub10yrs$donorID, dfPredictorsSub10yrs$campID),FUN=min)
colnames(dfFirstGiftDate10yrs)[1] <- "donorID"
colnames(dfFirstGiftDate10yrs)[2] <- "campID"
colnames(dfFirstGiftDate10yrs)[3] <- "MinGiftDate10yrs"

# Predictor 38 - Min of giftAmount for 0-20 years per donorID-campID
dfMinGift20yrs <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub20yrs GROUP BY donorID, campID')
colnames(dfMinGift20yrs)[1] <- "donorID"
colnames(dfMinGift20yrs)[2] <- "campID"
colnames(dfMinGift20yrs)[3] <- "minGiftAmount20yrs"

# Predictor 39 - Max of giftAmount for 0-20 years  per donorID-campID
dfMaxGift20yrs <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub20yrs GROUP BY donorID, campID')
colnames(dfMaxGift20yrs)[1] <- "donorID"
colnames(dfMaxGift20yrs)[2] <- "campID"
colnames(dfMaxGift20yrs)[3] <- "maxGiftAmount20yrs"

# Predictor 40 - Sum of giftAmount for 0-20 years per donorID-campID
dfSumGift20yrs <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub20yrs GROUP BY donorID, campID')
colnames(dfSumGift20yrs)[1] <- "donorID"
colnames(dfSumGift20yrs)[2] <- "campID"
colnames(dfSumGift20yrs)[3] <- "sumGiftAmount20yrs"

# Predictor 41 - Number of gifts for 0-20 years per donorID-campID
dfCountGift20yrs <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub20yrs GROUP BY donorID, campID')
colnames(dfCountGift20yrs)[1] <- "donorID"
colnames(dfCountGift20yrs)[2] <- "campID"
colnames(dfCountGift20yrs)[3] <- "countGiftAmount20yrs"

# Predictor 42 - Mean of giftAmount for 0-20 years per donorID-campID
dfMeanGift20yrs <- aggregate(dfPredictorsSub20yrs$giftAmount, by=list(dfPredictorsSub20yrs$donorID, dfPredictorsSub20yrs$campID),FUN=mean)
colnames(dfMeanGift20yrs)[1] <- "donorID"
colnames(dfMeanGift20yrs)[2] <- "campID"
colnames(dfMeanGift20yrs)[3] <- "meanGiftAmount20yrs"

# Predictor 43 - Median of giftAmount for 0-20 years per donorID-campID
dfMedianGift20yrs <- aggregate(dfPredictorsSub20yrs$giftAmount, by=list(dfPredictorsSub20yrs$donorID, dfPredictorsSub20yrs$campID),FUN=median)
colnames(dfMedianGift20yrs)[1] <- "donorID"
colnames(dfMedianGift20yrs)[2] <- "campID"
colnames(dfMedianGift20yrs)[3] <- "medianGiftAmount20yrs"

# Predictor 44 - Latest gift date for 0-20 years per donorID-campID
dfLatestgiftDate20yrs <- aggregate(dfPredictorsSub20yrs$giftDate, by=list(dfPredictorsSub20yrs$donorID, dfPredictorsSub20yrs$campID),FUN=max)
colnames(dfLatestgiftDate20yrs)[1] <- "donorID"
colnames(dfLatestgiftDate20yrs)[2] <- "campID"
colnames(dfLatestgiftDate20yrs)[3] <- "MaxGiftDate20yrs"

# Predictor 45 - First gift date for 0-20 years per donorID-campID
dfFirstGiftDate20yrs <- aggregate(dfPredictorsSub20yrs$giftDate, by=list(dfPredictorsSub20yrs$donorID, dfPredictorsSub20yrs$campID),FUN=min)
colnames(dfFirstGiftDate20yrs)[1] <- "donorID"
colnames(dfFirstGiftDate20yrs)[2] <- "campID"
colnames(dfFirstGiftDate20yrs)[3] <- "MinGiftDate20yrs"

# Merge all the predictors
dfBaseTablePredictors <- merge(dfPredictorsSub, dfMinGift, by.dfPredictorsSub = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGift, by.dfBaseTablePredictors = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGift, by.dfBaseTablePredictors = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfCountGift, by.dfBaseTablePredictors = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGift, by.dfBaseTablePredictors = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGift, by.dfBaseTablePredictors = c("donorId","campId"))
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfLatestgiftDate, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfFirstGiftDate, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMinGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfCountGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGift3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfLatestgiftDate3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfFirstGiftDate3yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMinGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfCountGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGift5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfLatestgiftDate5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfFirstGiftDate5yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMinGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfCountGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGift10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfLatestgiftDate10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfFirstGiftDate10yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMinGiftLast5Dontns, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGiftLast5Dontns, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGiftLast5Dontns, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGiftLast5Dontns, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGiftLast5Dontns, by.dfBaseTablePredictors= c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMinGift20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMaxGift20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfSumGift20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfCountGift20yrs, by.dfBaseTablePredictors= c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMeanGift20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfMedianGift20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfLatestgiftDate20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictors <- merge(dfBaseTablePredictors, dfFirstGiftDate20yrs, by.dfBaseTablePredictors = c("donorId","campId"),all.x = TRUE)

# Renaming columns and also dropping campDate
dfBaseTablePredictors$campDate= NULL

colnames(dfBaseTablePredictors)[13] <- "minGiftAmount"
colnames(dfBaseTablePredictors)[14] <- "maxGiftAmount"
colnames(dfBaseTablePredictors)[15] <- "sumGiftAmount"

# Deleting all the dates
dfBaseTablePredictors$giftDate =NULL
dfBaseTablePredictors$MaxGiftDate =NULL
dfBaseTablePredictors$MinGiftDate =NULL
dfBaseTablePredictors$MaxGiftDate3yrs =NULL
dfBaseTablePredictors$MinGiftDate3yrs =NULL
dfBaseTablePredictors$MaxGiftDate5yrs =NULL
dfBaseTablePredictors$MinGiftDate5yrs =NULL
dfBaseTablePredictors$MaxGiftDate10yrs =NULL
dfBaseTablePredictors$MinGiftDate10yrs =NULL
dfBaseTablePredictors$MaxGiftDate20yrs =NULL
dfBaseTablePredictors$MinGiftDate20yrs =NULL

# Zipcode to region Mapping
# Deleting chars in predictors table
dfBaseTablePredictors <-dfBaseTablePredictors[!(dfBaseTablePredictors$zipcode=="SW6"),]
dfBaseTablePredictors <-dfBaseTablePredictors[!(dfBaseTablePredictors$zipcode=="Missing"),]

dfBaseTablePredictors$zipcode=as.numeric(as.character(dfBaseTablePredictors$zipcode))

# Replacing zipcodes with provinces (Source:wikipedia)
dfBaseTablePredictors$region=cases("BCR"<-dfBaseTablePredictors$zipcode<1300,
                                   "WB"<-dfBaseTablePredictors$zipcode>1299 & dfBaseTablePredictors$zipcode<1500,
                                   "FB"<-dfBaseTablePredictors$zipcode>1499 & dfBaseTablePredictors$zipcode<2000,
                                   "AW"<-dfBaseTablePredictors$zipcode>1999 & dfBaseTablePredictors$zipcode<3000,
                                   "FB"<-dfBaseTablePredictors$zipcode>2999 & dfBaseTablePredictors$zipcode<3500,
                                   "LB"<-dfBaseTablePredictors$zipcode>3499 & dfBaseTablePredictors$zipcode<4000,
                                   "LI"<-dfBaseTablePredictors$zipcode>3999 & dfBaseTablePredictors$zipcode<5000,
                                   "NA"<-dfBaseTablePredictors$zipcode>4999 & dfBaseTablePredictors$zipcode<6000,
                                   "HN"<-dfBaseTablePredictors$zipcode>5999 & dfBaseTablePredictors$zipcode<6600,
                                   "LX"<-dfBaseTablePredictors$zipcode>6599 & dfBaseTablePredictors$zipcode<7000,
                                   "HN"<-dfBaseTablePredictors$zipcode>6999 & dfBaseTablePredictors$zipcode<8000,
                                   "WF"<-dfBaseTablePredictors$zipcode>7999 & dfBaseTablePredictors$zipcode<9000,
                                   "EF"<-dfBaseTablePredictors$zipcode>8999 & dfBaseTablePredictors$zipcode<10000,
                                   "Missing"<-dfBaseTablePredictors$zipcode =="NA" | dfBaseTablePredictors$zipcode == 0)

# Region Binary Variables
dfBaseTablePredictors$BCR = ifelse(dfBaseTablePredictors$region=="BCR",1,0)
dfBaseTablePredictors$WB = ifelse(dfBaseTablePredictors$region=="WB",1,0)
dfBaseTablePredictors$FB = ifelse(dfBaseTablePredictors$region=="FB",1,0)
dfBaseTablePredictors$AW = ifelse(dfBaseTablePredictors$region=="AW",1,0)
dfBaseTablePredictors$LB = ifelse(dfBaseTablePredictors$region=="LB",1,0)
dfBaseTablePredictors$LI = ifelse(dfBaseTablePredictors$region=="LI",1,0)
dfBaseTablePredictors$NAM = ifelse(dfBaseTablePredictors$region=="NA",1,0)
dfBaseTablePredictors$HN = ifelse(dfBaseTablePredictors$region=="HN",1,0)
dfBaseTablePredictors$LX = ifelse(dfBaseTablePredictors$region=="LX",1,0)
dfBaseTablePredictors$WF = ifelse(dfBaseTablePredictors$region=="WF",1,0)
dfBaseTablePredictors$EF = ifelse(dfBaseTablePredictors$region=="EF",1,0)
dfBaseTablePredictors$region  = NULL

# Language Binary Variable French = 1, Dutch = 0
dfBaseTablePredictors$language <- as.character(dfBaseTablePredictors$language)
dfBaseTablePredictors$language  = ifelse(dfBaseTablePredictors$language=="F", 1, 0)

# Gender Binary Variables
dfBaseTablePredictors$males = ifelse(dfBaseTablePredictors$gender=="M",1,0)
dfBaseTablePredictors$females = ifelse(dfBaseTablePredictors$gender=="F",1,0)
dfBaseTablePredictors$companies = ifelse(dfBaseTablePredictors$gender=="S",1,0)
dfBaseTablePredictors$couples = ifelse(dfBaseTablePredictors$gender=="C",1,0)
dfBaseTablePredictors$unknown = ifelse(dfBaseTablePredictors$gender=="U",1,0)
dfBaseTablePredictors$gender = NULL

# meangiftamount <30 = 0####
dfBaseTablePredictors$meanGiftAmount = ifelse(dfBaseTablePredictors$meanGiftAmount >= 30, 1,0)

# Replace NAs to 0
dfBaseTablePredictors[is.na(dfBaseTablePredictors)] <- 0
dfBaseTablePredictors$Total_Amount= NULL

# Drop campID from Base Predictors and get unique records
dfBaseTablePredictors$campID = NULL
dfBaseTablePredictors = unique (dfBaseTablePredictors)


## Part 2 - Model Building

# Create Train, Test and Validation
dfBaseTablePredictorspart <- sample(3, nrow(dfBaseTablePredictors), replace = TRUE, prob = c(0.5, 0.2, 0.3))
dfBaseTablePredictorstrain <- dfBaseTablePredictors[dfBaseTablePredictorspart==1,]
dfBaseTablePredictorstest <- dfBaseTablePredictors[dfBaseTablePredictorspart==2,]
dfBaseTablePredictorsvali <- dfBaseTablePredictors[dfBaseTablePredictorspart==3,]

# Selection of variables
vars = names(dfBaseTablePredictorstrain)[which(names(dfBaseTablePredictorstrain)!="Target")]
selected = c()
for(v in vars){
  pvalue= (cor.test(dfBaseTablePredictorstrain[,v],dfBaseTablePredictorstrain$Target,method="pearson"))$p.value
  if(pvalue<0.05){
    selected = c(selected,v)
  }
}

# Adding all the selected variables and a new variable - Target
dfBaseTablePredictorstrain = dfBaseTablePredictorstrain[,c(selected,"Target")]
dfBaseTablePredictorstest = dfBaseTablePredictorstest[,c(selected,"Target")]
dfBaseTablePredictorsvali = dfBaseTablePredictorsvali[,c(selected,"Target")]

# Random forest
modelrf = randomForest(Target ~ .-donorID, data=dfBaseTablePredictorstrain, importance=TRUE, ntree=100)
predictrftest = predict(modelrf ,newdata=dfBaseTablePredictorstest)
predictrftrain = predict(modelrf ,newdata=dfBaseTablePredictorstrain)
predictrfvali = predict(modelrf ,newdata=dfBaseTablePredictorsvali)
evtestrf = cbind(predictrftest, dfBaseTablePredictorstest$Target)
colnames(evtestrf)=c("predict","target")
evtrainrf = cbind(predictrftrain, dfBaseTablePredictorstrain$Target)
colnames(evtrainrf)=c("predict","target")
evvalirf = cbind(predictrfvali, dfBaseTablePredictorsvali$Target)
colnames(evvalirf)=c("predict","target")
plot(roc(target ~ predict, data=evtrainrf))
plot(roc(target ~ predict, data=evtestrf),add=T)
plot(roc(target ~ predict, data=evvalirf),add=T)
plot(roc(target~predict,data=evtestrf))

#create the graph of the random forest but takes a lot of time (hours)
#colors=c("red","blue","green")
#i=1
#for(ntree in c(250,500,1000)){
#modelrf = randomForest(Target ~., data=dfBaseTablePredictorstrain, importance=TRUE, ntree=ntree)
#predictrftest = predict(modelrf ,newdata=dfBaseTablePredictorstest)
#evtestrf = cbind(predictrftest, dfBaseTablePredictorstest$Target)
#colnames(evtestrf)=c("predict","target")
#plot(roc(target ~ predict, data=evtestrf),add=T,col=colors[i])
#i=i+1
#}

# Logistic_steps_regression
nothing = glm( Target ~ 1, data=dfBaseTablePredictorstrain, family = binomial)
fullmod = glm( Target ~ .-donorID, data=dfBaseTablePredictorstrain, family = binomial)
modelfw = step(nothing, scope=formula(fullmod), data=dfBaseTablePredictorstrain, direction = "forward") 
summary(modelfw)

# Choose the best guy
meangift_coefficient = names(modelfw$coefficients)

# Create the final model
auctrain = rep(0, length(meangift_coefficient)-1)
auctest = rep(0, length(meangift_coefficient)-1)
aucvali = rep(0, length(meangift_coefficient)-1)
for(i in c(1:(length(meangift_coefficient)-1))) {
  meangift_step = meangift_coefficient[2:(i+1)]
  formula <-paste("Target","~", paste (meangift_step,collapse="+"))
  model <- glm(formula,data=dfBaseTablePredictorstrain, family="binomial")
  predicttrain <- predict(model, newdata=dfBaseTablePredictorstrain, type="response")
  predicttest <- predict(model, newdata=dfBaseTablePredictorstest, type="response")
  predictvali <- predict(model, newdata=dfBaseTablePredictorsvali, type="response")
  evtrain = cbind(predicttrain, dfBaseTablePredictorstrain$Target)
  colnames(evtrain) = c("predict","Target")
  evttest = cbind(predicttest, dfBaseTablePredictorstest$Target)
  colnames(evttest) = c("predict","Target")
  evtvali = cbind(predictvali, dfBaseTablePredictorsvali$Target)
  colnames(evtvali) = c("predict","Target")
  auctrain [i] = roc(Target ~ predict, data = evtrain)$auc
  auctest[i] = roc(Target ~ predict, data = evttest)$auc
  aucvali[i] = roc(Target ~ predict, data = evtvali)$auc
}

# Plot
plot(auctrain, main="AUC", col="red")
par(new=TRUE)
plot(auctest, col="blue", add=TRUE)
plot(aucvali, col="green", add=TRUE)


#ctree
#plot
subdfBaseTablePredictorstrain <- dfBaseTablePredictorstrain
subdfBaseTablePredictorstrain$donorID = NULL
ctree_model = ctree(Target ~ ., data = subdfBaseTablePredictorstrain, controls = ctree_control(mincriterion = 0.99, minsplit= 30))
plot(ctree_model, inner_pannel=node_inner)


# Tree_classification
tree_classification <- rpart( Target ~ .-donorID, data = dfBaseTablePredictorstrain, method = "class", cp=0.0001)
summary(tree_classification)

# Tree graphic
plot(tree_classification)
# add the description of each leaf to the graph
text(tree_classification, use.n = TRUE, all=  TRUE, cex=.8)

# Logistic regression
logistic_regression <- glm( formula = Target ~ .-donorID, data = dfBaseTablePredictorstrain, family = "binomial")
summary(logistic_regression)

# Predict_probit
predict_probit_test = predict(probit,newdata = dfBaseTablePredictorstest) 
predict_probit_train = predict(probit,newdata = dfBaseTablePredictorstrain)
predict_probit_vali = predict(probit,newdata = dfBaseTablePredictorsvali)
#evaluation_probit
evaluation_test_probit = cbind(predict_probit_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_probit)= c ("predict","target")
evaluation_train_probit = cbind(predict_probit_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_probit)= c ("predict","target")
evaluation_vali_probit = cbind(predict_probit_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_probit)= c ("predict","target")

# Probit model # AIC : 95962
# Where is minGiftAmount10yrs
# Where is maxGiftAmount10yrs
probit <- glm(Target ~ .-donorID, family=binomial(link="probit"), data=dfBaseTablePredictorstrain)
summary(probit)


# Predict_probit
predict_probit_test = predict(probit,newdata = dfBaseTablePredictorstest) 
predict_probit_train = predict(probit,newdata = dfBaseTablePredictorstrain)
predict_probit_vali = predict(probit,newdata = dfBaseTablePredictorsvali)
# evaluation_probit
evaluation_test_probit = cbind(predict_probit_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_probit)= c ("predict","target")
evaluation_train_probit = cbind(predict_probit_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_probit)= c ("predict","target")
evaluation_vali_probit = cbind(predict_probit_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_probit)= c ("predict","target")

# Predict_ctree_model
predict_ctree_model_test = predict(ctree_model,newdata = dfBaseTablePredictorstest) 
predict_ctree_model_train = predict(ctree_model,newdata = dfBaseTablePredictorstrain) 
predict_ctree_model_vali = predict(ctree_model,newdata = dfBaseTablePredictorsvali) 

# Evaluation_classification_tree
evaluation_test_ctree_model = cbind(predict_ctree_model_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_ctree_model)= c ("predict","target")
evaluation_train_ctree_model = cbind(predict_ctree_model_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_ctree_model)= c ("predict","target")
evaluation_vali_ctree_model = cbind(predict_ctree_model_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_ctree_model)= c ("predict","target")

# Predict_classification_tree
predict_tree_classification_test = predict(tree_classification,newdata = dfBaseTablePredictorstest) [,2]
predict_tree_classification_train = predict(tree_classification,newdata = dfBaseTablePredictorstrain) [,2]
predict_tree_classification_vali = predict(tree_classification,newdata = dfBaseTablePredictorsvali) [,2]

# Evaluation_classification_tree
evaluation_test_classification = cbind(predict_tree_classification_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_classification)= c ("predict","target")
evaluation_train_classification = cbind(predict_tree_classification_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_classification)= c ("predict","target")
evaluation_vali_classification = cbind(predict_tree_classification_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_classification)= c ("predict","target")

# Predict_logistic_regression
predict_logistic_regression_test = predict(logistic_regression,newdata = dfBaseTablePredictorstest) 
predict_logistic_regression_train = predict(logistic_regression,newdata = dfBaseTablePredictorstrain)
predict_logistic_regression_vali = predict(logistic_regression,newdata = dfBaseTablePredictorsvali)

# Evaluation_logistic_regression
evaluation_test_logistic = cbind(predict_logistic_regression_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_logistic)= c ("predict","target")
evaluation_train_logistic = cbind(predict_logistic_regression_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_logistic)= c ("predict","target")
evaluation_vali_logistic = cbind(predict_logistic_regression_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_logistic)= c ("predict","target")

# Predict_logistic_stepwise
predict_logistic_stepwise_test = predict(modelfw,newdata = dfBaseTablePredictorstest) 
predict_logistic_stepwise_train = predict(modelfw,newdata = dfBaseTablePredictorstrain)
predict_logistic_stepwise_vali = predict(modelfw,newdata = dfBaseTablePredictorsvali)

# Evaluation_logistic_stepwise
evaluation_test_logistic_stepwise = cbind(predict_logistic_stepwise_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_logistic_stepwise)= c ("predict","target")
evaluation_train_logistic_stepwise = cbind(predict_logistic_stepwise_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_logistic_stepwise)= c ("predict","target")
evaluation_vali_logistic_stepwise = cbind(predict_logistic_stepwise_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_logistic_stepwise)= c ("predict","target")

# Predict_random_forest
predict_random_forest_test = predict(modelrf,newdata = dfBaseTablePredictorstest) 
predict_random_forest_train = predict(modelrf,newdata = dfBaseTablePredictorstrain)
predict_random_forest_vali = predict(modelrf,newdata = dfBaseTablePredictorsvali)

# Evaluation_random_forest
evaluation_test_random_forest = cbind(predict_random_forest_test, dfBaseTablePredictorstest$Target) 
colnames(evaluation_test_random_forest)= c ("predict","target")
evaluation_train_random_forest = cbind(predict_random_forest_train, dfBaseTablePredictorstrain$Target) 
colnames(evaluation_train_random_forest)= c ("predict","target")
evaluation_vali_random_forest = cbind(predict_random_forest_vali, dfBaseTablePredictorsvali$Target) 
colnames(evaluation_vali_random_forest)= c ("predict","target")

# ROC curve
plot(roc(target ~ predict, data = evaluation_train_random_forest ))
plot(roc(target ~ predict, data = evaluation_test_random_forest ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_random_forest ), add=TRUE, col="green")
plot(roc(target ~ predict, data = evaluation_train_probit ))
plot(roc(target ~ predict, data = evaluation_test_probit ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_probit ), add=TRUE, col="green")
plot(roc(target ~ predict, data = evaluation_train_logistic ))
plot(roc(target ~ predict, data = evaluation_test_logistic ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_logistic ), add=TRUE, col="green")
plot(roc(target ~ predict, data = evaluation_train_ctree_model ))
plot(roc(target ~ predict, data = evaluation_test_ctree_model ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_ctree_model ), add=TRUE, col="green")
plot(roc(target ~ predict, data = evaluation_train_classification ))
plot(roc(target ~ predict, data = evaluation_test_classification ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_classification ), add=TRUE, col="green")
plot(roc(target ~ predict, data = evaluation_train_logistic_stepwise ))
plot(roc(target ~ predict, data = evaluation_test_logistic_stepwise ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_vali_logistic_stepwise ), add=TRUE, col="green")

#ROC comparing all models together
plot(roc(target ~ predict, data = evaluation_test_logistic ))
plot(roc(target ~ predict, data = evaluation_test_probit ), add=TRUE, col="red")
plot(roc(target ~ predict, data = evaluation_test_logistic_stepwise ), add=TRUE, col="orange")
plot(roc(target ~ predict, data = evaluation_test_ctree_model ), add=TRUE, col="purple")
plot(roc(target ~ predict, data = evaluation_test_classification ), add=TRUE, col="blue")
plot(roc(target ~ predict, data = evaluation_train_random_forest ), add=TRUE, col="green")

# AUC
auc = matrix(0,3,6)
colnames(auc)=c("PR","LR","CT","RF","LS","CM")
rownames(auc)=c("train","test","validation")
auc[1,1]=roc(target ~ predict, data = evaluation_train_probit)$auc
auc[1,2]=roc(target ~ predict, data = evaluation_train_logistic)$auc
auc[1,3]=roc(target ~ predict, data = evaluation_train_ctree_model)$auc
auc[1,4]=roc(target ~ predict, data = evaluation_train_classification)$auc
auc[1,5]=roc(target ~ predict, data = evaluation_train_random_forest)$auc
auc[1,6]=roc(target ~ predict, data = evaluation_train_logistic_stepwise)$auc
auc[2,1]=roc(target ~ predict, data = evaluation_test_probit)$auc
auc[2,2]=roc(target ~ predict, data = evaluation_test_logistic)$auc
auc[2,3]=roc(target ~ predict, data = evaluation_test_ctree_model)$auc
auc[2,4]=roc(target ~ predict, data = evaluation_test_classification)$auc
auc[2,5]=roc(target ~ predict, data = evaluation_test_random_forest)$auc
auc[2,6]=roc(target ~ predict, data = evaluation_test_logistic_stepwise)$auc
auc[3,1]=roc(target ~ predict, data = evaluation_vali_probit)$auc
auc[3,2]=roc(target ~ predict, data = evaluation_vali_logistic)$auc
auc[3,3]=roc(target ~ predict, data = evaluation_vali_ctree_model)$auc
auc[3,4]=roc(target ~ predict, data = evaluation_vali_classification)$auc
auc[3,5]=roc(target ~ predict, data = evaluation_vali_random_forest)$auc
auc[3,6]=roc(target ~ predict, data = evaluation_vali_logistic_stepwise)$auc

# Lift graph logistic (test/train/validation)
pred <- prediction(evaluation_test_logistic[,1],evaluation_test_logistic[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_logistic[,1],evaluation_train_logistic[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_logistic[,1],evaluation_vali_logistic[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Lift graph probit (test/train/validation)
pred <- prediction(evaluation_test_probit[,1],evaluation_test_probit[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_probit[,1],evaluation_train_probit[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_probit[,1],evaluation_vali_probit[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Lift graph ctree (test/train/validation)
pred <- prediction(evaluation_test_ctree_model[,1],evaluation_test_ctree_model[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_ctree_model[,1],evaluation_train_ctree_model[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_ctree_model[,1],evaluation_vali_ctree_model[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Lift graph classification (test/train/validation)
pred <- prediction(evaluation_test_classification[,1],evaluation_test_classification[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_classification[,1],evaluation_train_classification[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_classification[,1],evaluation_vali_classification[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Lift graph logistic stepwise (test/train/validation)
pred <- prediction(evaluation_test_logistic_stepwise[,1],evaluation_test_logistic_stepwise[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_logistic_stepwise[,1],evaluation_train_logistic_stepwise[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_logistic_stepwise[,1],evaluation_vali_logistic_stepwise[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Lift graph random forest (test/train/validation)
pred <- prediction(evaluation_test_random_forest[,1],evaluation_test_random_forest[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue")
pred <- prediction(evaluation_train_random_forest[,1],evaluation_train_random_forest[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red",add=TRUE)
pred <- prediction(evaluation_vali_random_forest[,1],evaluation_vali_random_forest[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

#lift curve comparing all the models

pred <- prediction(evaluation_test_logistic[,1],evaluation_test_logistic[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="black",add=TRUE)
pred <- prediction(evaluation_test_probit[,1],evaluation_test_probit[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="red")
pred <- prediction(evaluation_test_logistic_stepwise[,1],evaluation_test_logistic_stepwise[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="orange",add=TRUE)
pred <- prediction(evaluation_test_ctree_model[,1],evaluation_test_ctree_model[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="purple",add=TRUE)
pred <- prediction(evaluation_test_classification[,1],evaluation_test_classification[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="blue",add=TRUE)
pred <- prediction(evaluation_test_random_forest[,1],evaluation_test_random_forest[,2])
perf <- performance(pred,"lift","rpp")
plot(perf, main="lift curve", col="green",add=TRUE)

# Cumulative curve logistic (test/train/validation)
pred <- prediction(evaluation_test_logistic[,1],evaluation_test_logistic[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_logistic[,1],evaluation_train_logistic[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_logistic[,1],evaluation_vali_logistic[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

# Cumulative curve probit (test/train/validation)
pred <- prediction(evaluation_test_probit[,1],evaluation_test_probit[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_probit[,1],evaluation_train_probit[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_probit[,1],evaluation_vali_probit[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

# Cumulative curve ctree (test/train/validation)
pred <- prediction(evaluation_test_ctree_model[,1],evaluation_test_ctree_model[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_ctree_model[,1],evaluation_train_ctree_model[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_ctree_model[,1],evaluation_vali_ctree_model[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

# Cumulative curve classification tree (test/train/validation)
pred <- prediction(evaluation_test_classification[,1],evaluation_test_classification[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_classification[,1],evaluation_train_classification[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_classification[,1],evaluation_vali_classification[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

# Cumulative curve logistic stepwise (test/train/validation)
pred <- prediction(evaluation_test_logistic_stepwise[,1],evaluation_test_logistic_stepwise[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_logistic_stepwise[,1],evaluation_train_logistic_stepwise[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_logistic_stepwise[,1],evaluation_vali_logistic_stepwise[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

# Cumulative curve random forest (test/train/validation)
pred <- prediction(evaluation_test_random_forest[,1],evaluation_test_random_forest[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue")
pred <- prediction(evaluation_train_random_forest[,1],evaluation_train_random_forest[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red",add=TRUE)
pred <- prediction(evaluation_vali_random_forest[,1],evaluation_vali_random_forest[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)


#Cumulative curve all model
pred <- prediction(evaluation_test_logistic[,1],evaluation_test_logistic[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="black",add=TRUE)
pred <- prediction(evaluation_test_probit[,1],evaluation_test_probit[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="red")
pred <- prediction(evaluation_test_logistic_stepwise[,1],evaluation_test_logistic_stepwise[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="orange",add=TRUE)
pred <- prediction(evaluation_test_ctree_model[,1],evaluation_test_ctree_model[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="purple",add=TRUE)
pred <- prediction(evaluation_test_classification[,1],evaluation_test_classification[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="blue",add=TRUE)
pred <- prediction(evaluation_test_random_forest[,1],evaluation_test_random_forest[,2])
perf <- performance(pred,"tpr","fpr")
plot(perf, main="cumulative gains", col="green",add=TRUE)

## Part 3 - Calculating score using CTree

#Remove commID & campID from dfScore
dfscore$commID = NULL
dfscore$campID = NULL

# Merge dfdonors and dfscore to get the details of all the donors present in Scores.txt
dbScoresDonors = merge(dfscore, dfdonors, by.dfscore = "donorId")

dfBaseTableScores = merge(dbScoresDonors, dfPopulation, dbScoresDonors = "donorId")

# Populate the column Target with 1 if it is greater than or equal to 30
dfBaseTableScores$Target[dfBaseTableScores$Total_Amount >= 30] <- 1

# Populate the column Target with 0 if it is lesser than 30
dfBaseTableScores$Target[dfBaseTableScores$Total_Amount < 30] <- 0

# dfUniqueCampaigns created in Part 1 will be reused here
# Merge dfBaseTable with dfUniqueCampaigns using campID
dfBaseTableScores <- merge(dfBaseTableScores, dfUniqueCampaigns, by = "campID")

# Rename 'date' to 'campDate' in Base table
colnames(dfBaseTableScores)[9] <- "campDate"

#Create dfPredictorsTable_Scores by merging dfBaseTableScores and dfgifts (which was created in Part 1)
dfPredictorsTable_Scores <- merge(dfBaseTableScores,dfgifts, by = "donorID", all.x = TRUE)

# Renaming columns in dfPredictorsTable_Scores to make it meaningful
colnames(dfPredictorsTable_Scores)[2] <- "campID"
colnames(dfPredictorsTable_Scores)[10] <- "giftcampID"
colnames(dfPredictorsTable_Scores)[11] <- "giftCommID"
colnames(dfPredictorsTable_Scores)[12] <- "giftAmount"
colnames(dfPredictorsTable_Scores)[13] <- "giftDate"

# Convert giftDate and campDate to character
dfPredictorsTable_Scores <- transform(dfPredictorsTable_Scores, giftDate = as.character(giftDate))

# Convert giftDate from character to date
dfPredictorsTable_Scores1 <- transform(dfPredictorsTable_Scores, giftDate = as.Date(giftDate, "%d/%m/%Y"))
dfPredictorsTable_Scores1 <- transform(dfPredictorsTable_Scores1, campDate = as.Date(campDate, "%d%b%Y"))

# Create subset dfBasePredictorsTable_Scores from dfPredictorsTable_Scores1 to have only records where gift date < 18JUL2014
campaignDate <- "2014-07-18"
dfBasePredictorsTable_Scores <- subset(dfPredictorsTable_Scores1, giftDate < campaignDate)

# Start to create predictors from dfBasePredictorsTable_Scores
# Predictor 1 - Min of giftAmount for all campaigns per donorID-campID
dfMinGift_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfBasePredictorsTable_Scores GROUP BY donorID, campID')

# Predictor 2 - Max of giftAmount for all campaigns per donorID-campID
dfMaxGift_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfBasePredictorsTable_Scores GROUP BY donorID, campID')

# Predictor 3 - Sum of giftAmount for all campaigns per donorID-campID
dfSumGift_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfBasePredictorsTable_Scores GROUP BY donorID, campID')

# Predictor 4 - Number of gifts for all campaigns per donorID-campID
dfCountGift_Scores <- sqldf('SELECT donorID, campID, Count(*) FROM dfBasePredictorsTable_Scores GROUP BY donorID, campID')
colnames(dfCountGift_Scores)[1] <- "donorID"
colnames(dfCountGift_Scores)[2] <- "campID"
colnames(dfCountGift_Scores)[3] <- "countGifts"

# Predictor 5 - Mean of giftAmount for all campaigns per donorID-campID
dfMeanGift_Scores <- aggregate(dfBasePredictorsTable_Scores$giftAmount, by=list(dfBasePredictorsTable_Scores$donorID, dfBasePredictorsTable_Scores$campID),FUN=mean)
colnames(dfMeanGift_Scores)[1] <- "donorID"
colnames(dfMeanGift_Scores)[2] <- "campID"
colnames(dfMeanGift_Scores)[3] <- "meanGiftAmount"

# Predictor 6 - Median of giftAmount for all campaigns per donorID-campID
dfMedianGift_Scores <- aggregate(dfBasePredictorsTable_Scores$giftAmount, by=list(dfBasePredictorsTable_Scores$donorID, dfBasePredictorsTable_Scores$campID),FUN=median)
colnames(dfMedianGift_Scores)[1] <- "donorID"
colnames(dfMedianGift_Scores)[2] <- "campID"
colnames(dfMedianGift_Scores)[3] <- "medianGiftAmount"

# Predictor 7 - Latest gift date for all campaigns per donorID-campID
dfLatestgiftDate_Scores <- aggregate(dfBasePredictorsTable_Scores$giftDate, by=list(dfBasePredictorsTable_Scores$donorID, dfBasePredictorsTable_Scores$campID),FUN=max)
colnames(dfLatestgiftDate_Scores)[1] <- "donorID"
colnames(dfLatestgiftDate_Scores)[2] <- "campID"
colnames(dfLatestgiftDate_Scores)[3] <- "MaxGiftDate"

# Predictor 8 - First gift date for all campaigns per donorID-campID
dfFirstGiftDate_Scores <- aggregate(dfBasePredictorsTable_Scores$giftDate, by=list(dfBasePredictorsTable_Scores$donorID, dfBasePredictorsTable_Scores$campID),FUN=max)
colnames(dfFirstGiftDate_Scores)[1] <- "donorID"
colnames(dfFirstGiftDate_Scores)[2] <- "campID"
colnames(dfFirstGiftDate_Scores)[3] <- "MinGiftDate"

# Subsetting data for the latest 5 campaigns
dfLastFiveCampaigns_Scores <- dfBasePredictorsTable_Scores %>%
  group_by(donorID) %>%
  arrange(desc(giftDate)) %>%
  slice(1:5)

# Predictor 9 - Min of giftAmount for the latest 5 donations per donorID-campID
dfMinGiftLast5Dontns_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfLastFiveCampaigns_Scores GROUP BY donorID, campID')
colnames(dfMinGiftLast5Dontns_Scores)[1] <- "donorID"
colnames(dfMinGiftLast5Dontns_Scores)[2] <- "campID"
colnames(dfMinGiftLast5Dontns_Scores)[3] <- "minGiftLast5Dons"

# Predictor 10 - Max of giftAmount for the latest 5 donations per donorID-campID 
dfMaxGiftLast5Dontns_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfLastFiveCampaigns_Scores GROUP BY donorID, campID')
colnames(dfMaxGiftLast5Dontns_Scores)[1] <- "donorID"
colnames(dfMaxGiftLast5Dontns_Scores)[2] <- "campID"
colnames(dfMaxGiftLast5Dontns_Scores)[3] <- "maxGiftLast5Dons"

# Predictor 11 - Sum of giftAmount for the latest 5 donations per donorID-campID
dfSumGiftLast5Dontns_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfLastFiveCampaigns_Scores GROUP BY donorID, campID')
colnames(dfSumGiftLast5Dontns_Scores)[1] <- "donorID"
colnames(dfSumGiftLast5Dontns_Scores)[2] <- "campID"
colnames(dfSumGiftLast5Dontns_Scores)[3] <- "sumGiftLast5Dons"

# Predictor 12 - Mean of giftAmount for all campaigns per donorID-campID
dfMeanGiftLast5Dontns_Scores <- aggregate(dfLastFiveCampaigns_Scores$giftAmount, by=list(dfLastFiveCampaigns_Scores$donorID, dfLastFiveCampaigns_Scores$campID),FUN=mean)
colnames(dfMeanGiftLast5Dontns_Scores)[1] <- "donorID"
colnames(dfMeanGiftLast5Dontns_Scores)[2] <- "campID"
colnames(dfMeanGiftLast5Dontns_Scores)[3] <- "meanGiftAmount5dns"

# Predictor 13 - Median of giftAmount for all campaigns per donorID-campID
dfMedianGiftLast5Dontns_Scores <- aggregate(dfLastFiveCampaigns_Scores$giftAmount, by=list(dfLastFiveCampaigns_Scores$donorID,dfLastFiveCampaigns_Scores$campID),FUN=median)
colnames(dfMedianGiftLast5Dontns_Scores)[1] <- "donorID"
colnames(dfMedianGiftLast5Dontns_Scores)[2] <- "campID"
colnames(dfMedianGiftLast5Dontns_Scores)[3] <- "medianGiftAmount5dns"

# Predictor 14 - Latest gift date for all campaigns per donorID-campID
dfLatestgiftDateLast5Dontns_Scores <- aggregate(dfLastFiveCampaigns_Scores$giftDate, by=list(dfLastFiveCampaigns_Scores$donorID, dfLastFiveCampaigns_Scores$campID),FUN=max)
colnames(dfLatestgiftDateLast5Dontns_Scores)[1] <- "donorID"
colnames(dfLatestgiftDateLast5Dontns_Scores)[2] <- "campID"
colnames(dfLatestgiftDateLast5Dontns_Scores)[3] <- "LatestGiftDate5dns"

# Predictor 15 - First gift date for all campaigns per donorID-campID
dfFirstGiftDateLast5Dontns_Scores <- aggregate(dfLastFiveCampaigns_Scores$giftDate, by=list(dfLastFiveCampaigns_Scores$donorID, dfLastFiveCampaigns_Scores$campID),FUN=min)
colnames(dfFirstGiftDateLast5Dontns_Scores)[1] <- "donorID"
colnames(dfFirstGiftDateLast5Dontns_Scores)[2] <- "campID"
colnames(dfFirstGiftDateLast5Dontns_Scores)[3] <- "FirstGiftDate5dns"

# Added Latest Gift date for every donorId-campID
dfPredictorsSubMerged_Scores <- merge(dfBasePredictorsTable_Scores, dfLatestgiftDate_Scores, by.dfBasePredictorsTable_Scores = c("donorId", "campId"))

# Calculate the year difference between the giftDate per donorId to the MaxGiftDate
dfPredictorsSubMerged_Scores$yr_diff <-  as.period(new_interval(start = dfPredictorsSubMerged_Scores$giftDate, end = dfPredictorsSubMerged_Scores$MaxGiftDate))$year

# Subset those records for 0-3years
dfPredictorsSub3yrs_Scores <- subset(dfPredictorsSubMerged_Scores, yr_diff<=3)
# Subset those records for 0-5years
dfPredictorsSub5yrs_Scores <- subset(dfPredictorsSubMerged_Scores, yr_diff<=5)
# Subset those records for 0-10years
dfPredictorsSub10yrs_Scores <- subset(dfPredictorsSubMerged_Scores, yr_diff<=10)
# Subset those records for 0-20years
dfPredictorsSub20yrs_Scores <- subset(dfPredictorsSubMerged_Scores, yr_diff<=20)

# Predictor 16 - Min of giftAmount for 0-3 years per donorID-campID
dfMinGift3yrs_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub3yrs_Scores GROUP BY donorID, campID')
colnames(dfMinGift3yrs_Scores)[1] <- "donorID"
colnames(dfMinGift3yrs_Scores)[2] <- "campID"
colnames(dfMinGift3yrs_Scores)[3] <- "minGiftAmount3yrs"

# Predictor 17 - Max of giftAmount 0-3 years per donorID-campID
dfMaxGift3yrs_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub3yrs_Scores GROUP BY donorID, campID')
colnames(dfMaxGift3yrs_Scores)[1] <- "donorID"
colnames(dfMaxGift3yrs_Scores)[2] <- "campID"
colnames(dfMaxGift3yrs_Scores)[3] <- "maxGiftAmount3yrs"

# Predictor 18 - Sum of giftAmount 0-3 years per donorID-campID
dfSumGift3yrs_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub3yrs_Scores GROUP BY donorID, campID')
colnames(dfSumGift3yrs_Scores)[1] <- "donorID"
colnames(dfSumGift3yrs_Scores)[2] <- "campID"
colnames(dfSumGift3yrs_Scores)[3] <- "sumGiftAmount3yrs"

# Predictor 19 - Number of gifts 0-3 years per donorID-campID
dfCountGift3yrs_Scores <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub3yrs_Scores GROUP BY donorID, campID')
colnames(dfCountGift3yrs_Scores)[1] <- "donorID"
colnames(dfCountGift3yrs_Scores)[2] <- "campID"
colnames(dfCountGift3yrs_Scores)[3] <- "countGiftAmount3yrs"

# Predictor 20 - Mean of giftAmount 0-3 years per donorID-campID
dfMeanGift3yrs_Scores <- aggregate(dfPredictorsSub3yrs_Scores$giftAmount, by=list(dfPredictorsSub3yrs_Scores$donorID, dfPredictorsSub3yrs_Scores$campID),FUN=mean)
colnames(dfMeanGift3yrs_Scores)[1] <- "donorID"
colnames(dfMeanGift3yrs_Scores)[2] <- "campID"
colnames(dfMeanGift3yrs_Scores)[3] <- "meanGiftAmount3yrs"

# Predictor 21 - Median of giftAmount 0-3 years per donorID-campID
dfMedianGift3yrs_Scores <- aggregate(dfPredictorsSub3yrs_Scores$giftAmount, by=list(dfPredictorsSub3yrs_Scores$donorID, dfPredictorsSub3yrs_Scores$campID),FUN=median)
colnames(dfMedianGift3yrs_Scores)[1] <- "donorID"
colnames(dfMedianGift3yrs_Scores)[2] <- "campID"
colnames(dfMedianGift3yrs_Scores)[3] <- "medianGiftAmount3yrs"

# Predictor 22 - Latest gift date 0-3 years per donorID-campID
dfLatestgiftDate3yrs_Scores <- aggregate(dfPredictorsSub3yrs_Scores$giftDate, by=list(dfPredictorsSub3yrs_Scores$donorID, dfPredictorsSub3yrs_Scores$campID),FUN=max)
colnames(dfLatestgiftDate3yrs_Scores)[1] <- "donorID"
colnames(dfLatestgiftDate3yrs_Scores)[2] <- "campID"
colnames(dfLatestgiftDate3yrs_Scores)[3] <- "MaxGiftDate3yrs"

# Predictor 23 - First gift date 0-3 years per donorID-campID
dfFirstGiftDate3yrs_Scores <- aggregate(dfPredictorsSub3yrs_Scores$giftDate, by=list(dfPredictorsSub3yrs_Scores$donorID, dfPredictorsSub3yrs_Scores$campID),FUN=min)
colnames(dfFirstGiftDate3yrs_Scores)[1] <- "donorID"
colnames(dfFirstGiftDate3yrs_Scores)[2] <- "campID"
colnames(dfFirstGiftDate3yrs_Scores)[3] <- "MinGiftDate3yrs"

# Predictor 24 - Min of giftAmount for 0-5 years per donorID-campID
dfMinGift5yrs_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub5yrs_Scores GROUP BY donorID, campID')
colnames(dfMinGift5yrs_Scores)[1] <- "donorID"
colnames(dfMinGift5yrs_Scores)[2] <- "campID"
colnames(dfMinGift5yrs_Scores)[3] <- "minGiftAmount5yrs"

# Predictor 25 - Max of giftAmount for 0-5 years  per donorID-campID
dfMaxGift5yrs_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub5yrs_Scores GROUP BY donorID, campID')
colnames(dfMaxGift5yrs_Scores)[1] <- "donorID"
colnames(dfMaxGift5yrs_Scores)[2] <- "campID"
colnames(dfMaxGift5yrs_Scores)[3] <- "maxGiftAmount5yrs"

# Predictor 26 - Sum of giftAmount for 0-5 years per donorID-campID
dfSumGift5yrs_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub5yrs_Scores GROUP BY donorID, campID')
colnames(dfSumGift5yrs_Scores)[1] <- "donorID"
colnames(dfSumGift5yrs_Scores)[2] <- "campID"
colnames(dfSumGift5yrs_Scores)[3] <- "sumGiftAmount5yrs"

# Predictor 27 - Number of gifts for 0-5 years per donorID-campID
dfCountGift5yrs_Scores <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub5yrs_Scores GROUP BY donorID, campID')
colnames(dfCountGift5yrs_Scores)[1] <- "donorID"
colnames(dfCountGift5yrs_Scores)[2] <- "campID"
colnames(dfCountGift5yrs_Scores)[3] <- "countGiftAmount5yrs"

# Predictor 28 - Mean of giftAmount for 0-5 years per donorID-campID
dfMeanGift5yrs_Scores <- aggregate(dfPredictorsSub5yrs_Scores$giftAmount, by=list(dfPredictorsSub5yrs_Scores$donorID, dfPredictorsSub5yrs_Scores$campID),FUN=mean)
colnames(dfMeanGift5yrs_Scores)[1] <- "donorID"
colnames(dfMeanGift5yrs_Scores)[2] <- "campID"
colnames(dfMeanGift5yrs_Scores)[3] <- "meanGiftAmount5yrs"

# Predictor 29 - Median of giftAmount for 0-5 years per donorID-campID
dfMedianGift5yrs_Scores <- aggregate(dfPredictorsSub5yrs_Scores$giftAmount, by=list(dfPredictorsSub5yrs_Scores$donorID, dfPredictorsSub5yrs_Scores$campID),FUN=median)
colnames(dfMedianGift5yrs_Scores)[1] <- "donorID"
colnames(dfMedianGift5yrs_Scores)[2] <- "campID"
colnames(dfMedianGift5yrs_Scores)[3] <- "medianGiftAmount5yrs"

# Predictor 30 - Latest gift date for 0-5 years per donorID-campID
dfLatestgiftDate5yrs_Scores <- aggregate(dfPredictorsSub5yrs_Scores$giftDate, by=list(dfPredictorsSub5yrs_Scores$donorID, dfPredictorsSub5yrs_Scores$campID),FUN=max)
colnames(dfLatestgiftDate5yrs_Scores)[1] <- "donorID"
colnames(dfLatestgiftDate5yrs_Scores)[2] <- "campID"
colnames(dfLatestgiftDate5yrs_Scores)[3] <- "MaxGiftDate5yrs"

# Predictor 31 - First gift date for 0-5 years per donorID-campID
dfFirstGiftDate5yrs_Scores <- aggregate(dfPredictorsSub5yrs_Scores$giftDate, by=list(dfPredictorsSub5yrs_Scores$donorID, dfPredictorsSub5yrs_Scores$campID),FUN=min)
colnames(dfFirstGiftDate5yrs_Scores)[1] <- "donorID"
colnames(dfFirstGiftDate5yrs_Scores)[2] <- "campID"
colnames(dfFirstGiftDate5yrs_Scores)[3] <- "MinGiftDate5yrs"

# Predictor 32 - Min of giftAmount for 0-10 years per donorID-campID
dfMinGift10yrs_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub10yrs_Scores GROUP BY donorID, campID')
colnames(dfMinGift10yrs_Scores)[1] <- "donorID"
colnames(dfMinGift10yrs_Scores)[2] <- "campID"
colnames(dfMinGift10yrs_Scores)[3] <- "minGiftAmount10yrs"

# Predictor 33 - Max of giftAmount for 0-10 years  per donorID-campID
dfMaxGift10yrs_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub10yrs_Scores GROUP BY donorID, campID')
colnames(dfMaxGift10yrs_Scores)[1] <- "donorID"
colnames(dfMaxGift10yrs_Scores)[2] <- "campID"
colnames(dfMaxGift10yrs_Scores)[3] <- "maxGiftAmount10yrs"

# Predictor 34 - Sum of giftAmount for 0-10 years per donorID-campID
dfSumGift10yrs_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub10yrs_Scores GROUP BY donorID, campID')
colnames(dfSumGift10yrs_Scores)[1] <- "donorID"
colnames(dfSumGift10yrs_Scores)[2] <- "campID"
colnames(dfSumGift10yrs_Scores)[3] <- "sumGiftAmount10yrs"

# Predictor 35 - Number of gifts for 0-10 years per donorID-campID
dfCountGift10yrs_Scores <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub10yrs_Scores GROUP BY donorID, campID')
colnames(dfCountGift10yrs_Scores)[1] <- "donorID"
colnames(dfCountGift10yrs_Scores)[2] <- "campID"
colnames(dfCountGift10yrs_Scores)[3] <- "countGiftAmount10yrs"

# Predictor 36 - Mean of giftAmount for 0-10 years per donorID-campID
dfMeanGift10yrs_Scores <- aggregate(dfPredictorsSub10yrs_Scores$giftAmount, by=list(dfPredictorsSub10yrs_Scores$donorID, dfPredictorsSub10yrs_Scores$campID),FUN=mean)
colnames(dfMeanGift10yrs_Scores)[1] <- "donorID"
colnames(dfMeanGift10yrs_Scores)[2] <- "campID"
colnames(dfMeanGift10yrs_Scores)[3] <- "meanGiftAmount10yrs"

# Predictor 37 - Median of giftAmount for 0-10 years per donorID-campID
dfMedianGift10yrs_Scores <- aggregate(dfPredictorsSub10yrs_Scores$giftAmount, by=list(dfPredictorsSub10yrs_Scores$donorID, dfPredictorsSub10yrs_Scores$campID),FUN=median)
colnames(dfMedianGift10yrs_Scores)[1] <- "donorID"
colnames(dfMedianGift10yrs_Scores)[2] <- "campID"
colnames(dfMedianGift10yrs_Scores)[3] <- "medianGiftAmount10yrs"

# Predictor 38 - Latest gift date for 0-10 years per donorID-campID
dfLatestgiftDate10yrs_Scores <- aggregate(dfPredictorsSub10yrs_Scores$giftDate, by=list(dfPredictorsSub10yrs_Scores$donorID, dfPredictorsSub10yrs_Scores$campID),FUN=max)
colnames(dfLatestgiftDate10yrs_Scores)[1] <- "donorID"
colnames(dfLatestgiftDate10yrs_Scores)[2] <- "campID"
colnames(dfLatestgiftDate10yrs_Scores)[3] <- "MaxGiftDate10yrs"

# Predictor 39 - First gift date for 0-10 years per donorID-campID
dfFirstGiftDate10yrs_Scores <- aggregate(dfPredictorsSub10yrs_Scores$giftDate, by=list(dfPredictorsSub10yrs_Scores$donorID, dfPredictorsSub10yrs_Scores$campID),FUN=min)
colnames(dfFirstGiftDate10yrs_Scores)[1] <- "donorID"
colnames(dfFirstGiftDate10yrs_Scores)[2] <- "campID"
colnames(dfFirstGiftDate10yrs_Scores)[3] <- "MinGiftDate10yrs"

# Predictor 40 - Min of giftAmount for 0-20 years per donorID-campID
dfMinGift20yrs_Scores <- sqldf('SELECT donorID, campID, MIN(giftAmount) FROM dfPredictorsSub20yrs_Scores GROUP BY donorID, campID')
colnames(dfMinGift20yrs_Scores)[1] <- "donorID"
colnames(dfMinGift20yrs_Scores)[2] <- "campID"
colnames(dfMinGift20yrs_Scores)[3] <- "minGiftAmount20yrs"

# Predictor 41 - Max of giftAmount for 0-20 years  per donorID-campID
dfMaxGift20yrs_Scores <- sqldf('SELECT donorID, campID, MAX(giftAmount) FROM dfPredictorsSub20yrs_Scores GROUP BY donorID, campID')
colnames(dfMaxGift20yrs_Scores)[1] <- "donorID"
colnames(dfMaxGift20yrs_Scores)[2] <- "campID"
colnames(dfMaxGift20yrs_Scores)[3] <- "maxGiftAmount20yrs"

# Predictor 42 - Sum of giftAmount for 0-20 years per donorID-campID
dfSumGift20yrs_Scores <- sqldf('SELECT donorID, campID, SUM(giftAmount) FROM dfPredictorsSub20yrs_Scores GROUP BY donorID, campID')
colnames(dfSumGift20yrs_Scores)[1] <- "donorID"
colnames(dfSumGift20yrs_Scores)[2] <- "campID"
colnames(dfSumGift20yrs_Scores)[3] <- "sumGiftAmount20yrs"

# Predictor 43 - Number of gifts for 0-20 years per donorID-campID
dfCountGift20yrs_Scores <- sqldf('SELECT donorID, campID, Count(*) FROM dfPredictorsSub20yrs_Scores GROUP BY donorID, campID')
colnames(dfCountGift20yrs_Scores)[1] <- "donorID"
colnames(dfCountGift20yrs_Scores)[2] <- "campID"
colnames(dfCountGift20yrs_Scores)[3] <- "countGiftAmount20yrs"

# Predictor 44 - Mean of giftAmount for 0-20 years per donorID-campID
dfMeanGift20yrs_Scores <- aggregate(dfPredictorsSub20yrs_Scores$giftAmount, by=list(dfPredictorsSub20yrs_Scores$donorID, dfPredictorsSub20yrs_Scores$campID),FUN=mean)
colnames(dfMeanGift20yrs_Scores)[1] <- "donorID"
colnames(dfMeanGift20yrs_Scores)[2] <- "campID"
colnames(dfMeanGift20yrs_Scores)[3] <- "meanGiftAmount20yrs"

# Predictor 45 - Median of giftAmount for 0-20 years per donorID-campID
dfMedianGift20yrs_Scores <- aggregate(dfPredictorsSub20yrs_Scores$giftAmount, by=list(dfPredictorsSub20yrs_Scores$donorID, dfPredictorsSub20yrs_Scores$campID),FUN=median)
colnames(dfMedianGift20yrs_Scores)[1] <- "donorID"
colnames(dfMedianGift20yrs_Scores)[2] <- "campID"
colnames(dfMedianGift20yrs_Scores)[3] <- "medianGiftAmount20yrs"

# Predictor 46 - Latest gift date for 0-20 years per donorID-campID
dfLatestgiftDate20yrs_Scores <- aggregate(dfPredictorsSub20yrs_Scores$giftDate, by=list(dfPredictorsSub20yrs_Scores$donorID, dfPredictorsSub20yrs_Scores$campID),FUN=max)
colnames(dfLatestgiftDate20yrs_Scores)[1] <- "donorID"
colnames(dfLatestgiftDate20yrs_Scores)[2] <- "campID"
colnames(dfLatestgiftDate20yrs_Scores)[3] <- "MaxGiftDate20yrs"

# Predictor 47 - First gift date for 0-20 years per donorID-campID
dfFirstGiftDate20yrs_Scores <- aggregate(dfPredictorsSub20yrs_Scores$giftDate, by=list(dfPredictorsSub20yrs_Scores$donorID, dfPredictorsSub20yrs_Scores$campID),FUN=min)
colnames(dfFirstGiftDate20yrs_Scores)[1] <- "donorID"
colnames(dfFirstGiftDate20yrs_Scores)[2] <- "campID"
colnames(dfFirstGiftDate20yrs_Scores)[3] <- "MinGiftDate20yrs"

# Merge all the predictors
dfBaseTablePredictorsForScores <- merge(dfBasePredictorsTable_Scores, dfMinGift_Scores, by.dfBasePredictorsTable_Scores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGift_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGift_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfCountGift_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGift_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGift_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfLatestgiftDate_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfFirstGiftDate_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"))
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMinGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfCountGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGift3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfLatestgiftDate3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfFirstGiftDate3yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMinGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfCountGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGift5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfLatestgiftDate5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfFirstGiftDate5yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMinGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfCountGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGift10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfLatestgiftDate10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfFirstGiftDate10yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMinGiftLast5Dontns_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGiftLast5Dontns_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGiftLast5Dontns_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGiftLast5Dontns_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGiftLast5Dontns_Scores, by.dfBaseTablePredictorsForScores= c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMinGift20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMaxGift20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfSumGift20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfCountGift20yrs_Scores, by.dfBaseTablePredictorsForScores= c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMeanGift20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfMedianGift20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfLatestgiftDate20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)
dfBaseTablePredictorsForScores <- merge(dfBaseTablePredictorsForScores, dfFirstGiftDate20yrs_Scores, by.dfBaseTablePredictorsForScores = c("donorId","campId"),all.x = TRUE)

# Deleting all the date columns
dfBaseTablePredictorsForScores$campDate= NULL
dfBaseTablePredictorsForScores$giftDate= NULL
dfBaseTablePredictorsForScores$MaxGiftDate =NULL
dfBaseTablePredictorsForScores$MinGiftDate =NULL
dfBaseTablePredictorsForScores$MaxGiftDate3yrs =NULL
dfBaseTablePredictorsForScores$MinGiftDate3yrs =NULL
dfBaseTablePredictorsForScores$MaxGiftDate5yrs =NULL
dfBaseTablePredictorsForScores$MinGiftDate5yrs =NULL
dfBaseTablePredictorsForScores$MaxGiftDate10yrs =NULL
dfBaseTablePredictorsForScores$MinGiftDate10yrs =NULL
dfBaseTablePredictorsForScores$MaxGiftDate20yrs =NULL
dfBaseTablePredictorsForScores$MinGiftDate20yrs =NULL

colnames(dfBaseTablePredictorsForScores)[12] <- "minGiftAmount"
colnames(dfBaseTablePredictorsForScores)[13] <- "maxGiftAmount"
colnames(dfBaseTablePredictorsForScores)[14] <- "sumGiftAmount"

#Convert factors to character
dfBaseTablePredictorsForScores$gender <- as.character(dfBaseTablePredictorsForScores$gender)
dfBaseTablePredictorsForScores$language <- as.character(dfBaseTablePredictorsForScores$language)
dfBaseTablePredictorsForScores$zipcode <- as.character(dfBaseTablePredictorsForScores$zipcode)
dfBaseTablePredictorsForScores$region <- as.character(dfBaseTablePredictorsForScores$region)

# Zipcode to region Mapping
# Deleting chars in predictors table
dfBaseTablePredictorsForScores <-dfBaseTablePredictorsForScores[!(dfBaseTablePredictorsForScores$zipcode=="SW6"),]
dfBaseTablePredictorsForScores <-dfBaseTablePredictorsForScores[!(dfBaseTablePredictorsForScores$zipcode=="Missing"),]
dfBaseTablePredictorsForScores$zipcode=as.numeric(as.character(dfBaseTablePredictorsForScores$zipcode))

# Replacing zipcodes with provinces (Source:wikipedia)
dfBaseTablePredictorsForScores$region=cases("BCR"<-dfBaseTablePredictorsForScores$zipcode<1300,
                                            "WB"<-dfBaseTablePredictorsForScores$zipcode>1299 & dfBaseTablePredictorsForScores$zipcode<1500,
                                            "FB"<-dfBaseTablePredictorsForScores$zipcode>1499 & dfBaseTablePredictorsForScores$zipcode<2000,
                                            "AW"<-dfBaseTablePredictorsForScores$zipcode>1999 & dfBaseTablePredictorsForScores$zipcode<3000,
                                            "FB"<-dfBaseTablePredictorsForScores$zipcode>2999 & dfBaseTablePredictorsForScores$zipcode<3500,
                                            "LB"<-dfBaseTablePredictorsForScores$zipcode>3499 & dfBaseTablePredictorsForScores$zipcode<4000,
                                            "LI"<-dfBaseTablePredictorsForScores$zipcode>3999 & dfBaseTablePredictorsForScores$zipcode<5000,
                                            "NA"<-dfBaseTablePredictorsForScores$zipcode>4999 & dfBaseTablePredictorsForScores$zipcode<6000,
                                            "HN"<-dfBaseTablePredictorsForScores$zipcode>5999 & dfBaseTablePredictorsForScores$zipcode<6600,
                                            "LX"<-dfBaseTablePredictorsForScores$zipcode>6599 & dfBaseTablePredictorsForScores$zipcode<7000,
                                            "HN"<-dfBaseTablePredictorsForScores$zipcode>6999 & dfBaseTablePredictorsForScores$zipcode<8000,
                                            "WF"<-dfBaseTablePredictorsForScores$zipcode>7999 & dfBaseTablePredictorsForScores$zipcode<9000,
                                            "EF"<-dfBaseTablePredictorsForScores$zipcode>8999 & dfBaseTablePredictorsForScores$zipcode<10000,
                                            "Missing"<-dfBaseTablePredictorsForScores$zipcode =="NA" | dfBaseTablePredictorsForScores$zipcode == 0)

# Region Binary Variables
dfBaseTablePredictorsForScores$BCR = ifelse(dfBaseTablePredictorsForScores$region=="BCR",1,0)
dfBaseTablePredictorsForScores$WB = ifelse(dfBaseTablePredictorsForScores$region=="WB",1,0)
dfBaseTablePredictorsForScores$FB = ifelse(dfBaseTablePredictorsForScores$region=="FB",1,0)
dfBaseTablePredictorsForScores$AW = ifelse(dfBaseTablePredictorsForScores$region=="AW",1,0)
dfBaseTablePredictorsForScores$LB = ifelse(dfBaseTablePredictorsForScores$region=="LB",1,0)
dfBaseTablePredictorsForScores$LI = ifelse(dfBaseTablePredictorsForScores$region=="LI",1,0)
dfBaseTablePredictorsForScores$NAM = ifelse(dfBaseTablePredictorsForScores$region=="NA",1,0)
dfBaseTablePredictorsForScores$HN = ifelse(dfBaseTablePredictorsForScores$region=="HN",1,0)
dfBaseTablePredictorsForScores$LX = ifelse(dfBaseTablePredictorsForScores$region=="LX",1,0)
dfBaseTablePredictorsForScores$WF = ifelse(dfBaseTablePredictorsForScores$region=="WF",1,0)
dfBaseTablePredictorsForScores$EF = ifelse(dfBaseTablePredictorsForScores$region=="EF",1,0)
dfBaseTablePredictorsForScores$region  = NULL

# Language Binary Variable French = 1, Dutch = 0
dfBaseTablePredictorsForScores$language <- as.character(dfBaseTablePredictorsForScores$language)
dfBaseTablePredictorsForScores$language  = ifelse(dfBaseTablePredictorsForScores$language=="F", 1, 0)

# Gender Binary Variables
dfBaseTablePredictorsForScores$males = ifelse(dfBaseTablePredictorsForScores$gender=="M",1,0)
dfBaseTablePredictorsForScores$females = ifelse(dfBaseTablePredictorsForScores$gender=="F",1,0)
dfBaseTablePredictorsForScores$companies = ifelse(dfBaseTablePredictorsForScores$gender=="S",1,0)
dfBaseTablePredictorsForScores$couples = ifelse(dfBaseTablePredictorsForScores$gender=="C",1,0)
dfBaseTablePredictorsForScores$unknown = ifelse(dfBaseTablePredictorsForScores$gender=="U",1,0)
dfBaseTablePredictorsForScores$gender = NULL

# meangiftamount <30 = 0####
dfBaseTablePredictorsForScores$meanGiftAmount = ifelse(dfBaseTablePredictorsForScores$meanGiftAmount >= 30, 1,0)

# Replace NAs to 0
dfBaseTablePredictorsForScores[is.na(dfBaseTablePredictorsForScores)] <- 0
dfBaseTablePredictorsForScores$Total_Amount= NULL

# Drop campID from Base Predictors and get unique records per donorID
dfBaseTablePredictorsForScores$campID = NULL
dfBaseTablePredictorsForScores$giftcampID = NULL
dfBaseTablePredictorsForScores$giftCommID = NULL
dfBaseTablePredictorsForScores$giftAmount = NULL
dfBaseTablePredictorsForScores = unique(dfBaseTablePredictorsForScores)

#ctree
#plot
ctree_model = ctree(Target ~ ., data = dfBaseTablePredictorsForScores, controls = ctree_control(mincriterion = 0.0001))
plot(ctree_model, inner_pannel=node_inner)

#To calculate the scores for the donors in Scores.txt
dfBaseTablePredictorsForScores$scores = predict(ctree_model,newdata = dfBaseTablePredictorsForScores) 
predict_scores_final <- sqldf('select distinct donorId, scores from dfBaseTablePredictorsForScores')
