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
  real<lower=0,upper=3> beta[nSubjects]; 
  real phi[nSubjects];
  real persev[nSubjects];
}

model {
  for (s in 1:nSubjects) {
    vector[4] v;   # value (mu)
    vector[4] sig; # sigma
    vector[4] eb;  # exploration bonus
    vector[4] pb;  # perseveration bonus
    real pe;       # prediction error
    real Kgain;    # Kalman gain

    v = rep_vector(v1, 4);
    sig = rep_vector(sig1, 4);

    for (t in 1:nTrials) {        
    
    if (choice[s,t] != 0) {
      
      eb = phi[s] * sig;
      pb = rep_vector(0.0, 4);
      
      if (t>1) {
        if (choice[s,t-1] !=0) {
          pb[choice[s,t-1]] = persev[s];
        } else {
                    
          if (t>2) {
            if (choice[s,t-2] !=0) {
              #pb[choice[s,t-2]] = persev[s];
            }
          }
      
        }
      }
      
      
      choice[s,t] ~ categorical_logit( beta[s] * (v + eb + pb) ); # compute action probabilities

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
    vector[4] eb;  # exploration bonus
    vector[4] pb;  # perseveration bonus
    real pe;       # prediction error
    real Kgain;    # Kalman gain

    v = rep_vector(v1, 4);
    sig = rep_vector(sig1, 4);
    
    log_lik[s] = 0;    

    for (t in 1:nTrials) {   
      
      if (choice[s,t] != 0) {
        
        eb = phi[s] * sig;
        pb = rep_vector(0.0, 4);
      
        if (t>1) {
          if (choice[s,t-1] !=0) {
            pb[choice[s,t-1]] = persev[s];
          } else {
                      
            if (t>2) {
              if (choice[s,t-2] !=0) {
                #pb[choice[s,t-2]] = persev[s];
              }
            }
        
          }
        }
        
        
        log_lik[s] = log_lik[s] + categorical_logit_lpmf(choice[s,t] | beta[s] * (v + eb + pb) );  

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


