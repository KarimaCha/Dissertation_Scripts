# script to plot fMRI Regressors from computational modeling in STAN
# 
# written by: Karima Chakroun, UKE, Hamburg, 2017


# =============================================================================
#### Get data ####
# =============================================================================

rm(list=ls())
setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN")
load('_data/dabandit_data.Rdata')

choice = dabandit_data[1,,,1];  # only Placebo, all subjects
reward = dabandit_data[1,,,2];  # only Placebo, all subjects


# =============================================================================
#### Get model parameters (medians) from StanFit ####
# =============================================================================

require(rstan)
require(loo)

modelnames <- c('BayesSM', 'BayesSMeb', 'BayesSMebP')
whichModel <- 3
  
if (whichModel == 1) {
  load('_outputs/dabandit_STAN_BayesSMf_mp_indv.Rdata')  # fit_rl
} else if (whichModel == 2) {
  load('_outputs/dabandit_STAN_BayesSMeb_mp_indv_Plac_newFix_noLim.Rdata')  # fit_rl
  #load('_outputs/dabandit_STAN_BayesSMeb_mp_indv_Plac.Rdata')  # fit_rl
} else if (whichModel == 3) {
  load('_outputs/dabandit_STAN_BayesSMebP_mp_indv_Plac_newFix_noLim.Rdata')  # fit_rl
  #load('_outputs/dabandit_STAN_BayesSMebP_mp_indv_Plac.Rdata')  # fit_rl
}

# REMARK for Daw-like analysis:
# only the 5 walk-parameters influence value-updates, thus for models with fix walk-parameters,
# values with/without boni can be compared using directly the full SMebP-model (not SMf/SMeb needed)

nSubj <- fit_rl@par_dims$beta
withPhi <- sum(fit_rl@model_pars=='phi')
withPersev <- sum(fit_rl@model_pars=='persev')

beta_medians   <- numeric(nSubj)
phi_medians    <- numeric(nSubj)
persev_medians <- numeric(nSubj)

for (s in 1:nSubj) {
  
  beta_s = paste0("beta[", s, "]")
  beta_post <- extract_log_lik(fit_rl, beta_s)
  beta_medians[s] <- median(beta_post)
  
  if (withPhi) {  
    phi_s = paste0("phi[", s, "]")
    phi_post <- extract_log_lik(fit_rl, phi_s)
    phi_medians[s] <- median(phi_post)
  }
  
  if (withPersev) {
    persev_s = paste0("persev[", s, "]")
    persev_post <- extract_log_lik(fit_rl, persev_s)
    persev_medians[s] <- median(persev_post)
  }
}


# =============================================================================
#### Compute trial-by-trial regressors ####
# =============================================================================

nTrials <- 300
nBandits <- 4

#### get trial-by-trial values for these variables:
v     <- array(NA, c(nSubj, nTrials, nBandits))  # value (mu)
sig   <- array(NA, c(nSubj, nTrials, nBandits))  # sigma (uncertainty)
eb    <- array(NA, c(nSubj, nTrials, nBandits))  # exploration bonus
pb    <- array(NA, c(nSubj, nTrials, nBandits))  # perseveration bonus
pa    <- array(NA, c(nSubj, nTrials, nBandits))  # choice probability
pe    <- array(NA, c(nSubj, nTrials))            # prediction error
Kgain <- array(NA, c(nSubj, nTrials))            # Kalman gain

#### create log_lik matrix (one value per subject, cumulated over trials)
log_lik <- numeric(nSubj)
add_log_lik <- array(NA, c(nSubj, nTrials))

#### define parameters of random walk (new Fix)
if (whichModel == 1) {
  initV = rep(50.0, 4)
  initSig = rep(4.0, 4)
  sigO = 4
  sigD = 2.8
  decay = 0.9836
  decay_center = 50
} else if (whichModel == 2) {
  initV = rep(83.36, 4)  #rep(50.0, 4)
  initSig = rep(3.02, 4) #rep(4.0, 4)
  sigO = 4
  sigD = 5.22 #2.8
  decay = 0.90 #0.9836
  decay_center = 57.13 #50
} else if (whichModel == 3) {
  initV = rep(84.01, 4)  #rep(50.0, 4)
  initSig = rep(3.29, 4) #rep(4.0, 4)
  sigO = 4
  sigD = 4.88 #2.8
  decay = 0.92 #0.9836
  decay_center = 47.67 #50
}

