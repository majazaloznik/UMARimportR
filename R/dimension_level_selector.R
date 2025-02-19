#' Select or deselect dimension levels interactively
#'
#' @description
#' Interactively select or deselect dimension levels from a dimensional data frame
#' while ensuring at least one level per dimension remains selected.
#'
#' @param dim_data A data frame containing dimensional data with columns:
#'   \code{tab_dim_id}, \code{dimension}, \code{level_value}, and \code{level_text}
#' @param mode Character string indicating mode: either "select" (default) or "deselect"
#' @param page_size Integer specifying number of items to display per page for large dimensions
#'
#' @return A filtered data frame containing only the selected dimension levels
#'
#' @details
#' The function handles two different selection interfaces:
#'
#' 1. For dimensions with 50 or fewer levels, all options are displayed at once
#' 2. For dimensions with more than 50 levels, a paginated interface is used
#'
#' In both cases, the function ensures that at least one level per dimension is selected.
#' The 'mode' parameter determines whether users select levels to keep ("select") or
#' levels to remove ("deselect").
#'
#' @examples
#' \dontrun{
#' # Sample data
#' df <- data.frame(
#'   tab_dim_id = rep(c("D1", "D2"), each = 4),
#'   dimension = rep(c("Gender", "Age Group"), each = 4),
#'   level_value = c("M", "F", "O", "U", "0-14", "15-64", "65+", "Unknown"),
#'   level_text = c("Male", "Female", "Other", "Unspecified",
#'                 "Children", "Working Age", "Elderly", "Not Stated")
#' )
#'
#' # Select mode (choose levels to keep)
#' result <- dimension_selector(df, mode = "select")
#'
#' # Deselect mode (choose levels to remove)
#' result <- dimension_selector(df, mode = "deselect")
#' }
#'
#' @export
dimension_level_selector <- function(dim_data, mode = "select", page_size = 50) {
  stopifnot(mode %in% c("select", "deselect"))
  # Validate input data
    if (!all(c("tab_dim_id", "dimension", "level_value", "level_text") %in% names(dim_data))) {
    stop("Input data must contain tab_dim_id, dimension, level_value, and level_text columns")
  }
  # Display dimension and levels
  dimension_name <- unique(dim_data$dimension)[1]
  cat(sprintf("Dimension: %s (%d levels)\n", dimension_name, nrow(dim_data)))
  for (i in seq_len(nrow(dim_data))) {
    cat(sprintf("%d: %s (%s)\n", i, dim_data$level_text[i], dim_data$level_value[i]))
  }

  # Get user input
  input <- readline(sprintf("Enter numbers to keep (comma-separated, or 'all' to keep everything): "))

  # Handle "all" input - FIXED: return just level values
  if (input == "all") {
    return(dim_data$level_value)
  }

  # Process specific selections
  indices <- c()

  # Parse input for values and ranges
  parts <- strsplit(input, ",")[[1]]
  for (part in parts) {
    part <- trimws(part)
    if (grepl("-", part)) {
      # Range selection
      range_parts <- as.numeric(strsplit(part, "-")[[1]])
      if (length(range_parts) == 2 && !any(is.na(range_parts))) {
        range_indices <- range_parts[1]:range_parts[2]
        indices <- c(indices, range_indices)
      }
    } else {
      # Single value selection
      idx <- as.numeric(part)
      if (!is.na(idx)) {
        indices <- c(indices, idx)
      }
    }
  }

  # Validate indices
  if (!all(!is.na(indices)) || !all(indices %in% seq_len(nrow(dim_data)))) {
    valid_indices <- indices[!is.na(indices) & indices %in% seq_len(nrow(dim_data))]
    if (length(valid_indices) == 0) {
      # Return empty character vector for empty selections
      return(character(0))
    }
    indices <- valid_indices
  }

  if (nrow(dim_data) > 50) {
    # For large dimensions, use paginated selector
    return(paginated_selector(dim_data, dim_name, mode, 20))
  }

  # Return just the level_values for consistency
  return(dim_data$level_value[indices])
}
#' Interactive paginated selector for dimension levels
#'
#' @description
#' Helper function for dimension_selector that provides a paginated interface
#' for selecting or deselecting levels when a dimension has many levels.
#'
#' @param dim_data Data frame containing a single dimension's data
#' @param dim_name Character string with the dimension name to display
#' @param mode Character string indicating mode: either "select" or "deselect"
#' @param page_size Integer specifying number of items to display per page
#'
#' @return Character vector of selected level values
#'
#' @details
#' Provides an interactive console interface with pagination for dimensions
#' with many levels. Features include:
#' - Navigation between pages
#' - Selection/deselection of individual or ranges of levels
#' - Select all / Clear all options
#' - View current selections
#'
#' @keywords internal
#'
# Helper function for paginated selection
paginated_selector <- function(dim_data, dim_name, mode, page_size) {
  n_levels <- nrow(dim_data)
  n_pages <- ceiling(n_levels / page_size)
  # Initialize selection based on mode
  if (mode == "select") {
    selected_indices <- integer(0)  # Start with nothing selected
  } else if (mode == "deselect") {
    selected_indices <- seq_len(nrow(dim_data))  # Start with everything selected
  }
  current_page <- 1
  while (TRUE) {
    # Display page header
    cat(sprintf("\n=== %s - Page %d of %d ===\n", dim_name, current_page, n_pages))
    # Calculate page range
    start_idx <- (current_page - 1) * page_size + 1
    end_idx <- min(current_page * page_size, n_levels)
    # Display items for current page
    for (i in start_idx:end_idx) {
      is_selected <- i %in% selected_indices
      selection_mark <- if(is_selected) "[x]" else "[ ]"
      cat(sprintf("%s %d: %s (%s)\n",
                  selection_mark, i,
                  dim_data$level_text[i],
                  dim_data$level_value[i]))
    }
    # Display navigation options
    cat("\nNavigation options:\n")
    cat("  p: Previous page\n")
    cat("  n: Next page\n")
    cat("  g: Go to page\n")
    if (mode == "select") {
      cat("  s: Select entries\n")
      cat("  d: Deselect entries\n")
    } else {
      cat("  s: Deselect entries (to be removed)\n")
      cat("  d: Select entries (to keep)\n")
    }
    cat("  a: Select all\n")
    cat("  c: Clear all selections\n")
    cat("  v: View current selections\n")
    cat("  f: Finish selection\n")
    # Get user choice
    user_choice <- tolower(readline(prompt = "Enter choice: "))

    if (user_choice == "p") {
      # Previous page
      current_page <- max(1, current_page - 1)
    } else if (user_choice == "n") {
      # Next page
      current_page <- min(n_pages, current_page + 1)
    } else if (user_choice == "g") {
      # Go to specific page
      page_num <- as.numeric(readline(prompt = sprintf("Enter page number (1-%d): ", n_pages)))
      if (!is.na(page_num) && page_num >= 1 && page_num <= n_pages) {
        current_page <- page_num
      } else {
        cat("Invalid page number.\n")
      }
    } else if (user_choice == "s" || user_choice == "d") {
      # Parse input for selections
      input <- readline(prompt = "Enter indices (e.g., 1,3,5-8): ")
      # Parse ranges and individual values
      parts <- strsplit(input, ",")[[1]]
      indices <- c()
      for (part in parts) {
        if (grepl("-", part)) {
          # Range
          range_parts <- as.numeric(strsplit(part, "-")[[1]])
          if (length(range_parts) == 2 && !any(is.na(range_parts))) {
            range_indices <- range_parts[1]:range_parts[2]
            indices <- c(indices, range_indices)
          }
        } else {
          # Single value
          idx <- as.numeric(part)
          if (!is.na(idx)) {
            indices <- c(indices, idx)
          }
        }
      }
      # Filter valid indices
      valid_indices <- indices[indices >= 1 & indices <= n_levels]
      if (length(valid_indices) > 0) {
        if ((mode == "select" && user_choice == "s") ||
            (mode == "deselect" && user_choice == "d")) {
          # In select mode: s adds to selection
          # In deselect mode: d specifies what to keep (replacing selection)
          if (mode == "deselect" && user_choice == "d") {
            # In deselect mode, 'd' completely replaces the selection
            selected_indices <- valid_indices
          } else {
            # In select mode or when using 's' in deselect mode
            selected_indices <- unique(c(selected_indices, valid_indices))
          }
        } else {
          # Remove from selection
          selected_indices <- setdiff(selected_indices, valid_indices)
        }
      }
    } else if (user_choice == "a") {
      # Select all
      selected_indices <- 1:n_levels
      cat("Selected all entries.\n")
    } else if (user_choice == "c") {
      # Clear all selections
      selected_indices <- c()
      cat("Cleared all selections.\n")
    } else if (user_choice == "v") {
      # View current selections
      if (length(selected_indices) > 0) {
        cat(sprintf("\nCurrently selected (%d items):\n", length(selected_indices)))
        for (idx in sort(selected_indices)) {
          cat(sprintf("  %d: %s (%s)\n",
                      idx, dim_data$level_text[idx], dim_data$level_value[idx]))
        }
      } else {
        cat("\nNo items currently selected.\n")
      }
      readline(prompt = "Press Enter to continue...")
    } else if (user_choice == "f") {
      # Finish selection
      if (length(selected_indices) == 0 && mode == "select") {
        cat("At least one level must be selected. Please make a selection.\n")
      } else {
        break
      }
    } else {
      cat("Invalid choice. Please try again.\n")
    }
  }
  # Return the selected values for both modes
  return(dim_data$level_value[selected_indices])
}
