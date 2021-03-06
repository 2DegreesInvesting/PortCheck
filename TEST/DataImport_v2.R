#This project was funded by the European Commission through LIFE program under grant: LIFE16 GIC/FR/000061 - PACTA)
# Fund-Look Through for portfolio data (Using output of Fund-Look-through_preparation)
# 17/04/21 Klaus Hagedorn

rm(list=ls())

#Load packages
library(plyr)
library(reshape2)

#Version - Control

# --- DATE ---   |  --- Editor ---  | --- Version Name --- | --- Edits / Adds / Changes / Bugfixes ---
# 2017 - 04 - 21 |        KH        |          1           | First version - loading all fund holdings and aditional information and binding it with input data (ISINs)

# Get user-name
UserName <- sub("/.*","",sub(".*Users/","",getwd()))

#-------------
# All Input parameters & make the code interactive
#------------
Input <- "1 File"
# Please select the input parameters here
FundDataLocation <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/PortCheck/00_Data/01_ProcessedData/02_FundData/")
FinancialDataFolder <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/PortCheck/00_Data/02_FinancialData/2016Q4/PORT/")
OutputLocation <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/PortCheck/02_PortfolioData/02_Swiss/") #Output-folder for the results
PortfolioLocation <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/PortCheck/02_PortfolioData/02_Swiss/")
# PortfolioHoldingsEQY<- "SwissEquity" #PortfolioData file name
# PortfolioHoldingsBonds<- "SwissBonds" #PortfolioData file name

# PortfolioLocation <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/Swiss TM/Companies/GBUV/")
# PortfolioHoldings1 <- "Swiss_BatchMissingPortfolios"
PortfolioHoldings <- "Swiss_BatchAll"

#-------------
# Read in all data (Fund data, portfolio data and financial data
#------------
#Read in portfolio data (including Fund-ISINs)
# if (Input == "1 File"){
PortfolioData <- read.csv(paste0(PortfolioLocation,PortfolioHoldings,".csv"),stringsAsFactors=FALSE,strip.white=TRUE)
# }else{
# PortfolioDataEQY <- read.csv(paste0(PortfolioLocation,PortfolioHoldingsEQY,".csv"),stringsAsFactors=FALSE,strip.white=TRUE)
# PortfolioDataEQY$Type <- "EQY"
# PortfolioDataBonds <- read.csv(paste0(PortfolioLocation,PortfolioHoldingsBonds,".csv"),stringsAsFactors=FALSE,strip.white=TRUE)
# PortfolioDataBonds$Type <- "Bonds"
# PortfolioData <- rbind(PortfolioDataEQY,PortfolioDataBonds)
# }
# PortfolioData <- subset(PortfolioData,!PortfolioData$PortfolioName %in% c("Ethenea"))
# PortfolioData1 <- read.csv(paste0(PortfolioLocation,PortfolioHoldings1,".csv"),stringsAsFactors=FALSE,strip.white=TRUE)
# PortfolioData1 <- subset(PortfolioData1,!PortfolioData1$PortfolioName %in% PortfolioData$PortfolioName)
# PortfolioData <- rbind(PortfolioData,PortfolioData1)
# PortfolioData <- ddply(PortfolioData,.(InvestorName,PortfolioName,ISIN,Currency),summarise, MarketValue = sum(MarketValue,na.rm = TRUE),NumberofShares = sum(NumberofShares,na.rm = TRUE))
PortInput <- PortfolioData
PortSizeCheck <- sum(PortfolioData$MarketValue, na.rm = TRUE)

DataFolder <- paste0("C:/Users/",UserName,"/Dropbox (2� Investing)/PortCheck/00_Data/01_ProcessedData/")
ExchRates <- read.csv(paste0(DataFolder,"Currencies.csv"),stringsAsFactors = FALSE, strip.white = TRUE)
MissingCurrencies <- data.frame(MissingCurrencies = setdiff(unique(PortfolioData$Currency), ExchRates$Currency_abbr))
PortfolioData <- merge(PortfolioData, subset(ExchRates, select = c("Currency_abbr","ExchangeRate_31122016")), by.x = "Currency", by.y = "Currency_abbr", all.x = TRUE, all.y = FALSE)
PortfolioData$ValueUSD <- PortfolioData$MarketValue * PortfolioData$ExchangeRate_31122016

