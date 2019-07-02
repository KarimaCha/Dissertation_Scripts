data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;               
  int<lower=0,upper=4> choice[nSubjects, nTrials];     
  real<lower=0, upper=100> reward[nSubjects, nTrials]; 
  }

transformed data {
  real<lower=0, upper=100> v1;
  real<lower=0> sig1;
  real<lower=0> sigO;
  real<lower=0> sigD;
  real<lower=0,upper=1> decay;
  real<lower=0, upper=100> decay_center;
  
  v1 = 50.0;
  sig1 = 4.0;
  sigO = 4.0;
  sigD = 2.8;
  decay = 0.9836;
  decay_center = 50;
}

parameters {
  real<lower=0,upper=3> beta_mu;

  real<lower=0> beta_sd;

  real<lower=0,upper=3> beta[nSubjects]; 
 
}

model {
  beta_sd ~ cauchy(0,1);
  beta    ~ normal(beta_mu, beta_sd) ;  
  
  for (s in 1:nSubjects) {
    vector[4] v;   # value (mu)
    vector[4] sig; # sigma
    real pe;       # prediction error
    real Kgain;    # Kalman gain

    v = rep_vector(v1, 4);
    sig = rep_vector(sig1, 4);

    for (t in 1:nTrials) {        
    
    if (choice[s,t] != 0) {
      choice[s,t] ~ categorical_logit( beta[s] * v );  # compute action probabilities
      pe = reward[s,t] - v[choice[s,t]];  # prediction error 
      Kgain = sig[choice[s,t]]^2 / (sig[choice[s,t]]^2 + sigO^2); # Kalman gain
      
      v[choice[s,t]] = v[choice[s,t]] + Kgain * pe;  # value/mu updating (learning)
      sig[choice[s,t]] = sqrt( (1-Kgain) * sig[choice[s,t]]^2 ); # sigma updating
    }
    
    v = decay * v + (1-decay) * decay_center;  
    for (j in 1:4) 
    sig[j] = sqrt( decay^2 * sig[j]^2 + sigD^2 );
    #sig = sqrt( decay^2 * sig^2 + sigD^2 );  # no elementwise exponentiation in STAN!

    }
  }  
}

generated quantities{
  real log_lik[nSubjects];   

  for (s in 1:nSubjects) {
    vector[4] v;   # value (mu)
    vector[4] sig; # sigma
    real pe;       # prediction error
    real Kgain;    # Kalman gain

    v = rep_vector(v1, 4);
    sig = rep_vector(sig1, 4);
    
    log_lik[s] = 0; 

    for (t in 1:nTrials) {        
    
    if (choice[s,t] != 0) {
      log_lik[s] = log_lik[s] + categorical_logit_lpmf(choice[s,t] | beta[s] * v);  

      pe = reward[s,t] - v[choice[s,t]];  # prediction error 
      Kgain = sig[choice[s,t]]^2 / (sig[choice[s,t]]^2 + sigO^2); # Kalman gain
      
      v[choice[s,t]] = v[choice[s,t]] + Kgain * pe;  # value/mu updating (learning)
      sig[choice[s,t]] = sqrt( (1-Kgain) * sig[choice[s,t]]^2 ); # sigma updating
    }
    
    v = decay * v + (1-decay) * decay_center;  
    for (j in 1:4) 
    sig[j] = sqrt( decay^2 * sig[j]^2 + sigD^2 );
    #sig = sqrt( decay^2 * sig^2 + sigD^2 );  # no elementwise exponentiation in STAN!

    }
  } 
}


