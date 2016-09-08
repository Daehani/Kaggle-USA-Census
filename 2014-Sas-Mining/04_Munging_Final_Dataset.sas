LIBNAME FINAL 'F:/sasuser11/Final';

/* ���̺� ���� �� ���� ���� */
/*-------------------------------------------------------------*/
/* Join Key : date, place */
/* join : �Ϻ� ���������-���� ���̺�, �Ϻ� ȯ�ڼ�*/
/* ���� ���� : ���Ϻ���(weekday) -> 1:�Ͽ���, 2:������ ... 7:����� */
/*-------------------------------------------------------------*/
/*������ -> ��¥��*/
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
/* ������ ���� */
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


/* Raw Data ���� */
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


/* ������ ���׸�Ʈ ���� */
/*-------------------------------------------------------------*/
/* Segment 1 : ������, ���ϱ�, ������, ���Ǳ�, ������, ���α�, ��õ��, �����, ������, ���빮��,
                  ���۱�, ������, ���빮��, ���ʱ�, ������, ���ϱ�, ���ı�, ��õ��, ��������, ��걸,
                  ����, �߶��� (22��) */
/* Segment 2 : �߱�, ���α�, ������ (3��)*/
/*-------------------------------------------------------------*/
PROC SQL;
      CREATE TABLE FINAL.RAW_S1 AS
      SELECT * FROM final.raw
      WHERE place IN ('������', '���ϱ�', '������', '���Ǳ�', '������', '���α�', '��õ��', '�����', '������', '���빮��',
                              '���۱�', '������', '���빮��', '���ʱ�', '������', '���ϱ�', '���ı�', '��õ��', '��������', '��걸',
                              '����', '�߶���');
QUIT;
PROC SQL;
      CREATE TABLE FINAL.RAW_S2 AS
      SELECT * FROM final.raw
      WHERE place IN ('�߱�', '���α�', '������');
QUIT;


/* ���� ��ȯ */
/*-------------------------------------------------------------*/
/* wind_direction X^2 ��ȯ */
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



/* Lag Time ���� ��ȯ */
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
%DatabyPlace('������', 2); %DatabyPlace('���ϱ�', 3); %DatabyPlace('������', 4); %DatabyPlace('���Ǳ�', 5);
%DatabyPlace('������', 6); %DatabyPlace('���α�', 7); %DatabyPlace('��õ��', 8); %DatabyPlace('�����', 9);
%DatabyPlace('������', 10); %DatabyPlace('���빮��', 11); %DatabyPlace('���۱�', 12); %DatabyPlace('������', 13);
%DatabyPlace('���빮��', 14); %DatabyPlace('���ʱ�', 15); %DatabyPlace('������', 16); %DatabyPlace('���ϱ�', 17);
%DatabyPlace('���ı�', 18); %DatabyPlace('��õ��', 19); %DatabyPlace('��������', 20); %DatabyPlace('��걸', 21);
%DatabyPlace('����', 22); %DatabyPlace('�߶���', 25);


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
%DatabyPlace('������', 1); %DatabyPlace('���α�', 23); %DatabyPlace('�߱�', 24);

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


/* Data ���� */
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


/* �Ͽ��� ���� */
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


/* ������(ȯ�� = 0) ���� */
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
