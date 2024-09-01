
/*
<HEADER>
|----------------------------------------------------------------------------------------------
|
| Program:        write off
| Technician:     Shelly He
| Requestor:       
| Written:        29/08/2024 
| Description:    write off
| KeyWord:         
|
|
|----------------------------------------------------------------------------------------------
| Amendment History
| =================
| ---Date---  --------- By ---------- ----------------------Description------------------------
| DD/MM/YYYY  <Name>                  : 
|29/08/2024   Shelly He			        Created
| 
|
|----------------------------------------------------------------------------------------------
</HEADER>
*/
    	%let ENV_ID = PROD;
		%let BIW_SERVER = BIDWPROD;
		%let BIW_DATABASE = BIW;

	
  
/*----------------------------------------------------------------------------------------------
| Set-up
----------------------------------------------------------------------------------------------*/

/* Libraries / Paths */

   %let home = \\saklfile2\Marketing Grps\SECURE\Analytics and Insight\Conduct\Remediation\SDR;

  %let SDR = &home\SDR93643 - REM202210 - Business Incorrect UOD;


filename foo1 "&SDR\Data\new\business-financial-data-march-2024-csv.csv" lrecl=50000 ;

proc import 
  datafile=foo1
  out=finacial
  dbms=csv 
  replace ;
  guessingrows=max;
run;


filename foo2 "&SDR\Data\new\machine-readable-business-employment-data-mar-2024-quarter.csv" lrecl=50000 ;

proc import 
  datafile=foo2
  out=business 
  dbms=csv 
  replace ;
  guessingrows=max;
run;


/*general data checking */
proc summary data=finacial NMISS MEAN MEDIAN min max PRINT;
/*by Series_title_2;*/
class Series_title_2;
var Data_value;
run;



proc summary data=business NMISS MEAN MEDIAN min max PRINT;
class Series_title_2;
var Data_value;
run;


proc sql;
create table question1 as 
select distinct Series_title_2 from finacial
 where   Series_title_1 = 'Salaries and wages'
   and put(period,yyyymm7.)  contains ('2016')  
order by 1 desc
;
quit;





/*question 1 "Retail Trade" with 194053.71 */
proc sql;
create table question1 as 
select distinct Series_title_2,
mean(Data_value) as avg format 12.2
from business
where group = ('Industry by employment variable')
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
and Series_title_2 not in ('Total Industry')
and Series_title_2 not in 
(select distinct Series_title_2 from finacial
 where   Series_title_1 = 'Salaries and wages'
   and put(period,yyyymm7.)  contains ('2016')   )
group by Series_title_2
order by 2 desc

;
quit;






/*question 2 : 2023.03 with 38810.022 for  Wholesale Trade */
proc sql;
create table question2 as 
SELECT period ,Series_title_2,Data_value FROM finacial 
     where Data_value =
           (SELECT MAX(Data_value) FROM finacial 
              where Group = 'Industry by financial variable (NZSIOC Level 2)'
            and  Series_title_1 = 'Sales (operating income)'
            and Series_title_4 = 'Seasonally adjusted'
            and Data_value not in (SELECT MAX(Data_value) FROM finacial
                where Group = 'Industry by financial variable (NZSIOC Level 2)'
                and  Series_title_1 = 'Sales (operating income)'
                and Series_title_4 = 'Seasonally adjusted' )
             )
          and  Group = 'Industry by financial variable (NZSIOC Level 2)'
          and  Series_title_1 = 'Sales (operating income)'
          and Series_title_4 = 'Seasonally adjusted'
;
quit;



/*question 3*/
proc sql;
create table question3_1 as 
select  Series_title_2,mean(Data_value) as avg_d format 9.2
from business
where group = 'Territorial authority by employment variable'
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
group by Series_title_2
order by 2 desc
;
quit;

proc sql;
create table question3_2 as 
select  period,data_value
from business
where Series_title_2 in  (select  Series_title_2 from question3_1
where avg_d = (select max(avg_d) from question3_1 )) 
and group = 'Territorial authority by employment variable'
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
;
quit;

/*total 34995011*/
proc sql;
create table question3_3 as 
SELECT
  A.period,
  (
    SELECT SUM (B.data_value)
    FROM  question3_2 B
    WHERE    B.period <= A.period
  ) as data_value
FROM  question3_2 A
;
quit;

/*question 4 : 

preparation: data imputation
missing data manipulation

*/







/*question 5 : summary about Total earnings*/

%macro summary_m(var,min,max,by_v);
title "quarterly distribution about &var";
proc univariate data=business(where=  (Group  in  ('Industry by employment variable')
and  Series_title_2 not in ('Total Industry')
and Series_title_1 = "&var"
and Series_title_3 = 'Actual'
)) noprint;
 histogram Data_value
 / 
 normal ( 
 mu = est
 sigma = est
 color = blue
 w = 2.5 
 )
barlabel=percent
 midpoints = &min to &max by &by_v;
run;
%mend summary_m;

%summary_m(Total earnings,115,5900,150);

%summary_m(Filled jobs,5000,273500,15000);







/*question 5_1 : Total earnings*/

proc sql;
create table question5_1_avg as 
select distinct Series_title_2
,AVG(Data_value) as avg_jobs format 7.2
from business
where Group  in  ('Industry by employment variable')
and Series_title_2 not in ('Total Industry')
and Series_title_1 = 'Total earnings'
and Series_title_3 = 'Actual'
group by Series_title_2
order by 1 
;
quit;



