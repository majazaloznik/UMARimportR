#' Construct and execute an SQL function call
#'
#' Constructs the call for the funciton `schema`.`fun_name` from the database
#' with the arguments `args` and returns the result. Because of the way
#' the parameters get apssed the hash of the query remains the same which is
#' a bitch for testing with mock fixtures using dittodb. So we added a comment
#' to the query, just to ensure the hash is different.
#'
#' Inspiration from `timeseriesdb` package by Matt Bannert.
#'
#' @param fun_name character name of SQL function to call
#' @param args list of arguments, can be named (but then all of them have to be)
#'
#' @inheritParams common_parameters
#' @export
#'
#' @return value of `dbGetQuery(con, "SELECT * FROM schema.fun_name($args)")$fun_name`
#' @importFrom RPostgres Postgres
sql_function_call <- function(con, fun_name, args, schema = "platform") {
  args_pattern <- ""
  if(!is.null(args)) {
    args[sapply(args, is.null)] <- NA
    args_pattern <- sprintf("$%d", seq(length(args)))

    if(!is.null(names(args))) {
      args_pattern <- paste(
        sprintf("%s :=", names(args)),
        args_pattern
      )
    }
    args_pattern <- paste(args_pattern, collapse = ", ")
  }

  # Add comment with args for unique hashing
  param_values <- sapply(args, function(x) {
    if (inherits(x, "integer64")) return(as.numeric(x))
    if (inherits(x, "POSIXct")) return(format(x))
    x
  })

  param_comment <- sprintf(
    "/* Params: %s */",
    paste(names(args), param_values, collapse = ",")
  )

  # Fixed the order of arguments in dbQuoteIdentifier
  schema_quoted <- DBI::dbQuoteIdentifier(con, schema)
  fun_name_quoted <- DBI::dbQuoteIdentifier(con, fun_name)

  query <- sprintf("%s SELECT * FROM %s.%s(%s)",
                   param_comment,
                   schema_quoted,
                   fun_name_quoted,
                   args_pattern)

  res <- DBI::dbGetQuery(con, query, unname(args))
  res
}

#'
#'
#' #' Generic run sql file
#' #'
#' #' Executes an sql file. Uses dbExecute, which requires single statements to
#' #' be passed i.e. cannot handle a whole file, so the function splits the file
#' #' on `;`. Potentially not safe.
#' #' If file has stored procedures, use \link[SURSfetchR]{execute_sql_functions_file}
#' #' instead.
#' #'
#' #' Inspiration from `timeseriesdb` package by Matt Bannert.
#' #'
#' #' @param file path to sql file
#' #' @inheritParams common_parameters
#' #'
#' #' @export
#' execute_sql_file <- function(con, file,
#'                              schema = "platform"){
#'   sql <- readLines(file)
#'   sql <- gsub("platform\\.", sprintf("%s.", schema), sql)
#'   DBI::dbBegin(con)
#'   on.exit(  DBI::dbCommit(con))
#'   # split up SQL into a new statement for every ";"
#'   lapply(split(sql, cumsum(c(1,grepl(";",sql)[-length(sql)]))),
#'          function(x){
#'            DBI::dbExecute(con, paste(x, collapse = "\n"))
#'          })
#' }
#'
#' #' Generic run sql file function
#' #'
#' #' Executes an sql file. Uses dbExecute, which requires single statements to
#' #' be passed i.e. cannot handle a whole file, so the function splits the file
#' #' on `;`. Potentially not safe.
#' #' Inspiration from `timeseriesdb` package by Matt Bannert.
#' #'
#' #' @param file path to sql file
#' #' @inheritParams common_parameters
#' #'
#' #' @export
#' execute_sql_functions_file <- function(con, file,
#'                                        schema = "platform"){
#'   sql <- readLines(file)
#'   sql <- gsub("platform\\.", sprintf("%s.", schema), sql)
#'
#'   DBI::dbBegin(con)
#'   on.exit(DBI::dbCommit(con))
#'   # split up SQL into a new statement for every "plpgsql", which is at the end
#'   # of each function.
#'   lapply(split(sql, cumsum(c(1,grepl("plpgsql;",sql)[-length(sql)]))),
#'          function(x){
#'            DBI::dbExecute(con, paste(x, collapse = "\n"))
#'          })
#' }
#'
#'
#' #' Build all database tables
#' #'
#' #' Creates all the tables required to run the database in a given schema by
#' #' running the appropriate sql file. (Excluded from testing). Location of
#' #' sql file is in compiled package, hence no "inst/"
#' #'
#' #' @inheritParams common_parameters
#' #' @export
#' build_db_tables <- function(con, schema = "platform"){
#'   execute_sql_file(con,
#'                    file =system.file("sql/build_db.sql",
#'                                      package = "SURSfetchR"),
#'                    schema = schema)
#' }
#'