#### loop over subjects and trials:
for (s in 1:nSubj) {
  #  s=1  # choose subject to plot regressors for
  
  # get medians of choice parameter for this subject
  beta   <- beta_medians[s]
  
  if (withPhi) { 
    phi    <- phi_medians[s]
  }
  
  if (withPersev) {
    persev <- persev_medians[s]
  }
  
  # set initial values for t=1
  v[s,1,] = initV
  sig[s,1,] = initSig
  log_lik[s] = 0; 
  
  for (t in 1:nTrials) { 
    
    if (withPhi) { 
      eb[s,t,] = phi * sig[s,t,];
    }
    
    if (withPersev) {
      pb[s,t,] = rep(0.0, nBandits);
      
      if (t>1) {
        if (choice[s,t-1] !=0) {
          pb[s,t,choice[s,t-1]] = persev;
        } else {
          
          if (t>2) {
            if (choice[s,t-2] !=0) {
              pb[s,t,choice[s,t-2]] = persev;
            }
          }
          
        }
      }
    }
    
    
    if (choice[s,t] != 0) {
      
      # compute action probabilities and log_lik
      if (whichModel == 1) {
        pa[s,t,] = exp(beta * (v[s,t,])) / sum(exp(beta * (v[s,t,]))) 
      } else if (whichModel == 2) {
        pa[s,t,] = exp(beta * (v[s,t,] + eb[s,t,])) / sum(exp(beta * (v[s,t,] + eb[s,t,])))
      } else if (whichModel == 3) {
        pa[s,t,] = exp(beta * (v[s,t,] + eb[s,t,] + pb[s,t,])) / sum(exp(beta * (v[s,t,] + eb[s,t,] + pb[s,t,]))) 
      }
      
      add_log_lik[s,t] = log(pa[s,t,choice[s,t]])
      log_lik[s] = log_lik[s] + add_log_lik[s,t]
      
      pe[s,t] = reward[s,t] - v[s,t,choice[s,t]]  # prediction error 
      Kgain[s,t] = sig[s,t,choice[s,t]]^2 / (sig[s,t,choice[s,t]]^2 + sigO^2) # Kalman gain
      
      if (t < nTrials) {
        
        v[s,t+1,] = v[s,t,];
        v[s,t+1,choice[s,t]] = v[s,t,choice[s,t]] + Kgain[s,t] * pe[s,t]  # value/mu updating (learning)
        
        sig[s,t+1,] = sig[s,t,];
        sig[s,t+1,choice[s,t]] = sqrt( (1-Kgain[s,t]) * sig[s,t,choice[s,t]]^2 ) # sigma updating
      }
      
    } else {
      pe[s,t] = NA;
      Kgain[s,t] = NA;
      
      v[s,t+1,] = v[s,t,]; 
      sig[s,t+1,] = sig[s,t,];
    }
    
    if (t < nTrials) {
      v[s,t+1,] = decay * v[s,t+1,] + (1-decay) * decay_center 
      sig[s,t+1,] = sqrt( decay^2 * sig[s,t+1,]^2 + sigD^2 )
    }
    
  }
}
  
  
#### create Regressor list
Reg <- list()
Reg$v   <- v
Reg$sig <- sig
Reg$pa  <- pa
Reg$pe  <- pe
Reg$eb  <- eb
Reg$pb  <- pb
Reg$Kgain <- Kgain
Reg$addLL <- add_log_lik
Reg$LL    <- log_lik


#filename <- "C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN/_outputs/Regressors/reg_BayesSMebP_mp_indv_Plac_newFix_noLim.Rdata"
#save(file=filename, Reg)

# # for Matlab
# require(R.matlab)
# filenameMat <- "C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN_damem2/_outputs/Regressors/DeltaSM_1hp_excl51_Regressors.mat"
# writeMat(filenameMat, Reg = Reg)




