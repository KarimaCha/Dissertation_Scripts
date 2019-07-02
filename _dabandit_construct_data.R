# script to construct .Rdata from .mat data of study dabandit for RL modeling in STAN
# 
# written by: Karima Chakroun, UKE, Hamburg, 2017


rm(list = ls()) # clear workspace
require(R.matlab)

setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!LOGFILES/LOGFILES_25may16_complete")


########################################
#  Get filenames from logfiles folder
########################################

folders_d1 <- dir('Bandit_Day1')
folders_d2 <- dir('Bandit_Day2')
folders_d3 <- dir('Bandit_Day3')

subjIDs <- substr(folders_d3,1,10)
nSubj   <- length(subjIDs)
nDrugs  <- 3
nTrials <- 300

drugList <- read.table("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/Subjects/dabandit_drugOrder.txt", header=T)

drugList$VP.Nummer
drugList$Reihenfolge

data <- list()
data$subjIDs <- subjIDs
data$choices <- array(NA, c(nDrugs, nSubj, nTrials))
data$rewards <- array(NA, c(nDrugs, nSubj, nTrials))
data$payouts <- array(NA, c(nDrugs, nSubj, nTrials, 4))
data$rt      <- array(NA, c(nDrugs, nSubj, nTrials))
data$total_payout <- array(NA, c(nDrugs, nSubj))             


######### loop over subjects ####################

for (s in 1:nSubj) {  #nSubj) {
  
  subjID <- subjIDs[s]
  drugOrder <- drugList$Reihenfolge[drugList$VP.Nummer==subjID]
  
  ############  Placebo  ###############
  pos <- regexpr("P", drugOrder)
  folder_P <- paste0('Bandit_day', pos, '/', subjID, '_d', pos)
  file_P   <- dir(folder_P)
  
  if (subjID != "02_01_0120") {   # s=19
    
    neu <- readMat(paste0(folder_P, '/', file_P[1]))
    RespMatrix <- neu$p[,,1]$keys[,,1]$RespMatrix
    RespButton <- RespMatrix[,2:5]
    data$choices[1,s,] <- RespButton %*% c(1,2,3,4)    # choices recoded with 1,2,3,4

    Payouts <- RespMatrix[,6:9]
    data$payouts[1,s,,] <- Payouts
    data$rt[1,s,] <- RespMatrix[,10]
    
    Rewards_all <- RespButton * Payouts
    data$rewards[1,s,] <- round(rowSums(Rewards_all))  # reward of chosen bandit
    data$total_payout[1,s] <- ceiling(sum(data$rewards[1,s,])*0.05)/100
  
  } else {
    
    neu1 <- readMat(paste0(folder_P, '/', file_P[2]))
    neu2 <- readMat(paste0(folder_P, '/', file_P[3]))
    
    # Trial 1-225
    RespMatrix1 <- neu1$p[,,1]$keys[,,1]$RespMatrix
    RespButton1 <- RespMatrix1[1:225,2:5]
    data$choices[1,s,1:225] <- RespButton1 %*% c(1,2,3,4)    # choices recoded with 1,2,3,4

    Payouts1 <- RespMatrix1[1:225,6:9]
    data$payouts[1,s,1:225,] <- Payouts1
    data$rt[1,s,1:225] <- RespMatrix1[1:225,10]
    
    Rewards_all1 <- RespButton1 * Payouts1
    data$rewards[1,s,1:225] <- round(rowSums(Rewards_all1))  # reward of chosen bandit

    # Trial 226-300
    RespMatrix2 <- neu2$p[,,1]$keys[,,1]$RespMatrix
    RespButton2 <- RespMatrix2[226:300,2:5]
    data$choices[1,s,226:300] <- RespButton2 %*% c(1,2,3,4)    # choices recoded with 1,2,3,4
    
    Payouts2 <- RespMatrix2[226:300,6:9]
    data$payouts[1,s,226:300,] <- Payouts2
    data$rt[1,s,226:300] <- RespMatrix2[226:300,10]
    
    Rewards_all2 <- RespButton2 * Payouts2
    data$rewards[1,s,226:300] <- round(rowSums(Rewards_all2))  # reward of chosen bandit
    
    data$total_payout[1,s] <- ceiling(sum(data$rewards[1,s,])*0.05)/100
    
  }
  

  ############  LDopa   ###############
  pos = regexpr("D", drugOrder)
  folder_D <- paste0('Bandit_day', pos, '/', subjID, '_d', pos)
  file_D   <- dir(folder_D)  
  neu <- readMat(paste0(folder_D, '/', file_D))
  
  RespMatrix <- neu$p[,,1]$keys[,,1]$RespMatrix
  RespButton <- RespMatrix[,2:5]
  data$choices[2,s,] <- RespButton %*% c(1,2,3,4)    # choices recoded with 1,2,3,4
  
  Payouts <- RespMatrix[,6:9]
  data$payouts[2,s,,] <- Payouts
  data$rt[2,s,] <- RespMatrix[,10]
  
  Rewards_all <- RespButton * Payouts
  data$rewards[2,s,] <- round(rowSums(Rewards_all))  # reward of chosen bandit
  data$total_payout[2,s] <- ceiling(sum(data$rewards[2,s,])*0.05)/100
  
  
  ############  Haldol   ###############
  pos = regexpr("H", drugOrder)
  paste0('day', pos)
  folder_H <- paste0('Bandit_day', pos, '/', subjID, '_d', pos)
  file_H   <- dir(folder_H) 
  neu <- readMat(paste0(folder_H, '/', file_H))
  
  RespMatrix <- neu$p[,,1]$keys[,,1]$RespMatrix
  RespButton <- RespMatrix[,2:5]
  data$choices[3,s,] <- RespButton %*% c(1,2,3,4)    # choices recoded with 1,2,3,4
  
  Payouts <- RespMatrix[,6:9]
  data$payouts[3,s,,] <- Payouts
  data$rt[3,s,] <- RespMatrix[,10]
  
  Rewards_all <- RespButton * Payouts
  data$rewards[3,s,] <- round(rowSums(Rewards_all))  # reward of chosen bandit  
  data$total_payout[3,s] <- ceiling(sum(data$rewards[3,s,])*0.05)/100
  
}

# save data

dabandit_data_31 <- data
setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN")
save(file="_data/dabandit_data_31.Rdata", dabandit_data_31)


################################################################
# check if new data set is equal to the one used for Stanfits (dabandit_data.Rdata) > equal!

setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN")
load("_data/dabandit_data.Rdata")
load("_data/dabandit_data_31.Rdata")

all.equal(dabandit_data_31$choices, dabandit_data[,,,1])   # all.equal=TRUE
all.equal(dabandit_data_31$rewards, dabandit_data[,,,2])   # all.equal=TRUE


