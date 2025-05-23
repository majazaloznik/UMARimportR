test_that("insert_new_table_table works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      code = "TEST01",
      name = "Test Table",
      source_id = 1L,
      url = "http://example.com",
      notes = jsonlite::toJSON(list(note = "test note")),
      keep_vintage = TRUE,
      stringsAsFactors = FALSE
    )

    result <- insert_new_table_table(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_table_dimensions works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      table_id = 174L,
      dimension = "time",
      is_time = TRUE
    )

    result <- insert_new_table_dimensions(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_dimension_levels works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      tab_dim_id = 267L,
      level_value = "SI",
      level_text = "Slovenia",
      stringsAsFactors = FALSE
    )

    result <- insert_new_dimension_levels(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_unit works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      name = "meters",
      stringsAsFactors = FALSE
    )

    result <- insert_new_unit(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})


test_that("insert_new_series works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      table_id = 174L,
      name_long = "Monthly GDP",
      unit_id = 1L,
      code = "GDP_M",
      interval_id = "M",
      stringsAsFactors = FALSE
    )

    result <- insert_new_series(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_series_levels works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      series_id = 42785L,
      tab_dim_id = 267L,
      level_value = "SI",
      stringsAsFactors = FALSE
    )

    result <- insert_new_series_levels(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})


test_that("insert_new_source works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      id = 5L,
      name = "SURSi",
      name_long = "Statistical Office",
      url = "http://www.stat.si",
      stringsAsFactors = FALSE
    )

    result <- insert_new_source(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_category works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      id = 999L,
      name = "Economic Statistics",
      source_id = 1L,
      stringsAsFactors = FALSE
    )

    result <- insert_new_category(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_category_relationship works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      id = 999L,
      parent_id = 57L,
      source_id = 1L,
      stringsAsFactors = FALSE
    )

    result <- insert_new_category_relationship(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_category_table works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      category_id = 1L,
      table_id = 191L,
      source_id = 5L,
      stringsAsFactors = FALSE
    )

    result <- insert_new_category_table(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_new_vintage works correctly", {
  with_mock_db({
    con <- make_test_connection()

    df <- data.frame(
      series_id = 1918L,
      published = as.POSIXct("2024-01-01 10:00:00"),
      stringsAsFactors = FALSE
    )

    result <- insert_new_vintage(con, df, schema = "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), "count")
    expect_type(result$count, "integer")
    expect_true(result$count %in% c(0,1))

    dbDisconnect(con)
  })
})

test_that("insert_prepared_data_points correctly inserts data", {
  with_mock_db({
    con <- make_test_connection()

    # Create minimal prep_data structure
    prep_data <- list(
      data = data.frame(
        time = c("2023", "2022"),
        value = c(100.5, 95.2),
        flag = c("T", ""),
        VRSTA.PODATKA = c("orig", "orig"),
        SKD.DEJAVNOST...NAMENSKA.SKUPINA = c("B+C+D[skd]", "B+C+D[skd]"),
        interval_id = c("A", "A"),
        stringsAsFactors = FALSE
      ),
      table_id = 123,
      time_dimension = "LETO",
      interval_id = "A",
      dimension_ids = c(9, 11),
      dimension_names = c("VRSTA PODATKA", "SKD DEJAVNOST / NAMENSKA SKUPINA")
    )

    # Use mockery to replace database execution functions
    mockery::stub(insert_prepared_data_points, "DBI::dbWriteTable", TRUE)
    mockery::stub(insert_prepared_data_points, "DBI::dbGetQuery", data.frame(count = 2))
    mockery::stub(insert_prepared_data_points, "DBI::dbExecute", 2)

    # Capture messages
    msgs <- capture_messages({
      result <- insert_prepared_data_points(prep_data, con)
    })

    # Check result structure
    expect_equal(result$periods_inserted, 2)
    expect_equal(result$datapoints_inserted, 2)
    expect_equal(result$flags_inserted, 2)

    # Check messages
    expect_true(any(grepl("Inserted 2 new periods", msgs)))
    expect_true(any(grepl("Inserted 2 new data points", msgs)))
    expect_true(any(grepl("Inserted 2 new flags", msgs)))

    dbDisconnect(con)
  })
})
