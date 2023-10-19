# auxiliary function that grid searches over the inital values of the STAN HMC sampler until it runs
library(progress)

run_init_grid <- function(stan_data, 
                          stan_model, 
                          param_grid, 
                          seed = 1234, 
                          chains = 4, 
                          parallel_chains = 4,
                          refresh = 500) {

    # example of grid: grid = list(alpha = c(1,2,3,4), beta = c(0.4, 0.5, 0.6))
    # while fit$summary() returns an Error:
        # iterate over grid of params in grid list
    
    # create grid
    grid <- expand.grid(param_grid)
    # create progress bar
    prog_bar <- progress_bar$new(total = nrow(grid))
    
    while (TRUE) {
        # iterate over rows of grid and call $sample()
        for (i in 1:nrow(grid)) {
            # get row of grid
            init_params <- as.list(grid[i,])
            # sample
            suppressMessages(suppressWarnings({
                fit <- stan_model$sample(data = stan_data, 
                                            init = function() init_params, 
                                            chains = chains, 
                                            parallel_chains = parallel_chains, 
                                            refresh = refresh, 
                                            seed = seed)
            }))
            
            tryCatch({
                fit$summary()
                # If no error occurs, print success message
                print(paste("Successful initialization for", names(init_params), ":", init_params))
                return(fit)  # Return fit if no error occurs
            }, error = function(e) {
                print(paste("Initialization failed for", names(init_params), ":", init_params))
            })
            # Update progress bar within the loop
            prog_bar$tick()
        }
    }
}