--- query_raw. The raw data is already grouped by hour.
SELECT
    toDate(time) AS date,
    min(hits) AS min_hits_per_hour,
    max(hits) AS max_hits_per_hour,
    avg(hits) AS avg_hits_per_hour
FROM wikistat
WHERE project = 'en'
GROUP BY date

--- mv. For each project on each date, calculate the min, max, and average number of hits per hour.
CREATE TABLE wikistat_daily_summary
(
    `project` String,
    `date` Date,
    `min_hits_per_hour` AggregateFunction(min, UInt64),  --- Use AggregateFunction to store the state of the aggregate function.
    `max_hits_per_hour` AggregateFunction(max, UInt64),
    `avg_hits_per_hour` AggregateFunction(avg, UInt64)
)
ENGINE = AggregatingMergeTree --- AggregatingMergeTree is similar to SummingMergeTree, but we need to specify the aggregate functions.
ORDER BY (project, date);

CREATE MATERIALIZED VIEW wikistat_daily_summary_mv
TO wikistat_daily_summary AS
SELECT
    project,
    toDate(time) AS date,
    minState(hits) AS min_hits_per_hour, --- min/max/avgState functions need to be used with AggregateFunction.
    maxState(hits) AS max_hits_per_hour,
    avgState(hits) AS avg_hits_per_hour
FROM wikistat
GROUP BY project, date

INSERT INTO wikistat_daily_summary SELECT
    project,
    toDate(time) AS date,
    minState(hits) AS min_hits_per_hour,
    maxState(hits) AS max_hits_per_hour,
    avgState(hits) AS avg_hits_per_hour
FROM wikistat
GROUP BY project, date

--- query_mv 
SELECT
    date,
    minMerge(min_hits_per_hour) min_hits_per_hour, --- minMerge/maxMerge/avgMerge to query the AggregateFunction.
    maxMerge(max_hits_per_hour) max_hits_per_hour,
    avgMerge(avg_hits_per_hour) avg_hits_per_hour
FROM wikistat_daily_summary
WHERE project = 'en'
GROUP BY date

