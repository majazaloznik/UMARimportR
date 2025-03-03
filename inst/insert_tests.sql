BEGIN;

DO $$
DECLARE
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_table tests...';

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_table(
        'TEST02',
        'Test Table',
        1,
        'http://example.com',
        '{"note": "test note"}'::jsonb,
        true
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.table
        WHERE code = 'TEST02'
        AND name = 'Test Table'
    ), 'Table should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate insert
    RAISE NOTICE 'Testing duplicate insert...';
    SELECT * FROM platform.insert_new_table(
        'TEST01',
        'Test Table 2',  -- different name
        1,
        'http://example.com',
        '{"note": "test note"}'::jsonb,
        true
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate insert should return 0';
    RAISE NOTICE 'Duplicate insert test passed';

    -- Test 3: Insert with nulls
    RAISE NOTICE 'Testing insert with nulls...';
    SELECT * FROM platform.insert_new_table(
        'TEST03',
        'Test Table Nulls',
        1,
        NULL,
        NULL,
        false
    ) INTO v_result;

    ASSERT v_result = 1, 'Insert with nulls should return 1';

    -- Verify the null insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.table
        WHERE code = 'TEST03'
        AND url IS NULL
        AND notes IS NULL
    ), 'Table with nulls should exist';
    RAISE NOTICE 'Null insert test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

