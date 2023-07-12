library(tidyverse)
library(openaitools)

read_response_file <- function(file) {
  resp <- readRDS(file)
  id <- as.numeric(str_extract(file, "\\d+(?=\\.rds)"))
  completion <- chat_completion_to_tibble(resp$result)
  completion$prompt <- resp$prompt
  completion$pair_id <- id
  completion
}

gpt3resps <- fs::dir_ls("posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/exp_2/gpt3.5/") |> 
  map(read_response_file, .progress = TRUE) |> 
  list_rbind() |> 
  inner_join(input_data, by = "pair_id")

gpt3resps |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d,]+\\.?$"), "[^\\d]")),
         correct = extracted == c) |> 
  group_by(carries) |> 
  summarise(mean(correct, na.rm = TRUE))

gpt4resps <- fs::dir_ls("posts/2023-07-06-why-is-gpt-good-at-adding-numbers/data/exp_2/gpt4/") |> 
  map(read_response_file, .progress = TRUE) |> 
  list_rbind() |> 
  inner_join(input_data, by = "pair_id")

gpt4resps |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d,]+\\.?$"), "[^\\d]")),
         correct = extracted == c) |> 
  group_by(carries) |> 
  summarise(mean(correct, na.rm = TRUE))

gpt3resps |> 
  bind_rows(gpt4resps) |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d, ]+\\.?$"), "[^\\d]")),
         correct = extracted == c) |> 
  # filter(index == 0) |> 
  group_by(carries, model) |> 
  summarise(acc = mean(correct, na.rm = TRUE)) |> 
  ggplot(aes(x = carries, y = acc, color = model)) + 
  geom_line() +
  scale_y_continuous(labels = scales::percent, limits = c(0, .8)) +
  colinlib::theme1() +
  labs(y = 'Accuracy', x = 'Number of Carries', color = 'Model', title = 'GPT performance at 7-digit addition',
       subtitle = 'by number of required carries (in base 10)')


gpt3resps |> 
  bind_rows(gpt4resps) |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d, ]+\\.?$"), "[^\\d]")),
         correct_reply = extracted == c) |> 
  filter(!is.na(extracted)) -> replydata
glm(correct_reply ~ model * carries, data = replydata, family = binomial) |> 
  summary()



bind_rows(gpt4resps) |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d,]+\\.?$"), "[^\\d]")),
         correct_reply = extracted == c) |> 
  filter(!is.na(extracted)) |> 
  glm(correct_reply ~ carries, data = _, family = binomial) |> 
  summary()


gpt3resps |> 
  bind_rows(gpt4resps) |> 
  mutate(extracted = as.numeric(str_remove_all(str_extract(message_content, "[\\d, ]+\\.?$"), "[^\\d]")),
         correct = extracted == c) |> 
  # filter(index == 0) |> 
  group_by(carries, model) |> 
  # filter(extracted/c<20) |> 
  ggplot(aes(x = c, y = extracted, color = model)) +
  geom_abline(color = 'grey40') +
  geom_text(aes(label = ifelse((extracted/c>5) | (extracted/c<.1), 
                               paste(c, extracted, sep = "=>"), NA)), size = 2, vjust=0, hjust=1) +
  geom_point(alpha = 0.5) +
  colinlib::theme1('none') +
  labs(y = "GPT answer", c = "Actual answer") +
  scale_y_log10() + 
  scale_x_log10()
