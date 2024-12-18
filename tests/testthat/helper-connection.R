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
