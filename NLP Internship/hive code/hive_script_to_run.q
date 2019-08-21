
drop table trends_ranked;
drop table tags_taxonomy;
drop table article_types;
drop table fashion_taxonomy;

------------------------------------------------------------------------------------------------------------------------

drop table matched_trends;
drop table unmatched_trends;
drop table unmatched_trends_split;
drop table unmatched_trends_sub_split;
drop table results;
drop table results_final;

------------------------------------------------------------------------------------------------------------------------

drop table temp_refined;
drop table temp_data;
drop table temp_not_found;
drop table temp_sum_score;
drop table trends_scored;

------------------------------------------------------------------------------------------------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS trends_ranked (
trend STRING, 
score INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/clean_trends';

CREATE EXTERNAL TABLE IF NOT EXISTS tags_taxonomy (
item STRING,
type  STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gtaxonomy/tags_taxonomy';

CREATE EXTERNAL TABLE IF NOT EXISTS article_types (
key STRING,
article_type STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gtaxonomy/article_types';

CREATE EXTERNAL TABLE IF NOT EXISTS fashion_taxonomy (
key STRING,
sub_category STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gtaxonomy/fashion';

------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS matched_trends (
trend STRING,
score INT,
type STRING,
sub_category STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/output';

-- To match trends from ranked_final with fashion_taxonomy and retrieve required columns

INSERT INTO matched_trends
SELECT 
trends_ranked.trend,
trends_ranked.score,
'product' as type,
fashion_taxonomy.sub_category,
fashion_taxonomy.gender
FROM
trends_ranked
JOIN 
fashion_taxonomy
ON 
lower(trim(trends_ranked.trend)) = lower(trim(fashion_taxonomy.key));

------------------------------------------------------------------------------------------------------------------------

-- To match trends from ranked_final with tags_taxonomy excluding those which already found a match in the previous step

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.trend,
A.score
FROM
trends_ranked A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
) A
JOIN tags_taxonomy B
ON lower(trim(A.trend)) = lower(trim(B.item));

------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS unmatched_trends (
trend STRING, 
score INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temporary';

-- To load unmatched trends into a temporary table

INSERT INTO unmatched_trends
SELECT 
A.trend,
A.score
FROM
trends_ranked A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL;

------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS unmatched_trends_split (
trend STRING, 
score INT,
trend_split ARRAY<STRING>
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temporary1';

-- To split trend into an array of words

INSERT INTO unmatched_trends_split
SELECT
A.trend,
A.score,
split(A.trend, ' ') as trend_split
FROM
unmatched_trends A;

------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS unmatched_trends_sub_split (
trend STRING, 
score INT,
trend_split ARRAY<STRING>,
trend_size INT,
trend_split_6 STRING,
trend_split_5 STRING,
trend_split_4 STRING,
trend_split_3 STRING,
trend_split_2 STRING,
trend_split_1 STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temporary2';

INSERT INTO unmatched_trends_sub_split
SELECT
A.trend,
A.score,
A.trend_split,
A.size,
(CASE 
WHEN (A.size >= 6) THEN CONCAT(A.trend_split[size-6], ' ', A.trend_split[size-5], ' ', A.trend_split[size-4], ' ', A.trend_split[size-3], ' ', A.trend_split[size-2], ' ', A.trend_split[size-1]) 
ELSE 'NA'
END) as trend_split_6,
(CASE 
WHEN (A.size >= 5) THEN CONCAT(A.trend_split[size-5], ' ', A.trend_split[size-4], ' ', A.trend_split[size-3], ' ', A.trend_split[size-2], ' ', A.trend_split[size-1]) 
ELSE 'NA'
END) as trend_split_5,
(CASE 
WHEN (A.size >= 4) THEN CONCAT(A.trend_split[size-4], ' ', A.trend_split[size-3], ' ', A.trend_split[size-2], ' ', A.trend_split[size-1]) 
ELSE 'NA'
END) as trend_split_4,
(CASE 
WHEN (A.size >= 3) THEN CONCAT(A.trend_split[size-3], ' ', A.trend_split[size-2], ' ', A.trend_split[size-1]) 
ELSE 'NA'
END) as trend_split_3,
(CASE 
WHEN (A.size >= 2) THEN CONCAT(A.trend_split[size-2], ' ', A.trend_split[size-1]) 
ELSE 'NA'
END) as trend_split_2,
A.trend_split[size-1] as trend_split_1
FROM
(SELECT
trend,
score,
trend_split,
size(trend_split) as size
FROM
unmatched_trends_split
) A;

------------------------------------------------------------------------------------------------------------------------
-- Partial match logic starts here ###########
------------------------------------------------------------------------------------------------------------------------
-- Partial match lookup on fashion_taxonomy (6 levels)
------------------------------------------------------------------------------------------------------------------------
-- To match the unmatched list of trends with fashion_taxonomy using first 6 substrings
------------------------------------------------------------------------------------------------------------------------

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
unmatched_trends_sub_split A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_6)) = lower(trim(B.key));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_5)) = lower(trim(B.key));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_4)) = lower(trim(B.key));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_3)) = lower(trim(B.key));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_2)) = lower(trim(B.key));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
'product' as type,
B.sub_category,
B.gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
fashion_taxonomy B
ON 
lower(trim(A.trend_split_1)) = lower(trim(B.key));

------------------------------------------------------------------------------------------------------------------------
-- Partial match lookup on tags_taxonomy (6 levels)
------------------------------------------------------------------------------------------------------------------------

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_6)) = lower(trim(B.item));

INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_5)) = lower(trim(B.item));


INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_4)) = lower(trim(B.item));


INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_3)) = lower(trim(B.item));


INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_2)) = lower(trim(B.item));


INSERT INTO matched_trends
SELECT 
A.trend,
A.score,
B.type,
'NA' as sub_category,
'NA' as gender
FROM
(
SELECT 
A.*
FROM
unmatched_trends_sub_split A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL
)A
JOIN 
tags_taxonomy B
ON 
lower(trim(A.trend_split_1)) = lower(trim(B.item));

------------------------------------------------------------------------------------------------------------------------
-- Union of all the records which found a match and those which never matched

CREATE TABLE IF NOT EXISTS results (
trend STRING,
score INT,
type STRING,
sub_category STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/results';

INSERT INTO results
SELECT
trend,
score,
type,
sub_category,
gender
FROM 
matched_trends
UNION
SELECT 
A.trend,
A.score,
'Not found' as type,
'Not found' as sub_category,
'Not found' as gender
FROM
trends_ranked A
LEFT JOIN 
matched_trends B
ON 
lower(trim(A.trend)) = lower(trim(B.trend))
WHERE
B.trend IS NULL;

------------------------------------------------------------------------------------------------------------------------

-- Join with article_types to find the article_type

CREATE TABLE IF NOT EXISTS results_final (
trend STRING,
score INT,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/results_final';

INSERT INTO results_final
SELECT
A.trend,
A.score,
A.type,
A.sub_category,
B.article_type,
A.gender
FROM
results A
LEFT OUTER JOIN
article_types B
ON
lower(trim(A.sub_category)) = lower(trim(B.key));

------------------------------------------------------------------------------------------------------------------------
------------------------------------------- Refinement starts here -------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- This table has the original trend and the trimmed one

CREATE TABLE IF NOT EXISTS temp_refined (
trend STRING,
score INT,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
new_trend string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temp_refined';

----------- Removing some part of the code from here --------

INSERT INTO temp_refined
SELECT 
trend,
score,
type,
sub_category,
article_type,
gender,
trim(trend) as new_trend
FROM
results_final;

------------------------------------------------------------------------------------------------------------------------

-- Create a temporary table which is a subset of results_final with records having value as trend = sub_category

CREATE TABLE IF NOT EXISTS temp_data (
trend STRING,
score INT,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temp_data';

INSERT INTO temp_data
SELECT 
trim(new_trend) as trend,
score,
type,
sub_category,
article_type,
gender
FROM
temp_refined
WHERE
trim(new_trend) = trim(sub_category);

------------------------------------------------------------------------------------------------------------------------
-- Create a temporary table to store records where article_type is NULL

CREATE TABLE IF NOT EXISTS temp_not_found (
trend STRING,
score INT,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temp_not_found';

INSERT INTO temp_not_found
SELECT 
trim(new_trend) as trend,
score,
type,
sub_category,
article_type,
gender
FROM 
temp_refined
WHERE
article_type IS NULL;

------------------------------------------------------------------------------------------------------------------------

-- Remove records with values trend = sub_category

INSERT OVERWRITE TABLE temp_refined 
    SELECT * from temp_refined 
    WHERE new_trend <> sub_category;

-- Remove records with values article_type is NULL

INSERT OVERWRITE TABLE temp_refined
   SELECT * FROM 
   temp_refined
   WHERE
   article_type IS NOT NULL;

------------------------------------------------------------------------------------------------------------------------
-- Create a table with score summed up at sub_category level

CREATE TABLE IF NOT EXISTS temp_sum_score (
trend STRING,
score INT,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
total_score INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/temp_sum_score';

INSERT INTO temp_sum_score
SELECT 
A.new_trend,
A.score,
A.type,
A.sub_category,
A.article_type,
A.gender,
B.total_score
FROM
temp_refined A
JOIN
(
SELECT sub_category, SUM(score) as total_score
FROM
temp_refined
GROUP BY sub_category
) B
ON 
A.sub_category = B.sub_category;

ALTER TABLE temp_sum_score ADD COLUMNS (score_part int);

INSERT OVERWRITE TABLE temp_sum_score
 SELECT trend,
        score,
        type,
        sub_category,
        article_type,
        gender,
        total_score,
        ((score/total_score) * 100) as score_part
 FROM
        temp_sum_score;

ALTER TABLE temp_sum_score ADD COLUMNS (new_score int);
        
INSERT OVERWRITE TABLE temp_sum_score
SELECT trend,
        score,
        type,
        sub_category,
        article_type,
        gender,
        total_score,
        ((score/total_score) * 100) as score_part,
        (score + score_part) as new_score
 FROM
        temp_sum_score; 
        
-------------------------------------------------------------------------------------------   

-- Merging repeting trends and adding their scores

CREATE TABLE IF NOT EXISTS trends_scored (
trend STRING,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
score INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/trends_scored';

INSERT INTO trends_scored
SELECT 
trend, 
type, 
sub_category, 
article_type, 
gender,
sum(new_score) as score
FROM
temp_sum_score
GROUP BY
trend, type, sub_category, article_type, gender;

-------------------------------------------------------------------------------------------

-- hive -e 'set hive.cli.print.header=true; select * from trends_scored' > /home/hadoop/final_result/trends_scored.csv

-------------------------------------------------------------------------------------------

-- hive -e 'set hive.cli.print.header=true; select * from temp_not_found where type != "Not found" ' > /home/hadoop/final_result/style_fabric_color.csv

-------------------------------------------------------------------------------------------

-- hive -e 'set hive.cli.print.header=true; select * from temp_not_found where type = "Not found" ' > /home/hadoop/final_result/unmatched_trends.csv

-------------------------------------------------------------------------------------------
