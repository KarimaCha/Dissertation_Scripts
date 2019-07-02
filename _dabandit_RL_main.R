# =============================================================================
#### Info ####
# =============================================================================
# run reinforcement learning model with R/Stan
# written by: Karima Chakroun, UKE, Hamburg, 2017


run_fit_rl <- function(level = 2, model = 4) {

# clear workspace
#rm(list = ls())

#level <- 5  
levels <- c('sp_ss', 'smp_indv',    # 1,2 (only Placebo)
            'mp_indv', 'mp_hrch',   # 3,4 (only Placebo)

            'mp_hrch_1hp1',         # 5   (all drugs with  1 hyperparameter > 3 parameters per subject)
            'mp_hrch_1hp3',         # 6   (all drugs with 1 hyperparameter > 1 parameter per subject)
            'mp_hrch_3hp',          # 7   (all drugs with 3 hyperparameters)

            'mp_hrch_1hp1_Opt',     # 8
            'mp_hrch_1hp3_Opt',     # 9
            'mp_hrch_3hp_Opt',      # 10

            'mp_indv_Plac',        # 11  (only Placebo)
            'mp_indv_Dopa',        # 12  (only LDopa)
            'mp_indv_Hald',        # 13  (only Haloperidol)

            'mp_hrch_Opt_Plac',     # 14  (only Placebo)
            'mp_hrch_Opt_Dopa',     # 15  (only LDopa)
            'mp_hrch_Opt_Hald')     # 16  (only Haloperidol)

#model <- 4  
models <- c('DeltaSMf', 'DeltaSMebP',       # 1,2
            'BayesSMeb', 'BayesSMebP',      # 3,4 
            'BayesSMebKC', 'BayesSoSMebP',  # 5,6  
            'DeltaEG',   'BayesEG')         # 7,8

modelname <- paste(models[model], '_', levels[level], sep="")


# =============================================================================
#### Construct Data ####
# =============================================================================

library(rstan)
library(ggplot2)
#library(R.matlab)
#library(loo)

###

PC = Sys.info()[[4]]
if(PC=="ISNA01D48F4A2C8") {
    setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN")
} else {
    setwd("/projects/crunchie/chakroun/Bayes_STAN")
}

load('_data/dabandit_data.Rdata')
sz <- dim(dabandit_data)   # dabandit_data[3(drugs),31(subjects),300(trials),2(ch/rew)]
nTrials <- sz[3]  #100 

if (level == 1) {
  nSubjects <- 1
  dataList <- list(nTrials = nTrials,
                   choice = dabandit_data[1,1,,1],  # only Placebo of 1. subject
                   reward = dabandit_data[1,1,,2])  # only Placebo of 1. subject
} else if (level==2 | level==3 | level==4 | level>=11) {
  nSubjects <- sz[2]
  drug=1
  if (level==12 | level==15) {drug=2}
  if (level==13 | level==16) {drug=3}
  dataList <- list(nSubjects = nSubjects,
                   nTrials = nTrials,
                   choice = dabandit_data[drug,,,1],  # only Placebo/Ldopa/Haldol of all subjects
                   reward = dabandit_data[drug,,,2])  # only Placebo/Ldopa/Haldol of all subjects
} else if (level>=5 & level<=10) {
  nSubjects <- sz[2]  #4
  nConditions <- sz[1]
  dataList <- list(nSubjects = nSubjects,
                   nTrials = nTrials,
                   nConditions = nConditions,
                   choice = dabandit_data[,1:nSubjects,1:nTrials,1],   # all drugs of all subjects
                   reward = dabandit_data[,1:nSubjects,1:nTrials,2])   # all drugs of all subjects
}


# #### if all drugs at once (n=93)
# nSubjects <- sz[2]*3
# dataList <- list(nSubjects = nSubjects,
#                  nTrials = nTrials,
#                  choice = rbind(dabandit_data[1,,,1],dabandit_data[2,,,1],dabandit_data[3,,,1]) ,  # only Placebo/Ldopa/Haldol of all subjects
#                  reward = rbind(dabandit_data[1,,,2],dabandit_data[2,,,2],dabandit_data[3,,,2]) )


# load gaps only for DeltaSMeb model: gaps[3(drugs),31(subjects),300(trials),4(bandits)]
if (model==2) {    
  load('_data/dabandit_gaps.Rdata')   
  if (level == 1) {
    dataList$gaps <- gaps[1,1,,]    # only Placebo of 1. subject
  } else if (level==2 | level==3 | level==4 | level>=11) {
    dataList$gaps <- gaps[drug,,,]  # only Placebo of all subjects
  } else if (level>=5 & level<=10) {
    dataList$gaps <- gaps[,,,]      # all drugs of all subjects
  }
}


# =============================================================================
#### Running Stan ####
# =============================================================================

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())  # options(mc.cores = 2)

modelFile <- paste('_scripts/', modelname, '_model.stan',sep="")
if (level==11 | level==12 | level==13) {
  modelFile <- paste('_scripts/', models[model], '_', substr(levels[level],1,nchar(levels[level])-5), '_model.stan', sep="")
  #modelFile <- paste('_scripts/', models[model], '_smp_hrch_model.stan', sep="") # same modelfile for all drugs
} else if (level==14 | level==15 | level==16) {
  modelFile <- paste('_scripts/', models[model], '_mp_hrch_Opt_model.stan', sep="") # same modelfile for all drugs
}

nIter     <- 2000
nChains   <- 4
nWarmup   <- floor(nIter / 2)
nThin     <- 1

startTime = Sys.time()   
print(startTime)
cat("Estimating", modelFile, "model... \n")
cat("Calling", nChains, "simulations in Stan... \n")

fit_rl <- stan(
  modelFile,
  data    = dataList,
  chains  = nChains,
  iter    = nIter,
  warmup  = nWarmup,
  thin    = nThin,
  init    = "random",
  seed    = 1450154637
)

endTime = Sys.time()  
print(endTime)
cat("Finishing", modelFile, "model simulation ... \n")
cat("It took", as.character.Date(endTime - startTime), "\n")

filename <- paste("_outputs/dabandit_STAN_", modelname, "_noLim.Rdata", sep="")
save(fit_rl, file = filename) # save result

return(fit_rl)
}


# =============================================================================
#### Call function ####
# =============================================================================

fit_rl <- run_fit_rl(11,2)
rm(fit_rl)

fit_rl <- run_fit_rl(12,2)
rm(fit_rl)

fit_rl <- run_fit_rl(13,2)
rm(fit_rl)

#############


# lev = c(11,12,13)
# mod = c(6)
# 
# for (y in lev) {
#   for (x in mod) {
#     fit_rl <- run_fit_rl(y,x,0)
#     rm(fit_rl)
#   }
# }

