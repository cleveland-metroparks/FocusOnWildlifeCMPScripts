-- Name:  zoon_class_answers
-- Comment:  Calculate concensus number of animals and creates view
-- For now, just HOWMANY
SELECT subject_ids,
  jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'answers'->'HOWMANY' as number_of_animals
FROM camera_trap.zooniverse_classification_nodups
-- WHERE subject_ids='5056764';