PortSizeCheck0USD <- sum(PortfolioData$ValueUSD, na.rm = TRUE)

NegativeValues <- subset(PortfolioData, !(!(MarketValue < 0 & (is.na(NumberofShares) | NumberofShares == 0)) & !(NumberofShares < 0 & (is.na(MarketValue) | MarketValue == 0 ))))
NegativeValues <- ddply(NegativeValues,.(ISIN, Currency, PortfolioName, InvestorName),summarize, NumberofShares = sum(NumberofShares,na.rm = TRUE), MarketValue = sum(MarketValue,na.rm = TRUE), ValueUSD = sum(ValueUSD,na.rm = TRUE))

PortfolioData <- subset(PortfolioData, !(MarketValue <= 0 & (is.na(NumberofShares) | NumberofShares == 0)) & !(NumberofShares <= 0 & (is.na(MarketValue) | MarketValue == 0 )))

# PortfolioData <- subset(PortfolioData, !(MarketValue == 0 & is.na(NumberofShares)) & !(NumberofShares == 0 & is.na(MarketValue)))
PortfolioData <- ddply(PortfolioData,.(ISIN, Currency, PortfolioName, InvestorName),summarize, NumberofShares = sum(NumberofShares,na.rm = TRUE), MarketValue = sum(MarketValue,na.rm = TRUE), ValueUSD = sum(ValueUSD,na.rm = TRUE))
PortInputPositiveValuesOnly <- PortfolioData

PortSizeCheck0 <- sum(PortfolioData$MarketValue, na.rm = TRUE)

# 3) create overview file for meta analysis (a)AUM total, negative values total, AUM without ISIN vs with ISINs, AUM False ISINs (position without valueUSD vs positions with valueUSD (sum this) vs AUM assessable (b) Financial instrumetn split, (c) funds vs direct, etc.
PortInputNAISINs <- subset(PortfolioData, ISIN %in% c("n.a. (diverse Cash)", "n.a. (diverse HFoFs)", "n.a. (diverse Hypotheken)", "n.a. (diverse Immobilien Ausland)", "n.a. (diverse Immobilien CH)", "n.a. (diverse PE)", "N/A", "-", "0") | is.na(ISIN))
PortfolioData$ISIN [PortfolioData$ISIN  %in% c("n.a. (diverse Cash)", "n.a. (diverse HFoFs)", "n.a. (diverse Hypotheken)", "n.a. (diverse Immobilien Ausland)", "n.a. (diverse Immobilien CH)", "n.a. (diverse PE)", "N/A", "-", "0") | is.na(PortfolioData$ISIN) ] <- "NA_ISIN_Input"


PortSizeCheck01 <- sum(PortfolioData$ValueUSD, na.rm = TRUE)

if("Name" %in% colnames(PortfolioData)){PortfolioData <- rename(PortfolioData,c("Name" = "Name_InputPort"))}
#Read in fund look-through data
Fund_Data <- read.csv(paste0(FundDataLocation,"FundLookThroughData.csv"),stringsAsFactors=FALSE,strip.white=TRUE) 
Fund_Data_EQY <- read.csv(paste0(FundDataLocation,"FundLookThroughData_EQY.csv"),stringsAsFactors=FALSE,strip.white=TRUE)
Fund_Data_CBonds <- read.csv(paste0(FundDataLocation,"FundLookThroughData_Bonds.csv"),stringsAsFactors=FALSE,strip.white=TRUE)

#Read in financial data
# BBG_Data <- read.csv(paste0(FinancialDataFolder,"FinancialData.csv"),stringsAsFactors=FALSE,strip.white=TRUE)
BBG_Data <- read.csv(paste0(FinancialDataFolder,"FinancialData_20170925.csv"),stringsAsFactors=FALSE,strip.white=TRUE)
BBG_Data <- rename(BBG_Data, c( "Mkt.Val..P." = "SharePrice"))
BBG_Data_sub <- subset(BBG_Data, ! is.na(BBG_Data$ISIN) & ISIN != "")

#Test if there are duplicates left in the financial database
ISINCount <- as.data.frame(table(BBG_Data_sub$ISIN))
DupsInBBGDataBETTERCHECK <- subset(ISINCount, Freq > 1, select = "Var1")
BBG_Data_sub <- BBG_Data_sub[!duplicated(BBG_Data_sub),]

