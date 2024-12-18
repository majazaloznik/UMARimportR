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
