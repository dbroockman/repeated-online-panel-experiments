library(shiny)
library(ggplot2)
library(grid)
library(plyr)
library(reshape2)
library(scales) #needed for ggplot: scale_x_continuous(labels = comma)
library(rmarkdown)
library(knitr)
library(tools)

options(scipen=999)

#Global defaults changed by user inputs. These should not be accessed
#directly, but via the GetParms() function other than when the widget
#in question is being created.
#note: BK.DEFAULT.MDE is in ui.R
BK.DEFAULT.COST.TREATMENT.MAIL <- 2
BK.DEFAULT.COST.TREATMENT.CANVASS <- 10
BK.SURVEY.TESTRETEST <- 0.78
BK.MAIL.SURVEY.RESPONSE.RATE <- 0.045
BK.SURVEY.RETENTION.RATE <- .8
BK.CANVASS.CONTACT <- 0.3
BK.COST.RECRUITMENT.MAIL <- .35
BK.COST.PRE.INCENTIVE <- 0
BK.COST.POST.INCENTIVE <- 5
BK.COST.RESPONDENT <- 0

#Global defaults NOT changed by user inputs (hence the prefix
#"FIXED"). These are binding hard coded numbers. May be there should
#be advanced-advanced options to make these visible.
#FIXED.COST.MAIL <- .35
#FIXED.COST.INCENTIVE <- 9
FIXED.PHONE.RESPONSE <- 0.08
FIXED.COST.PHONE <- 4.5
FIXED.POWER <- "80%"
FIXED.ALPHA <- "0.05"

#Sample Size and Cost of Berkeley Design
design.Berkeley <-
  function(mde.sd = BK.DEFAULT.MDE, n.treatments, n.post.waves,
           survey.testretest = BK.SURVEY.TESTRETEST,
           survey.mail.response.rate = BK.MAIL.SURVEY.RESPONSE.RATE,
           survey.retention.rate = BK.SURVEY.RETENTION.RATE,
           canvass.contact = BK.CANVASS.CONTACT,
           exp_type = "Mail",
           cost.recruitment.mail = BK.COST.RECRUITMENT.MAIL,
           cost.pre.incentive = BK.COST.PRE.INCENTIVE,
           cost.post.incentive = BK.COST.PRE.INCENTIVE,
           cost.treatment = BK.DEFAULT.COST.TREATMENT.MAIL,
           cost.respondent = BK.COST.RESPONDENT)
{
    n.treatments <- as.numeric(n.treatments)
  if(exp_type!="Canvass") {
    post.treat.n.survey <- (1-survey.testretest) * (6/mde.sd)^2
    n.mailed.treat <- ((post.treat.n.survey/survey.retention.rate)/2) * n.treatments
    n.treated.condition <- (post.treat.n.survey/survey.retention.rate)/2
    n.mailed.control <- (post.treat.n.survey/survey.retention.rate)/2
    Berkeley.treated.total <- n.mailed.treat
    n.mailed.survey <- (n.mailed.treat+n.mailed.control)/survey.mail.response.rate
    n.respond.presurvey <- n.mailed.survey*survey.mail.response.rate
    Berkeley.cost.treatment <- n.mailed.treat*cost.treatment
    Berkeley.cost.survey <- (n.mailed.survey*cost.recruitment.mail)+
                            (n.mailed.survey*survey.mail.response.rate*cost.pre.incentive) +
                            (n.mailed.survey*survey.mail.response.rate*cost.post.incentive*survey.retention.rate*as.numeric(n.post.waves) +
                            (n.mailed.survey*survey.mail.response.rate+n.mailed.survey*survey.mail.response.rate*survey.retention.rate*as.numeric(n.post.waves))*cost.respondent) 
    #People responding to the baselime plus respondents to all subsequent surveys times the cost per respondent a vendor may charge.
  }
  else{
    post.treat.n.survey <- ((1-survey.testretest)*(6/mde.sd)^2) / canvass.contact
    n.treated.condition <- ((post.treat.n.survey/survey.retention.rate)/2) * canvass.contact
    n.mailed.treat <- ((post.treat.n.survey/survey.retention.rate)/2) * n.treatments
    n.mailed.control <- (post.treat.n.survey/survey.retention.rate)/2
    Berkeley.treated.total <- (n.mailed.treat+n.mailed.control) * canvass.contact
    n.mailed.survey <- (n.mailed.treat+n.mailed.control) / survey.mail.response.rate
    n.respond.presurvey <- n.mailed.survey*survey.mail.response.rate
    Berkeley.cost.treatment <- n.mailed.treat*cost.treatment*canvass.contact+n.mailed.control*cost.treatment*canvass.contact
    Berkeley.cost.survey <- (n.mailed.survey*cost.recruitment.mail) +
                            (n.mailed.survey*survey.mail.response.rate*cost.pre.incentive) +
                            (n.mailed.survey*survey.mail.response.rate*canvass.contact*cost.post.incentive*survey.retention.rate*as.numeric(n.post.waves) +
                            (n.mailed.survey*survey.mail.response.rate + n.mailed.survey*survey.mail.response.rate*canvass.contact*survey.retention.rate*as.numeric(n.post.waves))*cost.respondent)
    #People responding to the baselime plus respondents to all subsequent surveys times the cost per respondent a vendor may charge.
    }
  post.treat.n.survey.conditions <- post.treat.n.survey/2+post.treat.n.survey/2*as.numeric(n.treatments)
  Berkeley.cost.incentive <- n.respond.presurvey*cost.pre.incentive+post.treat.n.survey*cost.post.incentive*as.numeric(n.post.waves)
   # n.respond.presurvey*cost.incentive+post.treat.n.survey.conditions*cost.incentive*as.numeric(post.waves)*survey.retention
  Berkeley.cost.total <- Berkeley.cost.survey+Berkeley.cost.treatment
  design.out.Berkeley <- list(n.mailed.survey=n.mailed.survey,
                              n.mailed.treat=n.mailed.treat,
                              n.mailed.control=n.mailed.control,
                              survey.mail.response.rate=survey.mail.response.rate,
                              n.treatments=n.treatments,
                              n.respond.presurvey=n.respond.presurvey,
                              Berkeley.cost.survey=Berkeley.cost.survey,
                              Berkeley.cost.total=Berkeley.cost.total,
                              Berkeley.cost.treatment=Berkeley.cost.treatment,
                              Berkeley.cost.incentive=Berkeley.cost.incentive,
                              Berkeley.treated.total=Berkeley.treated.total,
                              cost.treatment=cost.treatment,
                              n.treated.condition=n.treated.condition,
                              post.treat.n.survey=round(post.treat.n.survey*canvass.contact),
                              mde.sd=mde.sd,
                              mde.pp=mde.sd*33.3333)
  return(design.out.Berkeley)
}