#-------------
# Merge portfolio with financial data and prepare for fund-look-through (e.g. calculate USD-Value held of each security)
#------------
PortfolioData_w_BBG <- merge(BBG_Data_sub,PortfolioData, by = "ISIN", all.x = FALSE, all.y = TRUE)
PortfolioData_wo_BBG <- unique(subset(PortfolioData_w_BBG,is.na(Name), select = c("ISIN")))
PortfolioData_wo_BBG2 <- subset(PortfolioData_w_BBG,is.na(Name))

PortfolioData_w_BBG$ValueType <- "NumberofShares"
PortfolioData_w_BBG$ValueType[PortfolioData_w_BBG$MarketValue != 0 & !is.na(PortfolioData_w_BBG$MarketValue)] <- "MarketValue"

# # Calculate ValueUSD (AUMs in each single fund)
# PortfolioData_w_BBG$Position <- PortfolioData_w_BBG$ValueUSD
# PortfolioData_w_BBG$Position[is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0] <- PortfolioData_w_BBG$NumberofShares[is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0] 
PortfolioData_w_BBG$ValueUSD[is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0] <- PortfolioData_w_BBG$SharePrice[is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0] * PortfolioData_w_BBG$NumberofShares[is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0]

Test <- subset(PortfolioData_w_BBG, is.na(ValueUSD))
write.csv(Test, "InputWithoutBBGInformation_missingPorts.csv", row.names = FALSE)

# PortfolioData_w_BBG$ISIN[PortfolioData_w_BBG$ISIN %in% Test$ISIN & PortfolioData_w_BBG$ISIN != "NA_ISIN_Input" & (is.na(PortfolioData_w_BBG$ValueUSD) | PortfolioData_w_BBG$ValueUSD == 0)] <- "NA_ISIN_BBG_Data"
PortSizeCheck1 <- sum(PortfolioData_w_BBG$ValueUSD, na.rm = TRUE)

# Portfolio Meta Analysis
PortfolioEntries <- aggregate(ISIN ~ InvestorName + PortfolioName, data = PortfolioData_w_BBG, FUN = length)
PortfolioEntries <- rename(PortfolioEntries, c("ISIN" = "NrOfPosition"))
PortfolioSizes <- aggregate(PortfolioData_w_BBG["ValueUSD"], by  = PortfolioData_w_BBG[,c("InvestorName","PortfolioName")],FUN = sum, na.rm = TRUE)
PortfolioSizes <- rename(PortfolioSizes, c("ValueUSD" = "PortfolioSizeUSD"))
Test <- aggregate(ISIN ~ InvestorName + PortfolioName, data = Test, FUN = length)
Test <- rename(Test,c("ISIN" = "NrOfPositionsWOValueUSD"))
PortfolioSizes <- merge(merge(PortfolioSizes, PortfolioEntries, by = c("InvestorName","PortfolioName"), all.x = TRUE),Test,by = c("InvestorName","PortfolioName"), all.x = TRUE)

