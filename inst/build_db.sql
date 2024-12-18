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

GRANT ALL ON ALL TABLES IN SCHEMA platform TO maintainer;
