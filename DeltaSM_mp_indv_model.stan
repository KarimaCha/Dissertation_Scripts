data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  int<lower=0,upper=4> choice[nSubjects, nTrials];     
  real<lower=0, upper=100> reward[nSubjects, nTrials]; 
}

transformed data {
  real<lower=0, upper=100> v1;  # initial values for V
  v1 = 50.0;
}

parameters {
  real<lower=0,upper=1> lr[nSubjects];
  real<lower=0,upper=3> beta[nSubjects];  
}

model {
  for (s in 1:nSubjects) {
    vector[4] v; 
    real pe;    
    v = rep_vector(v1, 4);

    for (t in 1:nTrials) {      
      if (choice[s,t] != 0) {
        choice[s,t] ~ categorical_logit( beta[s] * v );
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] = v[choice[s,t]] + lr[s] * pe; 
      }
    }
  }    
}

generated quantities{
  real log_lik[nSubjects];

  for (s in 1:nSubjects) {
    vector[4] v; 
    real pe;    
    v = rep_vector(v1, 4);
    log_lik[s] = 0;

    for (t in 1:nTrials) {      
      if (choice[s,t] != 0) {
        log_lik[s] = log_lik[s] + categorical_logit_lpmf(choice[s,t] | beta[s] * v );
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] = v[choice[s,t]] + lr[s] * pe; 
      }
    }
  }  
}

