library(testthat)
library(dittodb)

make_test_connection <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 dbname = "platform",
                 host = "localhost",
                 port = 5433,
                 user = "postgres",
                 password = Sys.getenv("PG_local_15_PG_PSW"))
}

#
# start_db_capturing()
# con <- make_test_connection()
# DBI::dbExecute(con, "set search_path to test_schema")
#
# # Test basic function
# result1 <- sql_function_call(con, "get_count", NULL, "test_schema")
#
# # Test with parameters
# result2 <- sql_function_call(
#   con,
#   "filter_data",
#   list(min_value = 10, category_param = "test"),
#   "test_schema"
# )
#
# # Test NULL handling
# result3 <- sql_function_call(
#   con,
#   "handle_nulls",
#   list(param1 = NULL, param2 = 1),
#   "test_schema"
# )
#
# sql_function_call(con, "filter_data", list(10, "test"), "test_schema")
# stop_db_capturing()
