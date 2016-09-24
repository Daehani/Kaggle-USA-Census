library(sqldf)
library(dplyr)
library(data.table)
library(rattle)
library(rpart.plot)
library(RColorBrewer)
library(rpart)
library(stringr)

############################################################
# 01. Data 준비 : Data 생성 및 target 변수 생성
############################################################
## 연속형변수와 명목형 변수를 따로 할당
# c.var : 명목형, i.var : 연속형
c.var <- c('CIT',
           'COW',
           'DDRS',
           'DEAR',
           'DEYE',
           'DOUT',
           'DPHY',
           'DRAT',
           'DRATX',
           'DREM',
           'ENG',
           'FER',
           'GCL',
           'GCM',
           'GCR',
           'HINS1',
           'HINS2',
           'HINS3',
           'HINS4',
           'HINS5',
           'HINS6',
           'HINS7',
           'JWRIP',
           'JWTR',
           'LANX',
           'MAR',
           'MARHD',
           'MARHM',
           'MARHT',
           'MARHW',
           'MARHYP',
           'MIG',
           'MIL',
           'MLPA',
           'MLPB',
           'MLPCD',
           'MLPE',
           'MLPFG',
           'MLPH',
           'MLPI',
           'MLPJ',
           'MLPK',
           'NWAB',
           'NWAV',
           'NWLA',
           'NWLK',
           'NWRE',
           'RELP',
           'SCH',
           'SCHG',
           'SCHL',
           'SEX',
           'WKL',
           'WKW',
           'WRK',
           'ANC',
           'ANC1P',
           'ANC2P',
           'DECADE',
           'DIS',
           'DRIVESP',
           'ESP',
           'ESR',
           'FOD1P',
           'FOD2P',
           'HICOV',
           'HISP',
           'INDP',
           'JWAP',
           'JWDP',
           'LANP',
           'MIGPUMA',
           'MIGSP',
           'MSP',
           'NAICSP',
           'NATIVITY',
           'NOP',
           'OC',
           'OCCP',
           'PAOC',
           'POBP',
           'POWPUMA',
           'POWSP',
           'PRIVCOV',
           'PUBCOV',
           'QTRBIR',
           'RAC1P',
           'RAC2P',
           'RAC3P',
           'RACAIAN',
           'RACASN',
           'RACBLK',
           'RACNH',
           'RACNUM',
           'RACPI',
           'RACSOR',
           'RACWHT',
           'RC',
           'SCIENGP',
           'SCIENGRLP',
           'SFR',
           'SOCP',
           'VPS',
           'WAOB'
)
i.var <- c('SERIALNO',
           'PWGTP',
           'AGEP',
           'CITWP',
           'INTP',
           'JWMNP',
           'OIP',
           'PAP',
           'RETP',
           'SSIP',
           'SSP',
           'WAGP',
           'WKHP',
           'YOEP',
           'PERNP',
           'PINCP',
           'POVPIP','SEMP',
           'SFN'
)

# read data 
cols <- c(c.var, i.var)
path <- "~\\Kaggle-USA-Census"
pusa <- fread(paste(path, "ss13pusa.csv", sep = "\\"), select = cols)
pusb <- fread(paste(path, "ss13pusb.csv", sep = "\\"), select = cols)
pus.all <- bind_rows(pusa, pusb)

# 한국인들만 추출
korea <- subset(pus.all, POBP==217 & RAC3P==8)

# 한국인 중에서 레퍼런스가 0이거나 1인 사람 추출
# (0 : 집 주인, 1 : 배우자)
pus02 <- filter(korea, RELP == "0" | RELP =="1")

# 한국인 남자와 한국인 여자 따로 추출
k_men <- subset(pus02, SEX == 1)
k_women <- subset(pus02, SEX == 2)

# 모든 남자, 여자 추출
u_men <- subset(pus.all,SEX == 1)
u_women <- subset(pus.all, SEX == 2)