#==============================================================================
### Log_lik histogram
hist(exp(add_log_lik), main=modelnames[whichModel],ylim=c(0,3000))


#==============================================================================
### check: how often is the persev-bandit equal to the max-value bandit (exploit)
### > persev-parameter might be interpreted differently, eg as exploitation-bonus

persev_equals_maxV <- numeric(nSubj)
persev_equals_minSig <- numeric(nSubj)

for (s in 1:nSubj) {
  maxBandit <- apply(v[s,,],1,which.max)
  persevBandit <- apply(abs(pb[s,,]),1,which.max)
  #neu2[apply(pb[1,,],1,sum)==0] <- 0
  minSigmaBandit <- apply(abs(sig[s,,]),1,which.min)
  
  persev_equals_maxV[s] <- sum(maxBandit==persevBandit)
  persev_equals_minSig[s] <- sum(minSigmaBandit==persevBandit)
}

barplot(persev_equals_maxV,ylim=c(0,300),ylab="persevBandit = maxBandit",col="blue")
barplot(persev_equals_minSig,ylim=c(0,300),ylab="persevBandit = minSigBandit",col="green")

#neu <- as.numeric(((pb[1,,]!=0) * 1) %*% matrix(1:4,ncol=1))
#neu <- unlist(apply(pb[1,,],1,function(x){if(sum(abs(x))>0){which(abs(x)>0)}else{0}}))

#==============================================================================



# =============================================================================
#### Plot trial-by-trial regressors ####
# =============================================================================

setwd("C:/Users/chakroun/Documents/!02_DABANDIT_Studie/!dabandit_CogModeling/Bayes_STAN")
load('_data/dabandit_data_31.Rdata')

choice = dabandit_data_31$choices[1,,];  # only Placebo, all subjects
reward = dabandit_data_31$rewards[1,,];  # only Placebo, all subjects
subjIDs <- dabandit_data_31$subjIDs

col_bandits <- c('black','blue','red','yellow','green')


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Loop over subjects
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.pardefault <- par()

