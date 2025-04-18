% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db_writing.R
\name{insert_new_table_dimensions}
\alias{insert_new_table_dimensions}
\title{Insert a new dimension for a table}
\usage{
insert_new_table_dimensions(con, df, schema = "platform")
}
\arguments{
\item{con}{Database connection object}

\item{df}{A data frame with one row containing the following columns:
* table_id (integer): ID of the table this dimension belongs to
* dimension (character): name of the dimension
* is_time (logical): whether this is a time dimension}

\item{schema}{Character string specifying the database schema. Defaults to "platform"}
}
\value{
A data frame with one column 'count' indicating number of rows inserted
        (1 for success, 0 if dimension already exists for this table)
}
\description{
Inserts a new dimension into the table_dimensions table. If the dimension
already exists for this table, the function will not insert a duplicate
and will return 0.
}
\examples{
\dontrun{
df <- data.frame(
  table_id = 1,
  dimension = "time",
  is_time = TRUE
)
insert_new_table_dimensions(con, df)
}

}
