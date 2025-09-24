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

  # Normalize encoding for consistent hashing across platforms
  normalize_for_comment <- function(x) {
    if (is.character(x)) {
      # Convert to ASCII for consistent hashing (not for database storage)
      x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "?")
    } else if (inherits(x, "integer64")) {
      as.numeric(x)
    } else if (inherits(x, "POSIXct")) {
      format(x, "%Y-%m-%d %H:%M:%S", tz = "UTC")
    } else {
      x
    }
  }
  # Add comment with args for unique hashing
  param_values <- sapply(args, normalize_for_comment)

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

#' Ensure proper UTF-8 encoding for dataframe column names
#'
#' @param df A dataframe to fix column names encoding
#' @return A dataframe with valid UTF-8 column names
#'
ensure_colnames_utf8 <- function(df) {
  # Check if column names are already UTF-8 encoded
  are_utf8 <- !is.na(iconv(names(df), from = "UTF-8", to = "UTF-8"))

  # Only convert names that aren't already UTF-8
  if (!all(are_utf8)) {
    for (i in which(!are_utf8)) {
      for (enc in c("CP1250", "latin2", "windows-1250", "CP852")) {
        converted <- iconv(names(df)[i], from = enc, to = "UTF-8", sub = "")
        if (!is.na(converted)) {
          names(df)[i] <- converted
          break
        }
      }
    }
  }
  return(df)
}

