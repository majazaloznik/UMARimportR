--
--  TESTS FOR DELETE TABLE
--
BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_series_id integer;
    v_dimension_id1 integer;
    v_dimension_id2 integer;
    v_vintage_id integer;
    v_result record;
BEGIN
    -- Create test table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_DEL', 'Test Delete Table', 1)
    RETURNING id INTO v_table_id;

    -- Create two dimensions, storing IDs separately
    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'dim1', false)
    RETURNING id INTO v_dimension_id1;

    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'dim2', false)
    RETURNING id INTO v_dimension_id2;

    -- Add dimension levels
    INSERT INTO platform.dimension_levels (tab_dim_id, level_value, level_text)
    VALUES (v_dimension_id1, 'level1', 'Level One'),
           (v_dimension_id1, 'level2', 'Level Two');

    -- Create category_table entry
    INSERT INTO platform.category_table (table_id, category_id, source_id)
    VALUES (v_table_id, 0, 1);

    -- Create two test series, getting just one ID back
    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series 1', 'TS01')
    RETURNING id INTO v_series_id;

    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series 2', 'TS02');

    -- Add series levels
    INSERT INTO platform.series_levels (series_id, tab_dim_id, level_value)
    VALUES (v_series_id, v_dimension_id1, 'level1');

    -- Create vintages for both series
    INSERT INTO platform.vintage (series_id, published)
    SELECT s.id, NOW()
    FROM platform.series s
    WHERE s.table_id = v_table_id;

    -- Add data points
    INSERT INTO platform.data_points (vintage_id, period_id, value)
    SELECT v.id, '2020', 42.0
    FROM platform.vintage v
    JOIN platform.series s ON s.id = v.series_id
    WHERE s.table_id = v_table_id;

    -- Add flags
    INSERT INTO platform.flag_datapoint (vintage_id, period_id, flag_id)
    SELECT v.id, '2020', 'e'
    FROM platform.vintage v
    JOIN platform.series s ON s.id = v.series_id
    WHERE s.table_id = v_table_id;

    -- Test deletion and count verification
    SELECT * FROM platform.delete_table(v_table_id) INTO v_result;

    -- Verify counts
    ASSERT v_result.table_count = 1,
        'Should delete 1 table';
    ASSERT v_result.series_count = 2,
        'Should delete 2 series';
    ASSERT v_result.vintage_count = 2,
        'Should delete 2 vintages';
    ASSERT v_result.data_points_count = 2,
        'Should delete 2 data points';
    ASSERT v_result.flag_count = 2,
        'Should delete 2 flags';
    ASSERT v_result.dimension_count = 2,
        'Should delete 2 dimensions';
    ASSERT v_result.dimension_levels_count = 2,
        'Should delete 2 dimension levels';
    ASSERT v_result.series_levels_count = 1,
        'Should delete 1 series level';
    ASSERT v_result.category_table_count = 1,
        'Should delete 1 category table entry';

    -- Verify no orphaned records
    ASSERT NOT EXISTS (SELECT 1 FROM platform.series WHERE table_id = v_table_id),
        'No series should remain';
    ASSERT NOT EXISTS (SELECT 1 FROM platform.table_dimensions WHERE table_id = v_table_id),
        'No dimensions should remain';
    ASSERT NOT EXISTS (SELECT 1 FROM platform.category_table WHERE table_id = v_table_id),
        'No category_table entries should remain';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--
--  TESTS FOR DELETE SERIES
--

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_series_id integer;
    v_dimension_id integer;
    v_vintage_id1 integer;
    v_vintage_id2 integer;
    v_result record;
