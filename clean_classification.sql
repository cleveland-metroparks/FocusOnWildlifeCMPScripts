-- Testing ways to clean up raw report data

-- I started splitting these up on 8/31/2017

SET search_path TO camera_trap,public;

-- Set up test table
CREATE TABLE json_test (
  id serial primary key,
  data jsonb,
  data2 json
);

INSERT INTO json_test (data) VALUES 
  ('{}'),
  ('{"a": 1}'),
  ('{"a": 2, "b": ["c", "d"]}'),
  ('{"a": 1, "b": {"c": "d", "e": true}}'),
  ('{"b": 2}');
INSERT INTO json_test (data2) VALUES 
  ('{}'),
  ('{"a": 1}'),
  ('{"a": 2, "b": ["c", "d"]}'),
  ('{"a": 1, "b": {"c": "d", "e": true}}'),
  ('{"b": 2}');

SET search_path TO camera_trap,public;
CREATE TABLE zooniverse_classification_report_raw2 (
  id BIGSERIAL primary key,
  classification_id bigint,
  user_name text,
  user_id numeric,
  user_ip text,
  workflow_id integer,
  workflow_name text,
  workflow_version numeric,
  created_at timestamp with time zone,
  gold_standard boolean,
  expert  boolean,
  metadata jsonb,
  annotations jsonb,
  subject_data jsonb,
  subject_ids bigint
);

-- In Powershell
-- cd "C:\Program Files\PostgreSQL\9.6\bin"
-- .\psql -d NR_monitoring -h 10.0.0.27 -U plorch -p 5432
-- enter password
-- order in copy command must match order in .csv

-- \COPY camera_trap.zooniverse_classification_report_raw2(classification_id,user_name,user_id,user_ip,workflow_id,
--   workflow_name,workflow_version,created_at,gold_standard,expert,metadata,annotations,subject_data,subject_ids) 
-- FROM 'C:\Users\pdl\Documents\GitHub\FocusOnWildlifeCMPScripts\focus-on-wildlife-cleveland-metroparks-classifications_test.csv' 
-- DELIMITER ',' CSV HEADER;

-- Scripts to explore jsons from classification report
SELECT classification_id,user_name,metadata,annotations,subject_data 
  FROM camera_trap.zooniverse_classification_report_raw 
  WHERE subject_ids='5037604'
  ORDER BY user_name

-- This did not work
json_pretty(SELECT annotations 
  FROM camera_trap.zooniverse_classification_report_raw 
  WHERE subject_ids='5037604'
  ORDER BY user_name
)

-- Find subjects which were presented to users more than once
--  This currently produces no records, but works when you change 1 to 0 on the HAVING line
-- Idea from here: https://stackoverflow.com/questions/28156795/how-to-find-duplicate-records-in-postgresql
SELECT subject_ids,user_name,count(*) as cnt
  FROM camera_trap.zooniverse_classification_report_raw 
  GROUP BY subject_ids,user_name
  HAVING cnt>1
  ORDER BY subject_ids,user_name

-- Start figuring out how to get stuff out of the jsonb fields
SELECT annotations ? value
  FROM camera_trap.zooniverse_classification_report_raw 
  WHERE subject_ids='5037604' 
  ORDER BY user_name

SELECT * FROM camera_trap.zooniverse_classification_report_raw 
  WHERE subject_ids='5037604'
  ORDER BY user_name

SELECT subject_ids,user_name,classification_id,annotations,jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'choice' as choice
FROM camera_trap.zooniverse_classification_report_raw
WHERE subject_ids='5037604' 
ORDER BY subject_ids,user_name;

-- If we want to remove duplicates, rather than using Brooke Simon's python code for that,
  -- Need to also limit to one workflow id and version

-- This will limit by workflow and add row numbers. No longer needed since I added serial primary key for camera_trap.zooniverse_classification_report_raw2
SELECT ROW_NUMBER() OVER() AS row2,* 
  FROM camera_trap.zooniverse_classification_report_raw
    WHERE workflow_id=1432 AND workflow_version=478.99 -- AND subject_ids='5056764'

-- Did not use this as it deletes, rather than selects for a materialized view
  -- Could duplicate table after update, then just do delete