#-------------
# # Merge Portfolio Data with fund data for the lookthrough and calculate owned holdings of Portfolios
#------------
#All Instruments (R-pull with Port-Weight for both EQY & CBonds):
Portfolio_LookThrough <- merge(Fund_Data, subset(PortfolioData_w_BBG, select = c("ISIN", "ValueUSD", "PortfolioName","InvestorName")),  by.y = "ISIN", by.x = "FundISIN")
# FundCoverage <- rename(unique(subset(Portfolio_LookThrough, select = c("InvestorName", "PortfolioName", "FundISIN", "ValueUSD", "FundCoverage"))), c("FundCoverage" = "FundCoverageMS"))
Portfolio_LookThrough <- merge(Portfolio_LookThrough, unique(subset(BBG_Data_sub, select = c("ISIN", "Security.Type", "Name","SharePrice"))),by.x = "HoldingISIN", by.y = "ISIN", all.x = TRUE, all.y = FALSE)
Portfolio_LookThrough$Position <- Portfolio_LookThrough$ValueUSD * Portfolio_LookThrough$value / 100
Portfolio_LookThrough$Position[Portfolio_LookThrough$ValueUnit == "SharesPerUSD"] <- Portfolio_LookThrough$ValueUSD[Portfolio_LookThrough$ValueUnit == "SharesPerUSD"] * Portfolio_LookThrough$value[Portfolio_LookThrough$ValueUnit == "SharesPerUSD"] * Portfolio_LookThrough$SharePrice[Portfolio_LookThrough$ValueUnit == "SharesPerUSD"]
Portfolio_LookThrough <- subset(Portfolio_LookThrough, FundCoverage <= 100)
# Portfolio_LookThrough <- merge(subset(Portfolio_LookThrough, select = -c (value,ValueUnit)), unique(subset(BBG_Data_sub, select = c("ISIN", "Security.Type", "Name"))),by.x = "HoldingISIN", by.y = "ISIN", all.x = TRUE, all.y = FALSE)
Portfolio_LookThroughCovered <- subset(Portfolio_LookThrough, !is.na(Name))
FundCoverage <- rename(aggregate(Portfolio_LookThroughCovered["Position"], by = Portfolio_LookThroughCovered[,c("InvestorName", "PortfolioName", "FundISIN", "ValueUSD", "FundCoverage")],FUN = sum),c("FundCoverage" = "FundCoverageMS"))
FundCoverage$FundCoverageBBG <- FundCoverage$Position / FundCoverage$ValueUSD
FundCoveragePortfolioLevel <- ddply(FundCoverage,.(InvestorName,PortfolioName),summarize, USDinFunds = sum(ValueUSD,na.rm = TRUE), USDcovered = sum(Position,na.rm = TRUE))
FundCoveragePortfolioLevel$Coverage <- FundCoveragePortfolioLevel$USDcovered / FundCoveragePortfolioLevel$USDinFunds

PortfolioData_wo_BBG <- subset(PortfolioData_wo_BBG, !ISIN %in% Portfolio_LookThrough$FundISIN)
PortfolioData_wo_BBG2 <- subset(PortfolioData_wo_BBG2, !ISIN %in% Portfolio_LookThrough$FundISIN)
Test <- aggregate(ISIN ~ InvestorName + PortfolioName, data = PortfolioData_wo_BBG2, FUN = length)
Test <- rename(Test,c("ISIN" = "NrOfPositionsWOBBGInformation"))
PortfolioSizes <- merge(PortfolioSizes,Test,by = c("InvestorName","PortfolioName"), all.x = TRUE)
Test <- aggregate(ValueUSD ~ InvestorName + PortfolioName, data = PortfolioData_wo_BBG2, FUN = sum)
Test <- rename(Test,c("ValueUSD" = "ValueUSDOfPositionsWOBBGWValueUSDInformation"))
PortfolioSizes <- merge(PortfolioSizes,Test,by = c("InvestorName","PortfolioName"), all.x = TRUE)

PortfolioData_wo_BBG$Type <- "MissingISINsPortfolio"
MissingISINsLookThrough <- rename(subset(Portfolio_LookThrough, is.na(Position), select = "HoldingISIN"),c("HoldingISIN" = "ISIN"))
MissingISINsLookThrough$Type <- "MissingISINsFundsLookThrough"

MissingISINs <- rbind(PortfolioData_wo_BBG, MissingISINsLookThrough)

PortfolioData_Funds <- subset(PortfolioData_w_BBG, ISIN %in% Portfolio_LookThrough$FundISIN)
FundsBBG <- subset(PortfolioData_w_BBG, Security.Type %in% c("ETF", "Closed End Fund", "Mutual Fund") | Sector == "Funds", select = c("ISIN", "SharePrice","PortfolioName", "InvestorName", "NumberofShares", "ValueUSD", "Security.Type", "ICB.Subsector.Name", "Group"))  

FundMetaanalysis <- merge(FundsBBG, rename(subset(FundCoverage,select = c("InvestorName", "PortfolioName", "FundISIN", "FundCoverageMS", "Position", "FundCoverageBBG")), c("Position" = "PositionsCovered")), by.x = c("InvestorName", "PortfolioName", "ISIN"), by.y = c("InvestorName", "PortfolioName", "FundISIN"), all = TRUE)
FundMetaanalysisPortLevel <- ddply(FundMetaanalysis,.(InvestorName,PortfolioName),summarize, FundsUSD = sum(ValueUSD,na.rm = TRUE), FundsCoveredUSD = sum(PositionsCovered, na.rm = TRUE))
FundMetaanalysisPortLevel$Coverage <- FundMetaanalysisPortLevel$FundsCoveredUSD / FundMetaanalysisPortLevel$FundsUSD
PortfolioMetaAnalysis <- merge(PortfolioSizes,FundMetaanalysisPortLevel, by = c("InvestorName", "PortfolioName"), all = TRUE)