#
# execute_sql_file <- function(con, file, schema = "platform") {
#   # 1. Add input validation
#   if (!file.exists(file)) stop("SQL file does not exist")
#   if (!inherits(con, "DBIConnection")) stop("Invalid connection object")
#
#   # 2. Separate SQL processing into its own function
#   sql <- process_sql_file(file, schema)
#
#   # 3. Use tryCatch for better error handling
#   tryCatch({
#     DBI::dbBegin(con)
#     lapply(sql, function(stmt) {
#       if (nchar(trimws(stmt)) > 0) {  # Skip empty statements
#         DBI::dbExecute(con, stmt)
#       }
#     })
#     DBI::dbCommit(con)
#   }, error = function(e) {
#     DBI::dbRollback(con)
#     stop("SQL execution failed: ", e$message)
#   })
# }
#
# process_sql_file <- function(file, schema) {
#   sql <- readLines(file, warn = FALSE)
#   sql <- gsub("platform\\.", sprintf("%s.", schema), sql)
#
#   # More robust statement splitting
#   statements <- split_sql_statements(sql)
#   statements
# }
#
# split_sql_statements <- function(sql) {
#   # Handle multi-line statements and comments better
#   sql <- paste(sql, collapse = "\n")
#   sql <- gsub("--.*\n", "\n", sql)  # Remove single-line comments
#   sql <- gsub("/\\*.*?\\*/", "", sql, perl = TRUE)  # Remove multi-line comments
#
#   statements <- strsplit(sql, ";")[[1]]
#   statements <- trimws(statements)
#   statements[nchar(statements) > 0]
# }
#
# execute_sql_functions_file <- function(con, file, schema = "platform") {
#   if (!file.exists(file)) stop("SQL file does not exist")
#   if (!inherits(con, "DBIConnection")) stop("Invalid connection object")
#
#   sql <- readLines(file, warn = FALSE)
#   sql <- gsub("platform\\.", sprintf("%s.", schema), sql)
#
#   # More robust function splitting
#   functions <- split_sql_functions(sql)
#
#   tryCatch({
#     DBI::dbBegin(con)
#     lapply(functions, function(func) {
#       if (nchar(trimws(func)) > 0) {
#         DBI::dbExecute(con, func)
#       }
#     })
#     DBI::dbCommit(con)
#   }, error = function(e) {
#     DBI::dbRollback(con)
#     stop("Function creation failed: ", e$message)
#   })
# }
#
# split_sql_functions <- function(sql) {
#   # Handle both LANGUAGE plpgsql and other PostgreSQL function definitions
#   sql <- paste(sql, collapse = "\n")
#   # More sophisticated function boundary detection
#   functions <- strsplit(sql, "(?<=LANGUAGE [a-zA-Z]+ *;)", perl = TRUE)[[1]]
#   functions <- trimws(functions)
#   functions[nchar(functions) > 0]
# }
#
# build_db_tables <- function(con, schema = "platform") {
#   sql_file <- system.file("sql/build_db.sql", package = "SURSfetchR")
#   if (sql_file == "") {
#     stop("Could not find build_db.sql in package")
#   }
#
#   # Check if schema exists
#   schema_exists <- DBI::dbGetQuery(
#     con,
#     "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = $1)",
#     list(schema)
#   )
#
#   if (!schema_exists[[1]]) {
#     DBI::dbExecute(con, sprintf('CREATE SCHEMA "%s"', schema))
#   }
#
#   execute_sql_file(con, sql_file, schema = schema)
# }
