test_that("delete_vintage returns correct structure", {
  with_mock_db({
    con <- make_test_connection()

    result <- delete_vintage(con, 6397, schema = "test_platform")

    expect_s3_class(result, "data.frame")
    expect_equal(names(result), c("vintage_count", "data_points_count", "flag_count"))
    expect_type(result$vintage_count, "integer")
    expect_type(result$data_points_count, "integer")
    expect_type(result$flag_count, "integer")
    expect_true(all(result >= 0))

    dbDisconnect(con)
  })
})

test_that("delete_series returns correct structure", {
  with_mock_db({
    con <- make_test_connection()

    result <- delete_series(con, 5803, schema = "test_platform")

    expect_s3_class(result, "data.frame")
    expect_equal(names(result),
                 c("series_count", "vintage_count", "data_points_count",
                   "flag_count", "series_levels_count"))
    expect_type(result$series_count, "integer")
    expect_type(result$vintage_count, "integer")
    expect_type(result$data_points_count, "integer")
    expect_type(result$flag_count, "integer")
    expect_type(result$series_levels_count, "integer")
    expect_true(all(result >= 0))

    dbDisconnect(con)
  })
})

test_that("delete_table returns correct structure", {
  with_mock_db({
    con <- make_test_connection()

    result <- delete_table(con, 249, schema = "test_platform")

    expect_s3_class(result, "data.frame")
    expect_equal(names(result),
                 c("table_count", "series_count", "vintage_count",
                   "data_points_count", "flag_count", "dimension_count",
                   "dimension_levels_count", "series_levels_count",
                   "category_table_count"))
    expect_type(result$table_count, "integer")
    expect_type(result$series_count, "integer")
    expect_type(result$vintage_count, "integer")
    expect_type(result$data_points_count, "integer")
    expect_type(result$flag_count, "integer")
    expect_type(result$dimension_count, "integer")
    expect_type(result$dimension_levels_count, "integer")
    expect_type(result$series_levels_count, "integer")
    expect_type(result$category_table_count, "integer")
    expect_true(all(result >= 0))

    dbDisconnect(con)
  })
})

test_that("delete_empty vintages works", {
  with_mock_db({
    con <- make_test_connection()
    result <- remove_empty_vintages(con, "test_platform")
    expect_equal(length(result), 1)
    dbDisconnect(con)
  })
})
