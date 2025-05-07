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

#' Set locale for data operations
#'
#' @param locale Character string specifying locale to use
#' @param category Locale category to set (default: LC_CTYPE)
#' @return returns a function to restore the previous locale
#' @export
set_data_locale <- function(locale = "UTF-8", category = "LC_CTYPE") {
  old_locale <- Sys.getlocale(category)

  # Handle UTF-8 special case
  if (locale == "UTF-8") {
    # Try platform-specific UTF-8 locale variants
    locales <- if (.Platform$OS.type == "windows") {
      c("English_United States.UTF-8", "English_United Kingdom.UTF-8")
    } else {
      c("en_US.UTF-8", "C.UTF-8")
    }

    # Try each locale until one works
    for (loc in locales) {
      if (tryCatch({Sys.setlocale(category, loc); TRUE}, error = function(e) FALSE)) {
        break
      }
    }
  } else {
    # Set specific locale
    Sys.setlocale(category, locale)
  }

  # Return function to restore original locale
  function() Sys.setlocale(category, old_locale)
}