BEGIN
    -- Ensure period exists
    INSERT INTO platform.period (id, interval_id)
    VALUES ('A2020', 'A')
    ON CONFLICT DO NOTHING;

    -- Create test table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_DEL_SERIES', 'Test Delete Series', 1)
    RETURNING id INTO v_table_id;

    -- Create dimension
    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'dim1', false)
    RETURNING id INTO v_dimension_id;

    -- Add dimension level
    INSERT INTO platform.dimension_levels (tab_dim_id, level_value, level_text)
    VALUES (v_dimension_id, 'level1', 'Level One');

    -- Create test series
    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series', 'TS01')
    RETURNING id INTO v_series_id;

    -- Add series level
    INSERT INTO platform.series_levels (series_id, tab_dim_id, level_value)
    VALUES (v_series_id, v_dimension_id, 'level1');

    -- Create vintages separately
    INSERT INTO platform.vintage (series_id, published)
    VALUES (v_series_id, NOW())
    RETURNING id INTO v_vintage_id1;

    INSERT INTO platform.vintage (series_id, published)
    VALUES (v_series_id, NOW() - interval '1 day')
    RETURNING id INTO v_vintage_id2;

    -- Add data points for both vintages
    INSERT INTO platform.data_points (vintage_id, period_id, value)
    VALUES (v_vintage_id1, 'A2020', 42.0),
           (v_vintage_id2, 'A2020', 42.0);

    -- Add flags for both vintages
    INSERT INTO platform.flag_datapoint (vintage_id, period_id, flag_id)
    VALUES (v_vintage_id1, 'A2020', 'e'),
           (v_vintage_id2, 'A2020', 'e');

    -- Test deletion and count verification
    SELECT * FROM platform.delete_series(v_series_id) INTO v_result;

    -- Verify counts
    ASSERT v_result.series_count = 1,
        'Should delete 1 series';
    ASSERT v_result.vintage_count = 2,
        'Should delete 2 vintages';
    ASSERT v_result.data_points_count = 2,
        'Should delete 2 data points';
    ASSERT v_result.flag_count = 2,
        'Should delete 2 flags';
    ASSERT v_result.series_levels_count = 1,
        'Should delete 1 series level';

    -- Verify no orphaned records
    ASSERT NOT EXISTS (SELECT 1 FROM platform.vintage WHERE series_id = v_series_id),
        'No vintages should remain';
    ASSERT NOT EXISTS (SELECT 1 FROM platform.series_levels WHERE series_id = v_series_id),
        'No series_levels should remain';

    -- Test deletion of non-existent series (should return all zeros)
    SELECT * FROM platform.delete_series(999999) INTO v_result;

    ASSERT v_result.series_count = 0 AND
           v_result.vintage_count = 0 AND
           v_result.data_points_count = 0 AND
           v_result.flag_count = 0 AND
           v_result.series_levels_count = 0,
        'Deleting non-existent series should return all zeros';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--
--  TESTS FOR DELETE VINTAGE
--


BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_series_id integer;
    v_vintage_id integer;
    v_result record;
BEGIN
    -- Ensure periods exist
    INSERT INTO platform.period (id, interval_id)
    VALUES ('A2020', 'A'),
           ('A2021', 'A')
    ON CONFLICT DO NOTHING;

    -- Create test table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_DEL_VINTAGE', 'Test Delete Vintage', 1)
    RETURNING id INTO v_table_id;

    -- Create test series
    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series', 'TS01')
    RETURNING id INTO v_series_id;

    -- Create vintage
    INSERT INTO platform.vintage (series_id, published)
    VALUES (v_series_id, NOW())
    RETURNING id INTO v_vintage_id;

    -- Add multiple data points with different periods
    INSERT INTO platform.data_points (vintage_id, period_id, value)
    VALUES (v_vintage_id, 'A2020', 42.0),
           (v_vintage_id, 'A2021', 43.0);

    -- Add multiple flags
    INSERT INTO platform.flag_datapoint (vintage_id, period_id, flag_id)
    VALUES (v_vintage_id, 'A2020', 'e'),
           (v_vintage_id, 'A2021', 'p');

    -- Test deletion and count verification
    SELECT * FROM platform.delete_vintage(v_vintage_id) INTO v_result;

    -- Verify counts
    ASSERT v_result.vintage_count = 1,
        'Should delete 1 vintage';
    ASSERT v_result.data_points_count = 2,
        'Should delete 2 data points';
    ASSERT v_result.flag_count = 2,
        'Should delete 2 flags';

    -- Verify no orphaned records
    ASSERT NOT EXISTS (SELECT 1 FROM platform.data_points WHERE vintage_id = v_vintage_id),
        'No data points should remain';
    ASSERT NOT EXISTS (SELECT 1 FROM platform.flag_datapoint WHERE vintage_id = v_vintage_id),
        'No flags should remain';

    -- Test deletion of non-existent vintage (should return all zeros)
    SELECT * FROM platform.delete_vintage(999999) INTO v_result;

    ASSERT v_result.vintage_count = 0 AND
           v_result.data_points_count = 0 AND
           v_result.flag_count = 0,
        'Deleting non-existent vintage should return all zeros';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;
