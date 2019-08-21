
-- Join previous trend scores for time series creation

DROP TABLE trends_scored_1;
DROP TABLE trends_scored_2;
DROP TABLE trends_scored_3;

-----------------------------------------------------------------------------

-- This is the oldest trend

CREATE TABLE IF NOT EXISTS trends_scored_1(
trend STRING,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
score STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/trends_scored_1';

-- This is the mid trend

CREATE TABLE IF NOT EXISTS trends_scored_2(
trend STRING,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
score STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/trends_scored_2';

-- This is the latest trend

CREATE TABLE IF NOT EXISTS trends_scored_3(
trend STRING,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
score STRING,
color STRING,
fabric STRING,
pattern STRING,
sleeve STRING,
needlework STRING,
embellishment STRING,
style STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 's3://gcuisine/trends_scored_3';

-------------------------------------------------------------------------------------------

drop table trends_timeseries;

CREATE TABLE IF NOT EXISTS trends_timeseries(
trend STRING,
type STRING,
sub_category STRING,
article_type STRING,
gender STRING,
score_1 STRING,
score_2 STRING,
score_3 STRING,
color STRING,
fabric STRING,
pattern STRING,
sleeve STRING,
needlework STRING,
embellishment STRING,
style STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://gcuisine/trends_timeseries';

INSERT INTO trends_timeseries
SELECT
trim(C.trend),
trim(C.type),
trim(C.sub_category),
trim(C.article_type),
trim(C.gender),
COALESCE(trim(C.score_oldest),0),
COALESCE(trim(D.score),0),
COALESCE(trim(C.score_latest),0),
trim(C.color),
trim(C.fabric),
trim(C.pattern),
trim(C.sleeve),
trim(C.needlework),
trim(C.embellishment),
trim(C.style)
FROM
(SELECT DISTINCT
A.trend, 
A.type, 
A.sub_category, 
A.article_type, 
A.gender,
A.score as score_latest,
B.score as score_oldest,
A.color,
A.fabric,
A.pattern,
A.sleeve,
A.needlework,
A.embellishment,
A.style
FROM
trends_scored_3 A
LEFT JOIN
trends_scored_1 B
ON
lower(trim(A.trend)) = lower(trim(B.trend))
) C
LEFT JOIN
trends_scored_2 D
ON 
lower(trim(C.trend)) = lower(trim(D.trend));

-------------------------------------------------------------------------------------------

-- hive -e 'set hive.cli.print.header=true; select * from trends_timeseries' > /home/hadoop/timeseries/trends_timeseries.csv

-------------------------------------------------------------------------------------------
