library(shiny)
library(ggplot2)
library(shinythemes)
library(scales)

#global defaults. The rest are in server.R
BK.DEFAULT.MDE <- 0.15

fluidPage(theme = shinytheme("cerulean"),
  
  #titlePanel("Design Your Experiment"),
  
  sidebarPanel(
    tags$head(includeScript("ga.js")),
    uiOutput("title"),
    radioButtons("exp_type", "Treatment Type", c("Canvass", "Mail")), #This is where the flow for mail or canvass experiment begins
    
    uiOutput("placebo_disp"), #This asks if a placebo will be present, condition on canvass 
    uiOutput("canvass.contact"), #Input canvass contact rate, if canvass experiment
  
    selectInput('n.treatments', 'Number of Treatment Conditions (not including control or placebo)', c("1","2","3","4"),selected=1),
    selectInput('n.post.waves', 'Number of Post-Treatment Survey Waves', c("1","2","3","4","5","6"),selected=2),
#    helpText("This is for estimating persistence and tracking polls"),

    sliderInput("mde.sd","Minimum Detectable Effect (MDE) size, standard deviations",value=BK.DEFAULT.MDE,min=0,max=1,step=0.01),

    checkboxInput("advanced", "Display Advanced Options",
                  value=FALSE),  #Displays test-retest, recruitment,
                                 #and retention   #rates

    #The details of these are in server.R. One does need to call these
    #here to position the items
    uiOutput("advanced.survey.mail.response.rate"),
    uiOutput("advanced.retention"),
    uiOutput("advanced.canvass.contact"),
    uiOutput("advanced.cost.treatment"),
    uiOutput("advanced.cost.recruitment.mail"),
    uiOutput("advanced.cost.pre.incentive"),
    uiOutput("advanced.cost.post.incentive"),
    uiOutput("advanced.dv"),
    uiOutput("advanced.cost.respondent"),

    #It would be good to have contextual help boxes over the options
    helpText(HTML("This calculator is designed for regular persuasion experiments. To discuss alternative designs or suggest their inclusions in the calculator, please contact <a href=experiments@lists.berkeley.edu>experiments@lists.berkeley.edu</a>."))
  ),
  

  mainPanel(
    uiOutput("intro"),
    uiOutput("line1"),
    uiOutput("input.list1"),
    plotOutput('plot'),
    #uiOutput("graph.line"),
    uiOutput("design.line1"),
    uiOutput("design.line"),
    uiOutput("advanced.line"),
    uiOutput("advanced.list"),
    uiOutput("additional.assumptions")
   )#mainPanel
)#FluidPage
