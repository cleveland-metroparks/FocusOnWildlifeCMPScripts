--Name:  duplicates_1432_478_99
--Description:  creates duplicates_1432_478_99 view
SELECT * FROM (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
  FROM camera_trap.zooniverse_classification_report_raw2
      ) dups
  WHERE 
    dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row > 1 -- AND dups.subject_ids='4580284'