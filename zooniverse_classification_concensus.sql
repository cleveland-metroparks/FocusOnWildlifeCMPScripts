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
  max_tie_row_no,
  tie_break
  FROM(SELECT subject_ids,
    choice,
    num_classifications,
    number_votes_for_species,
    frac_votes_for_species,
    pielou_evenness,
    row_no,
    max_tie_row_no,
    CASE WHEN max_tie_row_no = 1 THEN 1
      WHEN max_tie_row_no > 1 AND row_no = 1 AND choice = 'NOTHINGTHERE' THEN 2
      WHEN max_tie_row_no > 1 AND row_no = 1 AND choice != 'NOTHINGTHERE' THEN 1
      ELSE 2
      END as tie_break
    FROM(SELECT subject_ids,
        choice,
        num_classifications,
        number_votes_for_species,
        frac_votes_for_species,
        pielou_evenness,
        row_no,
        last_value(ties.row_no) OVER (PARTITION BY subject_ids) as max_tie_row_no
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
              ORDER BY subject_ids,choice) as ranked
              WHERE ranked.rn=1  -- Choose top ranked choice only. Still has ties among rn=1 subject_ids. Comment out to see whole table to see if it is working
            ORDER BY subject_ids) as evenness
      ORDER BY subject_ids) as ties
    ORDER BY subject_ids) as tb2
-- WHERE CASE WHEN tb2.max_row_no > 1 THEN
--         tb2.row_no = 2
--       ELSE
--         tb2.row_no = 1
--       END
  ORDER BY subject_ids) as fin
  WHERE fin.tie_break = 1