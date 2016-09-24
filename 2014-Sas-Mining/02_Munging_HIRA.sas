/* 라이브러리 폴더 생성 */
options dlcreatedir;
LIBNAME HIRA 'F:/sasuser11/Hira';
%put %sysfunc(pathname(HIRA));


/* 20Table(요양기관현황) */
/*-------------------------------------------------------------*/
/* 1. 환자유형 : 외래  */
/* -> FOM_CD(서식코드) = 03(외과외래), 05(치과외래), 08(보건기관외래), 11(정신과외래), 13(한방외래) */
/* 2. 주상병, 부상병코드 : 호흡기(J로 시작)  */
/* -> msick_cd(주상병코드), ssick_cd(부상병코드) */
/*-------------------------------------------------------------*/
/* 2012 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_2012 AS
	SELECT * FROM MINING.NPS_200TABLE_2012
	WHERE FOM_CD IN('03', '05', '08', '11', '13')
	AND (msick_cd LIKE 'J%' OR ssick_cd LIKE 'J%');
RUN;
/* 2013 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_2013 AS
	SELECT * FROM MINING.NPS_200TABLE_2013
	WHERE FOM_CD IN ('03', '05', '08', '11', '13')
	AND (msick_cd LIKE 'J%' OR ssick_cd LIKE 'J%');
RUN;
/* 2014 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_2014 AS
	SELECT * FROM MINING.SAMPLE_NPS_2014_20
	WHERE FOM_CD IN ('03', '05', '08', '11', '13')
	AND (msick_cd LIKE 'J%' OR ssick_cd LIKE 'J%');
RUN;


/* YKIHO(요양기관현황) */
/*-------------------------------------------------------------*/
/* 1. 요양기관 규모 : 병원 OR 의원 */
/* -> y_jong(종별코드)= 21(병원), 31(의원) */
/* 2. 위치 : 서울 */
/* -> sido_cd(시도코드) = 11(서울) */
/*-------------------------------------------------------------*/
/* 2012 */
PROC SQL;
	CREATE TABLE HIRA.YKIHO_2012 AS
	SELECT * FROM MINING.SAMPLING_NPS_SAS_YKIHO_2012_MOD
	WHERE y_jong IN('21', '31')
	AND sido_cd = '11';
RUN;
/* 2013 */
PROC SQL;
	CREATE TABLE HIRA.YKIHO_2013 AS
	SELECT * FROM MINING.SAMPLING_NPS_SAS_YKIHO_2013
	WHERE y_jong IN('21', '31')
	AND sido_cd = '11';
RUN;
/* 2014 */
PROC SQL;
	CREATE TABLE HIRA.YKIHO_2014 AS
	SELECT * FROM MINING.SAMPLING_NPS_SAS_YKIHO_2014
	WHERE y_jong IN('21', '31')
	AND sido_cd = '11';
RUN;


/* 20Table YKIHO 테이블 조인 */
/*-------------------------------------------------------------*/
/* 1. key : yno(요양기관 대체키) */
/*-------------------------------------------------------------*/
/* 2012 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_YKIHO_2012 AS
	SELECT A.*, B.*
	FROM HIRA.NPS_20TABLE_2012 A, HIRA.YKIHO_2012 B
	WHERE A.yno = B.yno;
RUN;
/* 2013 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_YKIHO_2013 AS
	SELECT A.*, B.*
	FROM HIRA.NPS_20TABLE_2013 A, HIRA.YKIHO_2013 B
	WHERE A.yno = B.yno;
RUN;
/* 2014 */
PROC SQL;
	CREATE TABLE HIRA.NPS_20TABLE_YKIHO_2014 AS
	SELECT A.*, B.* 
	FROM HIRA.NPS_20TABLE_2014 A, HIRA.YKIHO_2014 B
	WHERE A.yno = B.yno;
RUN;

 
/* 2012~2014 테이블 조인 */
/*-------------------------------------------------------------*/
/* 필요없는 사후변수들은 제거 */
/* 요양만료일자(RECU_TO_DD)는 공란이 존재 -> 요양개시일자(RECU_FR_DD)를 질환이 발생한 날짜로 결정 */
/*-------------------------------------------------------------*/
/* 테이블 조인으로 인한 변수 Type 변경 */
/* RECU_FR_DD : 날짜형 -> 문자형 */
DATA HIRA.nps_20TABLE_YKIHO_2014;
	SET HIRA.nps_20TABLE_YKIHO_2014;
	RECU_FR_DD2 = PUT(recu_fr_dd, YYMMDDn8.);
	DROP recu_fr_dd;
	RENAME RECU_FR_DD2 = RECU_FR_DD;
