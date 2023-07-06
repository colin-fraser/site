library(testthat)
library(lubridate)

# Ensure that you have the latest version of your function loaded
source("functions.R")

test_that("create_blog_post creates post correctly", {
  test_dir <- tempfile()  # Use a temporary directory to avoid clutter
  cat(paste("Testing in", test_dir))
  dir.create(test_dir)
  today <- lubridate::today("America/Vancouver")
  
  slug_1 <- "a-sample-blog-post"
  create_blog_post("A Sample Blog Post", 
                   posts_dir = test_dir, 
                   open = FALSE, 
                   create_branch = FALSE)
  expect_true(dir.exists(file.path(test_dir, paste(today, slug_1, sep = '-'))))
  expect_true(file.exists(file.path(test_dir, paste(today, slug_1, sep = '-'), "index.qmd")))
  
  slug_2 <- "a-blog-post-about-r"
  create_blog_post("A Blog Post About R", 
                   categories = c("R", "Programming"), 
                   posts_dir = test_dir, 
                   open = FALSE, 
                   create_branch = FALSE,
                   prepend_date_to_slug = FALSE)
  expect_contains(readLines(file.path(test_dir, slug_2, "index.qmd")),
                  c("categories:", "- R", "- Programming"))
  
  slug_3 <- "2022-01-01-a-historical-blog-post"
  create_blog_post("A Historical Blog Post", 
                   categories = "History", 
                   date = as.Date("2022-01-01"), 
                   author = "Historian",
                   posts_dir = test_dir, 
                   open = FALSE, 
                   create_branch = FALSE)
  expect_true(dir.exists(file.path(test_dir, slug_3)))
  expect_true(file.exists(file.path(test_dir, slug_3, "index.qmd")))
  
  slug_4 <- "custom-slug"
  create_blog_post("A Blog Post With Custom Slug", 
                   slug = slug_4, 
                   posts_dir = test_dir, 
                   open = FALSE, 
                   create_branch = FALSE)
  expect_true(dir.exists(file.path(test_dir, slug_4)))
  expect_true(file.exists(file.path(test_dir, slug_4, "index.qmd")))
  
  slug_6 <- "a-blog-post-without-date-in-slug"
  create_blog_post("A Blog Post Without Date in Slug", 
                   date = as.Date("2023-01-01"), 
                   prepend_date_to_slug = FALSE, 
                   posts_dir = test_dir, 
                   open = FALSE, 
                   create_branch = FALSE)
  expect_true(dir.exists(file.path(test_dir, slug_6)))
  expect_true(file.exists(file.path(test_dir, slug_6, "index.qmd")))
})
