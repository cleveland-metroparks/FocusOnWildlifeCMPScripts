-- Name:  zoon_class_number_of_animals
-- Comments:  table with counts for number of animals to be used as a view
-- Note the extra item in the partition by to get the rank within choice, within subject_ids 
--  for when there are two different estimates of number_of_animals for one choice.  Also note
--  count(number_of_animals) counts number of votes for that count
SELECT *
  FROM(SELECT subject_ids,
    choice,
    number_of_animals,
    number_of_votes_for_count,
    CASE  sum(number_of_votes_for_count) over (PARTITION BY subject_ids)
      WHEN 0 THEN NULL
      ELSE (number_of_votes_for_count)::numeric / sum(number_of_votes_for_count) over (PARTITION BY subject_ids)
    END as frac_votes_for_count,
    RANK() OVER (PARTITION BY subject_ids,choice ORDER BY number_of_votes_for_count DESC) AS rn_count
  FROM(SELECT subject_ids,choice,number_of_animals,count(number_of_animals) as number_of_votes_for_count
        FROM camera_trap.zooniverse_classification_choices
        GROUP BY subject_ids,choice,number_of_animals) AS counted
    ORDER BY subject_ids,choice) as s
  WHERE s.rn_count=1  -- comment this out to see the whole table to see if it is working
