shinyUI(fluidPage(
  
  titlePanel("Look Over Korean Immigrants Life Style"),
  
  sidebarPanel(
    selectInput("selection", "보고싶은 변수를 선택하세요",
                choices = list("나이" = "AGE",
                               "지역" = "ST",
                               "성별" = "SEX",
                               "최종 학력" = "SCHL",
                               "산업군" = "INDP", 
                               "자영업" = "SE",
                               "임금" = "PINCP"
                               )),
    
    checkboxGroupInput('selectDECADE', "이민 온 년도(10's)",
                       choices = c("1950년대 이전"="~1950's", "1950년대"="1950's", "1960년대"="1960's", "1970년대"="1970's", "1980년대"="1980's", "1990년대"="1990's", "2000년대 이후"="2000's~"),
                       selected = c("~1950's", "1950's", "1960's", "1970's", "1980's", "1990's", "2000's~")
    ),
    
    conditionalPanel(
      condition = "input.selection == 'AGE'",
      radioButtons('selectAGEP', "구분",
                   choices = c("현재 나이"="pre", "이민 온 당시 나이"="imm")
      )
    ),
    
    conditionalPanel(
      condition = "input.selection == 'INDP'",
      checkboxGroupInput('selectINDP', "산업군",
                        choices = c("농수산업"="Agriculture, Forestry, Fishing, Hunting", 
                                    "광업"="Mining", 
                                    "수도전기가스/건설업"="Utilities, Construction", 
                                    "제조업"="Manufacturing", 
                                    "무역/물류"="Trade, Logistic", 
                                    "정보/통신"="Information, Communications", 
                                    "금융"="Finance",
                                    "전문직"="Professional", 
                                    "교육"="Education", 
                                    "의료보건"="Health", 
                                    "기타 서비스업"="Other Services", 
                                    "예술/연예"="Arts, Entertainment", 
                                    "공공행정"="Public Administration", 
                                    "군수업"="Military")
      )
    ),
    
    conditionalPanel(
      condition = "input.selection == 'SCHL'",
      checkboxGroupInput('selectSCHL', '최종 학력',
                         choices = c("고졸이하"="High school or lower", 
                                     "준학사"="Some college", 
                                     "(전문)대학학위"="Associate",
                                     "학사학위"="Bachelor", 
                                     "석사학위"="Master", 
                                     "전문학위"="Professional", 
                                     "박사학위"="Doctorate")
      )
    )
  ),
      
  mainPanel(
    tabsetPanel(type = "tabs",
      tabPanel("Plot",
               plotOutput("plot", height=700, click="plot_click", brush=brushOpts("plot_brush")),#
               br(),
               
               tableOutput("table"),
               
               
               fluidRow(
                 conditionalPanel(
                   condition = "input.selection == 'PINCP'",
                     column(width = 6,
                            h4("Clicked Point"),
                            verbatimTextOutput("click_info")
                     ),
                     column(width = 6,
                            h4("Brushed Point"),
                            verbatimTextOutput("brush_info")
                     )
                 )
               )
               
      ),
      tabPanel("Data", dataTableOutput("dtable"))
    )
  )
))

