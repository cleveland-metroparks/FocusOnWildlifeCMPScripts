-- Name:  zooniverse_classification_choices
-- Comment:  Calculate concensus choice, fraction, and evenness for each subject_ids and creates view
SELECT *,
  jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice,
  jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'answers' as answers,
  jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'answers'->'HOWMANY' as number_of_animals,
-- This is just to deal with the wierd use of subject_id as a key rather than a value
  jsonb_object_keys(subject_data::jsonb) as subject_id,
  replace(split_part(split_part(jsonb_each(subject_data::jsonb)::text,',"',2),'")',1),'""','"')::jsonb as subject_rest
FROM camera_trap.zooniverse_classification_nodups
-- WHERE subject_ids='5056764';