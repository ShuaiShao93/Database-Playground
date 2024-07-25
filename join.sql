--- create title table
CREATE TABLE wikistat_titles
(
    `path` String,
    `title` String
)
ENGINE = MergeTree
ORDER BY path

INSERT INTO wikistat_titles
VALUES('Ana_Sayfa', 'Ana Sayfa - artist'),
      ('Bruce_Jenner', 'William Bruce Jenner');


--- create mv
CREATE TABLE wikistat_with_titles
(
    `time` DateTime,
    `path` String,
    `title` String,
    `hits` UInt64
)
ENGINE = MergeTree
ORDER BY (path, time);

CREATE MATERIALIZED VIEW wikistat_with_titles_mv TO wikistat_with_titles
AS SELECT time, path, title, hits
FROM wikistat AS w
INNER JOIN wikistat_titles AS wt ON w.path = wt.path

INSERT INTO wikistat_with_titles SELECT
    time, path, title, hits
FROM wikistat AS w
INNER JOIN wikistat_titles AS wt ON w.path = wt.path

--- query
SELECT * FROM wikistat_with_titles LIMIT 5


--- insert into left table. New row is found in mv.
INSERT INTO wikistat VALUES(now(), 'en', '', 'Ana_Sayfa', 123);

SELECT *
FROM wikistat_with_titles
ORDER BY time DESC
LIMIT 3


--- check query_log for speed
SELECT query, query_duration_ms, *
FROM system.query_log
ORDER BY event_time DESC
LIMIT 5


--- insert into right table. No new row is found in mv. MV trigger is only for left table.
INSERT INTO wikistat_titles
VALUES('Academy_Awards', 'Oscar academy awards');

SELECT *
FROM wikistat_with_titles
WHERE path = 'Academy_Awards'


--- update left table. New row is found in mv.
INSERT INTO wikistat VALUES(now(), 'en', '', 'Academy_Awards', 456);

SELECT *
FROM wikistat_with_titles
WHERE path = 'Academy_Awards'
