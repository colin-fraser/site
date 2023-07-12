library(openaitools)  # install from github.com/colin-fraser/openaitools
library(tidyverse)
library(furrr)
library(R.utils)

set.seed(1729)
N <- 200
input_data <- tibble(
  a = sample.int(1e7, N, replace = TRUE),
  b = sample.int(1e7, N, replace = TRUE),
  c = a + b,
  prompt_1 = str_glue("{a}+{b}="),
  prompt_2 = str_glue("What is {a} + {b}?")
)

try_api_call <- function(prompts, output_dir, max_retries = 3, initial_sleep_time = 2, timeout = 10, ...) {
  if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  n <- length(prompts)
  counter <- 0
  
  for(prompt in prompts) {
    counter <- counter + 1
    cat(paste(counter, n, sep = '/'), '\n')
    safe_filename <- gsub("[^a-zA-Z0-9]", "_", prompt)  
    output_file <- file.path(output_dir, paste0(safe_filename, ".rds"))
    
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
        saveRDS(result, output_file)
        success <- TRUE
      }
    }
    
    if(!success) warning(paste0("Max retries reached for prompt: '", prompt, "'. Moving on."))
  }
}


try_api_call(input_data$prompt_1, "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/1")
try_api_call(input_data$prompt_2, "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/2")
try_api_call(input_data$prompt_1, "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/3", model = "gpt-4", timeout = 20)
try_api_call(input_data$prompt_2, "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/4", model = "gpt-4", timeout = 20)

