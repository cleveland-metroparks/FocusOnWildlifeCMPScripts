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


## Report types, basic

* workflow contents - has workflow id, contents version, and question choices
* workflows - has workflow id, workflow version, tasks, and some other stuff I don't understand fully
* subjects - has subject, project, workflow, subject_set IDs, image names, image links, classification count, retirement date/time, reason
  * this is the one to look at to see what has not been retired yet
  * could be used to see what is currently linked to workflow
* classifications - included user information and ip, workflow_id and version, created at date/time, session information, classification answers, subject data and ids


## Old aggregation report

* 


## Todo
* need to find a way to recreate the aggregate report from either the classifications report
* No clue where to even start with this



[1] A description of all Snapshot Serengeti approach and datasets (raw dataset and processed datasets can be found here:
doi:10.5061/dryad.5pt92), the field methods, and uses for the data can be 
found in:
Swanson et al. 2015. Snapshot Serengeti - High-resolution annotated camera trap 
images of 40 mammal species in Serengeti National Park. Scientific Data.