FundsCovered <- subset(PortfolioData_Funds, select = c("ISIN", "SharePrice","PortfolioName", "InvestorName", "NumberofShares", "ValueUSD", "Security.Type", "ICB.Subsector.Name"))

FundsWithMissingBBGData <- subset(FundsCovered, is.na(ValueUSD), select = c("ISIN"))
if(nrow(FundsWithMissingBBGData) > 0){
  FundsWithMissingBBGData$QTY <- 1
  FundsWithMissingBBGData$Date <- "31-12-2016"
  # write.csv(FundsWithMissingBBGData, "BBG-Look-up-needed.csv",row.names = FALSE)
}

PortfolioData_w_BBG_test <- subset(PortfolioData_w_BBG,!is.na(Name) & !ISIN %in% Portfolio_LookThrough$FundISIN)

if(is.null(length(setdiff(PortfolioData_w_BBG$ISIN,c(PortfolioData_Funds$ISIN,PortfolioData_wo_BBG$ISIN,PortfolioData_w_BBG_test$ISIN))))){
  print("ISINS GETTING LOST!! CHECK LOSTISINS")
  LOSTISINS <- setdiff(PortfolioData_w_BBG$ISIN,c(PortfolioData_Funds$ISIN,PortfolioData_wo_BBG$ISIN,PortfolioData_w_BBG_test$ISIN))
}

PositionLevelMetaAnalysis <- PortfolioData_w_BBG
PositionLevelMetaAnalysis$ISINInfo <- "Direct Holding"
PositionLevelMetaAnalysis$ISINInfo[PositionLevelMetaAnalysis$ISIN %in% Portfolio_LookThrough$FundISIN] <- "FUND_ISIN"
PositionLevelMetaAnalysis$ISINInfo[is.na(PositionLevelMetaAnalysis$Name) & PositionLevelMetaAnalysis$ISINInfo %in% c("FUND_ISIN")] <- "NA_FUND_ISIN_BBG_Data"
PositionLevelMetaAnalysis$ISINInfo[is.na(PositionLevelMetaAnalysis$Name) & !PositionLevelMetaAnalysis$ISINInfo %in% c("NA_ISIN_Input","FUND_ISIN")] <- "NA_ISIN_BBG_Data"
PositionLevelMetaAnalysis$ISINInfo[is.na(PositionLevelMetaAnalysis$ValueUSD) & !PositionLevelMetaAnalysis$ISINInfo %in% c("NA_ISIN_Input","FUND_ISIN")] <- "NA_ISIN+Value_BBG_Data"

PortfolioData_w_BBG <- subset(PortfolioData_w_BBG, !is.na(Name) & !ISIN %in% Portfolio_LookThrough$FundISIN)

# Create the equity portfolio input files for the fund analysis
Portfolio <- subset(PortfolioData_w_BBG, select = c("ISIN", "Name", "Security.Type", "ValueUSD", "PortfolioName","InvestorName"))
Portfolio$HoldingType <- "Direct Holding"
Portfolio_Funds <- subset(Portfolio_LookThrough, select = c("HoldingISIN", "Name", "Security.Type", "Position", "PortfolioName","InvestorName"))
Portfolio_Funds <- rename(Portfolio_Funds, c("HoldingISIN" = "ISIN", "Position" = "ValueUSD"))
# Portfolio_Funds_summed <- ddply(Portfolio_Funds,.(ISIN, Name, Security.Type, PortfolioName, InvestorName), summarise, Position = sum(Position, na.rm = TRUE))
Portfolio_Funds_summed <- aggregate(Portfolio_Funds["ValueUSD"], by=Portfolio_Funds[,c("ISIN", "Name", "Security.Type", "PortfolioName", "InvestorName")], FUN=sum)
Portfolio_Funds_summed$HoldingType <- "Fund Holding"

# Portfolio_Funds_summed$PortfolioName <- paste0(paste0(Portfolio_Funds_summed$PortfolioName,"_Funds"))

