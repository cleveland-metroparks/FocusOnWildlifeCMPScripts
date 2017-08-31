-- Name:  zooniverse_classification_nodups
-- Description:  creates materialized view without duplicates from one workflow and version classification table from zooniverse
SELECT * FROM (
  SELECT *,
  	ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
  FROM camera_trap.zooniverse_classification_report_raw2) dups
  WHERE 
    dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row = 1