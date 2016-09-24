LIBNAME FINAL 'F:/sasuser11/Final';

/* 테이블 조인 및 변수 생성 */
/*-------------------------------------------------------------*/
/* Join Key : date, place */
/* join : 일별 공기오염도-날씨 테이블, 일별 환자수*/
/* 변수 생성 : 요일변수(weekday) -> 1:일요일, 2:월요일 ... 7:토요일 */
/*-------------------------------------------------------------*/
/*문자형 -> 날짜형*/
data patient_2012_2014_1;
      set hira.patient_2012_2014;
      date = recu_fr_dd * 1 ;
run;
data patient_2012_2014_1;
      set patient_2012_2014_1;
      date1 = input(put( date , 8.), yymmdd8.);
      format date1 date7.;
      drop recu_fr_dd date;
run;
/* 데이터 조인 */
proc sql;
      create table final.raw as
      select A.*, B.pat_tot,
            year(date) as year, month(date) as month, weekday(date) as weekday
      from air.air_pollute_weather_all as A left join hira.patient_2012_2014_1 as B
      on A.date = B.date1 and A.place = B.plc_cd_nm
      where date between '01jan12'D and '31dec14'D;
quit;
data final.raw;
      set final.raw;
      if pat_tot = . then pat_tot = 0;
run;


/* Raw Data 분할 */
/*-------------------------------------------------------------*/
/* Training Set : 2012-01-01 ~ 2014-08-31 */
/* Scoring Set : 2014-09-01 ~ 2014-12-31 */
/*-------------------------------------------------------------*/
PROC SQL;
      CREATE TABLE FINAL.TRAIN AS
      SELECT * FROM FINAL.RAW
      WHERE date between '01jan12'D and '31aug14'D;
RUN;
PROC SQL;
      CREATE TABLE FINAL.SCORE AS
      SELECT * FROM FINAL.RAW
      WHERE date between '01sep14'D and '31dec14'D;
RUN;


/* 데이터 세그먼트 분할 */
/*-------------------------------------------------------------*/
/* Segment 1 : 강동구, 강북구, 강서구, 관악구, 광진구, 구로구, 금천구, 노원구, 도봉구, 동대문구,
                  동작구, 마포구, 서대문구, 서초구, 성동구, 성북구, 송파구, 양천구, 영등포구, 용산구,
                  은평구, 중랑구 (22구) */
/* Segment 2 : 중구, 종로구, 강남구 (3구)*/
/*-------------------------------------------------------------*/
PROC SQL;
      CREATE TABLE FINAL.RAW_S1 AS
      SELECT * FROM final.raw
      WHERE place IN ('강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구', '노원구', '도봉구', '동대문구',
                              '동작구', '마포구', '서대문구', '서초구', '성동구', '성북구', '송파구', '양천구', '영등포구', '용산구',
                              '은평구', '중랑구');
QUIT;
PROC SQL;
      CREATE TABLE FINAL.RAW_S2 AS
      SELECT * FROM final.raw
      WHERE place IN ('중구', '종로구', '강남구');
QUIT;


/* 변수 변환 */
/*-------------------------------------------------------------*/
/* wind_direction X^2 변환 */
/*-------------------------------------------------------------*/
data FINAL.RAW_S1;
      set FINAL.RAW_S1;
      avg_wind_direction_2 = avg_wind_direction ** 2;
      max_wind_direction_2 = max_wind_direction ** 2;
      temp_max_wind_direction_2 = temp_max_wind_direction ** 2;
      drop avg_wind_direction max_wind_direction temp_max_wind_direction;
run;
data FINAL.RAW_S2;
      set FINAL.RAW_S2;
      avg_wind_direction_2 = avg_wind_direction ** 2;
      max_wind_direction_2 = max_wind_direction ** 2;
      temp_max_wind_direction_2 = temp_max_wind_direction ** 2;
      drop avg_wind_direction max_wind_direction temp_max_wind_direction;
run;



/* Lag Time 변수 변환 */
/*-------------------------------------------------------------*/
/* Segment 1 */
%macro DatabyPlace(gu, no);
proc sql;
      create table temp_&no as
      select * from FINAL.RAW_S1
      where place = &gu
      order by date;
quit;
%mend;
%DatabyPlace('강동구', 2); %DatabyPlace('강북구', 3); %DatabyPlace('강서구', 4); %DatabyPlace('관악구', 5);
%DatabyPlace('광진구', 6); %DatabyPlace('구로구', 7); %DatabyPlace('금천구', 8); %DatabyPlace('노원구', 9);
%DatabyPlace('도봉구', 10); %DatabyPlace('동대문구', 11); %DatabyPlace('동작구', 12); %DatabyPlace('마포구', 13);
%DatabyPlace('서대문구', 14); %DatabyPlace('서초구', 15); %DatabyPlace('성동구', 16); %DatabyPlace('성북구', 17);
%DatabyPlace('송파구', 18); %DatabyPlace('양천구', 19); %DatabyPlace('영등포구', 20); %DatabyPlace('용산구', 21);
%DatabyPlace('은평구', 22); %DatabyPlace('중랑구', 25);