#Sample Size and Cost of Traditional Design
design.traditional <-
  function(mde.sd=BK.DEFAULT.MDE,n.treatments,n.post.waves,
           canvass.contact=BK.CANVASS.CONTACT,
           phone.response=FIXED.PHONE.RESPONSE,
           exp_type="Mail",
           cost.phone=FIXED.COST.PHONE,
           cost.treatment=BK.DEFAULT.COST.TREATMENT.MAIL)
{
  if(exp_type!="Canvass") {    
    n.condition.traditional <- (6/mde.sd)^2/phone.response/2
    n.treated.condition <- n.condition.traditional
    n.treat.traditional <- n.condition.traditional*as.numeric(n.treatments)
    traditional.cost.treatment <- n.treat.traditional*cost.treatment
  }
  else{
    n.condition.traditional <- (6/(mde.sd*canvass.contact))^2/phone.response/2
    n.treated.condition <- n.condition.traditional*canvass.contact
    n.treat.traditional <- n.condition.traditional*as.numeric(n.treatments)
    traditional.cost.treatment <-
      n.treat.traditional*cost.treatment*canvass.contact

#useful for debugging    
#    cat("mde:",mde,"\n")
#    cat("ate.sd",ate.sd,"\n")
#    cat("canvass.contact",canvass.contact,"\n")
#    cat("phone.response",phone.response,"\n")                
#    cat("n.condition.traditional:",n.condition.traditional,"\n")
#    cat("n.treat.traditional:",n.treat.traditional,"\n")    
  }
  n.control.traditional <- n.condition.traditional
  n.called.traditional <- n.treat.traditional+n.control.traditional
  traditional.cost.survey <- cost.phone*n.called.traditional*phone.response*as.numeric(n.post.waves)
  traditional.cost.total <- traditional.cost.survey+traditional.cost.treatment
  design.out.traditional <- list(n.treat.traditional=n.treat.traditional,n.called.traditional=n.called.traditional,n.control.traditional=n.control.traditional,
                                 traditional.cost.survey=traditional.cost.survey,
                                 traditional.cost.total=traditional.cost.total,traditional.cost.treatment=traditional.cost.treatment,
                                 n.treated.condition=n.treated.condition)
  return(design.out.traditional)
}


