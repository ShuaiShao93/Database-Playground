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