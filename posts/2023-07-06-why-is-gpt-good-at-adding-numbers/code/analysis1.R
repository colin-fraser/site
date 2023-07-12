library(tidyverse)
library(openaitools)

data_loc <- "posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data"
prompt_1 <- "{a}+{b}="
prompt_2 <- "What is {a} + {b}?"

process_response_file <- function(filepath, prompt_template) {
  file_name <- str_remove(fs::path_file(filepath), "\\.rds")
  numbers <- fs::path_file(file_name) |> 
    str_extract_all("\\d+") |> 
    _[[1]] |> 
    as.numeric()
  
  chat_completion_to_tibble(readRDS(filepath)) |> 
    mutate(prompt_template = prompt_template, a = numbers[1], b = numbers[2], right_answer = a + b)
}

process_directory <- function(dirpath, prompt_template, prepend = data_loc) {
  if (!is.null(prepend)) {
    dirpath <- file.path(data_loc, dirpath)
  }
  fs::dir_ls(dirpath) |> 
    map(process_response_file, prompt_template = prompt_template) |> 
    list_rbind()
}

result_data <- process_directory("1", prompt_1) |> 
  bind_rows(process_directory("2", prompt_2)) |> 
  bind_rows(process_directory("3", prompt_1)) |> 
  bind_rows(process_directory("4", prompt_2))

extract_number <- function(x) {
  str_extract(x, "[\\d,]+\\.?$") |> 
    str_remove_all("[^\\d]") |> 
    as.numeric()
}

get_digits <- function(n) {
  as.numeric(strsplit(as.character(n), "")[[1]])
}

carries <- function(a, b, c = a + b) {
  
  get_digits <- function(n) as.integer(strsplit(as.character(n), "")[[1]])
  
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

processed <- result_data |>
  transmute(
    model,
    a,
    b,
    right_answer,
    prompt_template,
    message_content,
    extracted = extract_number(message_content),
    correct = right_answer == extracted,
    carries = carries_v(a, b),
    n_carries = map_int(carries, sum),
    a_digits = floor(log10(a)) + 1,
    b_digits = floor(log10(b)) + 1,
    difference = a - b,
    no_carries = n_carries == 0
  )

processed |> 
  group_by(n_carries, model, prompt_template) |> 
  summarise(accuracy = mean(correct), n = n()) |> 
  ggplot(aes(x = n_carries, y = accuracy, color = model, linetype = prompt_template)) + 
  geom_line()


  mutate(carries = carries_v(a, b), n_carries = map_int(carries, sum), 
         a_digits = floor(log10(a))+1, b_digits = floor(log10(b)) + 1,
         difference = a - b, no_carries = n_carries == 0) |> 
  glm(correct ~ model + prompt_template + log10(a)*log10(b) + n_carries*model, data = _, family = binomial) |> 
  summary()

