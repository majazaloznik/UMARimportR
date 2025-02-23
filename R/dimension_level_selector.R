#' Select or deselect dimension levels interactively
#'
#' @description
#' Interactively select or deselect dimension levels from a dimensional data frame
#' while ensuring at least one level per dimension remains selected.
#'
#' @param df A data frame containing dimensional data with columns:
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
dimension_selector <- function(df, mode = "select", page_size = 20) {
  # Input validation
  stopifnot(
    purrr::every(c("tab_dim_id", "dimension", "level_value", "level_text"), ~.x %in% names(df)),
    mode %in% c("select", "deselect")
  )

  # Get unique dimensions
  unique_dims <- unique(df$tab_dim_id)

  # Store selected level values by dimension
  selected <- list()

  # Process each dimension
  for (i in seq_along(unique_dims)) {
    dim_id <- unique_dims[i]
    # Get dimension info - use == explicitly for scalar comparison
    # FIX: Use !! to force evaluation of dim_id as a scalar in dplyr
    dim_data <- dplyr::filter(df, tab_dim_id == !!dim_id)

    dim_name <- dim_data$dimension[1]
    level_count <- nrow(dim_data)

    cat(sprintf("\nDimension: %s (%d levels)\n", dim_name, level_count))

    if (level_count > page_size) {
      # Pagination for large dimensions
      selected_values <- paginated_selector(dim_data, dim_name, mode, page_size)
      selected[[as.character(dim_id)]] <- selected_values
    } else {
      # Display all options at once for smaller dimensions
      for (j in seq_len(nrow(dim_data))) {
        cat(sprintf("%d: %s (%s)\n", j, dim_data$level_text[j], dim_data$level_value[j]))
      }

      valid_input <- FALSE
      while (!valid_input) {
        prompt_text <- if (mode == "select") "Enter numbers to keep" else "Enter numbers to remove"
        cat(paste0(prompt_text, " (comma-separated, or 'all' to keep everything):\n"))

        input <- readline(prompt = "Enter selection: ")

        # Handle "all" selection
        if (tolower(input) == "all") {
          selected[[as.character(dim_id)]] <- dim_data$level_value
          valid_input <- TRUE
          next
        }

        # Parse and validate input indices
        input_parts <- trimws(strsplit(input, ",")[[1]])
        indices <- suppressWarnings(as.numeric(input_parts))

        if (!all(!is.na(indices)) || !all(indices %in% seq_len(nrow(dim_data)))) {
          cat("Invalid selection. Please try again.\n")
          next
        }

        # Apply selection based on mode
        if (mode == "select") {
          # In select mode: check if at least one level is selected
          if (length(indices) == 0) {
            cat("You must select at least one level. Please try again.\n")
            next
          }
          selected[[as.character(dim_id)]] <- dim_data$level_value[indices]
        } else {
          # In deselect mode: check if we'd be removing all levels
          if (length(indices) == nrow(dim_data)) {
            cat("Cannot remove all levels. Please try again.\n")
            next
          }
          selected[[as.character(dim_id)]] <- dim_data$level_value[-indices]
        }

        valid_input <- TRUE
      }
    }
  }

  # Return the rows matching the selection criteria
  # Pre-allocate the result with the correct structure
  all_selected_rows <- vector("list", length(unique_dims))

  for (i in seq_along(unique_dims)) {
    dim_id <- unique_dims[i]
    dim_id_char <- as.character(dim_id)

    # Convert to character to avoid factor level issues
    level_values <- as.character(selected[[dim_id_char]])

    # FIX: Use !! to force evaluation of dim_id as a scalar
    dim_rows <- dplyr::filter(df, tab_dim_id == !!dim_id, level_value %in% level_values)
    all_selected_rows[[i]] <- dim_rows
  }

  # Combine the results efficiently
  result <- dplyr::bind_rows(all_selected_rows)

  return(result)
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
# Helper function for paginated selection
paginated_selector <- function(dim_data, dim_name, mode, page_size) {
  n_levels <- nrow(dim_data)
  n_pages <- ceiling(n_levels / page_size)

  # Initialize selection based on mode
  if (mode == "select") {
    # Start with nothing selected in select mode
    selected_indices <- c()
  } else {
    # Start with everything selected in deselect mode
    selected_indices <- 1:n_levels
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

      # Handle empty input
      if (trimws(input) == "") {
        cat("No indices entered. Please try again.\n")
        next
      }

      # Parse ranges and individual values
      parts <- strsplit(input, ",")[[1]]
      indices <- c()

      for (part in parts) {
        part <- trimws(part)
        if (grepl("-", part)) {
          # Range
          range_parts <- suppressWarnings(as.numeric(strsplit(part, "-")[[1]]))
          if (length(range_parts) == 2 && !any(is.na(range_parts))) {
            range_indices <- range_parts[1]:range_parts[2]
            indices <- c(indices, range_indices)
          }
        } else {
          # Single value
          idx <- suppressWarnings(as.numeric(part))
          if (!is.na(idx)) {
            indices <- c(indices, idx)
          }
        }
      }

      # Filter valid indices
      valid_indices <- indices[indices >= 1 & indices <= n_levels]
      valid_indices <- unique(valid_indices)  # Remove duplicates

      if (length(valid_indices) > 0) {
        # Handle selection based on mode and user choice
        if ((mode == "select" && user_choice == "s") ||
            (mode == "deselect" && user_choice == "d")) {
          # Add to selection
          selected_indices <- unique(c(selected_indices, valid_indices))
        } else {
          # Remove from selection
          new_selected <- setdiff(selected_indices, valid_indices)

          # In select mode, we need to ensure at least one item remains selected
          # when we're finishing the selection
          if (length(new_selected) > 0 || mode == "deselect") {
            selected_indices <- new_selected
          } else {
            cat("Cannot deselect all items. At least one must remain selected.\n")
          }
        }
      } else {
        cat("No valid indices entered. Please try again.\n")
      }
    } else if (user_choice == "a") {
      # Select all
      selected_indices <- 1:n_levels
      cat("Selected all entries.\n")
    } else if (user_choice == "c") {
      if (mode == "select") {
        cat("Cannot clear all selections in select mode. At least one must remain selected.\n")
      } else {
        # Clear all selections
        selected_indices <- c()
        cat("Cleared all selections.\n")
      }
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
      # Finish selection - check if we have a valid selection before leaving
      if (mode == "select" && length(selected_indices) == 0) {
        cat("At least one level must be selected. Please make a selection.\n")
      } else if (mode == "deselect" && length(selected_indices) == n_levels) {
        cat("You must deselect at least one level. Please make a selection.\n")
      } else {
        break
      }
    } else {
      cat("Invalid choice. Please try again.\n")
    }
  }

  # Return the selected values based on mode
  if (mode == "select") {
    # In select mode, return only the selected values
    if (length(selected_indices) == 0) {
      # Safety check - this should never happen due to validation above
      return(dim_data$level_value[1])  # Return at least the first value
    }
    return(dim_data$level_value[selected_indices])
  } else {
    # In deselect mode, return everything EXCEPT the selected indices
    remaining_indices <- setdiff(1:n_levels, selected_indices)
    if (length(remaining_indices) == 0) {
      # Safety check - this should never happen due to validation above
      return(dim_data$level_value[1])  # Return at least the first value
    }
    return(dim_data$level_value[remaining_indices])
  }
}
