CREATE OR REPLACE FUNCTION platform.normal_rand(integer, double precision, double precision)
 RETURNS SETOF double precision
 LANGUAGE c
 STRICT
AS '$libdir/tablefunc', $function$normal_rand$function$

CREATE OR REPLACE FUNCTION platform.crosstab(text)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab$function$

CREATE OR REPLACE FUNCTION platform.crosstab2(text)
 RETURNS SETOF tablefunc_crosstab_2
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab$function$

CREATE OR REPLACE FUNCTION platform.crosstab3(text)
 RETURNS SETOF tablefunc_crosstab_3
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab$function$

CREATE OR REPLACE FUNCTION platform.crosstab4(text)
 RETURNS SETOF tablefunc_crosstab_4
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab$function$

CREATE OR REPLACE FUNCTION platform.crosstab(text, integer)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab$function$

CREATE OR REPLACE FUNCTION platform.crosstab(text, text)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$crosstab_hash$function$

CREATE OR REPLACE FUNCTION platform.connectby(text, text, text, text, integer, text)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$connectby_text$function$

CREATE OR REPLACE FUNCTION platform.connectby(text, text, text, text, integer)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$connectby_text$function$

CREATE OR REPLACE FUNCTION platform.connectby(text, text, text, text, text, integer, text)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$connectby_text_serial$function$

CREATE OR REPLACE FUNCTION platform.connectby(text, text, text, text, text, integer)
 RETURNS SETOF record
 LANGUAGE c
 STABLE STRICT
AS '$libdir/tablefunc', $function$connectby_text_serial$function$

CREATE OR REPLACE FUNCTION platform.f_dynamic_copy(_file text, _colz text, _tbl text DEFAULT 'tmp1'::text, _delim text DEFAULT '	'::text, _nodelim text DEFAULT chr(127))
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
   row_ct int;
BEGIN

   -- create actual temp table with all columns text
   EXECUTE (
      SELECT format('CREATE TEMP TABLE %I(', _tbl)
          || _colz || ')'
      );

   -- Import data
   EXECUTE format($$COPY %I FROM %L WITH (FORMAT csv, HEADER, NULL '\N', DELIMITER %L)$$
                , _tbl, _file, _delim);

   GET DIAGNOSTICS row_ct = ROW_COUNT;
   RETURN format('Created table %I with %s rows.', _tbl, row_ct);