RUN;

%LET var = RECU_FR_DD PLC_CD_NM DGSBJT_CD PAT_AGE
		SEX_TP_CD SOPR_YN ORG_DF BED_GRADE MSICK_CD SSICK_CD;
DATA HIRA.NPS_20TABLE_YKIHO_2012_2014;
	RETAIN &var;
	SET HIRA.NPS_20TABLE_YKIHO_2012 HIRA.NPS_20TABLE_YKIHO_2013 
		HIRA.NPS_20TABLE_YKIHO_2014;
	KEEP &var;
RUN;


/* 타겟변수 생성 */	
/*-------------------------------------------------------------*/
/* 타겟 변수 : 일별 구별 환자 수(PATIENT) */
/*-------------------------------------------------------------*/
PROC SQL;
	CREATE TABLE HIRA.PATIENT_2012_2014 AS
	SELECT RECU_FR_DD, PLC_CD_NM, 
		COUNT(*) AS PAT_TOT
	FROM HIRA.NPS_20TABLE_YKIHO_2012_2014
	GROUP BY RECU_FR_DD, PLC_CD_NM;
QUIT;


/* 전체 년도 집계(평균) */
proc sql;
	create table HIRA.PATIENT_2012_2014_AVG as
	select plc_cd_nm, 
		mean(PAT_TOT) as pat_tot
	from HIRA.PATIENT_2012_2014_AVG
	group plc_cd_nm;
quit;


/* 환자수 집계 */
/*-------------------------------------------------------------*/
/* PAT_TOT : 전체 환자수 */
/* PAT_0_10 : 0세 이상 10세 미만 환자 수 */
/* PAT_10_20 : 10세 이상 20세 미만 환자 수 */
/* PAT_20_30 : 20세 이상 30세 미만 환자 수 */
/* PAT_30_40 : 30세 이상 40세 미만 환자 수 */
/* PAT_40_50 : 40세 이상 50세 미만 환자 수 */
/* PAT_50_60 : 50세 이상 60세 미만 환자 수 */
/* PAT_70_end : 70세 이상 환자 수 */
/*-------------------------------------------------------------*/
PROC SQL;
	CREATE TABLE HIRA.PATIENT_AGE_2012_2014 AS
	SELECT SUBSTR(RECU_FR_DD, 1, 4) AS year, PLC_CD_NM, 
		COUNT(*) AS PAT_TOT,
		SUM(CASE WHEN 0 <= PAT_AGE < 10 THEN 1 ELSE 0 END) AS PAT_0_10,
		SUM(CASE WHEN 10 <= PAT_AGE < 20 THEN 1 ELSE 0 END) AS PAT_10_20,
		SUM(CASE WHEN 20 <= PAT_AGE < 30 THEN 1 ELSE 0 END) AS PAT_20_30,
		SUM(CASE WHEN 30 <= PAT_AGE < 40 THEN 1 ELSE 0 END) AS PAT_30_40,
		SUM(CASE WHEN 40 <= PAT_AGE < 50 THEN 1 ELSE 0 END) AS PAT_40_50,
		SUM(CASE WHEN 50 <= PAT_AGE < 60 THEN 1 ELSE 0 END) AS PAT_50_60,
		SUM(CASE WHEN 60 <= PAT_AGE < 70 THEN 1 ELSE 0 END) AS PAT_60_70,
		SUM(CASE WHEN 70 <= PAT_AGE THEN 1 ELSE 0 END) AS PAT_70_end
	FROM HIRA.NPS_20TABLE_YKIHO_2012_2014
	GROUP BY year, PLC_CD_NM;
QUIT;
/* 연도 변수 : 문자형 -> 날짜형 */
DATA HIRA.PATIENT_AGE_2012_2014;
	retain year1;
	SET HIRA.PATIENT_AGE_2012_2014;
	year1 = year * 1;
	drop year;
	rename year1 = year;
RUN;