DELETE FROM camera_trap.zooniverse_classification_report_raw2
WHERE id IN (SELECT id
              FROM (SELECT id,
                             ROW_NUMBER() OVER (partition BY subject_ids, user_name ORDER BY id) AS rnum
                     FROM camera_trap.zooniverse_classification_report_raw2) dups
              WHERE dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.rnum > 1);
ALTER TABLE camera_trap.zooniverse_classification_report_raw2 DROP COLUMN IF EXISTS rnum RESTRICT;

-- *** Duplicates *** This was used in the duplicates view

--Name:  duplicates_1432_478_99
--Description:  creates duplicates_1432_478_99 view
SELECT * FROM (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
  FROM camera_trap.zooniverse_classification_report_raw2
      ) dups
  WHERE 
    dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row > 1 -- AND dups.subject_ids='4580284'
-- or
SELECT * FROM (
  SELECT id,subject_ids,classification_id,user_name,annotations,workflow_id,workflow_version,
  ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
  FROM camera_trap.zooniverse_classification_report_raw2
      ) dups
  WHERE 
    dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row > 1 -- AND subject_ids='5056764'dups.Row > 1

-- Table without duplicates
--  This works and is used in materialized view zooniverse_classification_nodups
  -- Need to delete the Row column before saving
-- Name:  zooniverse_classification_nodups
-- Description:  table without duplicates from one workflow and version
SELECT * FROM (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
  FROM camera_trap.zooniverse_classification_report_raw2
      ) dups
  WHERE 
    dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row = 1

--   This did not work (chokes on duplicates.id)
WITH duplicates AS (
  SELECT * FROM (
    SELECT *,
    ROW_NUMBER() OVER(PARTITION BY subject_ids, user_name ORDER BY subject_ids asc) AS Row
    FROM camera_trap.zooniverse_classification_report_raw2
        ) dups
    WHERE 
      dups.workflow_id=1432 AND dups.workflow_version=478.99 AND dups.Row > 1) -- AND dups.subject_ids='4580284'
SELECT * FROM camera_trap.zooniverse_classification_report_raw2
  WHERE dups.workflow_id=1432 AND dups.workflow_version=478.99 AND id NOT IN duplicates.id;

--  This spins forever so does the version without the ORDER BY
--  It works correctly if you add WHERE subject_ids='5056764'
SELECT DISTINCT ON (subject_ids, user_name) *
  FROM camera_trap.zooniverse_classification_report_raw2
  ORDER BY subject_ids, user_name;

-- This failed
SELECT * as b FROM(SELECT min(id) as minid 
  FROM camera_trap.zooniverse_classification_report_raw2 
  GROUP BY subject_ids, user_name) as a
WHERE a.minid=b.id;

-- This is good for seeing what choices a particular subject_id has with it
SELECT row,subject_ids,classification_id,user_name,annotations,subject_data,created_at,
jsonb_array_length(jsonb_array_elements(annotations::jsonb)->'value') as n_choices,
jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice,
jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'answers' as answers,
jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->'answers'->'HOWMANY' as c_count,
replace(split_part(split_part(jsonb_each(subject_data::jsonb)::text,',"',2),'")',1),'""','"')::jsonb as subject_data2
FROM camera_trap.zooniverse_classification_report_raw
WHERE subject_ids='5056764'

-- Need to get annotations
-- Need to merge with subjects file


-- Nothing there is '5040012' or '5054946' with one who put nothing there twice, 
-- One animal is '5055387', '5054140' with one missID, '5056764' with tons of disagreement
--  Two choices Human, motorized, is '5037604' or '5038246'
ORDER BY subject_ids,user_name,choice;

-- To figure out concensus

WITH choices AS (
  SELECT jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice
  FROM camera_trap.zooniverse_classification_nodups
  WHERE subject_ids='5056764'
)
SELECT choice,count(choice) as cnt
  FROM choices
  GROUP BY choice
-- or
  -- This one has rank built in and can be used to find most preferred
