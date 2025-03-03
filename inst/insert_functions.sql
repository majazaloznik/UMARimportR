-- Add new source
--
-- Insert new source into the `source` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_source(
                                            id INT,
                                            name TEXT,
                                            name_long TEXT,
                                            url TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.source (id, name, name_long, url)
    VALUES (id, name, name_long, url)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new table
--
-- Inserts new table into the `table` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_table(code TEXT,
                                        name TEXT,
                                        source_id INTEGER,
                                        url TEXT,
                                        notes JSONB,
                                        keep_vintage BOOL,
                                        OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.table (code, name, source_id, url, notes, keep_vintage)
    VALUES (code, name, source_id, url, notes, keep_vintage)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


-- Add new umar author
--
-- Insert new author into the `umar_author` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_author(name TEXT,
                                            initials TEXT,
                                            email TEXT,
                                            folder TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.umar_authors(name, initials, email, folder)
    VALUES (name, initials, email, folder)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


-- Add new category
--
-- Insert new category into the `category` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_category(id INTEGER,
                                            name TEXT,
                                            source_id INTEGER,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.category (id, name, source_id)
    VALUES (id, name, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


-- Add new category-relationship
--
-- Insert new row into the `category-relationship` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_category_relationship(id INTEGER,
                                            parent_id INTEGER,
                                            source_id INTEGER,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.category_relationship (category_id, parent_id, source_id)
    VALUES (id, parent_id, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


-- Add new category-table row
--
-- Insert new row into the `category-table` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_category_table(category_id INTEGER,
                                            table_id INTEGER,
                                            source_id INTEGER,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.category_table (category_id, table_id, source_id)
    VALUES (category_id, table_id, source_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new table_dimensions row
--
-- Insert new row into the `table_dimensions` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_table_dimensions(table_id INTEGER,
                                            dimension TEXT,
                                            is_time BOOLEAN,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.table_dimensions(table_id, dimension, is_time)
    VALUES (table_id, dimension, is_time)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new dimension_levels row
--
-- Insert new row into the `dimension_levels` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_dimension_levels(tab_dim_id INTEGER,
                                            level_value TEXT,
                                            level_text TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.dimension_levels(tab_dim_id, level_value, level_text)
    VALUES (tab_dim_id, level_value, level_text)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new unit row
--
-- Insert new row into the `unit` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_unit(name TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.unit ( name)
    VALUES (name)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new series row
--
-- Insert new row into the `series` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_series(table_id INTEGER,
                                            name_long TEXT,
                                            unit_id INTEGER,
                                            code TEXT,
                                            interval_id TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.series (table_id, name_long, unit_id, code, interval_id)
    VALUES (table_id, name_long, unit_id, code, interval_id)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


-- Add new series level row
--
-- Insert new row into the `series_level` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_series_levels(series_id INTEGER,
                                            tab_dim_id INTEGER,
                                            level_value TEXT,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.series_levels (series_id, tab_dim_id, level_value)
    VALUES (series_id, tab_dim_id, level_value)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;

-- Add new vintage row
--
-- Insert new row into the `vintage` table.
--
CREATE OR REPLACE FUNCTION platform.insert_new_vintage(series_id INTEGER,
                                            published TIMESTAMP,
                                            OUT count INTEGER)
AS $$
BEGIN
    INSERT INTO platform.vintage (series_id, published)
    VALUES (series_id, published)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS count = ROW_COUNT;
END;
$$ LANGUAGE plpgsql;



-- ============================================================================
-- Function: insert_prepared_data_points
-- Description: Inserts prepared data points into the database
-- ============================================================================
CREATE OR REPLACE FUNCTION platform.insert_prepared_data_points(
    p_table_id integer,
    p_dimension_ids integer[],
    p_interval_id character varying
)
RETURNS TABLE (
    periods_inserted integer,
    datapoints_inserted integer,
    flags_inserted integer
) AS $$
DECLARE
    v_periods_count integer;
    v_datapoints_count integer;
    v_flags_count integer;
BEGIN
    -- Insert new periods
    INSERT INTO platform.period (id, interval_id)
    SELECT DISTINCT time, p_interval_id
    FROM tmp_prepared_data
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_periods_count = ROW_COUNT;

    -- Insert data points
    INSERT INTO platform.data_points (vintage_id, period_id, value)
    SELECT
        v.id as vintage_id,
        t.time,
        t.value
    FROM tmp_prepared_data t
    JOIN platform.series s ON t.series_id = s.id
    JOIN platform.vintage v ON v.series_id = s.id
    WHERE s.table_id = p_table_id
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_datapoints_count = ROW_COUNT;

    -- Insert flags
    INSERT INTO platform.flag_datapoint (vintage_id, period_id, flag_id)
    SELECT
        v.id as vintage_id,
        t.time,
        t.flag
    FROM tmp_prepared_data t
    JOIN platform.series s ON t.series_id = s.id
    JOIN platform.vintage v ON v.series_id = s.id
    WHERE s.table_id = p_table_id
    AND t.flag <> ''
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_flags_count = ROW_COUNT;

    RETURN QUERY SELECT
        v_periods_count as periods_inserted,
        v_datapoints_count as datapoints_inserted,
        v_flags_count as flags_inserted;
END;
$$ LANGUAGE plpgsql;
