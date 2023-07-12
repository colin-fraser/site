# trying to come up with some sampling scheme that is uniform on the number of carries.

library(tidyverse)
library(openaitools)
library(R.utils)

get_digits <- function(n) as.integer(strsplit(as.character(n), "")[[1]])

carries <- function(a, b, c = a + b) {
  
  c <- get_digits(c)
  a <- get_digits(a)
  b <- get_digits(b)
  
  max_digits <- max(length(a), length(b), length(c))
  zero_pad <- function(x) c(rep(0, max_digits - length(x)), x)
  
  a <- zero_pad(a)
  b <- zero_pad(b)
  c <- zero_pad(c)
  
  digit_sum <- (a + b) %% 10
  (c - digit_sum) %% 10
}

carries_v <- Vectorize(carries)

n_carries <- function(a, b) sum(carries(a, b))


sample_with_k_carries <- function(a, k, max = 1e7, max_samples = 10000) {
  if (k > log10(max)) stop("k must be less than log10(max)")
  success <- FALSE
  counter <- 0
  while (!success) {
    b <- sample.int(max, 1)
    success <- n_carries(a, b) == k
    if (counter == max_samples) {
      warning(paste("Unable to find a match for", a, "with", k, "carries."))
      return(NA)
    }
    counter <- counter + 1
  }
  b
}

sample_a <- function(n, k, max = 1e7) {
  single_sample <- function() {
    valid_a <- FALSE
    while (!valid_a) {
      a <- sample.int(max, 1)
      a_digits <- get_digits(a)
      valid_a <- (sum(a_digits == 0) <= log10(max) - k) && (sum(a_digits == 9) <= k)
    }
    a 
  }
  replicate(n, single_sample())
}

sample_pairs_with_k_carries <- function(n, k, max = 1e7) {
  a <- sample_a(n, k, max)
  tibble(
    a = a,
    b = map_int(a, sample_with_k_carries, k = k, max = max)
  )
}

make_input_numbers <- function(prompt_templates = c('{a}+{b}=')) {
  map(0:7, sample_pairs_with_k_carries, n = 150, .progress = TRUE) |> 
    list_rbind()
}

set.seed(103)
input_numbers <- make_input_numbers()

input_data <- input_numbers |> 
  mutate(c = a + b, 
         carries = map2_int(a, b, n_carries),
         prompt = str_glue("{a}+{b}="),
         pair_id = row_number()
  )

try_api_call <- function(prompts, prompt_ids, output_dir, max_retries = 3, initial_sleep_time = 2, timeout = 10, ...) {
  if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  n <- length(prompts)
  counter <- 0
  
  for(i in seq_along(prompts)) {
    prompt <- prompts[i]
    id <- prompt_ids[i]
    counter <- i
    cat(paste(counter, n, sep = '/'), '\n')
    output_file <- file.path(output_dir, paste0(id, ".rds"))
    
    if(file.exists(output_file)) next
    
    n_retries <- 0
    success <- FALSE
    
    while(!success && n_retries < max_retries) {
      result <- tryCatch(withTimeout(quick_chat_completion(prompt, ...), timeout = timeout), 
                         TimeoutException = function(e) e,
                         error = function(e) e)
      
      if(inherits(result, "error") || inherits(result, "TimeoutException")) {
        n_retries <- n_retries + 1
        Sys.sleep(initial_sleep_time * 2^(n_retries - 1))  # Exponential backoff
      } else {
        result <- list(prompt = prompt, result = result)
        saveRDS(result, output_file)
        cat("Wrote ", output_file, "\n")
        success <- TRUE
      }
    }
    
    if(!success) warning(paste0("Max retries reached for prompt: '", prompt, "'. Moving on."))
  }
}

try_api_call(input_data$prompt, input_data$pair_id, output_dir = "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/exp_2/gpt3.5", model = "gpt-3.5-turbo", n = 10)
try_api_call(input_data$prompt, input_data$pair_id, output_dir = "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/exp_2/gpt4", model = "gpt-4", n = 10)