/**/
/* "Bar Chart of average earnings for each industries"*/

proc sgplot data = question5_1_avg;
title height=14pt "Bar Chart of average earnings for each industries";
    vbar Series_title_2/response=avg_jobs groupdisplay=cluster 
    datalabel   categoryorder=respdesc;
  xaxis display=(nolabel);
  yaxis grid;
quit;



proc sql;
create table question5_1 as 
select distinct Series_title_2
,period
,put(period,yyyymm7.) as year_end
,Data_value
from business
where Group  in  ('Industry by employment variable')
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
and put(period,yyyymm7.)  like ('%12')
order by 1 
;
quit;



/*smooth the Filled jobs value*/

proc expand data=question5_1 out=smoothed  ;
by Series_title_2;
id period;
convert Data_value=smooth / transform=(ewma 0.1);
run;




title1 "Yearly Filled jobs Trend Statistics";
proc sgplot data=smoothed(where= (Series_title_2 = 'Professional, Scientific and Technical Services'));
series x=period y=smooth / lineattrs=(pattern=solid);
series x=period y=Data_value / lineattrs=(pattern=solid);
yaxis display=(nolabel);
format period yyyymm7.;
run;


proc timeseries data=question5_1
out=timeseries;
by Series_title_2;
id period interval=year accumulate=total;
var Data_value;
run;



/*question 5_2 : Total earnings*/

proc sql;
create table question5_2 as 
select distinct substr(put(period,yyyymm7.),1,4) as year
,Series_title_2
,sum(Data_value) as year_earnings
from business
where Series_title_2  in 
 (select Series_title_2 from finacial  )
and Series_title_1 = 'Total earnings'
and Series_title_3 = 'Actual'
and substr(put(period,yyyymm7.),1,4) not in ('2011','2024')
group by substr(put(period,yyyymm7.),1,4),Series_title_2

order by 2,1
;
quit;



title1 "Yearly Earnings Trend Statistics";
proc sgplot data=question5_2(where= (Series_title_2 = 'Health Care and Social Assistance'));
series x=year y=year_earnings / lineattrs=(pattern=solid);
yaxis display=(nolabel);
run;


/*question 5_3 : Seasonally adjusted Filled jobs for area*/

proc sql;
create table question5_3 as 
select distinct Series_title_2
,avg(Data_value) as avg_d
from business
where Group  in  ('Industry by employment variable')
and Series_title_2 not in ('Total Industry')
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Seasonally adjusted'
and put(period,yyyymm7.)  like ('%12')
group by Series_title_2
order by 1 
;
quit;


title1 "average Filled jobs Trend Statistics from area";
proc sgplot data=question5_3;
series x=Series_title_2 y=avg_d / lineattrs=(pattern=solid);
yaxis display=(nolabel);
run;



/*question 5_4 : filled jobs for gender*/

proc sql;
create table question5_4 as 
select distinct Series_title_2
,period
,put(period,yyyymm7.) as year_end
,Data_value
from business
where Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
and put(period,yyyymm7.)  like ('%12')
and group = 'Sex by employment variable'
order by 1 
;
quit;


title1 "Yearly Filled jobs Trend Statistics from gender";
proc sgplot data=question5_4;
series x=year_end y=Data_value / lineattrs=(pattern=solid);
series x=year_end y=Data_value / lineattrs=(pattern=solid);
yaxis display=(nolabel);
run;



/*question 5_5 : filled jobs from age*/

proc sql;
create table question5_5 as 
select distinct Series_title_2
,period
,put(period,yyyymm7.) as year_end
,Data_value
from business
where Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
and put(period,yyyymm7.)  like ('%12')
and group = 'Age by employment variable'
order by 1 
;
quit;


title1 "Yearly Filled jobs Trend Statistics from gender";
proc sgplot data=question5_5;
series x=year_end y=Data_value / lineattrs=(pattern=solid);
yaxis display=(nolabel);
run;


/*question 5_6 : filled jobs from age*/

proc sql;
create table question5_6 as 
select distinct Series_title_2
,AVG(Data_value) AS avg_jobs
from business
where Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
and group = 'Age by employment variable'
group by Series_title_2
order by 1 
;
quit;


title1 "pie chart for age prospective";
proc gchart data=question5_6;
    pie Series_title_2/ sumvar=avg_jobs explode='25-29'
       plabel=(h=1.2 color=black);
run;
quit;



/*question 5_predict :Filled jobs*/

proc sql;
create table question5_predict as 
select distinct Series_title_2
,period format yyyymm7.
,Data_value
,log(Data_value) as Ylog
from business
where Group  in  ('Industry by employment variable')
and Series_title_2 not in ('Total Industry')
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
order by 4;
quit;


%summary_m(Filled jobs,5000,273500,15000);


proc sgplot data=question5_predict(where= (Series_title_2 = 'Health Care and Social Assistance'));
series x=period y=Ylog / lineattrs=(pattern=solid);
yaxis display=(nolabel);
format period yyyymm7.;
run;




proc forecast data=question5_predict(where= (Series_title_2 = 'Health Care and Social Assistance'))
interval=QTR
method=stepar seasons=QTR lead=12
out=out1 outfull outresid outest=est1;
id period;
var Ylog;
where period > 2016.06;
run;





