/* From test.sas (question 5_1): average earnings per industry, then the
   "Bar Chart of average earnings for each industries" via PROC SGPLOT VBAR. */
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

proc sgplot data = question5_1_avg;
title height=14pt "Bar Chart of average earnings for each industries";
    vbar Series_title_2/response=avg_jobs groupdisplay=cluster
    datalabel   categoryorder=respdesc;
  xaxis display=(nolabel);
  yaxis grid;
quit;
