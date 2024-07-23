--- init
CREATE TABLE wikistat
(
    `time` DateTime CODEC(Delta(4), ZSTD(1)),
    `project` LowCardinality(String),
    `subproject` LowCardinality(String),
    `path` String,
    `hits` UInt64
)
/*
MergeTree is the common table engine that saves rows in blocks of 8192 rows based on the primary key (order by).

Unlike SummingMergeTree or ReplacingMergeTree, MergeTree doesn't merge rows with the same primary key.
Instead it allows rows with the same primary key to exist in storage.
*/
ENGINE = MergeTree
ORDER BY (path, time);

INSERT INTO wikistat SELECT *
FROM s3('https://ClickHouse-public-datasets.s3.amazonaws.com/wikistat/partitioned/wikistat*.native.zst') LIMIT 1e9


--- query_raw
SELECT
    project,
    sum(hits) AS h
FROM wikistat
WHERE date(time) = '2015-05-01'
GROUP BY project
ORDER BY h DESC
LIMIT 10


--- mv
CREATE TABLE wikistat_top_projects
(
    `date` Date,
    `project` LowCardinality(String),
    `hits` UInt32
)
ENGINE = SummingMergeTree --- SummingMergeTree is a variant of MergeTree that sums up values with the same primary key.
ORDER BY (date, project);

CREATE MATERIALIZED VIEW wikistat_top_projects_mv TO wikistat_top_projects AS
SELECT
    date(time) AS date,
    project,
    sum(hits) AS hits
FROM wikistat
GROUP BY
    date,
    project;

INSERT INTO wikistat_top_projects SELECT
    date(time) AS date,
    project,
    sum(hits) AS hits
FROM wikistat
GROUP BY
    date,
    project


--- query_mv
SELECT
    project,
    sum(hits) hits
FROM wikistat_top_projects
WHERE date = '2015-05-01'
GROUP BY project
ORDER BY hits DESC
LIMIT 10


--- insert
INSERT INTO wikistat
VALUES(now(), 'test', '', '', 10),
      (now(), 'test', '', '', 10),
      (now(), 'test', '', '', 20),
      (now(), 'test', '', '', 30);

SELECT hits
FROM wikistat_top_projects
/*
FINAL merges the results with the same keys before returning them,
otherwise you will see multiple rows with the same key.

Note that this doesn't change the data in storage, so if you run
the same query without final again, you still see multiple rows.
*/
FINAL
WHERE (project = 'test') AND (date = date(now()))


--- size
SELECT
    total_rows,
    formatReadableSize(total_bytes) AS total_bytes_on_disk
FROM system.tables
WHERE table = 'wikistat_top_projects'