%macro var_leg(no);
data temp_&no;
      set temp_&no;
      NO_lag4 = lag4(NO);
      O3_lag4 = lag4(O3);
      CO_lag4 = lag4(CO);
      SO_lag4 = lag4(SO);
      PM10_lag2 = lag2(PM10);
      PM25_lag2 = lag2(PM25);
      avg_wind_speed_lag4 = lag4(avg_wind_speed);
      max_wind_speed_lag5 = lag5(max_wind_speed);
      temp_max_wind_speed_lag5 = lag5(temp_max_wind_speed);
      avg_wind_direction_2_lag2 = lag2(avg_wind_direction_2);
      max_wind_direction_2_lag2 = lag2(max_wind_direction_2);
      temp_max_wind_direction_2_lag2 = lag2(temp_max_wind_direction_2);
      avg_temp_lag5 = lag5(avg_temp);
      min_temp_lag5 = lag5(min_temp);
      max_temp_lag4 = lag4(max_temp);
      range_temp_lag5 = lag5(range_temp);
      avg_humi_lag1 = lag1(avg_humi);
      min_humi_lag5 = lag5(min_humi);
      max_humi_lag2 = lag2(max_humi);
      range_humi_lag4 = lag4(range_humi);
      precipi_lag5 = lag5(precipi);
      drop day NO O3 CO SO PM10 PM25 avg_wind_direction_2 max_wind_direction_2 temp_max_wind_direction_2 avg_wind_speed max_wind_speed temp_max_wind_speed
            avg_temp min_temp max_temp range_temp avg_humi min_humi max_humi range_humi precipi;
run;
%mend;
%var_leg(2);%var_leg(3);%var_leg(4);%var_leg(5);%var_leg(6);%var_leg(7);%var_leg(8);%var_leg(9);
%var_leg(10);%var_leg(11);%var_leg(12);%var_leg(13);%var_leg(14);%var_leg(15);%var_leg(16);%var_leg(17);
%var_leg(18);%var_leg(19);%var_leg(20);%var_leg(21);%var_leg(22);%var_leg(25);
data FINAL.RAW_S1_LAG;
      set temp_2 temp_3 temp_4 temp_5 temp_6 temp_7 temp_8 temp_9 temp_10 temp_11 temp_12 temp_13
            temp_14 temp_15 temp_16 temp_17 temp_18 temp_19 temp_20 temp_21 temp_22 temp_25;
run;


/* Segment 2 */
%macro DatabyPlace(gu, no);
proc sql;
      create table temp_&no as
      select * from FINAL.RAW_S2
      where place = &gu
      order by date;
quit;
%mend;
%DatabyPlace('강남구', 1); %DatabyPlace('종로구', 23); %DatabyPlace('중구', 24);

%macro var_leg(no);
data temp_&no;
      set temp_&no;
      NO_lag4 = lag4(NO);
      O3_lag4 = lag4(O3);
      CO_lag4 = lag4(CO);
      SO_lag1 = lag1(SO);
      PM10_lag1 = lag1(PM10);
      PM25_lag1 = lag1(PM25);
      avg_wind_speed_lag4 = lag4(avg_wind_speed);
      max_wind_speed_lag5 = lag5(max_wind_speed);
      temp_max_wind_speed_lag5 = lag5(temp_max_wind_speed);
      avg_wind_direction_2_lag2 = lag2(avg_wind_direction_2);
      max_wind_direction_2_lag2 = lag2(max_wind_direction_2);
      temp_max_wind_direction_2_lag5 = lag5(temp_max_wind_direction_2);
      avg_temp_lag5 = lag5(avg_temp);
      min_temp_lag4 = lag4(min_temp);
      max_temp_lag4 = lag4(max_temp);
      range_temp_lag2 = lag2(range_temp);
      avg_humi_lag1 = lag1(avg_humi);
      min_humi_lag3 = lag3(min_humi);
      max_humi_lag2 = lag2(max_humi);
      range_humi_lag3 = lag3(range_humi);
      precipi_lag5 = lag5(precipi);
      drop day NO O3 CO SO PM10 PM25 avg_wind_direction_2 max_wind_direction_2 temp_max_wind_direction_2 avg_wind_speed max_wind_speed temp_max_wind_speed
            avg_temp min_temp max_temp range_temp avg_humi min_humi max_humi range_humi precipi;
run;
%mend;
%var_leg(1); %var_leg(23); %var_leg(24);
data FINAL.RAW_S2_LAG;
      set temp_1 temp_23 temp_24;
run;


/* Data 분할 */
/*-------------------------------------------------------------*/
/* Training Set : 2014-01-01 ~ 2014-08-31 */
/* Scoring Set : 2014-09-01 ~ 2014-12-31 */
/*-------------------------------------------------------------*/
%macro partition(data, seg);
PROC SQL;
      CREATE TABLE FINAL.TRAIN_&seg AS
      SELECT * FROM &data
      WHERE date between '01jan12'D and '31aug14'D;
RUN;
PROC SQL;
      CREATE TABLE FINAL.SCORE_&seg AS
      SELECT * FROM &data
      WHERE date between '01sep14'D and '31dec14'D;
RUN;
%mend;
%partition(FINAL.RAW_S1_LAG, S1);
%partition(FINAL.RAW_S2_LAG, S2);


/* 일요일 제거 */
/*-------------------------------------------------------------*/
proc sql;
      create table final.TRAIN_S1 as
      select * from final.TRAIN_S1
      where weekday ^= 1;
quit;
proc sql;
      create table final.TRAIN_S2 as
      select * from final.TRAIN_S2
      where weekday ^= 1;
quit;
proc sql;
      create table final.SCORE_S1 as
      select * from final.SCORE_S1
      where weekday ^= 1;
quit;
proc sql;
      create table final.SCORE_S2 as
      select * from final.SCORE_S2
      where weekday ^= 1;
quit;


/* 공휴일(환자 = 0) 제거 */
/*-------------------------------------------------------------*/
proc sql;
      create table final.TRAIN_S1 as
      select * from final.TRAIN_S1
      where pat_tot ^= 0;
quit;
proc sql;
      create table final.TRAIN_S2 as
      select * from final.TRAIN_S2
      where pat_tot ^= 0;
quit;
