"CREATE DATABASE platform_copy_temp WITH TEMPLATE platform OWNER postgres"




drop VIEW "views".ajpes_insolventnosti;
drop VIEW "views".ajpes_stecaji;
drop VIEW "views".latest_data_points_view;
drop MATERIALIZED VIEW "views".latest_data_points;
drop MATERIALIZED VIEW "views".mat_latest_series_data_table_74;
drop MATERIALIZED VIEW "views".mat_latest_series_data_table_80;

-- make alterations on the tables
ALTER TABLE platform.vintage
ADD COLUMN full_hash character varying,
ADD COLUMN partial_hash character varying;

ALTER TABLE platform.vintage ALTER COLUMN id TYPE bigint;
-- Step 4: Modify all foreign key columns
ALTER TABLE platform.data_points ALTER COLUMN vintage_id TYPE bigint;
ALTER TABLE platform.flag_datapoint ALTER COLUMN vintage_id TYPE bigint;

-- Alter the series_id column in the vintage table
ALTER TABLE platform.vintage ALTER COLUMN series_id TYPE BIGINT;

ALTER TABLE platform.dimension_levels ALTER COLUMN tab_dim_id TYPE BIGINT;
ALTER TABLE platform.series ALTER COLUMN table_id TYPE BIGINT;
ALTER TABLE platform.series_levels ALTER COLUMN series_id TYPE BIGINT;
ALTER TABLE platform.series_levels ALTER COLUMN tab_dim_id TYPE BIGINT;
ALTER TABLE platform.table_dimensions ALTER COLUMN table_id TYPE BIGINT;



-- "views".latest_data_points source

CREATE MATERIALIZED VIEW "views".latest_data_points
TABLESPACE pg_default
AS WITH latest_vintages AS (
  SELECT DISTINCT ON (vintage.series_id) vintage.id AS vintage_id,
  vintage.series_id
  FROM platform.vintage
  ORDER BY vintage.series_id, vintage.published DESC
)
SELECT s.code AS series_code,
t.code AS table_code,
s.name_long,
dp.period_id,
dp.value
FROM platform.data_points dp
JOIN latest_vintages lv ON dp.vintage_id = lv.vintage_id
JOIN platform.series s ON lv.series_id = s.id
JOIN platform."table" t ON s.table_id = t.id
ORDER BY s.code, dp.period_id
WITH DATA;

-- View indexes:
  CREATE INDEX idx_latest_data_points_period ON views.latest_data_points USING btree (period_id);
CREATE INDEX idx_latest_data_points_series ON views.latest_data_points USING btree (series_code);
CREATE INDEX idx_latest_data_points_table ON views.latest_data_points USING btree (table_code);


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
AS SELECT latest_data_points.series_code,
latest_data_points.table_code,
latest_data_points.name_long,
latest_data_points.period_id,
latest_data_points.value
FROM views.latest_data_points;

-- delete all functions in dbviewer - teh insert, get and delete ones anyway.
