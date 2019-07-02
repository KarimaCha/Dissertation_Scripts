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
  real<lower=0,upper=1> lr_mu;
  real<lower=0,upper=3> beta_mu;
  real phi_mu;
  
  real<lower=0> lr_sd;
  real<lower=0> beta_sd;
  real<lower=0> phi_sd;
  
  real<lower=0,upper=1> lr[nSubjects];
  real<lower=0,upper=3> beta[nSubjects];  
  real phi[nSubjects];   
}

model {
  lr_sd   ~ cauchy(0,1);
  beta_sd ~ cauchy(0,1);
  phi_sd  ~ cauchy(0,1);
  lr      ~ normal(lr_mu, lr_sd) ;
  beta    ~ normal(beta_mu, beta_sd) ;
  phi     ~ normal(phi_mu, phi_sd) ;
  
  for (s in 1:nSubjects) {
    vector[4] v;    # value
    real pe;        # prediction error
    vector[4] eb;   # exploration bonus
    
    v = rep_vector(v1, 4);

    for (t in 1:nTrials) {    
      if (choice[s,t] != 0) {
        eb = phi[s] * gaps[s,t];
        choice[s,t] ~ categorical_logit( beta[s] * (v + eb) ); # compute action probabilities
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
    
    v = rep_vector(v1, 4);
    log_lik[s] = 0;

    for (t in 1:nTrials) {    
      if (choice[s,t] != 0) {
        eb = phi[s] * gaps[s,t];
        log_lik[s] = log_lik[s] + categorical_logit_lpmf(choice[s,t] | beta[s] * (v + eb) );
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] = v[choice[s,t]] + lr[s] * pe; 
      }
    }
  }    
}

