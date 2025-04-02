test_that("calculate_vintage_hashes works", {
  with_mock_db({
    con <- make_test_connection()
    result <- calculate_vintage_hashes(361, con, "test_platform")
    expect_s3_class(result, "data.frame")
    expect_equal(names(result), c("vintage_id", "full_hash", "partial_hash"))
    expect_type(result$vintage_id, "integer")
    expect_type(result$full_hash, "character")
    expect_type(result$partial_hash, "character")
    expect_equal(result$full_hash[1],"049bde8ec1266ab9864bdbf895379443")
    dbDisconnect(con)
  })
})


test_that("add_missing_vintage_hashes produces expected output", {
  with_mock_db({
    con <- make_test_connection()

    # Capture all printed output
    output <- capture.output({
      x <- add_missing_vintage_hashes(con, "test_platform")
    })

    # Check for expected output
    expect_match(output[1], "Removed 1 empty vintages.", fixed = TRUE)
    expect_match(output[2], "Processed (\\d+)/(\\d+) vintages", perl = TRUE)
    expect_match(output[3], "All vintage hashes updated successfully", fixed = TRUE)
    print(x)
    expect_true(x == 1)
  })
})

test_that("vintage cleanup works", {
  with_mock_db({
    con <- make_test_connection()
    result <- list(
      no_keep_vintages_deleted = 0,
      redundant_vintages_deleted = 0,
      errors = list())
      result <- UMARimportR:::process_no_keep_vintage_table(con, "test_platform", 14, result)
    expect_true(result$no_keep_vintages_deleted == 24)
    result <- list(
      no_keep_vintages_deleted = 0,
      redundant_vintages_deleted = 0,
      errors = list())
    result <- UMARimportR:::process_keep_vintage_table(con, "test_platform", 15, result)
    expect_true(result$no_keep_vintages_deleted == 0)
  })
})
