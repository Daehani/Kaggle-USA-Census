library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)
library(RColorBrewer)
library(maps)


shinyServer(
  function(input, output) {
    pus <- reactive({
      pus <- read.csv("pus_kor.csv")
      
      #DECADE
      pus$DECADE <- factor(pus$DECADE)
      levels(pus$DECADE) <- c("~1950's", "1950's", "1960's", "1970's", "1980's", "1990's", "2000's~")
      
      # ST(State Code)
      pus$ST <- as.factor(pus$ST)
      levels(pus$ST) <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut",
                          "Delaware", "District of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois",
                          "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
                          "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", 
                          "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
                          "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
                          "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia",
                          "Wisconsin", "Wyoming", "Puerto Rico")
      
      # AGEY : 이민 온 당시 나이대
      pus$AGEY <- pus$AGEP - (2013-pus$YOEP) + 2
      pus$AGEG <- rep(0, nrow(pus))
      pus$AGEG <- ifelse(pus$AGEY >= 0 & pus$AGEY < 10, 0, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 10 & pus$AGEY < 20, 1, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 20 & pus$AGEY < 30, 2, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 30 & pus$AGEY < 40, 3, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 40 & pus$AGEY < 50, 4, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 50 & pus$AGEY < 60, 5, pus$AGEG)
      pus$AGEG <- ifelse(pus$AGEY >= 60, 6, pus$AGEG)
      pus$AGEG <- factor(pus$AGEG)
      levels(pus$AGEG) <- c("0's", "10's", "20's", "30's", "40's", "50's", "60's~")
      
      # SEX
      pus$SEX <- factor(pus$SEX)
      levels(pus$SEX) <- c("Male", "Female")
      
      #INDP
      pus$INDP <- ifelse(pus$INDP >= 170 & pus$INDP <= 290, 170, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 370 & pus$INDP <= 490, 370, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 570 & pus$INDP <= 770, 570, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 1070 & pus$INDP <= 3990, 1070, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 4070 & pus$INDP <= 6390, 4070, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 6470 & pus$INDP <= 6780, 6470, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 6870 & pus$INDP <= 7190, 6870, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 7270 & pus$INDP <= 7790, 7270, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 7860 & pus$INDP <= 7890, 7860, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 7970 & pus$INDP <= 8290, 7970, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 8370 & pus$INDP <= 8470, 8370, pus$INDP)
      pus$INDP <- ifelse(pus$INDP %in% c(8660, 8680, 8690), 8370, pus$INDP) 
      pus$INDP <- ifelse(pus$INDP >= 8770 & pus$INDP <= 9290, 8370, pus$INDP)
      pus$INDP <- ifelse(pus$INDP %in% c(8560, 8570, 8580, 8590, 8670), 8560, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 9370 & pus$INDP <= 9590, 9370, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 9670 & pus$INDP <= 9870, 9670, pus$INDP)
      pus$INDP <- ifelse(pus$INDP >= 9920 | is.na(pus$INDP), 9920, pus$INDP)
      pus$INDP <- factor(pus$INDP)
      levels(pus$INDP) <- c("Agriculture, Forestry, Fishing, Hunting", "Mining", "Utilities, Construction", 
                            "Manufacturing", "Trade, Logistic", "Information, Communications", "Finance",
                            "Professional", "Education", "Health", "Other Services",
                            "Arts, Entertainment", "Public Administration", "Military", "Unemployed"
      )
      
      # SCHL
      pus$SCHL <- ifelse(pus$SCHL <= 16, 16, pus$SCHL)
      pus$SCHL <- ifelse(pus$SCHL >= 17 & pus$SCHL <= 19, 19, pus$SCHL)
      pus$SCHL <- factor(pus$SCHL)
      levels(pus$SCHL) <- c("High school or lower", "Some college", "Associate", "Bachelor", "Master", "Professional", "Doctorate")
      
      # COW
      pus$SE <- ifelse(pus$COW %in% c(6, 7), 1, 0)
      pus$SE <- factor(pus$SE)
      levels(pus$SE) <- c("Not Self-employed", "Self-employed")
      
      pus %>% filter(DECADE %in% input$selectDECADE)
    })
    
#Plotting    
    output$plot <- renderPlot({     
      hues <- seq(15, 375, length=4)
      df.color <- hcl(h=hues, l=65, c=100)
          
      if(input$selection == "AGE") {
        if(input$selectAGEP == "pre") {
          ggplot(pus(), aes(AGEP, group=DECADE)) + 
            geom_bar(aes(colour=DECADE, fill=DECADE), binwidth=1, alpha=0.9) +
            scale_x_continuous(breaks=seq(0,100,10), limits=c(0,100)) + 
            scale_y_continuous(breaks=seq(0,250,50), limits=c(0,250)) +
            guides(fill=guide_legend(title="Immigrant Period", size=20)) + guides(colour=FALSE) +
            xlab("Age") + ylab("Count") + ggtitle("Age Distribution by Immigrant Period")
        }
        else {
          ggplot(pus(), aes(x=DECADE)) + 
            geom_bar(aes(fill=AGEG), position="fill") +
            guides(fill=guide_legend(title="Age at Immigration", size=20)) +
            xlab("Immigrant Period") + ylab("Ratio") + ggtitle("Age Group Ratio at Immigration by Immigrant Period")
        }
      }
      
      else if(input$selection == "ST") {
          all_state <- map_data("state")
          data <- as.data.frame(prop.table(table(pus()$ST)))
          data$state <- sort(tolower(c("district of columbia","Puerto Rico", state.name)))
          all_state$freq <- data$Freq[match(all_state$region, data$state)]*100
          
          p <- ggplot(all_state, aes(x=long, y=lat, group=group)) + 
              geom_polygon(aes(fill=freq), colour="gray78") + 
              scale_fill_gradient(name="Proportion(%)", low="white", high="blueviolet")
          p <- p + theme(strip.background = element_blank(),
                         strip.text.x     = element_blank(),
                         axis.text.x      = element_blank(),
                         axis.text.y      = element_blank(),
                         axis.ticks       = element_blank(),
                         axis.line        = element_blank(),
                         panel.background = element_blank(),
                         panel.border     = element_blank(),
                         panel.grid       = element_blank(),
                         legend.position  = "right") +
              xlab("") + ylab("") + ggtitle("Korean Immigrants Living in Proportion of State")
          p 
      }
      
      else if(input$selection == "SEX") {
        ind <- which(levels(pus()$SEX) %in% input$selectSEX)
        hues <- seq(15, 375, length=3+1)
        color <- hcl(h=hues, l=65, c=100)[c(3,1)]
#         color <- scales::alpha(color, 0.3)
#         color[ind] <- scales::alpha(color[ind], 1)
        
        ggplot(pus(), aes(x=DECADE)) + 
          geom_bar(aes(fill=SEX), position="fill") + 
          guides(fill=guide_legend(title="Sex", size=20)) +
          xlab("Immigrant Period") + ylab("Ratio")+ ggtitle("The Sex Ratio by Immigrant Period")
      }
      
      
      else if(input$selection == "INDP") {
        pal <- brewer.pal(n = 7, name = "Set1")
        color <- c(pal[1],"plum1","purple",pal[2],"yellowgreen","orange","firebrick1",pal[3],"dodgerblue","deeppink","seagreen",pal[4],pal[5],pal[6],pal[7])
        ind <- which(levels(pus()$INDP) %in% input$selectINDP)
        color <- scales::alpha(color, 0.1)
        color[ind] <- scales::alpha(color[ind], 1)
        
        ggplot(filter(pus(), DECADE != "~1950's", INDP != "Unemployed"), aes(x = DECADE)) + 
          geom_bar(aes(fill = INDP), position="fill") +
          scale_fill_manual(values = color) + guides(fill=guide_legend(title="Industry", size=20)) +
          xlab("Immigrant Period") + ylab("Ratio") + ggtitle("Industry Ratio by Immigrant Period")
      }
      
      else if(input$selection == "SCHL") {
        color <- c("dodgerblue","deepskyblue","seagreen","yellowgreen","gold","orange","firebrick1")
        ind <- which(levels(pus()$SCHL) %in% input$selectSCHL)
        color <- scales::alpha(color, 0.1)
        color[ind] <- scales::alpha(color[ind], 1)
        
        ggplot(filter(pus(), is.na(SCHL) == F & AGEP >= 35), aes(x=DECADE)) + 
          geom_bar(aes(fill=SCHL), position="fill") + 
          scale_fill_manual(values = color) + guides(fill=guide_legend(title="Education")) +
          xlab("Immigrant Period") + ylab("Ratio") + ggtitle("Final Education by Immigrant Period")
      }
      
      else if(input$selection == "SE") {
        color <- df.color[c(3,1)]
        
        ggplot(pus(), aes(x=DECADE)) + geom_bar(aes(fill=SE), position="fill") +
          guides(fill=guide_legend(title="Work Type", size=20)) +# scale_fill_manual(values = color) +
          xlab("Immigrant Period") + ylab("Ratio") + ggtitle("Self-Emplyment Ratio by Immigrant Period")
      }
      
      else if(input$selection == "PINCP") {
        income.df <- pus() %>% group_by(DECADE, INDP) %>% summarise(INCOME = mean(PINCP), N=n()) %>% replace(is.na(.), 0) %>% filter(DECADE != "~1950's", INDP != "Unemployed")
        income.df$DECADE <- factor(income.df$DECADE)
        income.df$INDP <- factor(income.df$INDP, levels = levels(income.df$INDP)[(length(levels(income.df$INDP))-1):1])
        income.df[, "INCOME"] <- round(income.df[, "INCOME"])
       
        ggplot(income.df, aes(x=DECADE)) + geom_point(aes(y=INDP, size=INCOME, colour=N)) +
          scale_size_continuous(name="Income", range=c(2, 10), breaks=c(min(income.df$INCOME), mean(income.df$INCOME), max(income.df$INCOME)), label=c("100", "50,000", "150,000")) +#, 
          scale_colour_continuous(name="# of Person", low="deepskyblue", high="red") +
          xlab("Immigrant Period") + ylab("Industry") +ggtitle("Avg. Income by Industry and Immigrant Period") + 
          theme_minimal()
      }
    })
        
#Interactive
    output$click_info <- renderPrint({
        income.df <- pus() %>% group_by(DECADE, INDP) %>% summarise(INCOME = mean(PINCP), N=n()) %>% replace(is.na(.), 0) %>% filter(DECADE != "~1950's", INDP != "Unemployed")
        income.df$DECADE <- factor(income.df$DECADE)
        income.df$INDP <- factor(income.df$INDP, levels = levels(income.df$INDP)[(length(levels(income.df$INDP))-1):1])
        income.df[, "INCOME"] <- round(income.df[, "INCOME"])
        
        click.df <- nearPoints(income.df, input$plot_click, threshold = 10, maxpoints = 1)
        as.data.frame(click.df)
    })
    
    
    output$brush_info <- renderPrint({
        income.df <- pus() %>% group_by(DECADE, INDP) %>% summarise(INCOME = mean(PINCP), N=n()) %>% replace(is.na(.), 0) %>% filter(DECADE != "~1950's", INDP != "Unemployed")
        income.df$DECADE <- factor(income.df$DECADE)
        income.df$INDP <- factor(income.df$INDP, levels = levels(income.df$INDP)[(length(levels(income.df$INDP))-1):1])
        income.df[, "INCOME"] <- round(income.df[, "INCOME"])
        
        brush.df <- brushedPoints(income.df, input$plot_brush)
        brush.df %>% arrange(desc(INCOME))
      
        as.data.frame(brush.df)
    })
    
#Summary Table
    output$table <- renderTable({
      if(input$selection == "AGE") { 
        if(input$selectAGEP == "pre") {
            age.df <- pus() %>% group_by(DECADE) %>% summarise(N=n())
            name <- t(age.df)[1,]
            age.df <- as.data.frame(t(age.df))
            names(age.df) <- name
            age.df[2, ]
        }
        else {
            age.df <- pus() %>% group_by(DECADE, AGEG) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
            age.df[, -1] <- data.frame(apply(age.df[, -1], 2, function(x) round(x/sum(x)*100, 1)))
            age.df
        }
      }
      else if(input$selection == "ST") {
          st.df <- pus() %>% group_by(ST) %>% summarise(Count=n()) %>% arrange(desc(Count))
          st.df$Prop <- round(st.df$Count / sum(st.df$Count) * 100, 1)
          head(st.df, 10)
      }
        
      else if(input$selection == "SEX") {
        sex.df <- pus() %>% group_by(DECADE, SEX) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
        sex.df[, -1] <- data.frame(apply(sex.df[, -1], 2, function(x) round(x/sum(x)*100, 1)))
        sex.df
      }
      else if(input$selection == "INDP") {
        indp.df <- pus() %>% filter(is.na(INDP) == F) %>% group_by(DECADE, INDP) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
        indp.df[, -1] <- data.frame(apply(indp.df[, -1], 2, function(x) round(x/sum(x)*100, 1)))
        indp.df %>% filter(INDP %in% input$selectINDP)
      }
      else if(input$selection == "SCHL") {
        schl.df <- pus() %>% group_by(DECADE, SCHL) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
        schl.df[, -1] <- data.frame(apply(schl.df[, -1], 2, function(x) round(x/sum(x)*100, 1)))
        schl.df %>% filter(SCHL %in% input$selectSCHL)
      }
    })
    
#Data Table
    output$dtable <- renderDataTable({
      if(input$selection == "AGE") {
        if(input$selectAGEP == "pre") {
            pus() %>% select(-COW, -POBP, -ANC1P, -RAC2P, -WKHP, -AGEY, -AGEG, -ST)
        }
        else pus() %>% group_by(DECADE, AGEG) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
      }
      else if(input$selection == "SEX") {
        pus() %>% group_by(DECADE, SEX) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
      }
      else if(input$selection == "INDP") {
        pus() %>% filter(is.na(INDP) == F) %>% group_by(DECADE, INDP) %>% summarise(N=n()) %>% spread(DECADE, N) %>% replace(is.na(.), 0)
      }
      else if(input$selection == "SCHL") {
        pus() %>% group_by(DECADE, SCHL) %>% summarise(N=n()) %>% spread(DECADE, N)
      }
      else if(input$selection == "PINCP") {
        df <- pus() %>% filter(is.na(INDP) == F) %>% group_by(DECADE, INDP) %>% summarise(INCOME = mean(PINCP)) %>% spread(DECADE, INCOME) %>% replace(is.na(.), 0)
        df[, -1] <- round(df[, -1])
        df
      }
    })
})