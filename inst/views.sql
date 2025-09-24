CREATE MATERIALIZED VIEW "views".mat_latest_data_points
TABLESPACE pg_default
AS WITH latest_vintages AS (
  SELECT DISTINCT ON (vintage.series_id) vintage.id AS vintage_id,
    vintage.series_id
  FROM platform.vintage
  ORDER BY vintage.series_id, vintage.published DESC
)
SELECT s.code AS series_code,
  t.code AS table_code,
  -- Clean name_long here instead of in every dependent view
  TRIM(SPLIT_PART(s.name_long, '--', 1)) as name_long,
  dp.period_id,
  dp.value,
  -- Extract interval (last character from series_code)
  RIGHT(s.code, 1) as interval,
  -- Year parsing
  CASE
    WHEN dp.period_id ~ '^\d{4}M\d{2}$' THEN CAST(LEFT(dp.period_id, 4) AS INTEGER)
    WHEN dp.period_id ~ '^\d{4}Q[1-4]$' THEN CAST(LEFT(dp.period_id, 4) AS INTEGER)
    WHEN dp.period_id ~ '^\d{4}$' THEN CAST(dp.period_id AS INTEGER)
    WHEN dp.period_id ~ '^\d{1,2}\.\d{1,2}\.\d{4}$' THEN CAST(RIGHT(dp.period_id, 4) AS INTEGER)
    ELSE NULL
  END as year,
  -- Month parsing
  CASE
    WHEN dp.period_id ~ '^\d{4}M\d{2}$' THEN CAST(RIGHT(dp.period_id, 2) AS INTEGER)
    WHEN dp.period_id ~ '^\d{4}Q1$' THEN 1
    WHEN dp.period_id ~ '^\d{4}Q2$' THEN 4
    WHEN dp.period_id ~ '^\d{4}Q3$' THEN 7
    WHEN dp.period_id ~ '^\d{4}Q4$' THEN 10
    WHEN dp.period_id ~ '^\d{4}$' THEN 1
    WHEN dp.period_id ~ '^\d{1,2}\.\d{1,2}\.\d{4}$' THEN 1
    ELSE NULL
  END as month,
  -- Date parsing
  CASE
    WHEN dp.period_id ~ '^\d{4}M\d{2}$' THEN
      MAKE_DATE(CAST(LEFT(dp.period_id, 4) AS INTEGER), CAST(RIGHT(dp.period_id, 2) AS INTEGER), 1)
    WHEN dp.period_id ~ '^\d{4}Q1$' THEN
      MAKE_DATE(CAST(LEFT(dp.period_id, 4) AS INTEGER), 1, 1)
    WHEN dp.period_id ~ '^\d{4}Q2$' THEN
      MAKE_DATE(CAST(LEFT(dp.period_id, 4) AS INTEGER), 4, 1)
    WHEN dp.period_id ~ '^\d{4}Q3$' THEN
      MAKE_DATE(CAST(LEFT(dp.period_id, 4) AS INTEGER), 7, 1)
    WHEN dp.period_id ~ '^\d{4}Q4$' THEN
      MAKE_DATE(CAST(LEFT(dp.period_id, 4) AS INTEGER), 10, 1)
    WHEN dp.period_id ~ '^\d{4}$' THEN
      MAKE_DATE(CAST(dp.period_id AS INTEGER), 1, 1)
    WHEN dp.period_id ~ '^\d{1,2}\.\d{1,2}\.\d{4}$' THEN
      MAKE_DATE(CAST(RIGHT(dp.period_id, 4) AS INTEGER), 1, 1)
    ELSE NULL
  END as date
FROM platform.data_points dp
  JOIN latest_vintages lv ON dp.vintage_id = lv.vintage_id
  JOIN platform.series s ON lv.series_id = s.id
  JOIN platform."table" t ON s.table_id = t.id
ORDER BY s.code, dp.period_id
WITH DATA;

