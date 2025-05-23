% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db_writing.R
\name{insert_new_category}
\alias{insert_new_category}
\title{Insert a new category}
\usage{
insert_new_category(con, df, schema = "platform")
}
\arguments{
\item{con}{Database connection object}

\item{df}{A data frame with one row containing the following columns:
* id (integer): Category identifier (unique within source_id)
* name (character): Category name (unique within source_id)
* source_id (integer): ID of the source this category belongs to}

\item{schema}{Character string specifying the database schema. Defaults to "platform"}
}
\value{
A data frame with one column 'count' indicating number of rows inserted
        (1 for success, 0 if category already exists for this source)
}
\description{
Inserts a new category into the category table. Categories are unique per source,
identified by both id and name.
}
\examples{
\dontrun{
df <- data.frame(
  id = 1,
  name = "Economic Statistics",
  source_id = 1
)
insert_new_category(con, df)
}

}
