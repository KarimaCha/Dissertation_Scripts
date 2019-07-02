data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  int<lower=0,upper=4> choice[nSubjects, nTrials];     
  real<lower=0, upper=100> reward[nSubjects, nTrials]; 
  vector[4] gaps[nSubjects, nTrials];   # how many trials was bandit not chosen?
}

transformed data {
  real<lower=0, upper=100> v1;  # initial values for V
  v1 = 50.0;
}

parameters {
  real<lower=0,upper=1> lr[nSubjects];
  real<lower=0,upper=3> beta[nSubjects];
  real phi[nSubjects];
  real persev[nSubjects];
}

model {
  for (s in 1:nSubjects) {
    vector[4] v;    # value
    real pe;        # prediction error
    vector[4] eb;   # exploration bonus
    vector[4] pb;  # perseveration bonus
        
    v = rep_vector(v1, 4);

    for (t in 1:nTrials) {   

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
      
      if (choice[s,t] != 0) {
        
        eb = phi[s] * gaps[s,t];
        choice[s,t] ~ categorical_logit( beta[s] * (v + eb + pb) ); # compute action probabilities
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] = v[choice[s,t]] + lr[s] * pe; 
        
      }
    }
  }    
}

generated quantities{
  real log_lik[nSubjects];

  for (s in 1:nSubjects) {
    vector[4] v;    # value
    real pe;        # prediction error
    vector[4] eb;   # exploration bonus
    vector[4] pb;  # perseveration bonus
    
    v = rep_vector(v1, 4);
    log_lik[s] = 0;

    for (t in 1:nTrials) { 
      
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
      
      if (choice[s,t] != 0) {
        
        eb = phi[s] * gaps[s,t];
        log_lik[s] = log_lik[s] + categorical_logit_lpmf(choice[s,t] | beta[s] * (v + eb + pb) ); 
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] = v[choice[s,t]] + lr[s] * pe; 
        
      }
    }
  }   
}