---

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_table_dimensions tests...';

    -- Create test table first
    RAISE NOTICE 'Creating test table...';
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_DIM', 'Test Dimension Table', 1)
    RETURNING id INTO v_table_id;

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_table_dimensions(
        v_table_id,
        'time',
        true
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.table_dimensions
        WHERE table_id = v_table_id
        AND dimension = 'time'
        AND is_time = true
    ), 'Dimension should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate insert
    RAISE NOTICE 'Testing duplicate insert...';
    SELECT * FROM platform.insert_new_table_dimensions(
        v_table_id,
        'time',
        true
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate insert should return 0';
    RAISE NOTICE 'Duplicate insert test passed';

    -- Test 3: Different dimension for same table
    RAISE NOTICE 'Testing different dimension insert...';
    SELECT * FROM platform.insert_new_table_dimensions(
        v_table_id,
        'region',
        false
    ) INTO v_result;

    ASSERT v_result = 1, 'Different dimension insert should return 1';
    RAISE NOTICE 'Different dimension insert test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

---
BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_dimension_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_dimension_levels tests...';

    -- Create test table first
    RAISE NOTICE 'Creating test table and dimension...';
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_DIM_LEV', 'Test Dimension Levels', 1)
    RETURNING id INTO v_table_id;

    -- Create dimension
    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'region', false)
    RETURNING id INTO v_dimension_id;

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_dimension_levels(
        v_dimension_id,
        'SI',
        'Slovenia'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.dimension_levels
        WHERE tab_dim_id = v_dimension_id
        AND level_value = 'SI'
        AND level_text = 'Slovenia'
    ), 'Level should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate insert
    RAISE NOTICE 'Testing duplicate insert...';
    SELECT * FROM platform.insert_new_dimension_levels(
        v_dimension_id,
        'SI',
        'Slovenia'
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate insert should return 0';
    RAISE NOTICE 'Duplicate insert test passed';

    -- Test 3: Insert with NULL level_text
    RAISE NOTICE 'Testing NULL level_text...';
    SELECT * FROM platform.insert_new_dimension_levels(
        v_dimension_id,
        'HR',
        NULL
    ) INTO v_result;

    ASSERT v_result = 1, 'Insert with null level_text should return 1';
    RAISE NOTICE 'NULL level_text test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--

BEGIN;

DO $$
DECLARE
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_unit tests...';

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_unit(
        'meters'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.unit
        WHERE name = 'meters'
    ), 'Unit should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate name insert
    RAISE NOTICE 'Testing duplicate name insert...';
    SELECT * FROM platform.insert_new_unit(
        'meters'
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate name insert should return 0';
    RAISE NOTICE 'Duplicate name insert test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_unit_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_series tests...';

    -- Create prerequisites
    RAISE NOTICE 'Creating test table and unit...';
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_SERIES', 'Test Series Table', 1)
    RETURNING id INTO v_table_id;

    INSERT INTO platform.unit (name)
    VALUES ('count')
    RETURNING id INTO v_unit_id;

    -- Test 1: Basic insert with monthly interval
    RAISE NOTICE 'Testing basic insert with monthly interval...';
    SELECT * FROM platform.insert_new_series(
        v_table_id,
        'Monthly Series',
        v_unit_id,
        'MS01',
        'M'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.series
        WHERE table_id = v_table_id
        AND code = 'MS01'
        AND interval_id = 'M'
    ), 'Series should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate code for same table
    RAISE NOTICE 'Testing duplicate code insert...';
    SELECT * FROM platform.insert_new_series(
        v_table_id,
        'Different Name',
        v_unit_id,
        'MS01',  -- same code
        'A'      -- different interval
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate code insert should return 0';
    RAISE NOTICE 'Duplicate code insert test passed';

    -- Test 3: Same code for different table
    RAISE NOTICE 'Testing same code for different table...';
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_SERIES2', 'Test Series Table 2', 1)
    RETURNING id INTO v_table_id;

    SELECT * FROM platform.insert_new_series(
        v_table_id,
        'Annual Series',
        v_unit_id,
        'MS01',  -- same code, different table
        'A'
    ) INTO v_result;

    ASSERT v_result = 1, 'Same code for different table should return 1';
    RAISE NOTICE 'Same code different table test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_series_id integer;
    v_dimension_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_series_levels tests...';

    -- Create prerequisites
    RAISE NOTICE 'Creating test table, dimension, series and dimension level...';

    -- Create table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_SER_LEV', 'Test Series Levels', 1)
    RETURNING id INTO v_table_id;

    -- Create dimension
    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'region', false)
    RETURNING id INTO v_dimension_id;

    -- Add dimension level
    INSERT INTO platform.dimension_levels (tab_dim_id, level_value, level_text)
    VALUES (v_dimension_id, 'SI', 'Slovenia');

    -- Create series
    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series', 'TS01')
    RETURNING id INTO v_series_id;

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_series_levels(
        v_series_id,
        v_dimension_id,
        'SI'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.series_levels
        WHERE series_id = v_series_id
        AND tab_dim_id = v_dimension_id
        AND level_value = 'SI'
    ), 'Series level should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate insert
    RAISE NOTICE 'Testing duplicate insert...';
    SELECT * FROM platform.insert_new_series_levels(
        v_series_id,
        v_dimension_id,
        'SI'
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate insert should return 0';
    RAISE NOTICE 'Duplicate insert test passed';

    -- Test 3: Insert with non-existent level value
    RAISE NOTICE 'Testing insert with invalid level value...';
    SELECT * FROM platform.insert_new_series_levels(
        v_series_id,
        v_dimension_id,
        'HR'  -- This level value doesn't exist in dimension_levels
    ) INTO v_result;

    -- Should return 0 since HR doesn't exist in dimension_levels
    ASSERT v_result = 0, 'Insert with non-existent level value should return 0';
    RAISE NOTICE 'Invalid level value test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--

BEGIN;

DO $$
DECLARE
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_source tests...';

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_source(
        5,
        'SURSi',
        'Statistical Office',
        'http://www.stat.si'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.source
        WHERE id = 5
        AND name = 'SURSi'
        AND name_long = 'Statistical Office'
    ), 'Source should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate id
    RAISE NOTICE 'Testing duplicate id...';
    SELECT * FROM platform.insert_new_source(
        5,  -- same id
        'DIFFERENT',
        'Different Office',
        'http://different.si'
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate id insert should return 0';
    RAISE NOTICE 'Duplicate id test passed';

    -- Test 3: Duplicate name
    RAISE NOTICE 'Testing duplicate name...';
    SELECT * FROM platform.insert_new_source(
        6,      -- different id
        'SURSi', -- same name
        'Another Statistical Office',
        'http://another.si'
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate name should return 0';
    RAISE NOTICE 'Duplicate name test passed';

    -- Test 4: Name with dash (should fail CHECK constraint)
    RAISE NOTICE 'Testing name with dash...';
    BEGIN
        SELECT * FROM platform.insert_new_source(
            7,
            'TEST-SOURCE',
            NULL,
            NULL
        ) INTO v_result;

        ASSERT FALSE, 'Should not allow dash in name';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Check constraint violation caught as expected';
    END;
    RAISE NOTICE 'Name check constraint test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;


--

BEGIN;

DO $$
DECLARE
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_category tests...';

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_category(
        999,  -- id
        'Test Category',
        1   -- source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.category
        WHERE id = 999
        AND name = 'Test Category'
        AND source_id = 1
    ), 'Category should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate id and source_id
    RAISE NOTICE 'Testing duplicate insert...';
    SELECT * FROM platform.insert_new_category(
        999,  -- same id
        'Different Name',
        1   -- same source_id
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate insert should return 0';
    RAISE NOTICE 'Duplicate insert test passed';

    -- Test 3: Same name, different id for same source
    RAISE NOTICE 'Testing same name different id for same source...';
    SELECT * FROM platform.insert_new_category(
        999,              -- different id
        'Test Category', -- same name
        1               -- same source_id
    ) INTO v_result;

    ASSERT v_result = 0, 'Same name for same source should return 0';
    RAISE NOTICE 'Same name test passed';

    -- Test 4: Same id for different source
    RAISE NOTICE 'Testing same id for different source...';
    SELECT * FROM platform.insert_new_category(
        999,  -- same id
        'Test Category 2',
        2   -- different source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'Same id for different source should return 1';
    RAISE NOTICE 'Different source test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;


--

BEGIN;

DO $$
DECLARE
    v_source_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_category_relationship tests...';

    -- Create prerequisites
    RAISE NOTICE 'Creating test categories...';

    -- Insert source
    INSERT INTO platform.source (id, name)
    VALUES (5, 'SURSi');

    -- Insert categories for testing
    INSERT INTO platform.category (id, name, source_id)
    VALUES
        (1, 'Parent', 1),
        (2, 'Child', 1),
        (3, 'Another', 1);

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_category_relationship(
        2,  -- category_id (child)
        1,  -- parent_id
        1   -- source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.category_relationship
        WHERE category_id = 2
        AND parent_id = 1
        AND source_id = 1
    ), 'Relationship should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate relationship
    RAISE NOTICE 'Testing duplicate relationship...';
    SELECT * FROM platform.insert_new_category_relationship(
        2,  -- same category_id
        1,  -- same parent_id
        1   -- same source_id
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate relationship should return 0';
    RAISE NOTICE 'Duplicate relationship test passed';

    -- Test 3: Different relationship for same child
    RAISE NOTICE 'Testing different parent for same child...';
    SELECT * FROM platform.insert_new_category_relationship(
        2,  -- same category_id
        3,  -- different parent_id
        1   -- same source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'Different parent relationship should return 1';
    RAISE NOTICE 'Different parent test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;

--

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_category_table tests...';

    -- Create prerequisites
    RAISE NOTICE 'Creating test source, category and table...';

    -- Insert source
    INSERT INTO platform.source (id, name)
    VALUES (5, 'SURSi');

    -- Insert category
    INSERT INTO platform.category (id, name, source_id)
    VALUES (1, 'Test Category', 5);

    -- Insert table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_CAT_TAB', 'Test Category Table', 5)
    RETURNING id INTO v_table_id;

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_category_table(
        1,          -- category_id
        v_table_id, -- table_id
        5          -- source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.category_table
        WHERE category_id = 1
        AND table_id = v_table_id
        AND source_id = 5
    ), 'Category-table link should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate link
    RAISE NOTICE 'Testing duplicate link...';
    SELECT * FROM platform.insert_new_category_table(
        1,          -- same category_id
        v_table_id, -- same table_id
        5          -- same source_id
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate link should return 0';
    RAISE NOTICE 'Duplicate link test passed';

    -- Insert another category for next test
    INSERT INTO platform.category (id, name, source_id)
    VALUES (2, 'Another Category', 5);

    -- Test 3: Different category for same table
    RAISE NOTICE 'Testing different category for same table...';
    SELECT * FROM platform.insert_new_category_table(
        2,          -- different category_id
        v_table_id, -- same table_id
        5          -- same source_id
    ) INTO v_result;

    ASSERT v_result = 1, 'Different category link should return 1';
    RAISE NOTICE 'Different category test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;


--

BEGIN;

DO $$
DECLARE
    v_table_id integer;
    v_series_id integer;
    v_result integer;
BEGIN
    RAISE NOTICE 'Starting insert_new_vintage tests...';

    -- Create prerequisites
    RAISE NOTICE 'Creating test table and series...';

    -- Create table
    INSERT INTO platform.table (code, name, source_id)
    VALUES ('TEST_VINT', 'Test Vintage Table', 1)
    RETURNING id INTO v_table_id;

    -- Create series
    INSERT INTO platform.series (table_id, name_long, code)
    VALUES (v_table_id, 'Test Series', 'TS01')
    RETURNING id INTO v_series_id;

    -- Test 1: Basic insert
    RAISE NOTICE 'Testing basic insert...';
    SELECT * FROM platform.insert_new_vintage(
        v_series_id,
        '2024-01-01 10:00:00'
    ) INTO v_result;

    ASSERT v_result = 1, 'First insert should return 1';

    -- Verify the insert
    ASSERT EXISTS (
        SELECT 1 FROM platform.vintage
        WHERE series_id = v_series_id
        AND published = '2024-01-01 10:00:00'
    ), 'Vintage should exist after insert';
    RAISE NOTICE 'Basic insert test passed';

    -- Test 2: Duplicate timestamp for same series
    RAISE NOTICE 'Testing duplicate timestamp...';
    SELECT * FROM platform.insert_new_vintage(
        v_series_id,
        '2024-01-01 10:00:00'  -- same timestamp
    ) INTO v_result;

    ASSERT v_result = 0, 'Duplicate timestamp should return 0';
    RAISE NOTICE 'Duplicate timestamp test passed';

    -- Test 3: Different timestamp for same series
    RAISE NOTICE 'Testing different timestamp...';
    SELECT * FROM platform.insert_new_vintage(
        v_series_id,
        '2024-01-01 11:00:00'  -- different timestamp
    ) INTO v_result;

    ASSERT v_result = 1, 'Different timestamp should return 1';
    RAISE NOTICE 'Different timestamp test passed';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;

ROLLBACK;



-- ============================================================================
-- Tests for insert_prepared_data_points
-- ============================================================================
BEGIN;
DO $$
DECLARE
    v_table_id integer;
    v_dimension_id1 integer;
    v_dimension_id2 integer;
    v_unit_id integer;
    v_series_id integer;
    v_vintage_id integer;
    v_count_result RECORD;
BEGIN
    RAISE NOTICE 'Starting insert_prepared_data_points tests...';

    -- Create test prerequisites
    INSERT INTO platform.table (code, name, source_id, url)
    VALUES ('TEST_TABLE', 'Test Table', 1, 'http://test.com')
    RETURNING id INTO v_table_id;

    INSERT INTO platform.unit (name)
    VALUES ('test_unit')
    RETURNING id INTO v_unit_id;

    -- Create dimensions - use separate inserts to get both IDs
    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'region', false)
    RETURNING id INTO v_dimension_id1;

    INSERT INTO platform.table_dimensions (table_id, dimension, is_time)
    VALUES (v_table_id, 'sector', false)
    RETURNING id INTO v_dimension_id2;

    -- Create dimension levels
    INSERT INTO platform.dimension_levels (tab_dim_id, level_value, level_text)
    VALUES
        (v_dimension_id1, 'SI', 'Slovenia'),
        (v_dimension_id2, 'S1', 'Total Economy');

    -- Create series
    INSERT INTO platform.series (table_id, name_long, code, unit_id, interval_id)
    VALUES (v_table_id, 'Test Series', 'TEST_SERIES', v_unit_id, 'A')
    RETURNING id INTO v_series_id;

    -- Create series levels
    INSERT INTO platform.series_levels (series_id, tab_dim_id, level_value)
    VALUES
        (v_series_id, v_dimension_id1, 'SI'),
        (v_series_id, v_dimension_id2, 'S1');

    -- Create vintage
    INSERT INTO platform.vintage (series_id, published)
    VALUES (v_series_id, CURRENT_TIMESTAMP)
    RETURNING id INTO v_vintage_id;

     -- Create temp table for testing
    CREATE TEMP TABLE tmp_prepared_data (
        series_id integer,
        time character varying,
        value numeric,
        flag character varying,
        region character varying,
        sector character varying,
        interval_id character varying
    );

    -- Insert test data
    INSERT INTO tmp_prepared_data (series_id, time, value, flag, region, sector, interval_id)
    VALUES
        (v_series_id, '2023', 100.5, 'T', 'SI', 'S1', 'A'),
        (v_series_id, '2022', 95.2, '', 'SI', 'S1', 'A');

    -- Test function execution
    SELECT * FROM platform.insert_prepared_data_points(
        v_table_id,
        ARRAY[v_dimension_id1, v_dimension_id2],
        'A'
    ) INTO v_count_result;

    -- Verify results
    ASSERT v_count_result.periods_inserted IN (0, 2),
        format('Expected 0 or 2 periods inserted, got %s', v_count_result.periods_inserted);

    ASSERT v_count_result.datapoints_inserted IN (0, 2),
        format('Expected 0 or 2 datapoints inserted, got %s', v_count_result.datapoints_inserted);

    ASSERT v_count_result.flags_inserted IN (0, 1),
        format('Expected 0 or 1 flags inserted, got %s', v_count_result.flags_inserted);

    -- Check data was actually inserted
    ASSERT EXISTS (
        SELECT 1
        FROM platform.data_points
        WHERE vintage_id = v_vintage_id AND period_id = '2023'
    ), 'Data point for 2023 should exist';

    -- Check flag was inserted
    ASSERT EXISTS (
        SELECT 1
        FROM platform.flag_datapoint
        WHERE vintage_id = v_vintage_id AND period_id = '2023' AND flag_id = 'T'
    ), 'Flag for 2023 should exist';

    RAISE NOTICE 'All tests passed successfully';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Test failed: %', SQLERRM;
    RAISE;
END $$;
ROLLBACK;
