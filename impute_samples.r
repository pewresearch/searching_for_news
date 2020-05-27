library(lme4)
library(dplyr)
library(tidyr)
library(reshape2)
library(ggplot2)

dir_separator = '/'

# dedupe function
dedupe = function(data, verbose = TRUE){
  # Deduplicates columns in data
  # Parameters:
  # data: data you want deduplicated
  # Returns: deduplicated dataframe 
  
  deduped <- data[!duplicated(as.list(data))]
  if (verbose) {
    print("Number of duplicate columns:")
    print((ncol(data) - ncol(deduped)))
  }
  return(deduped)
}

get_qq = function(x) {
  # Returns x values of each data point from a qq plt
  
  return(qqnorm(x)$x)
}
combine_category = function(f, local_title, save_path) {
  # Combines multiple samples into a single data point
  # For instances in which there are zero values,
  # runs a mixed effect model that imputes the actual value
  # based on the bias of the sample and of other values for that 
  # period that are not zero.
  # Parameters:
  # f: filename of csv with samples
  # local_title: region name
  # save_path: directory to save results in
  
  # print basic setup information
  print(local_title)
  print(paste("Loading: ", f))
  
  # Loading
  data = read.table(f, header=TRUE, sep = ",", quote = "'")
  
  # reorder columns
  # API code places the period in a somewhat random spot
  # It also may save the index in the first column, not any actual data
  # So first check if the first column is an integer; if so, drop it
  if (class(data[,1]) == "integer") {
    data = data[, -1]
  }
  # And then reorder
  df = data %>% select(period, everything())
  # and dedupe just in case
  df = dedupe(df)
  
  # get the region and topic
  filesplit = strsplit(f, dir_separator)
  fn = filesplit[[1]][length(filesplit[[1]])]
  local_fn = substr(fn, 1, nchar(fn)-4)
  print(paste("Working on:", local_fn))
  
  # report the number of samples; excluding the period column
  print(paste("# samples:", ncol(df)-1 ))  
  
  # Some search terms will simply not return any values
  # So after deduplication there will just be the date column and a single value column
  # No need to do any additional processing on that
  if (ncol(df) == 2) {
    print("Found all zeroes. Just saving this.")
    colnames(df) = c('period_date', 'value')
    write.csv(df, paste0(save_path,local_fn, '_combined.csv'))
  }
  else
  {
    # Complete some preprocessing before imputation.
    # (Data are already in long format)
    print("Extracting qq and log values. Converting values of 0 to NA.")
    print(head(df))
    long = df
    long = long %>% group_by(period) %>%
      mutate(qq = get_qq(value),
             value2 = na_if(value, 0),
             log_value = log(value2)) 
    long$sample = factor(long$sample)
    long$timeperiod = long$period
    
    # Fit mixed effects model allowing intercept and slope to vary by sample and period
    print("Running Mixed effects model.")
    lm1 = lmer(log_value~qq + (1 + qq|period) + (1 + qq|sample), REML = F, data=long)
    
    # Get coefficients in order to calculate predicted values conditional on week and sample
    print("Determining period and sample effects.")
    period_effects = as.data.frame(ranef(lm1)$period) %>% select(int_period=1, qq_period=2)
    period_effects$period = row.names(period_effects)
    sample_effects = as.data.frame(ranef(lm1)$sample) %>% select(int_sample=1, qq_sample=2)
    sample_effects$sample = row.names(sample_effects)
    
    print("Running Fixed effects model.")
    fixed_effects = fixef(lm1)
    
    long$int_fixed = fixed_effects[1] 
    long$qq_fixed = fixed_effects[2]
    
    print("Imputing...")
    long_betas = long %>% left_join(period_effects) %>% left_join(sample_effects) %>%
      mutate(int_full = int_fixed + int_sample + int_period,
             qq_full = qq_fixed + qq_sample + qq_period,
             pred = int_full + qq_full*qq,  # Predicted value on the log scale
             pred_exp = exp(pred),          # Exponentiated predicted value
             imputed_value = ifelse(is.na(value2), pred_exp, value)) # Use true value if available, else pred_exp
    # save this output
    write.csv(long_betas, paste0(save_path, local_fn, '_imputed_samples.csv'))
    
    # and convert and take the mean
    print("Taking the mean...")
    condensed = long_betas %>% group_by(period) %>%
      summarize(imp_value=mean(imputed_value),
                avg_value=mean(value)) # take the mean of these
    condensed$period_date = as.Date(condensed$period, format="%Y-%m-%d")
    condensed = arrange(condensed, period_date)
    
    final = condensed %>% select(period_date, imp_value, avg_value) %>%
      melt(id="period_date")
    print(save_path)
    save_title = paste(save_path, "-", local_title)
    plt = ggplot(final, aes(x = period_date, y=value, color=variable)) + geom_line() + 
      ggtitle(local_title) 
    plt
    ggsave(paste0(save_path, local_fn, '.png'),device='png')
    write.csv(final, paste0(save_path, local_fn, '_combined.csv'))
  } # else
  
}

process_region = function(data_directory, region, results_directory="") {
  # Using a list of samples of Google Health calls contained in csv files in data_dictionary, 
  # combine multiple samples into single data point and save results
  # Most of the combining work is actually done in combine_category
  # Parameters:
  # data_directory: parent directory above where data is stored
  # region: shorthand for region. DMA code for DMAs, state (e.g. US-CA) or country (e.g. US) code
  # results_directory: where to save the combined results
  
  current_wd <- getwd()
  
  # Scan directory for files
  setwd(data_directory)
  if (results_directory == "") { results_directory = paste0(region, '/combined/') }
  filenames = list.files(region, pattern='*.csv', full.names=TRUE)
  
  # run each file
  for (f in filenames) {
    if (startsWith(f, paste0(region, '/'))) {
      fn = substring(f, nchar(region)+2, nchar(f))
    }
    else { fn = f }
    local_title = substr(fn, 1, nchar(f)-4) # take the .csv off
    if (!dir.exists(results_directory)) { dir.create(results_directory) }
    combine_category(f, local_title, results_directory)
    print(f)
  } # for loop
  setwd(current_wd)
}

# run code
# Assumptions: 
# - Starting directory (below) is the parent directory in which data is stored
# - for each region, data is stored in a folder named after the region - either the DMA or the state/country code
# - under that, each file is a series of samples run by the Search Sampler python package
starting_dir = '~/repos/flint_water/Search/DATA/'

process_region(starting_dir, '513')
process_region(starting_dir, 'US-MI')
process_region(starting_dir, 'US')
