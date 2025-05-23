% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vintage_cleanup.R
\name{add_missing_vintage_hashes}
\alias{add_missing_vintage_hashes}
\title{Add vintage hashes to vintage table}
\usage{
add_missing_vintage_hashes(con, schema = "platform")
}
\arguments{
\item{con}{connection to database}

\item{schema}{schema name, defaults to "platform"}
}
\value{
number of updated vintages
}
\description{
Queries all the (newly added) vintages which don't have hashes yet
and calculates their hashes. Before doing that it actually deletes
any vintages in the database that don't have any datapoints, cuz
they shouldn't be there in the first plase. but might sometimes
occur if the datapoint import was somehow corrupted and only the vintages
got inserted.
}