function(input, output) {
  output$advanced.survey.mail.response.rate <- renderUI({
    if (input$advanced==FALSE)
      return()
    # Depending on input$experiment_type, we'll generate a different
    # UI component and send it to the client.
        sliderInput("survey.mail.response.rate",
                    "Initial pre-treatment survey response rate",
                    value = BK.MAIL.SURVEY.RESPONSE.RATE,step=0.005,min=0.01,max=0.2)
  })
  
  output$advanced.canvass.contact <- renderUI({ #If a canvass experiment, capture canvass contact rate
    if (input$exp_type!="Canvass" | (input$advanced==FALSE))
      return()
    sliderInput("canvass.contact","Canvass contact rate",
                value=BK.CANVASS.CONTACT, step=0.01,min=0.1,max=1)

  })
  
  output$advanced.dv <- renderUI({ #These are advanced options -- Test-retest
    if (input$advanced==FALSE)
      return()
    # Depending on input$experiment_type, we'll generate a different
    # UI component and send it to the client.
    sliderInput("survey.testretest", "Test-retest R^2",
                value = BK.SURVEY.TESTRETEST,step=0.01,min=0,max=.95)
  })
  
  output$advanced.retention <- renderUI({
    if (input$advanced==FALSE) {
      return()
    }
    else {
    # Depending on input$experiment_type, we'll generate a different
    # UI component and send it to the client.
      sliderInput("survey.retention.rate",
                  "Survey reinterview rate",
                  value = BK.SURVEY.RETENTION.RATE, step=0.02, min=0.4, max=1)
    }
  })

  output$advanced.cost.treatment <- renderUI({ #These are advanced
                                        #options --
    if (input$advanced==FALSE) {
      return()
    } else{
      if(input$exp_type!="Canvass") {      
        sliderInput("cost.treatment",
                    "Cost per mail flight",
                    value = 2, step=0.5, min=0, max=5)
      } else {
        sliderInput("cost.treatment",
                    "Cost per contact",
                    value = 10, step=1, min=0, max=50)        
      }
    }
  })
  
  output$advanced.cost.recruitment.mail <- renderUI({
    if (input$advanced==FALSE) {
      return()
    }
    else {
      sliderInput("cost.recruitment.mail",
                  "Cost of recruitment mail, per letter",
                  value = BK.COST.RECRUITMENT.MAIL, step=0.01, min=0.1, max=1)
    }
  })
  
  output$advanced.cost.respondent <- renderUI({
    if (input$advanced==FALSE) {
      return()
    }
    else {
      sliderInput("cost.respondent",
                  "Cost per respondent (for a vendor)",
                  value = BK.COST.RESPONDENT, step=1, min=0, max=10)
    }
  })
  
  output$advanced.cost.pre.incentive <- renderUI({
    if (input$advanced==FALSE) {
      return()
    }
    else {
      sliderInput("cost.pre.incentive",
                  "Dollar amount of pre-survey incentive",
                  value = BK.COST.PRE.INCENTIVE, step=1, min=0, max=20)
    }
  })
  
  output$advanced.cost.post.incentive <- renderUI({
    if (input$advanced==FALSE) {
      return()
    }
    else {
      sliderInput("cost.post.incentive",
                  "Dollar amount of post-survey incentive",
                  value = BK.COST.POST.INCENTIVE, step=1, min=0, max=20)
    }
  })
  

  #####OUTPUT#######
  
  GetParms <- reactive({
    #Beginning of setting input parameters. One calls this function
    #from every renderUI call that needs them. This function has to be
    #called a lot.
    if (input$advanced==FALSE) {
      if(input$exp_type!="Canvass")
      {
        cost.treatment <- BK.DEFAULT.COST.TREATMENT.MAIL
      } else {
        cost.treatment <- BK.DEFAULT.COST.TREATMENT.CANVASS
      }
    } else {
      cost.treatment <- as.numeric(input$advanced.cost.treatment)
    } #if (input$advanced==FALSE) {
    
    if (input$advanced==TRUE) {
      cost.treatment <- input$cost.treatment
      if(is.null(cost.treatment))
        {
          if(input$exp_type!="Canvass")
            {
              cost.treatment <- BK.DEFAULT.COST.TREATMENT.MAIL
            } else {
              cost.treatment <- BK.DEFAULT.COST.TREATMENT.CANVASS
            }
        }

      survey.testretest <- input$survey.testretest
      if(is.null(survey.testretest))
        survey.testretest <- survey.testretest

      survey.mail.response.rate <- input$survey.mail.response.rate
      if(is.null(survey.mail.response.rate))
        survey.mail.response.rate <- BK.MAIL.SURVEY.RESPONSE.RATE

      survey.retention.rate <- input$survey.retention.rate
      if(is.null(survey.retention.rate))
        survey.retention.rate <- BK.SURVEY.RETENTION.RATE  
      
      cost.recruitment.mail <- input$cost.recruitment.mail
      if(is.null(cost.recruitment.mail))
        cost.recruitment.mail <- BK.COST.RECRUITMENT.MAIL
      
      cost.respondent <- input$cost.respondent
      if(is.null(cost.respondent))
        cost.respondent <- BK.COST.RESPONDENT
      
      cost.pre.incentive <- input$cost.pre.incentive
      if(is.null(cost.pre.incentive))
        cost.pre.incentive <- BK.COST.PRE.INCENTIVE
      
      cost.post.incentive <- input$cost.post.incentive
      if(is.null(cost.post.incentive))
        cost.post.incentive <- BK.COST.POST.INCENTIVE

      canvass.contact <- input$canvass.contact
      if(is.null(canvass.contact))
        canvass.contact <- BK.CANVASS.CONTACT
    } else {
      survey.testretest <- BK.SURVEY.TESTRETEST
      survey.mail.response.rate <- BK.MAIL.SURVEY.RESPONSE.RATE
      survey.retention.rate <- BK.SURVEY.RETENTION.RATE
      canvass.contact <- BK.CANVASS.CONTACT
      cost.recruitment.mail <- BK.COST.RECRUITMENT.MAIL
      cost.pre.incentive <- BK.COST.PRE.INCENTIVE
      cost.post.incentive <- BK.COST.POST.INCENTIVE
      cost.respondent <- BK.COST.RESPONDENT
    }
    
    return(list(cost.treatment=cost.treatment,
                survey.testretest=survey.testretest,
                survey.mail.response.rate=survey.mail.response.rate,
                survey.retention.rate=survey.retention.rate,
                canvass.contact=canvass.contact,
                cost.recruitment.mail=cost.recruitment.mail,
                cost.pre.incentive=cost.pre.incentive,
                cost.post.incentive=cost.post.incentive,
                cost.respondent=cost.respondent
    ))
  })#end of GetParms()

Berkeley <- reactive({
  #Beginning of calculating Berkeley parameters.
  #This function has to be called a lot.
  #Same process as GetParms()
  unlist(design.Berkeley(mde.sd=as.numeric(input$mde.sd),n.treatments=as.numeric(input$n.treatments),
                        n.post.waves=as.numeric(input$n.post.waves),
                        survey.testretest=GetParms()$survey.testretest,
                        survey.mail.response.rate=GetParms()$survey.mail.response.rate,
                        survey.retention.rate=GetParms()$survey.retention.rate,
                        canvass.contact=GetParms()$canvass.contact, 
                        cost.recruitment.mail=GetParms()$cost.recruitment.mail, 
                        cost.pre.incentive=GetParms()$cost.pre.incentive, 
                        cost.post.incentive=GetParms()$cost.post.incentive, 
                        exp_type=input$exp_type,
                        cost.treatment=GetParms()$cost.treatment,
                        cost.respondent = GetParms()$cost.respondent))
        })#end of Berkeley()


output$title <-
  renderUI({HTML("<h3>Inputs: Design Parameters</h3>")})

output$intro <-
  renderUI({HTML("<br><b>Welcome</b> to the Broockman, Kalla, and Sekhon persuasion experiment design tool. For more information on the designs",
                 " described below, please review our paper: <a href=\"http://papers.ssrn.com/sol3/papers.cfm?abstract_id=2742869\" target=\"_blank\">Testing Theories of Attitude Change with Online Panel Field Experiments.")})

output$line1 <-
  renderUI({HTML("<h3>Results: Your Experiment</h3>")})
output$input.list1 <- renderUI({
      HTML("This experiment is designed to allow you to detect a treatment effect of ", input$mde.sd, " standard deviations which is
           approximately ", round(Berkeley()["mde.pp"], digits=1), "percentage points.")})

output$advanced.line <-
      renderUI({HTML("<h3>Fine Print</h3><p>Please note, the above assumes the following Advanced Options:</p>")})

output$advanced.list <- renderUI({
    if(input$exp_type!="Canvass")
      {
      HTML("<ul>
      <li>",paste0(GetParms()$survey.mail.response.rate*100,"%"),"response rate to the pre-treatment survey.</li>
      <li>",paste0(GetParms()$survey.retention.rate*100,"%"),"survey reinterview rate.</li>
      <li>",paste0("$",GetParms()$cost.treatment),"cost per persuasion mail flight.</li>
      <li>",paste0(GetParms()$survey.testretest)," test-retest R<sup>2</sup> of outcome on baseline variables.</li>
      <li>",paste0("$",GetParms()$cost.recruitment.mail)," cost per recruitment mailer.</li>
      <li>",paste0("$",GetParms()$cost.pre.incentive)," pre-survey incentive.</li>
      <li>",paste0("$",GetParms()$cost.post.incentive)," post-survey incentive.</li></ul>")
       } else {
      HTML("<ul>
      <li>",paste0(GetParms()$survey.mail.response.rate*100,"%"),"response rate to the pre-treatment survey.</li>
      <li>",paste0(GetParms()$survey.retention.rate*100,"%"),"survey reinterview rate.</li>
      <li>",paste0(GetParms()$canvass.contact*100,"%"),"canvass contact rate.</li>
      <li>",paste0("$",GetParms()$cost.treatment),"cost per canvass contact.</li>
      <li>",paste0(GetParms()$survey.testretest)," test-retest R<sup>2</sup> of outcome on baseline variables.</li>
      <li>",paste0("$",GetParms()$cost.recruitment.mail)," cost per recruitment mailer.</li>
      <li>",paste0("$",GetParms()$cost.pre.incentive)," pre-survey incentive.</li>
      <li>",paste0("$",GetParms()$cost.post.incentive)," post-survey incentive.</li></ul>")       
      }})

output$exp_type <- reactive({input$exp_type})

  output$graph.line <-
    renderUI({HTML("<table>
  <tr>
    <td width=\"45%\">This graph shows the minimium necessary size of the starting universe of voters and the number of voters that would need to be successfully contacted.</td>
    <td width=\"10%\"></td>
    <td width=\"45%\">This graph shows the estimated costs of the surveys and contacts and the sum of the two.</td>
  </tr>
</table>")})
  
  output$plot <- renderPlot({
#useful for debugging
#    cat("cost.treatment:", GetParms()$cost.treatment, "\n")
#    cat("survey.testretest:", GetParms()$survey.testretest, "\n")
#    cat("survey.recruitment:", GetParms()$survey.recruitment, "\n")
#    cat("survey.retention:", GetParms()$survey.retention, "\n")
#    cat("canvass.contact:", GetParms()$canvass.contact, "\n")
    #End of setting input parameters.

    traditional <-
      unlist(design.traditional(mde.sd=as.numeric(input$mde.sd),n.treatments=as.numeric(input$n.treatments),
                                n.post.waves=as.numeric(input$n.post.waves),
                                canvass.contact=GetParms()$canvass.contact,
                                exp_type=input$exp_type,
                                cost.treatment=GetParms()$cost.treatment))

    nm <- names(traditional)
    traditional <- as.data.frame(t(traditional))
    names(traditional) <- nm

    #JSS: These two checks are needed because the GetParms() data doesn't exist
    #sometimes. We need to leave the function and try again. FIX THIS
    #BETTER? SWITCH TO CANVASS + ADVANCED SLOW THE FIRST TIME

    #return if the length of traditional is less than expected
    if(length(traditional)<7)
      return()

    #return if the length of Berkeley() is less than expected    
    if(length(Berkeley())<13)
      return()    

    traditional.df <-
    subset(traditional,select=c("n.called.traditional","n.treated.condition","traditional.cost.survey","traditional.cost.total","traditional.cost.treatment"))

    Berkeley.df <-
    c(Berkeley()["n.mailed.survey"],Berkeley()["n.treated.condition"],Berkeley()["Berkeley.cost.survey"],Berkeley()["Berkeley.cost.total"],Berkeley()["Berkeley.cost.treatment"])
    Berkeley.df <- as.data.frame(t(Berkeley.df))
    names(Berkeley.df) <- c("n.called.traditional","n.treated.condition","traditional.cost.survey","traditional.cost.total","traditional.cost.treatment")
    df <- data.frame(rbind.fill(traditional,Berkeley.df))
    df <- rename(df, c("n.called.traditional"="Starting Universe Size","n.treated.condition"="Treatment Group Size","traditional.cost.survey"="Survey Cost","traditional.cost.total"="Total Cost","traditional.cost.treatment"="Treatment Cost"))
    df.size <- subset(df,select=c("Starting Universe Size","Treatment Group Size"))
    names(df.size)[names(df.size) == 'Treatment Group Size'] <- ifelse(input$exp_type=="Canvass",paste0("# of contacts needed \n per experimental group \n (",as.numeric(input$n.treatments)+1," groups)"),paste0("Number of mailers \n sent per experimental group \n (",input$n.treatments,ifelse(input$n.treatments==1," group)"," groups)")))
    df.size$Design <- c("Traditional Design","BKS Repeated Design")
    df.size <- melt(df.size, id.vars=c("Design"))

    ##TRYING TO DEBUG THE ERROR WHEN YOU CLICK ADVANCED OPTIONS
    #print(Berkeley())
    #print(is.na(Berkeley()))
    #print(Berkeley())
    #print(is.na(Berkeley.df))
    #print(is.na(traditional.df))
    #print(is.na(df.size))
    ##END OF DEBUG
    
    size <- ggplot(data=df.size, aes(x=variable, y=value, fill=Design,ymax = max(value))) +
      geom_bar(colour="black", stat="identity",position="dodge") + 
        theme_classic() + theme(legend.title=element_blank()) + theme(legend.position="top") +
          ylab("Estimated Number of Voters") + xlab(" ") +
              scale_fill_manual(values=c("#0000FF", "#00BF00", "#66CC99")) +
                geom_text(data=df.size,aes(x=variable,y=value+max(value)*.02,label=prettyNum(round(value,digits=0),big.mark=",",scientific=FALSE),vjust=0),position=position_dodge(width=1),size=4)
    
    
    df.cost <- subset(df,select=c("Survey Cost","Treatment Cost","Total Cost"))
    df.cost$Design <- c("Traditional Design", "BKS Repeated Design")
    df.cost <- melt(df.cost, id.vars=c("Design"))
    
    cost <- ggplot(data=df.cost, aes(x=variable, y=value, fill=Design,ymax = max(value))) +
      geom_bar(colour="black", stat="identity",position="dodge") +
        theme_classic() + theme(legend.title=element_blank()) +
          theme(legend.position="top") + 
            ylab("Estimated Cost ($)") + xlab(" ") +
                scale_fill_manual(values=c("#0000FF", "#00BF00", "#66CC99")) +
                   geom_text(data=df.cost,aes(x=variable,y=value+max(value)*.02,label=dollar(round(value,digits=0)),vjust=0),
                             position=position_dodge(width=1),size=3.5)
    
  
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(1, 2)))
    print(size, vp = viewport(layout.pos.row = 1,layout.pos.col = 1))
    print(cost, vp = viewport(layout.pos.row = 1,layout.pos.col = 2))
  }) #renderplot

output$design.line1 <-
  renderUI({HTML("<h3>Procedures</h3>")})

output$design.line <- renderUI({
  
  if(input$exp_type!="Canvass")
  {
    HTML("<ol>
      <li> You begin with a list of approximately",prettyNum(round(Berkeley()["n.mailed.survey"]),big.mark=",",scientific=FALSE),"voters to include in the experiment.</li>
      <li> These voters are sent mail inviting them to participate in an online survey. </li>
      <li>",prettyNum(round(Berkeley()["n.respond.presurvey"]),big.mark=",",scientific=FALSE),"voters",paste0("(",Berkeley()["survey.mail.response.rate"]*100,"%)"),"are expected to take this survey.</li>
      <li>",prettyNum(round(Berkeley()["n.mailed.treat"]),big.mark=",",scientific=FALSE),ifelse(Berkeley()["n.treatments"]>1,paste0("(across ",Berkeley()["n.treatments"]," treatment conditions)"),""),"will be randomly assigned to receive persuasion mail.",prettyNum(round(Berkeley()["n.mailed.control"]),big.mark=",",scientific=FALSE),"will be assigned to a control group that receives no mail.</li>
      <li> After the persuasion mail lands, these voters are sent an email inviting them to participate in a follow-up survey.</li>
      <li> The follow-up survey gathers data that allows for the effect of the canvass to be estimated, and a model to be constructed identifying those voters most persuaded.</li>
      ",ifelse(input$n.post.waves>1,"\n <li>Over the course of several weeks, follow-up waves assess to what extent the effects persist. </li>",""),"</ol>")
  } else {
    HTML("<ol>
      <li> You begin by providing a list of approximately",prettyNum(round(Berkeley()["n.mailed.survey"]),big.mark=",",scientific=FALSE),"voters to include in the experiment.</li>
      <li> These voters are sent mail inviting them to participate in an online survey. </li>
      <li> ", prettyNum(round(Berkeley()["n.respond.presurvey"]),big.mark=",",scientific=FALSE),"voters",paste0("(",Berkeley()["survey.mail.response.rate"]*100,"%)"),"are expected to take this survey.</li>
      <li> ", prettyNum(round(Berkeley()["n.mailed.treat"]),big.mark=",",scientific=FALSE),ifelse(Berkeley()["n.treatments"]>1,paste0("(across ",Berkeley()["n.treatments"]," treatment conditions)"),""),"will be randomly assigned to receive persuasion canvass.",prettyNum(round(Berkeley()["n.mailed.control"]),big.mark=",",scientific=FALSE),"will be assigned to a placebo group that receives a canvass on a topic unrelated to the persuasion (e.g., recycling or blood donations). We expect you to contact ", prettyNum(round(Berkeley()["n.treated.condition"]),big.mark=",",scientific=FALSE), " in each group.</li>
      <li> After the canvass, only those voters successfully reached at the door will be sent an email inviting them to participate in a follow-up survey. We expect ", prettyNum(round(Berkeley()["post.treat.n.survey"]/2*(Berkeley()["n.treatments"]+1)),big.mark=",",scientific=FALSE)," responses total.</li>
      <li> The follow-up survey gathers data that allows for the effect of the canvass to be estimated, and a model to be constructed identifying those voters most persuaded.</li>
      ",ifelse(input$n.post.waves>1,"\n <li>Over the course of several weeks, follow-up waves assess to what extent the effects persist. </li>",""),"</ol>")         
  }})

output$additional.assumptions <-
  renderUI({HTML("In addition to the above, this calculator assumes:
                <ul>
                <li>", FIXED.POWER, "statistical power with an alpha of", paste0(FIXED.ALPHA,".")," </li>
                <li> Only one voter per household. Allowing for more voters per household would lower costs by amortizing the cost of mailers across multiple people. </li>
                <li> Phone response rate of", paste0(FIXED.PHONE.RESPONSE*100,"%.")," </li>
                <li> Cost per phone response of", paste0(dollar(FIXED.COST.PHONE),".")," </li>
                <li> To convert from standard deviations to percentage points, we multiply SD by 33.3333 as an approximation. </li>
                </ul>
                 <br>If you have would like us to calculate an experiment with different parameters, or with any feature requests or bugs, please contact us at 
                <a href=experiments@lists.berkeley.edu>experiments@lists.berkeley.edu</a>.<br><br>")})

}

