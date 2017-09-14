-- Name: zooniverse_summary
-- Comments: Report summarizing all concensus views for QA/QC and shiny app
SELECT e.subject_id,
    e.num_classifications,
    e.pielou_evenness,
    e.species,
    e.frac_votes_for_species,
    e.number_votes_for_species,
    e.workflow_id,
    e.imagename1,e.imagename2,e.imagename3,
    e.imagelink1,e.imagelink2,e.imagelink3,
    e.non_deer_animal_count,
    e.number_votes_for_non_deer_counts,
    e.frac_votes_for_non_deer_counts,
    f.deer_counts,
    f.adult_antlerless,
    f.adult_antlered,
    f.adult_head_not_visible,
    f.young,
    f.number_votes_for_counts as number_votes_for_deer_counts,
    f.num_answers as number_answers_deer,
    f.frac_votes_for_counts as frac_votes_for_deer_counts
  FROM (SELECT c.subject_id,
    c.num_classifications,
    c.pielou_evenness,
    c.species,
    c.frac_votes_for_species,
    c.number_votes_for_species,
    c.workflow_id,
    c.imagename1,c.imagename2,c.imagename3,
    c.imagelink1,c.imagelink2,c.imagelink3,
    d.number_of_animals as non_deer_animal_count,
    d.number_of_votes_for_count as number_votes_for_non_deer_counts,
    d.frac_votes_for_count as frac_votes_for_non_deer_counts
    FROM (SELECT a.subject_ids as subject_id,
        a.num_classifications,
        a.pielou_evenness,
        a.choice as species,
        a.frac_votes_for_species,
        a.number_votes_for_species,
        b.workflow_id,
        b.imagename1,b.imagename2,b.imagename3,
        b.imagelink1,b.imagelink2,b.imagelink3
      FROM camera_trap.zoon_class_concensus as a, camera_trap.zoon_subj_wfid_1432 as b
      WHERE a.subject_ids = b.subject_id) as c, camera_trap.zoon_class_number_of_animals as d
    WHERE c.subject_id=d.subject_ids) as e, camera_trap.zoon_deer_counts as f
  WHERE e.subject_id=f.subject_ids
--  LIMIT 10