# 동성애자 제외
# : 남자끼리 결혼하고 여자끼리 결혼한 사람 제외
#  (시리얼 넘버가 겹치는 사람이 있음. 시리얼넘버는 한 가정에 한 번호가 주어짐)
a <- duplicated(k_men$SERIALNO)
b <- duplicated(k_women$SERIALNO)
gay <- k_men[duplicated(k_men$SERIALNO), 1]
lez <- k_women[duplicated(k_women$SERIALNO), 1]
k_men <- k_men[!a,]
k_women <- k_women[!b,]

# 한국인 여자와 결혼한 외국인 남자 인종 확인
# : 시리얼 넘버가 같고 레퍼런스가 0이거나 1인 남자를 조인
w_marry <- sqldf("select w.*, m.RAC3P RAC3PM
                 from k_women w,u_men m
                 where w.SERIALNO = m.SERIALNO
                 And m.RELP IN (0,1)")
w_marry %>% summarise(count=n_distinct(SERIALNO))

table(w_marry$RAC3PM) # 한국인 여자가 결혼한 배우자의 인종 확인

# 타겟변수 생성
# : 배우자의 인종이 한국인이면 0, 아니면 1
w_marry$TAR <- ifelse(w_marry$RAC3PM == 8,0,1)

############################################################
# 02. 데이터 전처리
############################################################
# 지역 그룹화
table(w_marry$POWSP)
w_marry$POWSP <- ifelse(w_marry$POWSP %in% c(9, 11, 23, 25, 33, 34, 36, 42, 44, 50), "The East", w_marry$POWSP)
w_marry$POWSP <- ifelse(w_marry$POWSP %in% c(2, 4, 15, 53, 6, 41, 32, 30, 56, 49, 8, 35, 16), "The West", w_marry$POWSP)
w_marry$POWSP <- ifelse(w_marry$POWSP %in% c(38, 46, 31,27, 20,19, 29,55,17,18,26,39),
                        "The Midwest", w_marry$POWSP)
w_marry$POWSP <- ifelse(w_marry$POWSP %in% c(48, 40, 5, 22, 28, 21, 47, 1, 13, 24, 10, 54, 51, 37, 45, 12), 
                        "The South", w_marry$POWSP)
w_marry$POWSP <- ifelse(w_marry$POWSP %in% c(251,254), "Asia", w_marry$POWSP)
w_marry$POWSP<- ifelse(w_marry$POWSP %in% c(301, 303,399,555), "The others", w_marry$POWSP)
w_marry$POWSP<-as.factor(w_marry$POWSP)

# 전공 그룹화
w_marry$major<-rep(0,nrow(w_marry))
w_marry$major[str_detect(w_marry$FOD1P,"^11|^13|^36")==1]<-"natural science"
w_marry$major[str_detect(w_marry$FOD1P,"^26|^33|^34|^35|^48|^64")==1]<-"humanities"
w_marry$major[str_detect(w_marry$FOD1P,"^15|^19|^20|^26|^32|^52|^53|^54|^55|^59")==1]<-"social science"
w_marry$major[str_detect(w_marry$FOD1P,"^62")==1]<-"business"
w_marry$major[str_detect(w_marry$FOD1P,"^37|^50")==1]<-"natural science"
w_marry$major[str_detect(w_marry$FOD1P,"^21|^23|^24|^25|^51|^56|^57")==1]<-"engineering"
w_marry$major[str_detect(w_marry$FOD1P,"^14|^22|^38|^41|^60")==1]<-"art"
w_marry$major[str_detect(w_marry$FOD1P,"^61")==1]<-"medical and pharmacy science"
w_marry$major[str_detect(w_marry$FOD1P,"^40")==1]<-"convergence science"
w_marry[w_marry$major==0,]$major<-NA
w_marry$major<-as.factor(w_marry$major)
summary(w_marry$major)

# 산업군 그룹화
w_marry$INDP <- ifelse(w_marry$INDP >= 170 & w_marry$INDP <= 290, 170, w_marry$INDP) # Agriculture, Forestry, Fishing, Hunting
w_marry$INDP <- ifelse(w_marry$INDP >= 370 & w_marry$INDP <= 490, 370, w_marry$INDP) # Mining 
w_marry$INDP <- ifelse(w_marry$INDP >= 570 & w_marry$INDP <= 770, 570, w_marry$INDP) # Utilities, Construction
w_marry$INDP <- ifelse(w_marry$INDP >= 1070 & w_marry$INDP <= 3990, 1070, w_marry$INDP) # Manufacturing
w_marry$INDP <- ifelse(w_marry$INDP >= 4070 & w_marry$INDP <= 6390, 4070, w_marry$INDP)  #, "Logistic, Warehousing", 
w_marry$INDP <- ifelse(w_marry$INDP >= 6470 & w_marry$INDP <= 6780, 6470, w_marry$INDP) # "Information, Communications", 
w_marry$INDP <- ifelse(w_marry$INDP >= 6870 & w_marry$INDP <= 7190, 6870, w_marry$INDP) # "Finance"
w_marry$INDP <- ifelse(w_marry$INDP >= 7270 & w_marry$INDP <= 7790, 7270, w_marry$INDP) # "Professional", 
w_marry$INDP <- ifelse(w_marry$INDP >= 7860 & w_marry$INDP <= 7890, 7860, w_marry$INDP) # "Education", 
w_marry$INDP <- ifelse(w_marry$INDP >= 7970 & w_marry$INDP <= 8290, 7970, w_marry$INDP) # "Health", 
w_marry$INDP <- ifelse(w_marry$INDP >= 8370 & w_marry$INDP <= 8470, 8370, w_marry$INDP) # "Other Services"
w_marry$INDP <- ifelse(w_marry$INDP %in% c(8660, 8680, 8690), 8370, w_marry$INDP) # Other
w_marry$INDP <- ifelse(w_marry$INDP >= 8770 & w_marry$INDP <= 9290, 8370, w_marry$INDP) # Other
w_marry$INDP <- ifelse(w_marry$INDP %in% c(8560, 8570, 8580, 8590, 8670), 8560, w_marry$INDP) # Art, Entertainment
w_marry$INDP <- ifelse(w_marry$INDP >= 9370 & w_marry$INDP <= 9590, 9370, w_marry$INDP) # "Public Administration"
w_marry$INDP <- ifelse(w_marry$INDP >= 9670 & w_marry$INDP <= 9870, 9670, w_marry$INDP) # "Military"
w_marry$INDP <- ifelse(w_marry$INDP == 9920, 9920, w_marry$INDP) # "Unemployed"
w_marry$INDP <- factor(w_marry$INDP)
levels(w_marry$INDP) <- c("Agriculture, Forestry, Fishing, Hunting", "Mining", "Utilities, Construction", 
                          "Manufacturing", "Trade, Logistic", "Information, Communications", "Finance",
                          "Professional", "Education", "Health", "Other Services",
                          "Arts, Entertainment", "Public Administration", "Military", "Unemployed"
)

# 직업 그룹화
w_marry$OCCP <- ifelse(w_marry$OCCP >= 10 & w_marry$OCCP <= 950, 10, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 1005 & w_marry$OCCP <= 1965, 1005, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 2000 & w_marry$OCCP <= 2920, 2000, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 3000 & w_marry$OCCP <= 4650, 3000, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 4700 & w_marry$OCCP <= 4965, 4700, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 5000 & w_marry$OCCP <= 5940, 5000, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 6005 & w_marry$OCCP <= 6130, 6005, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 6200 & w_marry$OCCP <= 6940, 6200, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 7000 & w_marry$OCCP <= 7630, 7000, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 7700 & w_marry$OCCP <= 8965, 7700, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 9000 & w_marry$OCCP <= 9750, 9000, w_marry$OCCP)
w_marry$OCCP <- ifelse(w_marry$OCCP >= 9800 & w_marry$OCCP <= 9830, 9800, w_marry$OCCP)
w_marry$OCCP <- factor(w_marry$OCCP)
levels(w_marry$OCCP) <- c("Management, Business, Financial", "Computer, Engineering, Science", "Education, Legal, Community Service, Arts, Media",
                          "Healthcare", "Sales", "Office, Administrative Support", "Farming, Fishing, Forestry", "Construction, Extraction",
                          "Installation, Maintenance, Repair", "Production", "Transportation", "Unemployed")
# 고용 상태
w_marry$OC <- rep(0,nrow(w_marry))
w_marry$OC[str_detect(w_marry$COW,"^1|^2")==1]<-"private company employee"
w_marry$OC[str_detect(w_marry$COW,"^3|^4|^5")==1]<-"government employee"
w_marry$OC[str_detect(w_marry$COW,"^6|^7")==1]<-"self-employed"
w_marry$OC[str_detect(w_marry$COW,"^8")==1]<-"without pay in family business"
w_marry$OC[str_detect(w_marry$COW,"^9")==1]<-"unemployed"
w_marry[w_marry$OC==0,]$OC<-"never worked"
w_marry$OC<-as.factor(w_marry$OC)

# 학력 범주화
w_marry$SCHL <- ifelse(w_marry$SCHL <= 16, 16, w_marry$SCHL)
w_marry$SCHL <- ifelse(w_marry$SCHL >= 17 & w_marry$SCHL <= 19, 19, w_marry$SCHL)
w_marry$SCHL <- factor(w_marry$SCHL)
levels(w_marry$SCHL) <- c("High school or lower", "Some college", "Associate", "Bachelor", "Master", "Professional", "Doctorate")

# 시민권
table(w_marry$CIT)
w_marry$CIT<-as.factor(w_marry$CIT)
levels(w_marry$CIT)<-c("Born abroad of American parent(s)",
                       "U.S. citizen by naturalization",
                       "Not a citizen of the U.S.")

# 영어 실력
table(w_marry$ENG)
w_marry$ENG<-as.factor(w_marry$ENG)
levels(w_marry$ENG)<-c("Very well","Well","Not well","Not at all")
summary(w_marry$ENG)

# 성별
w_marry$SEX<-as.factor(w_marry$SEX)
levels(w_marry$SEX)<-c("male","female")

# 집에서의 언어 활용
table(w_marry$LANX)
w_marry$LANX<-as.factor(w_marry$LANX)
levels(w_marry$LANX)<-c("speaks another language at home", "speaks only English at home")

# 결혼상태
table(w_marry$MAR)
w_marry$MAR<-as.factor(w_marry$MAR)
levels(w_marry$MAR)<-c("Married")

# 출근시간 범주화
w_marry$JWAP <- ifelse(w_marry$JWAP <= 10, 1 ,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 10 & w_marry$JWAP <=21,2,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 21 & w_marry$JWAP <=33,3,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 33 & w_marry$JWAP <=45,4,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 45 & w_marry$JWAP <=57,5,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 57 & w_marry$JWAP <=69,6,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 69 & w_marry$JWAP <=81,7,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 81 & w_marry$JWAP <=93,8,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 93 & w_marry$JWAP <=105,9,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 105 & w_marry$JWAP <=117,10,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 117 & w_marry$JWAP <=129,11,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 129 & w_marry$JWAP <=141,12,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 141 & w_marry$JWAP <=153,13,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 153 & w_marry$JWAP <=165,14,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 165 & w_marry$JWAP <=177,15,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 177 & w_marry$JWAP <=189,16,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 189 & w_marry$JWAP <=201,17,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 201 & w_marry$JWAP <=213,18,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 213 & w_marry$JWAP <=225,19,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 225 & w_marry$JWAP <=237,20,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 237 & w_marry$JWAP <=249,21,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 249 & w_marry$JWAP <=261,22,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 261 & w_marry$JWAP <=273,23,w_marry$JWAP)
w_marry$JWAP <- ifelse(w_marry$JWAP > 273 & w_marry$JWAP <=285,24,w_marry$JWAP)
w_marry$JWAP <- factor(w_marry$JWAP)

# 퇴근 시간 범주화
w_marry$JWDP <- ifelse(w_marry$JWDP <= 2, 1 ,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 2 & w_marry$JWDP <= 4,2,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 4 & w_marry$JWDP <= 6,3,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 6 & w_marry$JWDP <= 12,4,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 12 & w_marry$JWDP <= 18,5,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 18 & w_marry$JWDP <= 30,6,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 30 & w_marry$JWDP <= 42,7,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 42 & w_marry$JWDP <= 54,8,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 54 & w_marry$JWDP <= 66,9,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 66 & w_marry$JWDP <= 78,10,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 78 & w_marry$JWDP <= 84,11,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 84 & w_marry$JWDP <= 90,12,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 90 & w_marry$JWDP <= 96,13,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 96 & w_marry$JWDP <= 102,14,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 102 & w_marry$JWDP <= 108,15,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 108 & w_marry$JWDP <= 114,16,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 114 & w_marry$JWDP <= 120,17,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 120 & w_marry$JWDP <= 126,18,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 126 & w_marry$JWDP <= 132,19,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 132 & w_marry$JWDP <= 136,20,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 136 & w_marry$JWDP <= 142,21,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 142 & w_marry$JWDP <= 148,22,w_marry$JWDP)
w_marry$JWDP <- ifelse(w_marry$JWDP > 148 & w_marry$JWDP <= 159,23,w_marry$JWDP)
w_marry$JWDP <- factor(w_marry$JWDP)

# 보험
levels(w_marry$HINS5) <- c("Yes", "No")
levels(w_marry$HINS1) <- c("Yes", "No")

# 결혼 횟수
levels(w_marry$MARHT) <- c("One time", "Two times", "Three or more times")

# 군인 변수
w_marry$MIL<-as.factor(w_marry$MIL)
levels(w_marry$MIL)<-c("Now on active duty", "On active duty in the past but not now", 
                       "Only on active duty for training in Reserves/National Guard",
                       "Never served in the military")

# 범주형 범수는 범주로, 연속형 변수는 연속형으로 변환
w_marry[, c.var] <- apply(w_marry[, c.var], 2, as.factor)
w_marry[, i.var] <- apply(w_marry[, i.var], 2, as.integer)
w_marry$TAR <- ifelse(w_marry$RAC3PM == 8,0,1)
w_marry$TAR <- factor(w_marry$TAR)

############################################################
# 03. Modeling - Descision Tree
############################################################
# 최종 변수 선택  
w_marry2 <- select(w_marry, - c(RACAIAN, RACASN,RACBLK,RACNH,RACNUM,RACPI,RACSOR,
                                RACWHT,MAR, RELP, 
                                RAC3PM,SOCP,FOD1P,LANX,
                                POWPUMA, NAICSP, MIGPUMA, LANP,FOD2P, SERIALNO,
                                MARHYP,PWGTP,OCCP,CITWP,MIGSP) 
)

# rpart
fit <- rpart(TAR ~., data=w_marry2, method="class", control = rpart.control(minsplit=2))
rpart.plot(fit)
prp(fit, extra=6,
    box.col=c("pink","skyblue")[fit$frame$yval],
    branch.col=c("purple"), branch.lwd = 1, branch.lty = 8,
    split.font = 4)

############################################################
# 04. Evaluation
############################################################
# Confusion Matrix
w_marry %>% group_by(HINS5) %>%summarise(n=n())
table(w_marry2$TAR)
p <- predict(fit, w_marry2, type= "class")
table(Actual = w_marry2$TAR, Predicted = p)