END
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_dimensions_table(table_id integer, dimension text, is_time boolean, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.table_dimensions (table_id, dimension, is_time)
    VALUES (table_id, dimension, is_time)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_series(table_id integer, name_long text, unit_id integer, code text, interval_id integer, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.series (table_id, name_long, unit_id, code, interval_id)
    VALUES (table_id, name_long, unit_id, code, interval_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_series_level(series_id integer, tab_dim_id integer, level_value text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.series_level (series_id, tab_dim_id, level_value)
    VALUES (series_id, tab_dim_id, level_value)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_series_level(series_id integer, tab_dim_id text, level_value text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.series_level (series_id, tab_dim_id, level_value)
    VALUES (series_id, tab_dim_id, level_value)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_source(name text, name_long text, url text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.source (name, name_long, url)
    VALUES (name, name_long, url)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_unit(id integer, name text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO test_platform.unit (id, name)
    VALUES (id, name)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.prepare_data_points(p_code_no text)
 RETURNS TABLE(series_id integer, level_value character varying, dimension character varying)
 LANGUAGE plpgsql
AS $function$ 
DECLARE dim_id bigint[];
DECLARE tbl_dimz text[];
BEGIN 
-- Get the dimension ids for the non-time dimension
dim_id := array(SELECT id 
FROM test_platform.table_dimensions
WHERE table_id = (
        SELECT id
        FROM test_platform.table
        WHERE code = p_code_no)
    AND is_time = FALSE);
-- Replace spaces with periods in the dimension names for these ids
tbl_dimz := array(SELECT
    REPLACE(t.dimension, ' ', '.') as dimension
FROM test_platform.table_dimensions t
WHERE id = any(dim_id)
order by 1);

RETURN QUERY 
-- Get the levels for the non-time dimensions for each series
SELECT
    series_levels.series_id,
    series_levels.level_value,
    dimz.dimension
FROM
    test_platform.series_levels
    LEFT JOIN (
        SELECT
            id,
            table_dimensions.dimension
        FROM
            test_platform.table_dimensions
        WHERE
            table_id = (
            SELECT id
            FROM test_platform.table
            WHERE code = p_code_no)
            AND is_time = FALSE) dimz on tab_dim_id = dimz.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.prepare_data_points1(p_code_no text)
 RETURNS TABLE(dimensions text)
 LANGUAGE plpgsql
AS $function$ 
DECLARE dim_id table_dimensions.id%TYPE;
BEGIN 
-- Replace spaces with periods in the dimension names for these ids
RETURN QUERY SELECT
    REPLACE(t.dimension, ' ', '.') as dimension
FROM test_platform.table_dimensions t
WHERE id IN (
    SELECT id -- Get the dimension ids for the non-time dimension
    FROM test_platform.table_dimensions
    WHERE table_id = (
        SELECT id
        FROM test_platform.table
        WHERE code = p_code_no)
    AND is_time = FALSE)
order by 1;
END;
$function$

CREATE OR REPLACE FUNCTION platform.prepare_data_points2(p_code_no text)
 RETURNS TABLE(dimensions text)
 LANGUAGE plpgsql
AS $function$ 
DECLARE dim_id bigint[];
BEGIN 
-- Get the dimension ids for the non-time dimension
dim_id := array(SELECT id 
FROM test_platform.table_dimensions
WHERE table_id = (
        SELECT id
        FROM test_platform.table
        WHERE code = p_code_no)
    AND is_time = FALSE);
-- Replace spaces with periods in the dimension names for these ids
RETURN QUERY SELECT
    REPLACE(t.dimension, ' ', '.') as dimension
FROM test_platform.table_dimensions t
WHERE id = any(dim_id)
order by 1;
END;
$function$

CREATE OR REPLACE FUNCTION platform.sum(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
res int;
begin
res := $1 + $2;
return res;
end;
$function$

CREATE OR REPLACE FUNCTION platform.test(no integer)
 RETURNS TABLE(level_value character varying)
 LANGUAGE plpgsql
AS $function$ 
BEGIN 
RETURN QUERY 
SELECT
    dl.level_value
FROM
    test_platform.dimension_levels dl
WHERE
    tab_dim_id in (
        select
            td.id
        from
            test_platform.table_dimensions td
        where
            table_id = no
    );

END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_source(id integer, name text, name_long text, url text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.source (id, name, name_long, url)
    VALUES (id, name, name_long, url)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_table(code text, name text, source_id integer, url text, notes jsonb, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.table (code, name, source_id, url, notes)
    VALUES (code, name, source_id, url, notes)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_interval_from_series(p_series_id bigint)
 RETURNS TABLE(interval_id character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.interval_id
   FROM platform.series s
   WHERE s.id = p_series_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_vintage_from_series(p_series_id bigint, p_date_valid timestamp without time zone DEFAULT NULL::timestamp without time zone)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT v.id
   FROM platform.vintage v
   WHERE v.series_id = p_series_id
   AND (p_date_valid IS NULL OR v.published < p_date_valid)
   ORDER BY v.published DESC
   LIMIT 1;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_vintage_from_series_code(p_series_code text, p_date_valid timestamp without time zone DEFAULT NULL::timestamp without time zone)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT v.id
   FROM platform.vintage v
   JOIN platform.series s ON v.series_id = s.id
   WHERE s.code = p_series_code
   AND (p_date_valid IS NULL OR v.published < p_date_valid)
   ORDER BY v.published DESC
   LIMIT 1;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_unit_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(name character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u.name
    FROM platform.vintage v
    JOIN platform.series s ON v.series_id = s.id
    JOIN platform.unit u ON s.unit_id = u.id
    WHERE v.id = p_vintage_id::bigint;  -- Explicit cast
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_unit_from_series(p_series_id bigint)
 RETURNS TABLE(name character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u.name
    FROM platform.unit u
    JOIN platform.series s ON s.unit_id = u.id
    WHERE s.id = p_series_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_name_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(name_long character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT s.name_long
    FROM platform.vintage v
    JOIN platform.series s ON v.series_id = s.id
    WHERE v.id = p_vintage_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_name_from_series(p_series_id bigint)
 RETURNS TABLE(name_long character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.name_long
   FROM platform.series s
   WHERE s.id = p_series_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_name_from_series_code(p_series_code text)
 RETURNS TABLE(name_long character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.name_long
   FROM platform.series s
   WHERE s.code = p_series_code;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_table_name_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(name character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT t.name
   FROM platform.vintage v
   JOIN platform.series s ON v.series_id = s.id
   JOIN platform."table" t ON s.table_id = t.id
   WHERE v.id = p_vintage_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_table_name_from_series(p_series_id bigint)
 RETURNS TABLE(name character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT t.name
   FROM platform.series s
   JOIN platform."table" t ON s.table_id = t.id
   WHERE s.id = p_series_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_interval_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(interval_id character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.interval_id
   FROM platform.vintage v
   JOIN platform.series s ON v.series_id = s.id
   WHERE v.id = p_vintage_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_data_points_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(period_id character varying, value numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT dp.period_id, dp.value
   FROM platform.data_points dp
   WHERE dp.vintage_id = p_vintage_id
   ORDER BY dp.period_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_data_points_from_series(p_series_id bigint, p_date_valid timestamp without time zone DEFAULT NULL::timestamp without time zone)
 RETURNS TABLE(period_id character varying, value numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT dp.period_id, dp.value
    FROM platform.vintage v
    JOIN platform.data_points dp ON dp.vintage_id = v.id
    WHERE v.series_id = p_series_id
    AND (p_date_valid IS NULL OR v.published < p_date_valid)
    AND v.id = (
        SELECT id
        FROM platform.vintage v2
        WHERE v2.series_id = p_series_id
        AND (p_date_valid IS NULL OR v2.published < p_date_valid)
        ORDER BY published DESC
        LIMIT 1
    )
    ORDER BY dp.period_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_date_published_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(published timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT v.published AT TIME ZONE 'CET'
   FROM platform.vintage v
   WHERE v.id = p_vintage_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_last_period_from_vintage(p_vintage_id bigint)
 RETURNS TABLE(period_id character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT dp.period_id
   FROM platform.data_points dp
   WHERE dp.vintage_id = p_vintage_id
   AND dp.value IS NOT NULL
   ORDER BY dp.period_id DESC
   LIMIT 1;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_source_code_from_source_name(p_source_name text)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.id
   FROM platform.source s
   WHERE s.name = p_source_name;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_table_id_from_table_code(p_table_code text)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT t.id
   FROM platform."table" t
   WHERE t.code = p_table_code;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_tab_dim_id_from_table_id_and_dimension(p_table_id integer, p_dimension text)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT td.id
    FROM platform.table_dimensions td
    WHERE td.table_id = p_table_id
    AND td.dimension = p_dimension;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_unit_id_from_unit_name(p_unit_name text)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT u.id
   FROM platform.unit u
   WHERE u.name = p_unit_name;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_ids_from_table_id(p_table_id integer)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.id
   FROM platform.series s
   WHERE s.table_id = p_table_id
   ORDER BY s.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_dimension_levels_from_table_id(p_table_id integer)
 RETURNS TABLE(tab_dim_id bigint, dimension character varying, level_value character varying, level_text character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT
       td.id as tab_dim_id,
       td.dimension,
       dl.level_value,
       dl.level_text
   FROM platform.table_dimensions td
   JOIN platform.dimension_levels dl ON dl.tab_dim_id = td.id
   WHERE td.table_id = p_table_id
   ORDER BY td.dimension, dl.level_value;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_id_from_series_code(p_series_code text)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.id
   FROM platform.series s
   WHERE s.code = p_series_code;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_max_category_id_for_source(p_source_id integer)
 RETURNS TABLE(max_id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT COALESCE(MAX(c.id), 0)  -- Return 0 if no categories exist
   FROM platform.category c
   WHERE c.source_id = p_source_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_initials_from_author_name(p_author_name text)
 RETURNS TABLE(initials character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT a.initials
   FROM platform.umar_authors a
   WHERE a.name = p_author_name;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_email_from_author_initials(p_initials text)
 RETURNS TABLE(email character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT a.email
   FROM platform.umar_authors a
   WHERE a.initials = p_initials;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_level_value_from_text(p_tab_dim_id bigint, p_level_text character varying)
 RETURNS TABLE(level_value character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT dl.level_value
   FROM platform.dimension_levels dl
   WHERE dl.tab_dim_id = p_tab_dim_id
   AND dl.level_text = p_level_text;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_time_dimension_from_table_code(p_table_code text)
 RETURNS TABLE(dimension character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT td.dimension
    FROM platform.table_dimensions td
    JOIN platform."table" t ON td.table_id = t.id
    WHERE t.code = p_table_code
    AND td.is_time = true;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_dimension_id_from_table_id_and_dimension(p_table_id integer, p_dimension character varying)
 RETURNS TABLE(id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT td.id 
   FROM platform.table_dimensions td
   WHERE td.table_id = p_table_id 
   AND td.dimension = p_dimension;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_non_time_dimensions_from_table_id(p_table_id integer)
 RETURNS TABLE(dimension character varying, id bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT td.dimension, td.id
    FROM platform.table_dimensions td
    WHERE td.table_id = p_table_id
    AND td.is_time = false
    ORDER BY td.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_levels_from_dimension_id(p_tab_dim_id integer)
 RETURNS TABLE(tab_dim_id integer, level_value character varying, level_text character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT dl.tab_dim_id, dl.level_value, dl.level_text
    FROM platform.dimension_levels dl
    WHERE dl.tab_dim_id = p_tab_dim_id
    ORDER BY dl.level_value;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_dimensions_from_table_id(p_table_id integer)
 RETURNS TABLE(id bigint, table_id integer, dimension character varying, is_time boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT td.id, td.table_id, td.dimension, td.is_time
    FROM platform.table_dimensions td
    WHERE td.table_id = p_table_id
    ORDER BY td.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_series_from_table_id(p_table_id integer)
 RETURNS TABLE(id bigint, table_id integer, name_long character varying, unit_id integer, code character varying, interval_id character varying, live boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT s.id, s.table_id, s.name_long, s.unit_id, s.code, s.interval_id, s.live
   FROM platform.series s
   WHERE s.table_id = p_table_id
   ORDER BY s.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_dimension_position_from_table(p_table_id integer, p_dimension_name character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_position integer;
BEGIN
    WITH ranked_dimensions AS (
        SELECT 
            dimension,
            ROW_NUMBER() OVER (ORDER BY id) as position
        FROM platform.table_dimensions
        WHERE table_id = p_table_id
        AND is_time = false
    )
    SELECT position INTO v_position
    FROM ranked_dimensions
    WHERE dimension = p_dimension_name;

    RETURN v_position;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_tables_with_keep_vintage(p_keep_vintage boolean)
 RETURNS TABLE(id bigint, code character varying, name character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.id, t.code, t.name
    FROM platform."table" t
    WHERE t.keep_vintage = p_keep_vintage
    ORDER BY t.id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_category_id_from_name(p_category_name text, p_source_id integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.id
    FROM platform.category c
    WHERE c.name = p_category_name
    AND c.source_id = p_source_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_author(name text, initials text, email text, folder text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.umar_authors(name, initials, email, folder)
    VALUES (name, initials, email, folder)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_category(id integer, name text, source_id integer, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.category (id, name, source_id)
    VALUES (id, name, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_category_relationship(id integer, parent_id integer, source_id integer, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.category_relationship (category_id, parent_id, source_id)
    VALUES (id, parent_id, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.get_last_publication_date_from_table_id(p_table_id integer)
 RETURNS TABLE(published timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
   RETURN QUERY
   SELECT DISTINCT v.published
   FROM platform.vintage v
   JOIN platform.series s ON v.series_id = s.id
   WHERE s.table_id = p_table_id
   ORDER BY v.published DESC
   LIMIT 1;  -- Add this line to get only the most recent date
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_category_table(category_id integer, table_id integer, source_id integer, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.category_table (category_id, table_id, source_id)
    VALUES (category_id, table_id, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_table_dimensions(table_id integer, dimension text, is_time boolean, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.table_dimensions(table_id, dimension, is_time)
    VALUES (table_id, dimension, is_time)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_dimension_levels(tab_dim_id integer, level_value text, level_text text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.dimension_levels(tab_dim_id, level_value, level_text)
    VALUES (tab_dim_id, level_value, level_text)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_unit(name text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.unit ( name)
    VALUES (name)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_series(table_id integer, name_long text, unit_id integer, code text, interval_id text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.series (table_id, name_long, unit_id, code, interval_id)
    VALUES (table_id, name_long, unit_id, code, interval_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_series_levels(series_id integer, tab_dim_id integer, level_value text, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.series_levels (series_id, tab_dim_id, level_value)
    VALUES (series_id, tab_dim_id, level_value)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_vintage(series_id integer, published timestamp without time zone, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.vintage (series_id, published)
    VALUES (series_id, published)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.insert_new_table(code text, name text, source_id integer, url text, notes jsonb, keep_vintage boolean, OUT count integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO platform.table (code, name, source_id, url, notes, keep_vintage)
    VALUES (code, name, source_id, url, notes, keep_vintage)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$function$

CREATE OR REPLACE FUNCTION platform.delete_table(p_table_id integer, OUT table_count integer, OUT series_count integer, OUT vintage_count integer, OUT data_points_count integer, OUT flag_count integer, OUT dimension_count integer, OUT dimension_levels_count integer, OUT series_levels_count integer, OUT category_table_count integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_series_ids integer[];
    v_vintage_ids integer[];
    v_dimension_ids integer[];
BEGIN
    -- Get all series IDs for this table
    SELECT ARRAY_AGG(id) INTO v_series_ids
    FROM platform.series
    WHERE table_id = p_table_id;

    -- Get all vintage IDs for these series
    IF v_series_ids IS NOT NULL THEN
        SELECT ARRAY_AGG(id) INTO v_vintage_ids
        FROM platform.vintage
        WHERE series_id = ANY(v_series_ids);
    END IF;

    -- Get all dimension IDs
    SELECT ARRAY_AGG(id) INTO v_dimension_ids
    FROM platform.table_dimensions
    WHERE table_id = p_table_id;

    -- Count and delete flag_datapoints
    IF v_vintage_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO flag_count
        FROM platform.flag_datapoint
        WHERE vintage_id = ANY(v_vintage_ids);

        DELETE FROM platform.flag_datapoint
        WHERE vintage_id = ANY(v_vintage_ids);
    ELSE
        flag_count := 0;
    END IF;

    -- Count and delete data_points
    IF v_vintage_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO data_points_count
        FROM platform.data_points
        WHERE vintage_id = ANY(v_vintage_ids);

        DELETE FROM platform.data_points
        WHERE vintage_id = ANY(v_vintage_ids);
    ELSE
        data_points_count := 0;
    END IF;

    -- Count and delete vintages
    IF v_series_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO vintage_count
        FROM platform.vintage
        WHERE series_id = ANY(v_series_ids);

        DELETE FROM platform.vintage
        WHERE series_id = ANY(v_series_ids);
    ELSE
        vintage_count := 0;
    END IF;

    -- Count and delete series_levels
    IF v_series_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO series_levels_count
        FROM platform.series_levels
        WHERE series_id = ANY(v_series_ids);

        DELETE FROM platform.series_levels
        WHERE series_id = ANY(v_series_ids);
    ELSE
        series_levels_count := 0;
    END IF;

    -- Count and delete series
    IF v_series_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO series_count
        FROM platform.series
        WHERE table_id = p_table_id;

        DELETE FROM platform.series
        WHERE table_id = p_table_id;
    ELSE
        series_count := 0;
    END IF;

    -- Count and delete dimension_levels
    IF v_dimension_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO dimension_levels_count
        FROM platform.dimension_levels
        WHERE tab_dim_id = ANY(v_dimension_ids);

        DELETE FROM platform.dimension_levels
        WHERE tab_dim_id = ANY(v_dimension_ids);
    ELSE
        dimension_levels_count := 0;
    END IF;

    -- Count and delete table_dimensions
    SELECT COUNT(*) INTO dimension_count
    FROM platform.table_dimensions
    WHERE table_id = p_table_id;

    DELETE FROM platform.table_dimensions
    WHERE table_id = p_table_id;

    -- Count and delete category_table entries
    SELECT COUNT(*) INTO category_table_count
    FROM platform.category_table
    WHERE table_id = p_table_id;

    DELETE FROM platform.category_table
    WHERE table_id = p_table_id;

    -- Finally count and delete the table itself
    SELECT COUNT(*) INTO table_count
    FROM platform.table
    WHERE id = p_table_id;

    DELETE FROM platform.table
    WHERE id = p_table_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.delete_series(p_series_id integer, OUT series_count integer, OUT vintage_count integer, OUT data_points_count integer, OUT flag_count integer, OUT series_levels_count integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_vintage_ids integer[];
BEGIN
    -- Get all vintage IDs for this series
    SELECT ARRAY_AGG(id) INTO v_vintage_ids
    FROM platform.vintage
    WHERE series_id = p_series_id;

    -- Count and delete flag_datapoints
    IF v_vintage_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO flag_count
        FROM platform.flag_datapoint
        WHERE vintage_id = ANY(v_vintage_ids);

        DELETE FROM platform.flag_datapoint
        WHERE vintage_id = ANY(v_vintage_ids);
    ELSE
        flag_count := 0;
    END IF;

    -- Count and delete data_points
    IF v_vintage_ids IS NOT NULL THEN
        SELECT COUNT(*) INTO data_points_count
        FROM platform.data_points
        WHERE vintage_id = ANY(v_vintage_ids);

        DELETE FROM platform.data_points
        WHERE vintage_id = ANY(v_vintage_ids);
    ELSE
        data_points_count := 0;
    END IF;

    -- Count and delete vintages
    SELECT COUNT(*) INTO vintage_count
    FROM platform.vintage
    WHERE series_id = p_series_id;

    DELETE FROM platform.vintage
    WHERE series_id = p_series_id;

    -- Count and delete series_levels
    SELECT COUNT(*) INTO series_levels_count
    FROM platform.series_levels
    WHERE series_id = p_series_id;

    DELETE FROM platform.series_levels
    WHERE series_id = p_series_id;

    -- Finally count and delete the series itself
    SELECT COUNT(*) INTO series_count
    FROM platform.series
    WHERE id = p_series_id;

    DELETE FROM platform.series
    WHERE id = p_series_id;
END;
$function$

CREATE OR REPLACE FUNCTION platform.delete_vintage(p_vintage_id integer, OUT vintage_count integer, OUT data_points_count integer, OUT flag_count integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Count and delete flag_datapoints
    SELECT COUNT(*) INTO flag_count
    FROM platform.flag_datapoint
    WHERE vintage_id = p_vintage_id;

    DELETE FROM platform.flag_datapoint
    WHERE vintage_id = p_vintage_id;

    -- Count and delete data_points
    SELECT COUNT(*) INTO data_points_count
    FROM platform.data_points
    WHERE vintage_id = p_vintage_id;

    DELETE FROM platform.data_points
    WHERE vintage_id = p_vintage_id;

    -- Finally count and delete the vintage itself
    SELECT COUNT(*) INTO vintage_count
    FROM platform.vintage
    WHERE id = p_vintage_id;

    DELETE FROM platform.vintage
    WHERE id = p_vintage_id;
END;
$function$

