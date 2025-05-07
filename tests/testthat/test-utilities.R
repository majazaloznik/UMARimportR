
test_that("sql_function_call constructs queries correctly", {
  with_mock_db({
    con <- make_test_connection()
    DBI::dbExecute(con, "set search_path to test_schema")

    # Test basic function call without args
    result <- sql_function_call(con, "get_count", NULL, "test_schema")
    expect_true(is.data.frame(result))
    expect_equal(as.numeric(result$count), 42)

    # Test with parameters
    result <- sql_function_call(
      con,
      "filter_data",
      list(min_value = 10, category_param = "test"),
      "test_schema"
    )
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 2)
    expect_equal(result$category[1], "test")

    # Test NULL handling
    result <- sql_function_call(
      con,
      "handle_nulls",
      list(param1 = NULL, param2 = 1),
      "test_schema"
    )
    expect_equal(result$result[1], "param1 is null")

    dbDisconnect(con)
  })
})

test_that("sql_function_call validates inputs correctly", {
  with_mock_db({
    con <- make_test_connection()

    # Test invalid function name
    expect_error(
      sql_function_call(con, NULL, NULL),
      "x must be character or SQL"  # This is the actual error from DBI::dbQuoteIdentifier
    )

    # Test all unnamed arguments (should work)
    result <- sql_function_call(con, "filter_data", list(10, "test"),
                                "test_schema")
    expect_s3_class(result, "data.frame")

    # Test all named arguments (should work)
    result <- sql_function_call(con, "filter_data",
                                list(min_value = 10, category_param = "test"),
                                "test_schema")
    expect_s3_class(result, "data.frame")

    dbDisconnect(con)
  })
})



# tests/testthat/test-set_data_locale.R

test_that("set_data_locale changes locale and returns function to restore it", {
  # Save original locale
  original_locale <- Sys.getlocale("LC_CTYPE")

  # Set to UTF-8
  restore_fn <- UMARimportR::set_data_locale("UTF-8")

  # Check that locale changed - more flexible test
  current_locale <- Sys.getlocale("LC_CTYPE")
  expect_false(current_locale == original_locale,
               "Locale should change from original")

  # Restore original
  restore_fn()

  # Verify restoration
  expect_equal(Sys.getlocale("LC_CTYPE"), original_locale)
})

test_that("set_data_locale handles different locale categories", {
  # Test with LC_TIME
  original_time <- Sys.getlocale("LC_TIME")
  original_ctype <- Sys.getlocale("LC_CTYPE")

  restore_time <- UMARimportR::set_data_locale("C", "LC_TIME")

  # Check LC_TIME changed but LC_CTYPE didn't
  expect_equal(Sys.getlocale("LC_TIME"), "C")
  expect_equal(Sys.getlocale("LC_CTYPE"), original_ctype)

  # Restore
  restore_time()
  expect_equal(Sys.getlocale("LC_TIME"), original_time)
})

test_that("set_data_locale handles invalid locales", {
  # Try with invalid locale - should not error but may return a warning
  expect_error(UMARimportR::set_data_locale("NONEXISTENT_LOCALE"), NA)
  # This just tests that no error is thrown
})