SELECT choice,cnt,RANK() OVER (ORDER BY cnt DESC) AS rn
  FROM (SELECT choice,count(choice) as cnt
          FROM (SELECT jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice
                  FROM camera_trap.zooniverse_classification_nodups
                  WHERE subject_ids='5056764') choices
          GROUP BY choice) counts
-- giving just top rank requires one more subquery
  -- Used this for another materialized view
SELECT choice,cnt,rn
  FROM (SELECT choice,cnt,RANK() OVER (ORDER BY cnt DESC) AS rn
    FROM (SELECT choice,count(choice) as cnt
            FROM (SELECT jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice
                    FROM camera_trap.zooniverse_classification_nodups
                    WHERE subject_ids='5056764') choices
            GROUP BY choice) counts) s
  WHERE s.rn=1 limit 1
  
-- or
SELECT jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice' as choice,
  count(jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice') as cnt 
  FROM camera_trap.zooniverse_classification_report_raw
  WHERE subject_ids='5056764'
  GROUP BY jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value')->>'choice'


-- These produce unintended duplicates
WITH annotation_value AS (
  SELECT subject_ids,jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value') as annoval
  FROM camera_trap.zooniverse_classification_report_raw
  WHERE subject_ids='5037604'
)
SELECT a.subject_ids,a.classification_id,a.user_name,a.annotations,a.subject_data,
  b.annoval->>'choice' as choice,
  b.annoval->'answers' as answers,
  replace(split_part(split_part(jsonb_each(a.subject_data::jsonb)::text,',"',2),'")',1),'""','"')::jsonb as subject_data2
FROM camera_trap.zooniverse_classification_report_raw AS a,annotation_value AS b
WHERE a.subject_ids=b.subject_ids
ORDER BY a.subject_ids,a.user_name;

-- Another way?
SELECT subject_ids,classification_id,user_name,annotations,subject_data,
  annoval->>'choice' as choice,
  annoval->'answers' as answers,
  replace(split_part(split_part(jsonb_each(subject_data::jsonb)::text,',"',2),'")',1),'""','"')::jsonb as subject_data2
FROM camera_trap.zooniverse_classification_report_raw, (
  SELECT jsonb_array_elements(jsonb_array_elements(annotations::jsonb)->'value') as annoval
  FROM camera_trap.zooniverse_classification_report_raw
  WHERE subject_ids='5037604'
) AS annotation_value
WHERE subject_ids='5037604'
ORDER BY subject_ids,user_name;

-- Without WHERE subject_ids='5056764' and using the raw file, This ran overnight and did not finish before server disconnected, 
--  but it is close to what we want for a table that the consensus algorythm can work on when run on the nodups version

-- This is now a view without the WHERE
--  Done to allow better QA/QC
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

-- Using the view with choices
-- This finds the counts and ranks with ORDER BY so we can see it worked
-- Used in the zoon_class_concensus view
SELECT subject_ids,
    choice,
    number_votes_for_species,
    sum(number_votes_for_species) over (PARTITION BY subject_ids) as num_classifications,
    (number_votes_for_species)::numeric / sum(number_votes_for_species) over (PARTITION BY subject_ids) as frac_votes_for_species, 
    RANK() OVER (PARTITION BY subject_ids ORDER BY number_votes_for_species DESC) AS rn
  FROM(SELECT subject_ids,choice,count(choice) as number_votes_for_species
            FROM camera_trap.zooniverse_classification_choices
            GROUP BY subject_ids,choice) AS counted
        ORDER BY subject_ids,choice

-- Name:  zoon_class_number_of_animals
-- Description:  table with counts for number of animals to be used as a view
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

-- Concensus table
-- Made a view of this also to allow better QA/QC
-- Name:  zoon_class_concensus
-- Comment: table with choices, answers, and subject data split out of the nodup table
SELECT subject_ids,
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
              count(choice) as number_votes_for_species,
            FROM camera_trap.zooniverse_classification_choices
            GROUP BY subject_ids,choice) AS counted
        ORDER BY subject_ids,choice) as s
  WHERE s.rn=1  -- comment this out to see the whole table to see if it is working
--  ORDER BY subject_ids

