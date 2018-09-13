# Searching for News

This is a set of R scripts used for analyzing Google Health data for the "[Searching for news: The Flint water crisis](http://www.journalism.org/essay/searching-for-news/)" report, published April 27, 2017. These scripts combine multiple samples, minimize noise and identify points at which search volume changes. Please see our posts [describing how we did this research](https://medium.com/@pewresearch/using-google-trends-data-for-research-here-are-6-questions-to-ask-a7097f5fb526) and [how to use these scripts](https://medium.com/pew-research-center-decoded/sharing-the-code-we-used-to-study-the-publics-interest-in-the-flint-water-crisis-66215382b194) for more information.

## About the Report

This repository contains a generalized version of code used for collecting and analyzing data from the Google Health API for Pew Research Center's project, "[Searching for News: The Flint Water Crisis](http://www.journalism.org/essay/searching-for-news/)", published on April 27, 2017.

The project explored what aggregated search behavior can tell us about how news spreads and how public attention shifts in today's fractured information environment, using the water crisis in Flint, Michigan, as a case study.

The study delves into the kinds of searches that were most prevalent as a proxy for public interest, concerns and intentions about the crisis, and tracks the way search activity ebbed and flowed alongside real world events and their associated news coverage.

Researchers collected the data via Google's Health API, to which the Center requested and gained special access for this project. For more information, read our [Medium post](https://medium.com/@pewresearch/using-google-trends-data-for-research-here-are-6-questions-to-ask-a7097f5fb526) on how we used Google Trends data to conduct our research. Note that this requires access to the Health API; to apply, click [here](https://docs.google.com/forms/d/e/1FAIpQLSdZbYbCeULxWAFHsMRgKQ6Q1aFvOwLauVF8kuk5W_HOTrSq2A/viewform?visit_id=1-636281495024829628-2992692443&amp;rd=1).

# Requirements
R v3.4+

## Packages:
- dplyr
- purrr
- mgcv
- lubridate
- ggplot2
- changepoint
- stringr
- lme4
- tidyverse
- reshape2

## Instructions

**NOTE:** Use of this tool requires an API key from Google, with special access for the Health API. To request access, please contact the Google News Lab via this [form](https://docs.google.com/forms/d/e/1FAIpQLSdZbYbCeULxWAFHsMRgKQ6Q1aFvOwLauVF8kuk5W_HOTrSq2A/viewform?visit_id=1-636281495024829628-2992692443&amp;rd=1).

To combine samples, load the impute_samples.r script and call process_region() with the directory the data is stored in and the name of the region.

	starting_dir = <main data folder>
	combine_region(starting_dir, ‘513’)

To create changepoints, load the create_changepoints.r script and call run_plots() with the data folder and the name of the region (for charts):

	run_plots(“<folder>”, “Flint”)

For more information, see the post on how to use these scripts [here](https://medium.com/pew-research-center-decoded/sharing-the-code-we-used-to-study-the-publics-interest-in-the-flint-water-crisis-66215382b194).

## Acknowledgments

This report was made possible by The Pew Charitable Trusts. Pew Research Center is a subsidiary of The Pew Charitable Trusts, its primary funder. This report is a collaborative effort based on the input and analysis of [a number of individuals and experts at Pew Research Center](http://www.journalism.org/2017/04/27/google-flint-acknowledgments/). Google's data experts provided valuable input during the course of the project, from assistance in understanding the structure of the data to consultation on methodological decisions. While the analysis was guided by our consultations with the advisers, Pew Research Center is solely responsible for the interpretation and reporting of the data.

## Use Policy

In addition to the [license](https://github.com/pewresearch/searching_for_news/blob/master/LICENSE), Users must abide by the following conditions:

- User may not use the Center's logo
- User may not use the Center's name in any advertising, marketing or promotional materials.
- User may not use the licensed materials in any manner that implies, suggests, or could otherwise be perceived as attributing a particular policy or lobbying objective or opinion to the Center, or as a Center endorsement of a cause, candidate, issue, party, product, business, organization, religion or viewpoint.

### Recommended Report Citation

Pew Research Center, April, 2017, "Searching for News: The Flint Water Crisis"
 
### Recommended Package Citation

Pew Research Center, September 2018, "Searching For News" Available at: github.com/pewresearch/searching_for_news

### Related Pew Research Center Publications

- September 13, 2018 "[Sharing the code we used to study the public's interest in the Flint water crisis](https://medium.com/pew-research-center-decoded/sharing-the-code-we-used-to-study-the-publics-interest-in-the-flint-water-crisis-66215382b194)"

- April 27, 2017  "[Searching for News: The Flint Water Crisis](http://www.journalism.org/essay/searching-for-news/)"

- April 27, 2017  "[Using Google Trends data for research? Here are 6 questions to ask](https://medium.com/@pewresearch/using-google-trends-data-for-research-here-are-6-questions-to-ask-a7097f5fb526)"

- April 27, 2017  "[Q&A: Using Google search data to study public interest in the Flint water crisis](http://www.pewresearch.org/fact-tank/2017/04/27/flint-water-crisis-study-qa/)"

## Issues and Pull Requests

This code is provided as-is for use in your own projects.  You are free to submit issues and pull requests with any questions or suggestions you may have. We will do our best to respond within a 30-day time period.

# About Pew Research Center

Pew Research Center is a nonpartisan fact tank that informs the public about the issues, attitudes and trends shaping the world. It does not take policy positions. The Center conducts public opinion polling, demographic research, content analysis and other data-driven social science research. It studies U.S. politics and policy; journalism and media; internet, science and technology; religion and public life; Hispanic trends; global attitudes and trends; and U.S. social and demographic trends. All of the Center's reports are available at [www.pewresearch.org](http://www.pewresearch.org). Pew Research Center is a subsidiary of The Pew Charitable Trusts, its primary funder.

## Contact

For all inquiries, please email info@pewresearch.org. Please be sure to specify your deadline, and we will get back to you as soon as possible. This email account is monitored regularly by Pew Research Center Communications staff.
