/* ���̺귯�� ���� ���� */
options dlcreatedir;
LIBNAME HIRA 'F:/sasuser11/Hira';
%put %sysfunc(pathname(HIRA));


/* 20Table(�������Ȳ) */
/*-------------------------------------------------------------*/
/* 1. ȯ������ : �ܷ�  */
/* -> FOM_CD(�����ڵ�) = 03(�ܰ��ܷ�), 05(ġ���ܷ�), 08(���Ǳ���ܷ�), 11(���Ű��ܷ�), 13(�ѹ�ܷ�) */
/* 2. �ֻ�, �λ��ڵ� : ȣ���(J�� ����)  */
/* -> msick_cd(�ֻ��ڵ�), ssick_cd(�λ��ڵ�) */
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


/* YKIHO(�������Ȳ) */
/*-------------------------------------------------------------*/
/* 1. ����� �Ը� : ���� OR �ǿ� */
/* -> y_jong(�����ڵ�)= 21(����), 31(�ǿ�) */
/* 2. ��ġ : ���� */
/* -> sido_cd(�õ��ڵ�) = 11(����) */
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


/* 20Table YKIHO ���̺� ���� */
/*-------------------------------------------------------------*/
/* 1. key : yno(����� ��üŰ) */
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

 
/* 2012~2014 ���̺� ���� */
/*-------------------------------------------------------------*/
/* �ʿ���� ���ĺ������� ���� */
/* ��縸������(RECU_TO_DD)�� ������ ���� -> ��簳������(RECU_FR_DD)�� ��ȯ�� �߻��� ��¥�� ���� */
/*-------------------------------------------------------------*/
/* ���̺� �������� ���� ���� Type ���� */
/* RECU_FR_DD : ��¥�� -> ������ */
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


/* Ÿ�ٺ��� ���� */	
/*-------------------------------------------------------------*/
/* Ÿ�� ���� : �Ϻ� ���� ȯ�� ��(PATIENT) */
/*-------------------------------------------------------------*/
PROC SQL;
	CREATE TABLE HIRA.PATIENT_2012_2014 AS
	SELECT RECU_FR_DD, PLC_CD_NM, 
		COUNT(*) AS PAT_TOT
	FROM HIRA.NPS_20TABLE_YKIHO_2012_2014
	GROUP BY RECU_FR_DD, PLC_CD_NM;
QUIT;


/* ��ü �⵵ ����(���) */
proc sql;
	create table HIRA.PATIENT_2012_2014_AVG as
	select plc_cd_nm, 
		mean(PAT_TOT) as pat_tot
	from HIRA.PATIENT_2012_2014_AVG
	group plc_cd_nm;
quit;


/* ȯ�ڼ� ���� */
/*-------------------------------------------------------------*/
/* PAT_TOT : ��ü ȯ�ڼ� */
/* PAT_0_10 : 0�� �̻� 10�� �̸� ȯ�� �� */
/* PAT_10_20 : 10�� �̻� 20�� �̸� ȯ�� �� */
/* PAT_20_30 : 20�� �̻� 30�� �̸� ȯ�� �� */
/* PAT_30_40 : 30�� �̻� 40�� �̸� ȯ�� �� */
/* PAT_40_50 : 40�� �̻� 50�� �̸� ȯ�� �� */
/* PAT_50_60 : 50�� �̻� 60�� �̸� ȯ�� �� */
/* PAT_70_end : 70�� �̻� ȯ�� �� */
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
/* ���� ���� : ������ -> ��¥�� */
DATA HIRA.PATIENT_AGE_2012_2014;
	retain year1;
	SET HIRA.PATIENT_AGE_2012_2014;
	year1 = year * 1;
	drop year;
	rename year1 = year;
RUN;
