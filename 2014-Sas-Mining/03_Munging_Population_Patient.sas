LIBNAME AIR 'F:/sasuser11/AIR';
LIBNAME FINAL 'F:/sasuser11/FINAL';

/* Popultaion */
/*-------------------------------------------------------------*/
/* POPLUATION_2012 : 2012년 데이터 */
/* POPLUATION_2013 : 2013년 데이터 */
/* POPLUATION_2014 : 2014년 데이터 */
/* POPLUATION_2012_2014 : 2012 ~ 2014년 데이터 */
/*-------------------------------------------------------------*/
/* 2012 */
proc sql;
	create table AIR.POPULATION_2012 as
	select * 
	from AIR.POPULATION_TOTAL_2012 as to, AIR.POPULATION_FEMALE_2012 as fe
	where to.year = fe.year and to.place = fe.place;
run;
/* 2013 */
proc sql;
	create table AIR.POPULATION_2013 as
	select * 
	from AIR.POPULATION_TOTAL_2013 as to, AIR.POPULATION_FEMALE_2013 as fe
	where to.year = fe.year and to.place = fe.place;
run;
/* 2014 */
proc sql;
	create table AIR.POPULATION_2014 as
	select * 
	from AIR.POPULATION_TOTAL_2014 as to, AIR.POPULATION_FEMALE_2014 as fe
	where to.year = fe.year and to.place = fe.place;
run;
/* 테이블 조인 */
proc sql;
	create table AIR.POPULATION_2012_2014 as
	select * from AIR.POPULATION_2012
	union
	select * from AIR.POPULATION_2013
	union
	select * from AIR.POPULATION_2014;
quit;


/* 테이블 조인 및 변수 생성 */
/*-------------------------------------------------------------*/
/*1. 테이블 조인 : Population, Patient*/
/*2. 변수 생성 : 각 연령대별 인구수 대비 환자수*/
/*-------------------------------------------------------------*/
proc sql;
	create table final.population_patient as
	select *,
		pat.PAT_TOT / pop.age_total as pat_rat_tot,
		PAT_0_10 / age_0_10 as pat_rat_0_10,
		PAT_10_20 / age_10_20 as pat_rat_10_20,
		PAT_20_30 / age_20_30 as pat_rat_20_30,
		PAT_30_40 / age_30_40 as pat_rat_30_40,
		PAT_40_50 / age_40_50 as pat_rat_40_50,
		PAT_50_60 / age_50_60 as pat_rat_50_60,
		PAT_60_70 / age_60_70 as pat_rat_60_70,
		PAT_70_end / age_70_end as pat_rat_70_end
	from air.population_age as pop, hira.patient_age_2012_2014 as pat
	where pop.year = pat.year and pop.place = pat.plc_cd_nm;
quit;
data final.population_patient;
	set final.population_patient;
	drop plc_cd_nm;
run;


/* 전체 년도 평균 테이블 */
/*-------------------------------------------------------------*/
proc sql;
	create table final.population_patient_avg as
	select place,
		mean(age_total) as avg_age_total,
		mean(age_0_10) as avg_age_0_10,
		mean(age_10_20) as avg_age_10_20,
		mean(age_20_30) as avg_age_20_30,
		mean(age_30_40) as avg_age_30_40,
		mean(age_40_50) as avg_age_40_50,
		mean(age_50_60) as avg_age_50_60,
		mean(age_60_70) as avg_age_60_70,
		mean(age_70_end) as avg_age_70_end,
		mean(PAT_TOT) as avg_PAT_TOT,
		mean(PAT_0_10) as avg_PAT_0_10,
		mean(PAT_10_20) as avg_PAT_10_20,
		mean(PAT_20_30) as avg_PAT_20_30,
		mean(PAT_30_40) as avg_PAT_30_40,
		mean(PAT_40_50) as avg_PAT_40_50,
		mean(PAT_50_60) as avg_PAT_50_60,
		mean(PAT_60_70) as avg_PAT_60_70,
		mean(PAT_70_end) as avg_PAT_70_end,
		mean(pat_rat_tot) as avg_pat_rat_tot,
		mean(pat_rat_0_10) as avg_pat_rat_0_10,
		mean(pat_rat_10_20) as avg_pat_rat_10_20,
		mean(pat_rat_20_30) as avg_pat_rat_20_30,
		mean(pat_rat_30_40) as avg_pat_rat_30_40,
		mean(pat_rat_40_50) as avg_pat_rat_40_50,
		mean(pat_rat_50_60) as avg_pat_rat_50_60,
		mean(pat_rat_60_70) as avg_pat_rat_60_70,
		mean(pat_rat_70_end) as avg_pat_rat_70_end
	from final.population_patient
	group by place;
quit;
