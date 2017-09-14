-- Concensus table
-- Made a view of this also to allow better QA/QC
-- Name:  zoon_class_concensus
-- Comment: table with choices, answers, and subject data split out of the nodup table
SELECT subject_ids,
  created_at,
  choice,
  num_classifications,
  rn,
  number_votes_for_species,
  frac_votes_for_species,
    CASE WHEN frac_votes_for_species = 1.0 THEN 0
      WHEN frac_votes_for_species < 1.0 THEN -(sum(frac_votes_for_species*log(frac_votes_for_species)) OVER (PARTITION BY subject_ids))/log(num_classifications)
    END as pielou_evenness
  FROM (SELECT subject_ids,choice,number_votes_for_species,
    sum(number_votes_for_species) over (PARTITION BY subject_ids) as num_classifications,
    (number_votes_for_species)::numeric / sum(number_votes_for_species) over (PARTITION BY subject_ids) as frac_votes_for_species, 
    RANK() OVER (PARTITION BY subject_ids ORDER BY number_votes_for_species DESC) AS rn
    FROM(SELECT subject_ids,
              choice,
              count(choice) as number_votes_for_species
            FROM camera_trap.zooniverse_classification_choices
            GROUP BY subject_ids,choice) AS counted
        ORDER BY subject_ids,choice) as s
  WHERE s.rn=1  -- comment this out to see the whole table to see if it is working
--  ORDER BY subject_ids