TotalPortfolio <- rbind(Portfolio,Portfolio_Funds_summed)
PortSizeCheck2 <- sum(TotalPortfolio$ValueUSD, na.rm = TRUE)

TotalPortfolio <- merge(TotalPortfolio, subset(BBG_Data_sub, select = c("ISIN","ICB.Subsector.Name","Group", "Ticker", "Subgroup")), by = "ISIN", all.x = TRUE, all.y = FALSE)

ParticipantList <- read.csv(paste0(OutputLocation,"ParticipantsOverview.csv"),strip.white = TRUE, stringsAsFactors = FALSE)
TotalPortfolio <- merge(TotalPortfolio, ParticipantList, by = "InvestorName", all.x = TRUE)
# TotalPortfolio <- ddply(TotalPortfolio.(ISIN, Name, Security.Type, FundName, BrandName), summarise, Number.of.shares = sum(Number.of.shares, na.rm = TRUE))
# TotalPortfolio_EQY1 <- subset(TotalPortfolio, Security.Type %in% c("Common Stocks", "Common Stock","Depository Receipts","Tracking Stocks"))
Groups_notEQY <- c("Sovereign", "Agency CMBS", "Automobile ABS Other","CMBS Other","CMBS Subordinated" ,"Municipal-City" ,"Municipal-County","Debt Fund","Multi-National","Commodity Fund", "Real Estate Fund","Alternative Fund","Money Market Fund", "","Other ABS","Sovereign","Sovereign Agency","WL Collat CMO Mezzanine","WL Collat CMO Other","WL Collat CMO Sequential")

# TotalPortfolio_EQY <- subset(TotalPortfolio, (!is.na(ICB.Subsector.Name) & ICB.Subsector.Name != "") | Security.Type == "Common Stock" | (Name != Ticker & !Group %in% Groups_notEQY & !is.na(Group)), select = c("InvestorName", "PortfolioName", "ISIN", "ValueUSD"))

TotalPortfolio_EQY <- subset(TotalPortfolio, (!is.na(ICB.Subsector.Name) & ICB.Subsector.Name != "") | Security.Type == "Common Stock" | (Name != Ticker & !Group %in% Groups_notEQY & !is.na(Group)))
TotalPortfolio_EQY <- merge(TotalPortfolio_EQY, subset(BBG_Data_sub, select = c("ISIN","SharePrice")), by = "ISIN", all.x = TRUE, all.y = FALSE)

# TotalPortfolio_EQY <- subset(TotalPortfolio_EQY , !Group %in% grep("Fund",unique(TotalPortfolio_EQY $Group), value = TRUE) & SharePrice != "" & Group != "Alternative Investment", select = c("InvestorName", "PortfolioName", "ISIN", "ValueUSD"))
TotalPortfolio_EQY <- subset(TotalPortfolio_EQY , select = c("InvestorName", "PortfolioName", "ISIN", "ValueUSD"))

# Create the Cbond portfolio input files for the fund analysis
DebtData <- read.csv(paste0(FinancialDataFolder,"Cbonds_Issuer&Subs_DebtTicker_BICS_2016Q4.csv"),stringsAsFactors=FALSE,strip.white=TRUE)
# Rename Total row as to not confuse it with TOTAL SA...
DebtData$Co..Corp.TKR[DebtData$Co..Corp.TKR == "Total"] <- "TotalDebt"
GovBanksSupraNat <- subset(DebtData, (DebtData$Government.Development.Banks !=0 | DebtData$Supranationals != 0) & DebtData$Co..Corp.TKR != "TotalDebt") 
DebtData <- subset(DebtData, !DebtData$Co..Corp.TKR %in% GovBanksSupraNat$Co..Corp.TKR)


# TotalPortfolio <- read.csv(paste0(FinancialDataFolder,"FinancialData.csv"),stringsAsFactors=FALSE,strip.white=TRUE)

CorpDebtTicker <- colsplit(TotalPortfolio$Ticker, pattern = " ", names = c("COMPANY_CORP_TICKER",2,3))[1]
TotalPortfolio <- cbind(TotalPortfolio,CorpDebtTicker)

