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
