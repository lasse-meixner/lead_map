data {
   int<lower=0> N_obs;
   int<lower=0> N_cens;
   int<lower=1> K; // nr of predictors in poisson
   int<lower=1> L; // nr of predictors in logit
   int<lower=1> S; // nr of states
   array[N_obs] int state_obs; // which state the observation is from
   array[N_cens] int state_cens; 
   array[N_obs] int<lower=0> y_obs; 
   matrix[N_obs, K] x_obs; 
   matrix[N_cens, K] x_cens;
   matrix[N_obs, L] z_obs; // logit predictors + exclusion
   matrix[N_cens, L] z_cens;
   vector[N_obs] kids_obs; // offset
   vector[N_cens] kids_cens;
   array[N_cens] int<lower=0> ell;
   array[N_cens] int<lower=0, upper=1> zero_sup;
 }

 transformed data {
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
    int<lower=0> N = N_obs + N_cens;
    matrix[N, K] X = append_row(x_obs, x_cens); // for posterior predictive checks
    matrix[N, L] Z = append_row(z_obs, z_cens); // for posterior predictive checks
    array[N] int state = append_array(state_obs, state_cens); // for posterior predictive checks
    vector[N] log_kids = append_row(log_kids_obs, log_kids_cens); // for posterior predictive checks
}

 parameters {
   real alpha;
   vector[K] beta;
   vector[S] gamma;
   real mu_g;
   real<lower=0> sigma_g;
   vector[L-1] delta; // all but last delta coefficient
   real<lower=0> delta_last; // last delta coefficient for exclusion restriction
 }

 model {

   // priors
   alpha ~ normal(-4.12,0.416); // Note: see NHANES
   gamma ~ normal(mu_g, sigma_g); // logit intercept
   beta ~ normal(0, 0.5); // poisson coefficients (standardised)
   delta ~ normal(0, 0.4); // logit coefficients (standardised)
   delta_last ~ lognormal(-0.9, 0.4); // prior exclusion restriction

   // hyperpriors
   mu_g ~ normal(0, 1);
   sigma_g ~ lognormal(-1.5, 0.7);

    // likelihood
   for (i in 1:N_obs) { // note: could this gamma selection be vectorized?
     real mu_obs = exp(log_kids_obs[i] + alpha + dot_product(beta, x_obs[i]));
     real pi_obs = inv_logit(gamma[state_obs[i]] + dot_product(delta, z_obs[i, 1:(L-1)]) + delta_last * z_obs[i, L]);
     real lambda_obs = mu_obs * pi_obs;
     y_obs[i] ~ poisson(lambda_obs);
   }
   for (j in 1:N_cens) {
     real mu_cens = exp(log_kids_cens[j] + alpha + dot_product(beta,x_cens[j]));
     real pi_cens = inv_logit(gamma[state_cens[j]] + dot_product(delta,z_cens[j, 1:(L-1)]) + delta_last * z_cens[j, L]);
     real lambda_cens = mu_cens * pi_cens;
     target += log_diff_exp(poisson_lcdf(ell[j] | lambda_cens), poisson_lpmf(0 | lambda_cens));
   }
 }


// add generated quantities?

generated quantities {
  vector[N] mu = exp(log_kids + alpha + X * beta);
  vector[N] pi; // Declare pi as a vector of length N

  for (i in 1:N) {
    pi[i] = inv_logit(gamma[state[i]] + Z[i, 1:(L-1)] * delta + Z[i, L] * delta_last);
  }
  
  array[N] int<lower=0> y_star = poisson_log_rng(mu .* pi);
  array[N] int<lower=0> y = poisson_log_rng(mu);
}

// generate estimates for the unknown P(tested|negative) = (Tested_i - pi-mu)/(kids-mu)?