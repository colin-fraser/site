create_blog_post <- function(title, 
                             categories = NULL, 
                             date = lubridate::today(tzone = "America/Vancouver"), 
                             author = "Colin Fraser", 
                             slug = NULL,
                             posts_dir = "posts",
                             open = TRUE,
                             prepend_date_to_slug = NULL,
                             tz = "America/Vancouver") {
  if (inherits(date, "Date")) {
    date <- format(date, "%Y-%m-%d")
  }
  
  if (is.null(prepend_date_to_slug)) {
    prepend_date_to_slug <- is.null(slug)
  }
  
  # If slug is NULL, generate the slug from the title
  if (is.null(slug)) {
    slug <- gsub("[^a-zA-Z0-9-]", "", gsub("\\s", "-", tolower(title)))
  }
  
  # Prepend the date to the slug if prepend_date_to_slug is TRUE
  if (prepend_date_to_slug) {
    slug <- paste0(date, "-", slug)
  }
  
  # Define the path to the directory and file
  dir_path <- file.path(posts_dir, slug)
  file_path <- file.path(dir_path, "index.qmd")
  
  # If a directory or file with the same name already exists, stop and print a message
  if (dir.exists(dir_path) || file.exists(file_path)) {
    stop("A blog post with this name already exists!")
  } else {
    # Create the directory
    dir.create(dir_path)
    
    # Create frontmatter
    frontmatter <- c(
      "---",
      paste0("title: \"", title, "\""),
      paste0("date: ", date),
      paste0("author: ", author)
    )
    
    # Add categories to frontmatter if they exist
    if (!is.null(categories)) {
      frontmatter <- c(frontmatter, "categories:", paste0("- ", categories, collapse = "\n"))
    }
    
    frontmatter <- c(frontmatter, "---", "\n")
    
    # Write the frontmatter to the file
    writeLines(frontmatter, file_path)
    
    message(paste("Blog post created at", file_path))
  }
  if (open) {
    rstudioapi::documentOpen(file_path)
  }
  invisible(file_path)
}
