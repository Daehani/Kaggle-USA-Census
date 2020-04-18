library(RSQLite)
library(dplyr)
library(ggplot2)
library(data.table)

## 01. Data
# sqlite에 올려놓은 전체 데이터 추출 
db <- dbConnect(SQLite(), dbname="Census")
pus <- dbGetQuery(db, "SELECT * FROM Population")
WH <- pus[,c("COW","ANC1P","SERIALNO","POBP","WKHP")] # 사용할 변수만 추출

# 한국, 이스라엘, 독일, 멕시코, 스웨덴사람 추출
WH$NATIO <- rep(NA)
WH$NATIO <- ifelse(WH$POBP == 217 & WH$ANC1P ==750, "Korea", WH$NATIO)
WH$NATIO <- ifelse(WH$POBP == 214 & WH$ANC1P == 419, "Israel", WH$NATIO)
WH$NATIO <- ifelse(WH$POBP == 110 & WH$ANC1P == 32, "German", WH$NATIO)
WH$NATIO <- ifelse(WH$POBP == 303 & WH$ANC1P == 210, "Mexico", WH$NATIO)
WH$NATIO <- ifelse(WH$POBP == 136 & WH$ANC1P == 89, "Sweden", WH$NATIO)


## 02. 나라별 주당 근로시간 Boxplot
ggplot(filter(WH, is.na(NATIO)==F) , aes(x= NATIO, y= WKHP)) + geom_boxplot(aes(fill = NATIO), alph= 0.5) +
    stat_summary(fun.y=mean, geom="point", shape=23, size=4) + ggtitle("Working hours per week")
    
# 나라별 주당근로시간 평균
WH %>% 
    group_by(NATIO) %>%
    select(WKHP) %>% 
    summarise(mean(WKHP, na.rm=T))

table(WH$NATIO)

nation <- c("German", "Israel", "Korea", "Mexico")
mean <- c(26.202, 35.904, 39.981, 43.012) 
whr <- data.frame(nation, mean)

mean(WH$WKHP, na.rm= T)

### 자영업자
## 01. Data
WHSE <- filter(pus, COW == 6 | COW == 7)
WHSE$NATIO <- NA
WHSE$NATIO <- ifelse(WHSE$POBP == 217 & WHSE$ANC1P ==750, "Korea", WHSE$NATIO)
WHSE$NATIO <- ifelse(WHSE$POBP == 214 & WHSE$ANC1P == 419, "Israel", WHSE$NATIO)
WHSE$NATIO <- ifelse(WHSE$POBP == 110 & WHSE$ANC1P == 32, "German", WHSE$NATIO)
WHSE$NATIO <- ifelse(WHSE$POBP == 303 & WHSE$ANC1P == 210, "Mexico", WHSE$NATIO)
WHSE$NATIO <- ifelse(WHSE$POBP == 136 & WHSE$ANC1P == 89, "Sweden", WHSE$NATIO)    
table(WHSE$NATIO)                                      

## 02. 나라별 자영업자 주당 근로시간 Boxplot
ggplot(filter(WHSE, is.na(NATIO)==F), aes(x= NATIO, y= WKHP)) + geom_boxplot(aes(fill = NATIO), alph= 0.5) +
    stat_summary(fun.y=mean, geom="point", shape=23, size=4) + ggtitle("Working hours of self-employer per week")

# 나라별 자영업자 평균 주당 근로시간
WHSE %>% 
    group_by(NATIO) %>%
    select(WKHP) %>% 
    summarise(mean(WKHP, na.rm=T))