Subgroups_notBonds <- c("Sovereign", "Agency CMBS", "Automobile ABS Other","CMBS Other","CMBS Subordinated" ,"Municipal-City" ,"Municipal-County","Supranational Bank","US Municipals","FGLMC Single Family 30yr","FGLMC Single Family 15yr","GNMA Single Family 30yr","FNMA Single Family 30yr","FNMA Single Family 15yr","Export/Import Bank","Regional Authority","Regional Agencies", "Other ABS","Sovereign","Sovereign Agency","WL Collat CMO Mezzanine","WL Collat CMO Other","WL Collat CMO Sequential")
# TotalPortfolio_Bonds <- subset(TotalPortfolio, COMPANY_CORP_TICKER %in% DebtData$Co..Corp.TKR & Name == Ticker & !Subgroup %in% Subgroups_notBonds)
TotalPortfolio_Bonds <- subset(TotalPortfolio, (Name == Ticker  | Group == "Debt Fund") & !Subgroup %in% Subgroups_notBonds)
TotalPortfolio_Bonds$LoanIndicator <- sub(".* ","",TotalPortfolio_Bonds$Ticker)
TotalPortfolio_Bonds$BondTest <- sapply(TotalPortfolio_Bonds$LoanIndicator, function(x) gregexpr("[[:punct:]]",x))
TotalPortfolio_Bonds <- subset(TotalPortfolio_Bonds, BondTest != "-1" | LoanIndicator == "PERP" | Group == "Debt Fund", select = c("InvestorName", "PortfolioName", "ISIN", "ValueUSD"))
# TotalPortfolio_Bonds <- subset(TotalPortfolio_Bonds, select = c("InvestorName", "PortfolioName", "ISIN", "ValueUSD"))

TotalPortfolio$InstrumentType <- "Others"
TotalPortfolio$InstrumentType[TotalPortfolio$ISIN  %in% TotalPortfolio_EQY$ISIN] <- "Equity"
TotalPortfolio$InstrumentType[TotalPortfolio$ISIN  %in% TotalPortfolio_Bonds$ISIN] <- "Bonds"

PortSizeCheck3 <- sum(TotalPortfolio$ValueUSD, na.rm = TRUE)

PositionLevelMetaAnalysis <- merge(subset(PositionLevelMetaAnalysis,select = c("InvestorName", "PortfolioName", "ValueUSD", "Currency", "NumberofShares", "MarketValue", "ValueType", "ISIN", "ISINInfo")), ParticipantList, by = "InvestorName", all.x = TRUE)
PositionLevelMetaAnalysis <- merge(PositionLevelMetaAnalysis, unique(subset(TotalPortfolio, select = c("ISIN","InstrumentType","Group"))), all.x = TRUE, all.y = FALSE)
PositionLevelMetaAnalysis$InstrumentType[PositionLevelMetaAnalysis$ISINInfo %in% c("NA_ISIN_BBG_Data","NA_ISIN+Value_BBG_Data")] <- "NA"
# PositionLevelMetaAnalysis$InstrumentType[PositionLevelMetaAnalysis$ISINInfo == "FUND_ISIN"] <- "FUND"
PositionLevelMetaAnalysis$InstrumentType[PositionLevelMetaAnalysis$ISIN == "NA_ISIN_Input"] <- "NA_ISIN_Input"

TotalPortfolio$InvestorType[is.na(TotalPortfolio$InvestorType)] <- "Unknown"
OverviewPiechartData <- aggregate(TotalPortfolio["ValueUSD"], by = TotalPortfolio[,c("InvestorName", "PortfolioName", "HoldingType", "InvestorType", "InstrumentType")], FUN = sum)
OverviewPiechartDatawide <- dcast(OverviewPiechartData, InvestorName + PortfolioName + InvestorType + HoldingType  ~ InstrumentType, value.var = "ValueUSD")
OverviewPiechartDatawideTotal <- ddply(OverviewPiechartDatawide,.(InvestorName, PortfolioName, InvestorType),summarize, Bonds = sum(Bonds,na.rm = TRUE), Equity = sum(Equity,na.rm = TRUE), Others = sum(Others,na.rm = TRUE))
OverviewPiechartDatawideTotal$HoldingType <- "All"
OverviewPiechartDatawide <- rbind(OverviewPiechartDatawide,OverviewPiechartDatawideTotal)
OverviewPiechartDataFinal <- merge(OverviewPiechartDatawide,subset(PortfolioSizes, select =c("InvestorName", "PortfolioName", "PortfolioSizeUSD", "ValueUSDOfPositionsWOBBGWValueUSDInformation")),by = c("InvestorName","PortfolioName"), all.x = TRUE)
OverviewPiechartDataFinal <- rename(OverviewPiechartDataFinal, c("Others" = "PositionsWithValue_Ignore4piechart"))
OverviewPiechartDataFinal$Others <- OverviewPiechartDataFinal$PortfolioSizeUSD - OverviewPiechartDataFinal$Equity - OverviewPiechartDataFinal$Bonds

