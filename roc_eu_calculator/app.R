#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tibble)
library(ggplot2)
library(tidyr)

theme_set(ggthemes::theme_few())

roc <- function(x, p = 2) {
    (1 - (1 - x)^p)^(1/p)
}

roc_prime <- function(x) {
    (1 - x) / sqrt(2*x - x^2)
}

expected_utility <- function(pi, alpha, u_tp, u_tn, u_fp, u_fn, p = 2) {
    r <- roc(alpha, p)
    pi * r * u_tp + pi * (1 - r) * u_fn + (1-pi) * alpha * u_fp + (1-pi) * (1-alpha) * u_tn
}

max_eu <- function(eu_func) {
    optim(0.5, function(x) -eu_func(x), lower = 0, upper = 1, method = 'L-BFGS-B')$par
}

solver <- function(pi, u_tp, u_tn, u_fp, u_fn, eu = expected_utility,
                   roc = roc) {
    alpha <- max_eu(function(x) eu(pi, x, u_tp, u_tn, u_fp, u_fn))
    EER <- (u_fp - u_tn) / (u_fn - u_tp)
    r <- roc(alpha)
    tibble(
        FPR = alpha, TPR = r, EER = EER
    )
}

plotter <- function(solution, func, plot_title, y_title) {
    
    point_label <- glue::glue("({round(solution, 2)}, {round(func(solution), 2)})")
    tibble(FPR = 0:1000/1000,
           eu = func(FPR)) %>% 
        ggplot(aes(x = FPR, y = eu)) + 
        geom_line() + 
        annotate(x = solution, y = func(solution), geom = 'point', color = 'blue') +
        annotate(x = solution, y = func(solution), geom = 'text', label = point_label, hjust=0, 
                 vjust=0, size = 2, color = 'blue') +
        labs(x='False Positive Rate', y = y_title, title = plot_title)
}


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Binary Classifier Utility Maximizer"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            helpText("These controls set the parameters for a simple classifier optimizer. The \"classifier strength\" is the 'goodness' of the classifier, in terms of its closeness to the ideal perfect classifier."),
            sliderInput("pi",
                        "Prevalence",
                        min = 0,
                        max = 1,
                        value = 0.5),
            numericInput("u_tp", "Utility of a True Positive", value = 0),
            numericInput("u_tn", "Utility of a True Negative", value = 0),
            numericInput("u_fp", "Utility of a False Positive", value = -1),
            numericInput("u_fn", "Utility of a False Negative", value = -1),
            numericInput("p", "Classifier Strength", value = 2, step = .25, min = 1, max = 10)
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("roc_plot"),
            plotOutput("eu_plot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$roc_plot <- renderPlot({
        eu <- function(x) expected_utility(input$pi, x, input$u_tp, input$u_tn, input$u_fp, input$u_fn, p = input$p)
        solution <- max_eu(eu)
        roc_func <- function(x) roc(x, input$p)
        plotter(solution, roc_func, 'ROC Curve', 'TPR/Recall') +
            coord_fixed() + 
            geom_abline(color = 'grey', linetype = 'dashed')
    })

    output$eu_plot <- renderPlot({
        eu <- function(x) expected_utility(input$pi, x, input$u_tp, input$u_tn, input$u_fp, input$u_fn, p = input$p)
        solution <- max_eu(eu)
        plotter(solution, eu, 'Expected Utility Curve', 'Expected Utility')
    })
}



# Run the application 
shinyApp(ui = ui, server = server)
