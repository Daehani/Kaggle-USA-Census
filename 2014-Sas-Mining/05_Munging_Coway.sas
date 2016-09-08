LIBNAME Coway 'F:/sasuser11/Coway';

/* 서울 건만 추출 */
PROC SQL;
   CREATE TABLE Coway.IAQ_DATA_SEOUL AS 
   SELECT * FROM MINING.IAQ_DATA
   WHERE address1 like '서울시%' ;
QUIT;

/* 데이터 선택 및 형식 변경 */
data Coway.IAQ_DATA_SEOUL;
   set Coway.IAQ_DATA_SEOUL;
   date = input(put( dt , 8.), yymmdd8.);
   place = substr(address1,8,13);
   format date yymmdd10.;
   keep dev_id cus_id date place msr_pm10_val msr_pm_25_val type;
  run;

/*  변수 선택 */
/* 미세먼지:PM_10, 초미세먼지(PM_25) */
proc sql;
	create table coway.iaq_data_seoul_avg as
	select dev_id, cus_id, date, place, type,
		mean(msr_pm10_val) as in_PM10, mean(msr_pm_25_val) as in_PM25
	from coway.iaq_data_seoul
	group by dev_id, cus_id, date, place, type;
run;

/* 외부 공기질 테이블과 테이블 조인 */
proc sql;
	create table Coway.IOAQ_DATA_SEOUL as
	select A.*, B.PM10 as out_PM10, B.PM25 as out_PM25  
	from COWAY.IAQ_DATA_SEOUL_AVG as A left join AIR.AIR_POLLUTE_WEATHER_ALL as B
	on A.date = B.date and A.place = B.place;
quit;