-- to see deer answers only. This was used to generate concensus
SELECT subject_ids,
    choice,
    string_to_array(concat_ws(',',COALESCE(trim(both '"' from (answers::jsonb->'ADULTANTLERLESS')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'ADULTANTLERED')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'ADULTHEADNOTVISIBLE')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'YOUNG')::text),'0')::int),',')::int[] AS deer_counts,
    (answers::jsonb->'BEHAVIORCHECKALLTHATAPPLY')::text AS behavior
    FROM camera_trap.zooniverse_classification_choices AS a
    WHERE a.choice = 'DEER'
    ORDER BY subject_ids

-- Name: zoon_deer_counts
-- Comment: Get the concensus answers for deer questions for a view where deer_counts is Antlerless, Antlered, Not visible, Young
SELECT subject_ids,
  deer_counts,
  deer_counts[1] as adult_antlerless,
  deer_counts[2] as adult_antlered,
  deer_counts[3] as adult_head_not_visible,
  deer_counts[4] as young,
  (deer_counts[1]::int+deer_counts[2]::int+deer_counts[3]::int+deer_counts[4]::int) as total_deer,
  number_votes_for_counts,
  num_answers,
  frac_votes_for_counts
  FROM (SELECT subject_ids,
    deer_counts,
    number_votes_for_counts,
    sum(number_votes_for_counts) over (PARTITION BY subject_ids) as num_answers,
    (number_votes_for_counts)::numeric / sum(number_votes_for_counts) over (PARTITION BY subject_ids) as frac_votes_for_counts,
    RANK() OVER (PARTITION BY subject_ids ORDER BY number_votes_for_counts DESC) AS rn
      FROM (SELECT subject_ids,
        deer_counts,
        count(deer_counts) as number_votes_for_counts
        FROM (SELECT subject_ids,
          choice,
          string_to_array(concat_ws(',',COALESCE(trim(both '"' from (answers::jsonb->'ADULTANTLERLESS')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'ADULTANTLERED')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'ADULTHEADNOTVISIBLE')::text),'0')::int,
            COALESCE(trim(both '"' from (answers::jsonb->'YOUNG')::text),'0')::int),',')::int[] AS deer_counts
          FROM camera_trap.zooniverse_classification_choices AS a
          WHERE a.choice = 'DEER'
          ORDER BY subject_ids) as counts
        GROUP BY counts.subject_ids,counts.deer_counts) as s) as foo
    WHERE foo.rn=1

-- Subjects table with only workflow_id = 1432 for making a view
-- Name:  zoon_subj_wfid_1432
-- Comment:  Get only workflow_id = 1432 and break out imag info
SELECT *,
  (metadata::jsonb->'#Image 1')::text AS imagename1,
  (metadata::jsonb->'#Image 2')::text AS imagename2,
  (metadata::jsonb->'#Image 3')::text AS imagename3,
  (locations::jsonb->'0')::text AS imagelink1,
  (locations::jsonb->'1')::text AS imagelink2,
  (locations::jsonb->'2')::text AS imagelink3
  FROM camera_trap.zooniverse_subjects_report AS subj
  WHERE subj.workflow_id = 1432
--   limit 1

-- ***This uses cross joins and is probably wrong
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
        a.choice_z as species,
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

-- Name: zooniverse_summary
-- Comments: Report summarizing all concensus views for QA/QC and shiny app
WITH c AS (SELECT a.subject_ids as subject_id,
        a.num_classifications,
        a.pielou_evenness,
        a.choice_z as species,
        a.frac_votes_for_species,
        a.number_votes_for_species,
        b.workflow_id,
        b.imagename1,b.imagename2,b.imagename3,
        b.imagelink1,b.imagelink2,b.imagelink3
        FROM camera_trap.zoon_class_concensus as a LEFT JOIN
          camera_trap.zoon_subj_wfid_1432 as b
        ON a.subject_ids = b.subject_id),
    e AS (SELECT c.subject_id,
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
        FROM c LEFT JOIN
          camera_trap.zoon_class_number_of_animals as d
        ON c.subject_id=d.subject_ids)

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
  FROM e LEFT JOIN 
    camera_trap.zoon_deer_counts as f
  ON e.subject_id=f.subject_ids;