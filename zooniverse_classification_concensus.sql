-- Concensus table
-- Made a view of this also to allow better QA/QC
-- Added ability to break ties an not take Nothing There from ties
-- Name:  zoon_class_concensus
-- Comment: table with concensus choices, fraction, and peilou score from the zooniverse_classification_choices view

SELECT subject_ids,
  choice_z,
  num_classifications,
  number_votes_for_species,
  frac_votes_for_species,
  pielou_evenness,
  last_value(ties.tie_row_no) OVER (PARTITION BY subject_ids) AS max_tie_row_no
  FROM(SELECT subject_ids,
    choice_z,
    num_classifications,
    number_votes_for_species,
    frac_votes_for_species,
    pielou_evenness,
    row_number() OVER (PARTITION BY subject_ids) AS tie_row_no
    FROM(SELECT subject_ids,
      choice_z,
      num_classifications,
      number_votes_for_species,
      frac_votes_for_species,
      CASE WHEN frac_votes_for_species = 1.0 THEN 0
        WHEN frac_votes_for_species < 1.0 THEN -(sum(frac_votes_for_species*log(frac_votes_for_species)) OVER (PARTITION BY subject_ids))/log(num_classifications)
      END as pielou_evenness
      FROM (SELECT subject_ids,choice_z,number_votes_for_species,
        sum(number_votes_for_species) over (PARTITION BY subject_ids) as num_classifications,
        (number_votes_for_species)::numeric / sum(number_votes_for_species) over (PARTITION BY subject_ids) as frac_votes_for_species, 
        RANK() OVER (PARTITION BY subject_ids ORDER BY number_votes_for_species DESC) AS rn
        FROM(SELECT subject_ids,
          choice_z,
          count(choice_z) as number_votes_for_species
          FROM camera_trap.zooniverse_classification_choices
          GROUP BY subject_ids,choice_z) AS counted
--        ORDER BY subject_ids,choice_z) as ranked  -- This version sorts Nothing there choices to end and chooses first
        ORDER BY subject_ids,random()) as ranked  -- This version sorts choices randomly and chooses first to give a random choice
        WHERE ranked.rn=1  -- Choose top ranked choice_z only. Still has ties among rn=1 subject_ids. Comment out to see whole table to see if it is working
      ORDER BY subject_ids) as evenness
    ORDER BY subject_ids) as ties
  WHERE ties.tie_row_no=1  -- Resolves ties by sorting Z_NOTHINGTHERE to the end of sets and choosing first one (so alphabtically, which prefers fox squirrels, for example). Random among not NOTHINGTHERE would be better.
  ORDER BY subject_ids