INSERT INTO wikistat
VALUES(now(), 'test', '', '', 10),
      (now(), 'test', '', '', 10),
      (now(), 'test', '', '', 20),
      (now(), 'test', '', '', 30);

SELECT hits
FROM wikistat_top_projects
FINAL  --- FINAL merges the results with the same keys before returning them, otherwise you will see multiple rows with the same key
WHERE (project = 'test') AND (date = date(now()))