SELECT
    total_rows,
    formatReadableSize(total_bytes) AS total_bytes_on_disk
FROM system.tables
WHERE table = 'wikistat_top_projects'