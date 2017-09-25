-- Concensus table
-- Made a view of this also to allow better QA/QC
-- Added ability to break ties an not take Nothing There from ties
-- Name:  zoon_class_concensus
-- Comment: table with concensus choices, fraction, and peilou score from the zooniverse_classification_choices view
SELECT subject_ids,
    choice,
    num_classifications,
    number_votes_for_species,
    frac_votes_for_species,
    pielou_evenness,
    row_no,
    last_value(tb.row_no) OVER (PARTITION BY subject_ids) as max_row_no
    FROM(SELECT subject_ids,
      choice,
      num_classifications,
      number_votes_for_species,
      frac_votes_for_species,
      pielou_evenness,
      row_number() OVER (PARTITION BY subject_ids) AS row_no
      FROM(SELECT subject_ids,
        choice,
        num_classifications,
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
        ORDER BY subject_ids) as u
  ORDER BY subject_ids) as tb
