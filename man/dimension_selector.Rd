% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dimension_level_selector.R
\name{dimension_selector}
\alias{dimension_selector}
\title{Select or deselect dimension levels interactively}
\usage{
dimension_selector(df, mode = "select", page_size = 20)
}
\arguments{
\item{df}{A data frame containing dimensional data with columns:
\code{tab_dim_id}, \code{dimension}, \code{level_value}, and \code{level_text}}

\item{mode}{Character string indicating mode: either "select" (default) or "deselect"}

\item{page_size}{Integer specifying number of items to display per page for large dimensions}
}
\value{
A filtered data frame containing only the selected dimension levels
}
\description{
Interactively select or deselect dimension levels from a dimensional data frame
while ensuring at least one level per dimension remains selected.
}
\details{
The function handles two different selection interfaces:

1. For dimensions with 50 or fewer levels, all options are displayed at once
2. For dimensions with more than 50 levels, a paginated interface is used

In both cases, the function ensures that at least one level per dimension is selected.
The 'mode' parameter determines whether users select levels to keep ("select") or
levels to remove ("deselect").
}
\examples{
\dontrun{
# Sample data
df <- data.frame(
  tab_dim_id = rep(c("D1", "D2"), each = 4),
  dimension = rep(c("Gender", "Age Group"), each = 4),
  level_value = c("M", "F", "O", "U", "0-14", "15-64", "65+", "Unknown"),
  level_text = c("Male", "Female", "Other", "Unspecified",
                "Children", "Working Age", "Elderly", "Not Stated")
)

# Select mode (choose levels to keep)
result <- dimension_selector(df, mode = "select")

# Deselect mode (choose levels to remove)
result <- dimension_selector(df, mode = "deselect")
}

}
