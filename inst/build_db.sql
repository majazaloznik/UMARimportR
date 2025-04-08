drop table if exists platform.source cascade;
CREATE TABLE platform.source
(
    id integer NOT NULL,
    name character varying NOT NULL,
    name_long character varying,
    url character varying,
    PRIMARY KEY (id),
    UNIQUE(name)
);
ALTER TABLE platform.source
ADD CONSTRAINT no_dash_check CHECK (name NOT LIKE '%%-%%');

INSERT INTO platform.source(
  id, name, name_long, url)
VALUES (1, 'SURS', 'Statistični urad RS', 'https://pxweb.stat.si/SiStat/sl');

drop table if exists platform.category cascade;
CREATE TABLE platform.category
(
    id integer NOT NULL,
    name character varying NOT NULL,
    source_id integer NOT NULL REFERENCES platform.source (id),
    PRIMARY KEY (id, source_id)
);
ALTER TABLE platform.category
ADD CONSTRAINT unique_sourceid_name UNIQUE (source_id, name);

INSERT INTO platform.category (id, name, source_id)
                       VALUES (0, 'SiStat', 1);

drop table if exists platform.category_relationship cascade;
CREATE TABLE platform.category_relationship
(
    category_id integer NOT NULL,
    parent_id integer NOT NULL,
    source_id integer NOT NULL,
    foreign key (category_id, source_id) references platform.category ( id, source_id),
    foreign key (parent_id, source_id) references platform.category ( id, source_id),
    PRIMARY KEY (category_id, parent_id, source_id)
);


drop table if exists platform."interval" cascade;
CREATE TABLE platform."interval"
(
    id character varying NOT NULL,
    name character varying NOT NULL,
    PRIMARY KEY (id)
);

drop table if exists platform.unit cascade;
CREATE TABLE platform.unit
(
    id int GENERATED ALWAYS AS IDENTITY,
    name character varying NOT NULL,
    PRIMARY KEY (id),
	UNIQUE(name)
);

drop table if exists platform."table" cascade;
CREATE TABLE platform."table"
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    code character varying UNIQUE NOT NULL,
    name character varying NOT NULL,
	source_id integer NOT NULL REFERENCES platform."source" (id),
    url character varying,
    description character varying,
    notes json,
    PRIMARY KEY (id)
);

drop table if exists platform.category_table cascade;
CREATE TABLE platform.category_table
(
    table_id integer NOT NULL REFERENCES platform."table" (id),
    category_id integer NOT NULL,
    source_id integer not null ,
    PRIMARY KEY (table_id, category_id),
    foreign key (category_id, source_id) references platform.category ( id, source_id)
);

drop table if exists platform.table_dimensions cascade;
CREATE TABLE platform.table_dimensions
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    table_id integer NOT NULL REFERENCES platform."table" (id),
    dimension character varying NOT NULL,
	  is_time boolean NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (table_id, dimension)
);

drop table if exists platform.dimension_levels cascade;
CREATE TABLE platform.dimension_levels
(
    tab_dim_id integer NOT NULL REFERENCES platform.table_dimensions (id),
    level_value character varying NOT NULL,
    level_text character varying,
    PRIMARY KEY (tab_dim_id, level_value)
);

drop table if exists platform.series cascade;
CREATE TABLE platform.series
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    table_id integer NOT NULL REFERENCES platform."table" (id),
    name_long character varying NOT NULL,
	unit_id integer REFERENCES platform.unit (id),
    code character varying NOT NULL,
	interval_id character varying REFERENCES platform.interval (id),
    PRIMARY KEY (id),
	unique(table_id, code)
);

drop table if exists platform.series_levels cascade;
CREATE TABLE platform.series_levels
(
    series_id integer NOT NULL REFERENCES platform.series (id),
    tab_dim_id integer NOT NULL,
    level_value character varying NOT NULL,
    PRIMARY KEY (series_id, tab_dim_id),
    FOREIGN KEY (tab_dim_id, level_value) REFERENCES platform.dimension_levels (tab_dim_id, level_value)
);

drop table if exists platform.vintage cascade;
CREATE TABLE platform.vintage
(
    id int GENERATED ALWAYS AS IDENTITY,
    series_id integer NOT NULL  REFERENCES platform.series (id),
    published timestamp NOT NULL,
	  UNIQUE (series_id, published),
    PRIMARY KEY (id)
);

