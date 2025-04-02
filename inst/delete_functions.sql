CREATE OR REPLACE FUNCTION platform.delete_table(p_table_id integer,
    OUT table_count integer,
    OUT series_count integer,
    OUT vintage_count integer,
    OUT data_points_count integer,
    OUT flag_count integer,
    OUT dimension_count integer,
    OUT dimension_levels_count integer,
    OUT series_levels_count integer,
    OUT category_table_count integer)
RETURNS record AS $$
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
$$ LANGUAGE plpgsql;



-- DROP FUNCTION platform.delete_series(in int4, out int4, out int4, out int4, out int4, out int4);

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
;



CREATE OR REPLACE FUNCTION platform.delete_vintage(p_vintage_id integer,
    OUT vintage_count integer,
    OUT data_points_count integer,
    OUT flag_count integer)
RETURNS record AS $$
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
$$ LANGUAGE plpgsql;
