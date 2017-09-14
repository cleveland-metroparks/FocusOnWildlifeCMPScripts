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
