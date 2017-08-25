# Focus On Wildlife CMP Scripts

Scripts for processing Focus On Wildlife -- Cleveland Metroparks classification data

*Forked from similar scripts at Snapshot Serengeti* [Web link to GitHub repo](https://github.com/mkosmala/SnapshotSerengetiScripts)[1]

These scripts will take the raw data produced by the citizen science project 
Focus On Wildlife -- Cleveland Metroparks and turn them into processed 
datasets that can then be used for analysis.

## Notes from Ali Swanson on how to get started duplicating the aggregate report

* Brooke has some code at 
  * [Code for running basic aggregation on the raw data](https://github.com/zooniverse/Data-digging/blob/master/example_scripts/wildwatch_kenya/aggregate_survey.py) 
  * imports two scripts from the main `Data-digging` directory 

* The official aggregation approach and code for Snapshot Serengeti (e.g. www.nature.com/articles/sdata201526) is [here](https://github.com/mkosmala/SnapshotSerengetiScripts)

* The Oxford team is working to fix aggregation through the project builder - I'm hopeful we might be able to have something built this summer, but there are no guarantees.


## Zooniverse report types

* workflow contents - has workflow id, contents version, and question choices
* workflows - has workflow id, workflow version, tasks, and some other stuff I don't understand fully
* subjects - has subject, project, workflow, subject_set IDs, image names, image links, classification count, retirement date/time, reason
  * this is the one to look at to see what has not been retired yet
  * could be used to see what is currently linked to workflow
* classifications - included user information and ip, workflow_id and version, created at date/time, session information, classification answers, subject data and ids

## Basic generic reports

* These should be executed in a Canopy command prompt window
  * cd \Users\pdl\Documents\GitHub\FocusOnWildlifeCMPScripts)
  * then execute the commands listed below

### basic_project_stats.py

`python basic_project_stats.py focus-on-wildlife-cleveland-metroparks-classifications_test.csv workflow_id=1432 workflow_version=478.99 --keep_allcols outfile_csv=focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99.csv --remove_duplicates --keep_nonlive`

Produces output like this:

> Computing project stats using:
>    infile: focus-on-wildlife-cleveland-metroparks-classifications_test.csv
> Reading classifications from focus-on-wildlife-cleveland-metroparks-classifications_test.csv
> Considering only workflow id 1432
> Considering only major workflow version 478
> Retaining all non-live classifications in analysis.
> Found 1227 duplicate classifications (0.55 percent of total).
> Duplicates removed from analysis (1125 unique user-subject-workflow groups).
> 
> Overall:
> 
> 221497 classifications of 25396 subjects by 3158 classifiers,
> 1920 logged in and 1238 not logged in, from 3708 unique IP addresses.
> 189231 classifications were from logged-in users, 32266 from not-logged-in users.
> 
> That's 8.72 classifications per subject on average (median = 8.0).
> The most classified subject has 18 classifications; the least-classified subject has 1.
> 
> Median number of classifications per user: 18.00
> Mean number of classifications per user: 70.14
> 
> Top 10 most prolific classifiers:
> user_name
> barclem         15347
> martyreynard     6382
> Giant_Sloth      5790
> jfelix2          3921
> jgeschke         2952
> apmabr           2661
> jrhansler        2206
> auforester       1926
> Zandra           1724
> ramekens         1628
> Name: created_at, dtype: int64
> 
> 
> Gini coefficient for classifications by user: 0.77
> 
> Classifications were collected between 2017-01-05 and 2017-05-25.
> The highest classification id considered here is 56718037.
> 
> File with used subset of classification info written to focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99.csv .
> File with ranked list of user classification counts written to focus-on-wildlife-cleveland-metroparks-classifications_test_nclass_byuser_ranked.csv .
> Saved info for all classifications that have duplicates to focus-on-wildlife-cleveland-metroparks-classifications_test_duplicated_only.csv .

* We can use this output file to run R scripts or postgres to summarize IDs and calculate Pielou scores, etc.

## Modified aggregation report - this is not currently too useful

* Brooke has modified her aggregation report and put it here: [Weblink](https://github.com/zooniverse/Data-digging/tree/46a902c507365007d038f43fad0d295961f52a19/example_scripts/cleveland_wildlife)

`python aggregate_cleveland_survey.py focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99.csv`

Produces:

> 236894 annotations jailbroken from 221497 classifications, written to focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99_annotations_1lineeach.csv as individual marks...
> 
> Aggregated classifications written to focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99_aggregated.csv
>   (kitchen sink version: focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99_aggregated_kitchensink.csv )

* This approach mangles answers to our deer questions, among other problems

## Plot histogram of user classifications

`python plot_user_class_hist.py focus-on-wildlife-cleveland-metroparks-classifications_test_nclass_byuser_ranked.csv`

Output was some errors and 'Histograms written to nclass_hist.png and .pdf'

## Plot time series

`python active_users_timeseries.py focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99.csv workflow_id=1432 workflow_version=478 focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99`

## User session stats

`python sessions_inproj_byuser.py focus-on-wildlife-cleveland-metroparks-classifications_wfid1432_v478.99.csv`

Outputs to session_stats_2017-01-05_to_2017-05-25.csv

## Todo

* Make sense of aggregate report
* Get Peilou score etc. from Ali's scripts



[1] A description of all Snapshot Serengeti approach and datasets (raw dataset and processed datasets can be found here:
doi:10.5061/dryad.5pt92), the field methods, and uses for the data can be 
found in:
Swanson et al. 2015. Snapshot Serengeti - High-resolution annotated camera trap 
images of 40 mammal species in Serengeti National Park. Scientific Data.
