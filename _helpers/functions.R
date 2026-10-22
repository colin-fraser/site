generate_slug <- function(title, date, prepend_date = TRUE) {
  slug <- gsub("[^a-zA-Z0-9-]", "", gsub("\\s", "-", tolower(title)))
  if (prepend_date) {
    slug <- paste0(date, "-", slug)
  }
  return(slug)
}

create_directory <- function(posts_dir, slug) {
  dir_path <- file.path(posts_dir, slug)
  if (dir.exists(dir_path)) {
    stop("A directory with this name already exists!")
  }
  dir.create(dir_path)
  return(dir_path)
}

generate_frontmatter <- function(title, date, author, categories) {
  frontmatter <- c(
    "---",
    paste0("title: \"", title, "\""),
    paste0("date: ", date),
    paste0("author: ", author)
  )
  
  if (!is.null(categories)) {
    frontmatter <- c(frontmatter, "categories:", paste0("- ", categories, collapse = "\n"))
  }
  
  frontmatter <- c(frontmatter, "---", "\n")
  
  return(frontmatter)
}

write_post <- function(dir_path, title, date, author, categories) {
  file_path <- file.path(dir_path, "index.qmd")
  
  frontmatter <- generate_frontmatter(title, date, author, categories)
  
  writeLines(frontmatter, file_path)
  
  message(paste("Blog post created at", file_path))
  return(file_path)
}

create_git_branch <- function(slug) {
  if (askYesNo(paste0("Do you want to create a new branch called ", slug, "?\n"))) {
    git_output <- system(paste("git checkout -b", slug), intern = TRUE)
    if (length(git_output) > 0 && any(grepl("error:", git_output))) {
      warning("Git command failed with error: ", paste(git_output, collapse = "\n"))
    }
  } else {
    warning("Cancelled branch creation")
  }
}

create_blog_post <- function(title, 
                             categories = NULL, 
                             date = lubridate::today(tzone = "America/Vancouver"), 
                             author = "Colin Fraser", 
                             slug = NULL,
                             posts_dir = "posts",
                             open = TRUE,
                             prepend_date_to_slug = NULL,
                             create_branch = TRUE,
                             tz = "America/Vancouver") {
  if (inherits(date, "Date")) {
    date <- format(date, "%Y-%m-%d", tz = tz)
  }
  
  if (is.null(prepend_date_to_slug)) {
    prepend_date_to_slug <- is.null(slug)
  }
  
  slug <- ifelse(is.null(slug), generate_slug(title, date, prepend_date_to_slug), slug)
  dir_path <- create_directory(posts_dir, slug)
  file_path <- write_post(dir_path, title, date, author, categories)
  
  if (create_branch) {
    create_git_branch(slug)
  }
  
  if (open) {
    rstudioapi::documentOpen(file_path)
  }
  
  invisible(file_path)
}
