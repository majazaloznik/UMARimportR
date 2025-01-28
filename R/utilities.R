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

sql_function_call <- function(con,
                              fun_name,
                              args,
                              schema = "platform") {
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
  param_comment <- paste(
    sprintf("/* Params: %s */",
            paste(names(args), unname(sapply(args, as.character)),
                  collapse = ",")),
    collapse = ""
  )

  query <- sprintf("%s SELECT * FROM %s.%s(%s)",
                   param_comment,
                   DBI::dbQuoteIdentifier(con, schema),
                   DBI::dbQuoteIdentifier(con, fun_name),
                   args_pattern)

  res <- DBI::dbGetQuery(con, query, unname(args))

  res
}