drop table if exists platform.period cascade;
CREATE TABLE platform.period
(
    id character varying NOT NULL,
    interval_id character varying NOT NULL  REFERENCES platform."interval" (id),
    PRIMARY KEY (id)
);

drop table if exists platform.data_points cascade;
CREATE TABLE platform.data_points
(
    vintage_id integer NOT NULL REFERENCES platform.vintage (id),
    period_id character varying NOT NULL REFERENCES platform.period (id),
    value numeric,
    PRIMARY KEY (vintage_id, period_id)
);

create index ind_vintage_id_period_id on platform.data_points
(vintage_id, period_id);

drop table if exists platform.flag cascade;
CREATE TABLE platform.flag
(
    id character varying NOT NULL,
    name character varying NOT NULL,
    PRIMARY KEY (id)
);

drop table if exists platform.flag_datapoint cascade;
CREATE TABLE platform.flag_datapoint
(
    vintage_id integer NOT NULL,
    period_id character varying NOT NULL,
    flag_id character varying NOT NULL REFERENCES platform.flag (id),
    PRIMARY KEY (vintage_id, period_id, flag_id),
    FOREIGN KEY (vintage_id, period_id) REFERENCES platform.data_points (vintage_id, period_id)
);

drop table if exists platform.umar_authors;
CREATE TABLE platform.umar_authors
(
    name character varying NOT NULL,
    initials character varying NOT NULL,
    email character varying NOT NULL,
    folder character varying,
    PRIMARY KEY (initials)
);

INSERT INTO platform."interval"(
  id, name)
VALUES ('D', 'daily'),
('W', 'weekly'),
('F', 'biweekly'),
('M', 'monthly'),
('B', 'bimonthly'),
('Q', 'quarterly'),
('S', 'semiannually'),
('A', 'annualy');

INSERT INTO platform.flag(
  id, name)
VALUES ('M', 'manj zanesljiva ocena'),
('T', 'začasni podatki'),
('Z', 'zaupno'),
('N', 'za objavo premalo zanesljiva ocena'),
('b', 'break in time series'),
('c', 'confidential'),
('d', 'definition differs, see metadata'),
('e', 'estimated'),
('f', 'forecast'),
('n', 'not significant'),
('p', 'provisional'),
('r', 'revised'),
('s', 'eurostat estimate'),
('u', 'low reliability'),
('z', 'not applicable');

INSERT INTO platform."unit"(
  name)
VALUES ('1000');


ALTER TABLE platform."series"
ADD COLUMN "live" boolean DEFAULT true NOT NULL;

ALTER TABLE platform."table"
ADD COLUMN "update" boolean DEFAULT true NOT NULL;

ALTER TABLE platform."table"
ADD COLUMN "keep_vintage" boolean DEFAULT true NOT NULL;

ALTER TABLE platform.vintage
ADD COLUMN full_hash character varying,
ADD COLUMN partial_hash character varying;




-- Step 1: Drop dependent foreign keys (second level first)
ALTER TABLE platform.flag_datapoint DROP CONSTRAINT flag_datapoint_vintage_id_period_id_fkey;

-- Step 2: Drop first level foreign keys
ALTER TABLE platform.data_points DROP CONSTRAINT data_points_vintage_id_fkey;

-- Step 3: Modify the primary vintage_id column
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


-- Step 5: Recreate foreign key constraints (first level first)
ALTER TABLE platform.data_points ADD CONSTRAINT data_points_vintage_id_fkey
  FOREIGN KEY (vintage_id) REFERENCES platform.vintage(id);

-- Step 6: Recreate second level constraints
ALTER TABLE platform.flag_datapoint ADD CONSTRAINT flag_datapoint_vintage_id_period_id_fkey
  FOREIGN KEY (vintage_id, period_id) REFERENCES platform.data_points(vintage_id, period_id);

-- Also update the index that uses this column
DROP INDEX IF EXISTS platform.ind_vintage_id_period_id;
CREATE INDEX ind_vintage_id_period_id ON platform.data_points(vintage_id, period_id);
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

CREATE OR REPLACE VIEW "views".latest_data_points_view
AS SELECT latest_data_points.series_code,
    latest_data_points.table_code,
    latest_data_points.name_long,
    latest_data_points.period_id,
    latest_data_points.value
   FROM views.latest_data_points;


GRANT ALL ON ALL TABLES IN SCHEMA platform TO maintainer;
