# install.packages("changepoint")
library(dplyr)
library(purrr)
library(mgcv)
library(lubridate)
library(ggplot2)
library(changepoint)
library(stringr)

pdf_dir = "DATA/changepoint/"

theme_pew = function(base_size = 12, base_family = "") {
  # ggplot theme
  
  # Starts with theme_grey and then modify some parts
  theme_grey(base_size = base_size, base_family = base_family) %+replace%
    theme(
      axis.line = element_line(colour = "black"),
      axis.text         = element_text(size = rel(0.8)),
      axis.ticks        = element_line(colour = "black"),
      legend.key        = element_rect(colour = "grey80"),
      panel.background = element_blank(),
      panel.border      = element_rect(fill = NA, colour = "grey50"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line.x = element_line(color="black", size = .3),
      axis.line.y = element_line(color="black", size = .3),
      strip.background  = element_rect(fill = "grey80", colour = "grey50", size = 0.2)
    )
}

cp_binseg = function(df_imputed_values, df_means, df_smoothed_values, region, category, Q_val=10, max_y=-1, do_plotting=TRUE, bin_width=.1) {
  # Runs a series of binary segmentation changepoint models
  #   and saves the resulting charts to pdf
  # Args:
  #   df_imputed_values: Long-format dataframe of every imputed value
  #   df_means: Dataframe with each per-period mean of imputed values
  #   df_smoothed_values: Dataframe with smoothed values
  #   region: String name of region being plotted
  #   category: String name of category being plotted
  #   Q_val: Maximum number of changepoints to search for, passed to cpt.mean().
  #   max_y: integer to standardize y-axis. Defaults to -1, in which no re-scaling is done.
  #   do_plotting: Should PDF plots be produced or not?
  #   bin.width: Bin width for the histogram produced as a side effect of this function
  
  # Set up file
  dir.create(pdf_dir)
  pdf_path = paste0(pdf_dir, "changepoints_",region,"-", category,".pdf")
  pdf(file=pdf_path)

  # Run model and put results in a list
  binseg_est = cpt.mean(df_means$imputed_mean, method="BinSeg", Q=Q_val, minseglen = 3)
  
  # some models will identify the 1st and last periods, but this doesn't. We will need this for drawing lines.
  binseg_results = c(0, cpts(binseg_est), nrow(df_means))
  binseg_result_pairs = map2(binseg_results, lead(binseg_results, 1), ~c(.x, .y))
  binseg_result_pairs = binseg_result_pairs[-length(binseg_result_pairs)]
  # Extract information for charting
  # Setup
  binseg_range_means = NULL
  binseg_range_maxes = NULL
  prev_cps = NULL
  curr_cps = NULL
  prev_cps_dates = NULL
  curr_cps_dates = NULL
  range_max_dates = NULL
  i = 0
  # cycle through pairs of each element. Takes the mean, max, etc. of each range.
  # e.g. in a model with 10 periods, each row of the resulting dataframe will be period 1 to 2, 2 to 3, 3 to 4, etc.
  for (pair in binseg_result_pairs) 
  {
    i = i + 1
    prev_cp = pair[1] + 1
    curr_cp = pair[2]
    
    # take the mean of this range. Remember to set curr_cp - 1 - don't want to include changepoint in this range. 
    curr_mean = mean(df_means[prev_cp:curr_cp-1, "imputed_mean"]$imputed_mean)       
    curr_max = max(df_means[prev_cp:curr_cp-1,"imputed_mean"]$imputed_mean)

    binseg_range_means[i] = curr_mean
    binseg_range_maxes[i] = curr_max
    
    prev_cps_dates[i] = df_means[prev_cp, ]$period_date
    curr_cps_dates[i] = df_means[curr_cp, ]$period_date
    range_max_dates[i] = df_means[which(df_means$imputed_mean==curr_max), ]$period_date
    prev_cps[i] = prev_cp
    curr_cps[i] = curr_cp
  }
  binseg_range_max_deltas = map2(lag(binseg_range_maxes, 1), binseg_range_maxes, ~abs(.y - .x)) %>% unlist()
  binseg_range_max_delta_perc = binseg_range_max_deltas / lag(binseg_range_maxes, 1)
  mean_delta = mean(binseg_range_max_deltas, na.rm = TRUE)
  sd_delta = sd(binseg_range_max_deltas, na.rm = TRUE)
  
  # set data frame
  binseg_results = data.frame(prev = prev_cps,
                              curr = curr_cps,
                              prev_date = as.Date(prev_cps_dates),
                              curr_date = as.Date(curr_cps_dates),
                              means = binseg_range_means,
                              max_date = as.Date(range_max_dates),
                              maxes = binseg_range_maxes,
                              max_deltas = binseg_range_max_deltas,
                              max_delta_perc = binseg_range_max_delta_perc)
  print(binseg_results)
  write.csv(binseg_results, paste("DATA/changepoint/changepoints_",region,"-", category,".csv", sep=""))
  
  # and plot
  if (do_plotting) {
    plt_title = paste(region, category, "BinSeg: ", Q_val)
    binseg_plt = ggplot() + 
      ggtitle(plt_title) + 
      scale_x_date(date_breaks="4 month", date_labels ="%m/%y") + labs(x="Period", y="Proportion of Attention") + theme(axis.text.x = element_text(angle=90, hjust=1)) +
      theme_pew() +
      theme(legend.position = "none") +
      geom_point(data=df_imputed_values, aes(y=imputed_value, x=period_date), color="#CCCCCC", size=.05) +
      geom_line(data=df_means, aes(y=imputed_mean, x=period_date), color="#6600CC", alpha=.4) +
      geom_line(data=df_smoothed_values, aes(y=smoothed, x=period_date), color="#990033") + 
      geom_segment(data=binseg_results, aes(x=prev_date, xend=curr_date, y=means, yend=means), color="blue", size=.5) +
      geom_text(data=binseg_results, aes(x=prev_date, y=means+200, label=round(binseg_range_max_delta_perc, 3)), size=2)
    if (max_y > -1) {
      binseg_plt = binseg_plt + scale_y_continuous(limits=c(0,max_y))
      
      # Save histogram
      hist_plt = ggplot(data=binseg_results, aes(x=max_delta_perc)) + geom_histogram(binwidth = bin_width) +
        ggtitle(plt_title) + 
        labs(x="Diff in Max", y="Count") 
    }
    print(binseg_plt)
    print(hist_plt)
  }  
  dev.off()

}


run_gam = function(df, k_val=50, region, category, max_y, seed = 20180910) {
  # Runs gam model, calculating smoothed data.
  # In turn, runs changepoint model.
  # Args:
  #   df: Long-format dataframe of imputed values (col: imputed_value)
  #   k_val: gam model parameter that specifies number of curves in model. Lower = smoother.
  #   region: Name of region being run. Used for charts.
  #   category: Name of category being run. Used for charts.
  #   max_y: Maximum value of y, if standardizing. 
  #   seed: Seed for sampling 50 samples for each period if there are more than 50
  
  # Verify some basic conversions
  df$num_period = as.numeric(df$period)
  df$period_date = ymd(as.character(df$period))
  
  # if there are more than 50, take a random subset to get to 50
  df_samples = df %>% group_by(sample) %>% summarize(cnt = n())
  set.seed(seed)
  if (nrow(df_samples) > 50) {
    df = subset(df, sample %in% sample_n(df_samples, 50)$sample)
  }
  
  # calculate means
  df_means = df %>% 
    group_by(period_date) %>%
    summarize(imputed_mean = mean(imputed_value))
  
  # run gam
  m = gam(imputed_value~s(num_period, k=k_val),  data=df)
  
  # get predicted values
  df_pred = df %>% 
    select(period_date, num_period) %>% 
    distinct() %>% 
    as_tibble()
  df_pred$smoothed = predict(m, newdata = df_pred)
  
  cp_binseg(df, df_means, df_pred, region, category, max_y=max_y)
  df_pred$smoothed
}


run_plots = function(input_path, region) {
  # Creates all smoothed, changepoint filled plots per category for the specified region.
  # Args:
  #   input_path: sub-directory where data are stored
  #   region: Name of region being studied. This value is used for chart titles and file names.
  
  files = list.files(input_path, pattern='*imputed_samples.csv', full.names=TRUE)
  dfs = vector("list", length(files))
  i = 1
  # Need to determine the maximum y value so we can plot everything on the same y-scale
  cross_cat_max = 0
  for (f in files) {
    df = read.csv(f)
    curr_max = max(df$imputed_value)
    cross_cat_max = max(cross_cat_max, curr_max)
    dfs[[i]] = df
    i = i+1
  }
  
  # setup for run
  # Add some additional space at the top so we're not right at the top 
  cross_cat_max = cross_cat_max + 100
  df_results = dfs[[1]] %>% group_by(period) %>% summarize()
  for (i in 1:length(dfs)) {
    category = str_match(files[i],'-([A-z &]+)_imputed')[1,2]
    print(paste("Running", category))
    print(head(dfs[[i]]$imputed_value, 60))
    smoothed_vals = run_gam(dfs[[i]], 50, region, category, cross_cat_max)
    df_results[category] = smoothed_vals
  }
  
  # save imputed data
  dir.create("DATA/smoothed/")
  csv_file = paste("DATA/smoothed/smoothed_",region,'.csv', sep="")
  print(paste("Saving to:", csv_file))
  write.csv(df_results, csv_file)
}



setwd("~/repos/flint_water/Search")
all_results = NULL
run_plots("DATA/513/combined", "Flint")
run_plots("DATA/US/combined", "National")
run_plots("DATA/US-MI/combined", "Michigan")