x = 1:nTrials
for (s in 1:1) { #nSubj) {
  
  subjID <- subjIDs[s]
  phi=phi_medians[s]
  persev=persev_medians[s]

  # plot prediction error
  plot(x, pe[s,], type="l", ylim=c(-50,50),
       ylab='prediction error', xlab='trial',
       main = subjID)
  
  # plot Kalman gain
  plot(x, Kgain[s,], type="l", ylim=c(0,1),
       ylab='Kalman gain', xlab='trial',
       main = subjID)

  # plot Kalman gain together with sig (uncertainty) 
  plot(x, Kgain[s,], type="l", ylim=c(0,1), ylab='Kalman gain + uncertainty (/25)', xlab='trial', main = subjID)
  lines(x,sig[s,,1]/25, type="l", col=col_bandits[2])
  lines(x,sig[s,,2]/25, type="l", col=col_bandits[3])
  lines(x,sig[s,,3]/25, type="l", col=col_bandits[4])
  lines(x,sig[s,,4]/25, type="l", col=col_bandits[5])
  
  
  # plot v (expected values)
  plot(x,v[s,,1], type="l", col=col_bandits[2],   # type="o"
       ylim=c(0,125),ylab='expected value',xlab='trial',
       main = subjID)  
  lines(x,v[s,,2], type="l", col=col_bandits[3])
  lines(x,v[s,,3], type="l", col=col_bandits[4])
  lines(x,v[s,,4], type="l", col=col_bandits[5])
  #abline(h=50,col="grey")
  
  # add choices & rewards
  points(x, reward[s,], pch = 16, cex=0.4, 
         col = col_bandits[choice[s,]+1])
  #points(x, rep(100,nTrials), pch = 16, cex=0.3,
  #       col = col_bandits[choice[s,]+1])

  # plot v + eb
  plot(x,v[s,,1]+eb[s,,1], type="l", col=col_bandits[2],   # type="o"
       ylim=c(0,125),ylab='expected value + eb',xlab='trial',
       main = subjID)  
  lines(x,v[s,,2]+eb[s,,2], type="l", col=col_bandits[3])
  lines(x,v[s,,3]+eb[s,,3], type="l", col=col_bandits[4])
  lines(x,v[s,,4]+eb[s,,4], type="l", col=col_bandits[5])
  
  
  # plot v + eb + pb
  plot(x,v[s,,1]+eb[s,,1]+pb[s,,1], type="l", col=col_bandits[2],   # type="o"
       ylim=c(0,125),ylab='expected value + eb + pb',xlab='trial',
       main = subjID)  
  lines(x,v[s,,2]+eb[s,,2]+pb[s,,2], type="l", col=col_bandits[3])
  lines(x,v[s,,3]+eb[s,,3]+pb[s,,3], type="l", col=col_bandits[4])
  lines(x,v[s,,4]+eb[s,,4]+pb[s,,4], type="l", col=col_bandits[5])
  
  
  # plot variance (sig^2)
  plot(x,sig[s,,1]^2, type="l", col=col_bandits[2],
       ylab='variance (sig^2)',xlab='trial',
       main = subjID)
  lines(x,sig[s,,2]^2, type="l", col=col_bandits[3])
  lines(x,sig[s,,3]^2, type="l", col=col_bandits[4])
  lines(x,sig[s,,4]^2, type="l", col=col_bandits[5])
  
  # add asymptote: variance (sig^2) approaches this value
  max_variance <- sigD^2 / (1-decay^2)  
  abline(h=max_variance,lty="dashed")
  
  
  # plot uncertainties (sig)
  plot(x,sig[s,,1], type="l", col=col_bandits[2], ylim=c(0,35),
       ylab='uncertainty (sig)',xlab='trial',
       main = subjID)
  lines(x,sig[s,,2], type="l", col=col_bandits[3])
  lines(x,sig[s,,3], type="l", col=col_bandits[4])
  lines(x,sig[s,,4], type="l", col=col_bandits[5])
  
  
  # plot exploration bonus (same as plot with phi*sig)
  plot(x,eb[s,,1], type="l", col=col_bandits[2], ylim=c(0,35),   # type="o"
       ylab='exploration bonus',xlab='trial',
       main = subjID)
  lines(x,eb[s,,2], type="l", col=col_bandits[3])
  lines(x,eb[s,,3], type="l", col=col_bandits[4])
  lines(x,eb[s,,4], type="l", col=col_bandits[5])
  
  
  # plot perseveration bonus
  # plot(x,pb[s,,1], type="l", col=col_bandits[2], #ylim=c(0,110),  # type="o"
  #      ylab='perseveration bonus',xlab='trial',
  #      main = subjID)
  # lines(x,pb[s,,2], type="l", col=col_bandits[3])
  # lines(x,pb[s,,3], type="l", col=col_bandits[4])
  # lines(x,pb[s,,4], type="l", col=col_bandits[5])
  par(mfrow=c(4,1),mar=c(2,4,1.5,1)) 
  plot(x,pb[s,,1], type="l", col=col_bandits[2], #ylim=c(0,110),  # type="o"
       ylab='persev',xlab='trial', main = subjID)
  plot(x,pb[s,,2], type="l", col=col_bandits[3],ylab='persev',xlab='trial')
  plot(x,pb[s,,3], type="l", col=col_bandits[4],ylab='persev',xlab='trial')
  plot(x,pb[s,,4], type="l", col=col_bandits[5],ylab='persev',xlab='trial')
  par(mfrow=c(1,1),mar=c(5.1, 4.1, 4.1, 2.1))
  

  # plot action probabilities
  plot(x,pa[s,,1], type="l", col=col_bandits[2],   # type="o"
       ylim=c(0,1),ylab='action probability',xlab='trial',
       main = subjID)  
  lines(x,pa[s,,2], type="l", col=col_bandits[3])
  lines(x,pa[s,,3], type="l", col=col_bandits[4])
  lines(x,pa[s,,4], type="l", col=col_bandits[5])
  
  #filename <- paste0('_plots/Regressor_plots/BayesSMebP_mp_indv_Plac_newFix_noLim/regPlot_', subjID, '.png')  
  #dev.copy(png, filename); dev.off();

}