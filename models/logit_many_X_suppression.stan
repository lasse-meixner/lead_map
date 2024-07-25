data {
  int<lower=0> N_obs;
  int<lower=0> N_cens;
  int<lower=1> K;
  vector[N_obs] pi_obs; // will be Pr(tested)=tested/kids
  matrix[N_obs, K] x_obs;  // will include pediatricians
  matrix[N_cens, K] x_cens;
  vector[N_cens] kids_cens; // required for calculation of rate at lower suppression end
  int<lower=0> ell_ratio; // testing threshold
  int<lower=0, upper=1> zero_sup; // whether count of 0 is reported or included in suppression range
}

transformed data {
    int<lower=0> N = N_obs + N_cens;
    matrix[N, K] X = append_row(x_obs, x_cens);
    vector[N_cens] lower_bound = 1 / kids_cens;
}

parameters {
  real gamma;
  vector[K] kappa;
}

model {
  // add priors
  gamma ~ normal(0, 2);
  kappa ~ normal(0, 1); // implicitely vectorized
  target += logistic_lcdf(pi_obs | gamma + x_obs * kappa, 1);
  for (j in 1:N_cens) {
    real log_odds = gamma + dot_product(kappa, x_cens[j]);
    if (zero_sup) 
      target += logistic_lcdf(ell_ratio | log_odds, 1);
    else {
      real lower_bound_j = lower_bound[j];
      target += log_diff_exp(logistic_lcdf(ell_ratio | log_odds, 1), logistic_lcdf(lower_bound_j | log_odds, 1));
    }
  }
}