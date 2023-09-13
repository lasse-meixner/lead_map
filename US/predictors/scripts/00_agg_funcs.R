# Function to impute the median of a variable when the only information available about it is bin counts
# Note, if you use the function with counts (as opposed to proportions) you can get an issue when
# when cumulative frequency across all bins in a row is 1, because n_2 - cf2 = -0.5
# In this case you'd need to specify that if this cumulative frequency is 1, 
# the median is equal to the midpoint of the bin that the one unit is in

get_GroupedMedian <- function(frequencies, intervals) {
  
  cf <- cumsum(frequencies)
  
  if (NA %in% cf) {
    
    median_value <- NA
    
  } else {
  
  Midrow <- min(c(findInterval(max(cf)/2, cf) + 1), nrow(intervals)) # index number of the band the median is in
  L <- intervals[Midrow, 1]      # lower class boundary of median class
  H <- intervals[Midrow, 2]      # upper class boundary of median class
  h <- diff(intervals[Midrow, ]) # size of median class (difference between the two rows, L and upper class boundary, in the column with index Midrow)
  f <- frequencies[Midrow]       # frequency of median class
  cf2 <- max(c(cf[Midrow - 1], 0)) # cumulative frequency up to end of class before median class
  n_2 <- max(cf)/2               # total observations divided by 2. Will just be 0.5 since you're using proportions
  
  median_value <- L + (n_2 - cf2)/f * h
  
  }
  
  median_value
  
}

# Function to get mode of a vector 

get_Mode <- function(v) {
  
  uniqv <- unique(v)
  
  if (all(is.na(uniqv))) {
    
    mode <- NA
    
  } else {
    
    uniqv <-uniqv[!(uniqv %in% c(NA))]
    
    x <- tabulate(match(v, uniqv))
    
    mode <- toString(uniqv[which(x==max(x))])
  }
  
  mode
  
}