-- View indexes:
CREATE INDEX idx_mat_latest_data_points_period ON views.mat_latest_data_points USING btree (period_id);
CREATE INDEX idx_mat_latest_data_points_series ON views.mat_latest_data_points USING btree (series_code);
CREATE INDEX idx_mat_latest_data_points_table ON views.mat_latest_data_points USING btree (table_code);






-- "views".mat_latest_series_data_table_74 source

CREATE MATERIALIZED VIEW "views".mat_latest_series_data_table_74
TABLESPACE pg_default
AS SELECT d.period_id,
split_part(split_part(s.code::text, '--'::text, 3), '-'::text, 1) AS postopek,
split_part(split_part(s.code::text, '--'::text, 4), '-'::text, 1) AS oblika,
split_part(split_part(s.code::text, '--'::text, 5), '-'::text, 1) AS skd,
d.value,
s.code AS series_code,
s.name_long
FROM platform.series s
JOIN platform.vintage v ON s.id = v.series_id
JOIN platform.data_points d ON v.id = d.vintage_id
JOIN ( SELECT vintage.series_id,
       max(vintage.published) AS max_date
       FROM platform.vintage
       GROUP BY vintage.series_id) latest ON v.series_id = latest.series_id AND v.published = latest.max_date
WHERE s.table_id = 74
ORDER BY s.code, d.period_id
WITH DATA;

-- View indexes:
  CREATE INDEX idx_mat_latest_series_data_table_74_code ON views.mat_latest_series_data_table_74 USING btree (series_code);


-- "views".mat_latest_series_data_table_80 source

CREATE MATERIALIZED VIEW "views".mat_latest_series_data_table_80
TABLESPACE pg_default
AS SELECT d.period_id,
split_part(split_part(s.code::text, '--'::text, 3), '-'::text, 1) AS postopek,
split_part(split_part(s.code::text, '--'::text, 4), '-'::text, 1) AS oblika,
split_part(split_part(s.code::text, '--'::text, 5), '-'::text, 1) AS skd,
d.value,
s.code AS series_code,
s.name_long
FROM platform.series s
JOIN platform.vintage v ON s.id = v.series_id
JOIN platform.data_points d ON v.id = d.vintage_id
JOIN ( SELECT vintage.series_id,
       max(vintage.published) AS max_date
       FROM platform.vintage
       GROUP BY vintage.series_id) latest ON v.series_id = latest.series_id AND v.published = latest.max_date
WHERE s.table_id = 80
ORDER BY s.code, d.period_id
WITH DATA;

-- View indexes:
  CREATE INDEX idx_mat_latest_series_data_table_80_code ON views.mat_latest_series_data_table_80 USING btree (series_code);

-- "views".ajpes_insolventnosti source

CREATE OR REPLACE VIEW "views".ajpes_insolventnosti
AS SELECT mat_latest_series_data_table_74.period_id,
mat_latest_series_data_table_74.postopek,
mat_latest_series_data_table_74.oblika,
mat_latest_series_data_table_74.skd,
mat_latest_series_data_table_74.value,
mat_latest_series_data_table_74.series_code,
mat_latest_series_data_table_74.name_long
FROM views.mat_latest_series_data_table_74;

-- "views".ajpes_stecaji source

CREATE OR REPLACE VIEW "views".ajpes_stecaji
AS SELECT mat_latest_series_data_table_80.period_id,
mat_latest_series_data_table_80.postopek,
mat_latest_series_data_table_80.oblika,
mat_latest_series_data_table_80.skd,
mat_latest_series_data_table_80.value,
mat_latest_series_data_table_80.series_code,
mat_latest_series_data_table_80.name_long
FROM views.mat_latest_series_data_table_80;

-- "views".latest_data_points_view source

CREATE OR REPLACE VIEW "views".latest_data_points_view
AS SELECT mat_latest_data_points.series_code,
mat_latest_data_points.table_code,
mat_latest_data_points.name_long,
mat_latest_data_points.period_id,
mat_latest_data_points.value,
mat_latest_data_points.interval,
mat_latest_data_points.date
FROM views.mat_latest_data_points;
