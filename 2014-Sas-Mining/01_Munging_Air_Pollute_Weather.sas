LIBNAME AIR 'F:/sasuser11/AIR';

/* Air_Pollute, Weather ���̺� ���� */
/*-------------------------------------------------------------*/
/* Join Key : date, place */
/*-------------------------------------------------------------*/
PROC SQL;
	CREATE TABLE AIR.AIR_POLLUTE_WEATHER_ALL AS
	SELECT * FROM MINING.AIR_POLLUTE AS A LEFT JOIN MINING.WEATHER AS B
	ON A.DATE = B.DATE AND A.PLACE = B.PLACE;
QUIT;


/* �÷��� ��ȯ */
/*-------------------------------------------------------------*/
/* �������� : max_humi -> min_humi */
/* �ְ���� : min_humi -> max_humi */
/*-------------------------------------------------------------*/
DATA AIR.AIR_POLLUTE_WEATHER_ALL;
	RENAME max_humi = min_humi min_humi = max_humi;
	SET AIR.AIR_POLLUTE_WEATHER_ALL;
RUN;


/* ����ġ ó�� */
/*-------------------------------------------------------------*/
/* 1. ���̺� ���� : �� �������� �⵵��, �ֺ�, ������ ��հ� */
/* 2. ����ġ�� �ش� �⵵, �ֺ�, ������ ��հ� �Է� */
/*-------------------------------------------------------------*/
/* ��հ� ���̺� ���� */
proc sql;
	create table AIR.AIR_POLLUTE_WEATHER_AVG as
	select year, month, place,
		mean(NO) as NO,
		mean(O3) as O3,
		mean(CO) as CO,
		mean(SO) as SO,
		mean(PM10) as PM10,
		mean(PM25) as PM25,
		mean(avg_wind_speed) as avg_wind_speed,
		mean(avg_wind_direction) as avg_wind_direction,
		mean(max_wind_speed) as max_wind_speed,
		mean(max_wind_direction) as max_wind_direction,
		mean(temp_max_wind_speed) as temp_max_wind_speed,
		mean(temp_max_wind_direction) as temp_max_wind_direction,
		mean(avg_temp) as avg_temp,
		mean(min_temp) as min_temp,
		mean(max_temp) as max_temp,
		mean(precipi) as precipi,
		mean(avg_humi) as avg_humi,
		mean(min_humi) as min_humi,
		mean(max_humi) as max_humi
	from AIR.AIR_POLLUTE_WEATHER_ALL
	group by year, month, place;
quit;


/* ����ġ �Է� */
proc sql;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set NO = (select NO from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where NO = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set O3 = (select O3 from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where O3 = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set CO = (select CO from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where CO = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set SO  = (select SO  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where SO  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set PM10 = (select PM10 from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where PM10 = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set PM25  = (select PM25 from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where PM25  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set avg_wind_speed  = (select avg_wind_speed  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where avg_wind_speed = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set avg_wind_direction  = (select avg_wind_direction  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where avg_wind_direction  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set max_wind_speed = (select max_wind_speed from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where max_wind_speed = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set max_wind_direction = (select max_wind_direction from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where max_wind_direction = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set temp_max_wind_speed  = (select temp_max_wind_speed  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where temp_max_wind_speed  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set temp_max_wind_direction  = (select temp_max_wind_direction  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where temp_max_wind_direction  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set avg_temp  = (select avg_temp  from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where avg_temp  = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set min_temp   = (select min_temp   from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where min_temp   = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set max_temp   = (select max_temp   from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where max_temp   = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set precipi   = (select precipi   from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where precipi   = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set avg_humi = (select avg_humi   from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where avg_humi   = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set min_humi = (select min_humi    from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where min_humi    = .;
	update AIR.AIR_POLLUTE_WEATHER_ALL as a
		set max_humi   = (select max_humi   from AIR.AIR_POLLUTE_WEATHER_AVG as b
				where a.year = b.year and a.month = b.month and a.place = b.place)
		where max_humi   = .;
quit;


/* �Ļ����� */
/*-------------------------------------------------------------*/
/* �ϱ���(range_temp) : �ְ���(max_temp) - �������(min_temp) */
/* ������(range_humi) : �ְ����(max_humi) - ��������(min_humi) */
/*-------------------------------------------------------------*/
PROC SQL;
	CREATE TABLE AIR.AIR_POLLUTE_WEATHER_ALL AS
	SELECT *, 
		max_temp - min_temp as range_temp,
		max_humi - min_humi as range_humi
	FROM AIR.AIR_POLLUTE_WEATHER_ALL;
RUN;


/* �̻�ġ ���� */
/*-------------------------------------------------------------*/
/* max_temp(�ְ���) < 40 */
/*-------------------------------------------------------------*/
DATA AIR.AIR_POLLUTE_WEATHER_ALL;
	SET AIR.AIR_POLLUTE_WEATHER_ALL;
	IF max_temp < 40;
RUN;

