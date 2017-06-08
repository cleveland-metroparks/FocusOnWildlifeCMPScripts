import sys, os, glob
import pandas as pd, numpy as np
import ujson
import datetime
import aggregate_survey
from ast import literal_eval
from get_workflow_info import get_workflow_info, translate_non_alphanumerics, get_short_slug
from aggregate_question_utils import breakout_anno_survey, getfrac, aggregate_survey, write_class_row

datadir        =   'C:\Users\pdl\Documents\GitHub\FocusOnWildlifeCMPScripts'
classfile      = 'focus-on-wildlife-cleveland-metroparks-classifications_test.csv'
workflow_file  = 'focus-on-wildlife-cleveland-metroparks-workflows.csv'
workflow_cfile = 'focus-on-wildlife-cleveland-metroparks-workflow_contents.csv'

workflow_id = 1432
workflow_version = "478.99"

annofile     = classfile.replace('.csv', '_annotations_1lineeach.csv')
outfile      = classfile.replace('.csv', '_aggregated.csv')
outfile_huge = classfile.replace('.csv', '_aggregated_kitchensink.csv')

# now re-read the csv file with the annotations
annotations = pd.read_csv(annofile)
annotations['count'] = np.ones_like(annotations.created_at)

# we need to group by subject in order to aggregate
by_subj = annotations.groupby('subject_ids')

class_agg = by_subj.apply(aggregate_survey, workflow_info=workflow_info)

# check for empty columns
all_cols = class_agg.columns.values
use_cols = (class_agg.columns.values).tolist()
for thecol in all_cols:
    if sum(class_agg[thecol]) == 0.0:
        use_cols.remove(thecol)

# write both the kitchen sink version and the version with no totally empty columns
class_agg.to_csv(outfile_huge)
class_agg[use_cols].to_csv(outfile)