OverviewPiechartDataFinal <- subset(OverviewPiechartDataFinal, HoldingType == "All")
InvestorLevelIDentification <- as.data.frame(table(OverviewPiechartDataFinal$InvestorName))
SinglePorts <- subset(InvestorLevelIDentification, Freq == 1)
OverviewPiechartDataFinal$PortfolioType <- "Portfolio"
OverviewPiechartDataFinal$PortfolioType[OverviewPiechartDataFinal$InvestorName %in% SinglePorts$Var1] <- "Investor"

#create file at investor level
OverviewPiechartDataFinalMPS <- ddply(subset(OverviewPiechartDataFinal, !InvestorName %in% SinglePorts$Var1),.(InvestorName, InvestorType, HoldingType),summarize,PortfolioSizeUSD = sum(PortfolioSizeUSD,na.rm = TRUE), Bonds = sum(Bonds,na.rm = TRUE), Equity = sum(Equity,na.rm = TRUE), Others = sum(Others,na.rm = TRUE))
OverviewPiechartDataFinalMPS$PortfolioName <- OverviewPiechartDataFinalMPS$InvestorName
OverviewPiechartDataFinalMPS$PortfolioType <- "InvestorMPs"

OverviewPiechartDataFinal <- OverviewPiechartDataFinal[,colnames(OverviewPiechartDataFinalMPS)]
OverviewPiechartDataFinal <- rbind(OverviewPiechartDataFinal, OverviewPiechartDataFinalMPS)



# TotalPortfolio_Rest <- subset(TotalPortfolio, !ISIN %in% TotalPortfolio_Bonds$ISIN)
# write.csv(TotalPortfolio_Rest, "BondFilter_Test_Rest.csv", row.names = FALSE)
# write.csv(subset(TotalPortfolio_Bonds,select = -c(BondTest)), "BondFilter_Test_Bonds.csv", row.names = FALSE)

setwd(paste0(OutputLocation))
write.csv(OverviewPiechartDataFinal,paste0(PortfolioHoldings,"Portfolio_Overview_Piechart4.csv"),row.names = FALSE, na = "")
# write.csv(OverviewPiechartDataFinal,paste0(PortfolioHoldings,"Portfolio_Overview_Piechart_MetaAnalysis.csv"),row.names = FALSE, na = "")

write.csv(MissingISINs,paste0(PortfolioHoldings,"Missing_BBG-Data4.csv"), row.names = FALSE, na = "")
write.csv(PortfolioData_w_BBG,paste0(PortfolioHoldings,"PortfolioData_w_BBG-Info4.csv"),row.names = FALSE, na = "")
write.csv(TotalPortfolio,paste0(PortfolioHoldings,"Port4.csv"),row.names = FALSE, na = "")
write.csv(TotalPortfolio_EQY,paste0(PortfolioHoldings,"Port_EQY4.csv"),row.names = FALSE, na = "")
write.csv(TotalPortfolio_Bonds,paste0(PortfolioHoldings,"Port_Bonds4.csv"),row.names = FALSE, na = "")
write.csv(FundCoverage,paste0(PortfolioHoldings,"Port_ListofFunds4.csv"),row.names = FALSE, na = "")
write.csv(PortfolioMetaAnalysis,paste0(PortfolioHoldings,"Portfolio_Metaanalysis4.csv"),row.names = FALSE, na = "")
write.csv(FundMetaanalysis,paste0(PortfolioHoldings,"Portfolio_Funds_Metaanalysis_details4.csv"),row.names = FALSE, na = "")
write.csv(NegativeValues,paste0(PortfolioHoldings,"Portfolio_negativeValues4.csv"),row.names = FALSE, na = "")
write.csv(PositionLevelMetaAnalysis,paste0(PortfolioHoldings,"_PositionLevelMetaAnalysis4.csv"),row.names = FALSE, na = "")
