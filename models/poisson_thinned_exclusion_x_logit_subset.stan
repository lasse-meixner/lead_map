data {
   int<lower=0> N_obs;
   int<lower=0> N_cens;
   int<lower=1> K; // number of predictors in poisson
   int<lower=1> L; // number of predictors in logit (from x)
   array[N_obs] int<lower=0> y_obs; 
   matrix[N_obs, K] x_obs; 
   matrix[N_cens, K] x_cens;
   matrix[N_obs, L] w_obs;
   matrix[N_cens, L] w_cens;
   vector[N_obs] z_obs; // exclusion
   vector[N_cens] z_cens;
   vector[N_obs] kids_obs; // offset
   vector[N_cens] kids_cens;
   array[N_cens] int<lower=0> ell;
   real<lower=0> nhanes_prior_var; // prior variance for the NHANES data
 }

 transformed data {
    int<lower=0> N = N_obs + N_cens;
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
}

 parameters {
   real alpha;
   vector[K] beta;
   vector[L] kappa; // NEW for x in logit
   real gamma;
   real delta;
 }

 model {
   // priors
   alpha ~ normal(-1.69, nhanes_prior_var); // log(lambda/kids) = alpha = log(0.02) based on CDC national average figures
   gamma ~ normal(0, 1.5); // intercept for logit
   // structural
   vector[N_obs] mu_obs = exp(log_kids_obs + alpha + x_obs * beta); // this works for NxK * Kx1 (https://mc-stan.org/docs/2_18/stan-users-guide/vectorization.html)
   vector[N_obs] pi_obs = inv_logit(gamma + delta * z_obs + w_obs * kappa); // NEW for x in logit
   vector[N_obs] lambda_obs = mu_obs .* pi_obs; // elementwise product
   y_obs ~ poisson(lambda_obs); 
   for (j in 1:N_cens) {
     real mu_cens = exp(log_kids_cens[j] + alpha + dot_product(beta,x_cens[j]));
     real pi_cens = inv_logit(gamma + delta * z_cens[j] + dot_product(kappa,w_cens[j])); // NEW for x in logit
     real lambda_cens = mu_cens * pi_cens;
     target += log_diff_exp(poisson_lcdf(ell[j] | lambda_cens), poisson_lpmf(0 | lambda_cens));
   }
 }

generated quantities {
  // required variables: 
  //' matrix[N, K] X = append_row(x_obs, x_cens); // for posterior predictive checks
  //' vector[N] log_kids = append_row(log_kids_obs, log_kids_cens); // for posterior predictive checks
  // outcome counts
  //' array[N] int<lower=0> y_tilde = poisson_log_rng(log_kids + alpha + X * beta);
  // thinning probabilities (bernoulli_logit_rng doesn't help - I do not care for a binary draw given that each units thinning rate. I want the thinning rate itself!)
  vector[N] pi_tilde = inv_logit(gamma + delta * append_row(z_obs, z_cens) + append_row(w_obs, w_cens) * kappa);
  
}



// generate estimates for the unknown P(tested|negative) = (Tested_i - pi-mu)/(kids-mu)?