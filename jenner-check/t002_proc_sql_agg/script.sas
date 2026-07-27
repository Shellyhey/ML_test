/* Sample 'business' dataset for the captured run — synthesized to match the
   columns and category values that test.sas reads from the StatsNZ business
   employment CSV (Group, Series_title_1..3, Series_title_2 industry, period,
   Data_value). Real StatsNZ figures are not shipped; these are illustrative. */
data business;
  length Group $60 Series_title_1 $40 Series_title_2 $60 Series_title_3 $30;
  format period yyyymmn6.;
  infile datalines dsd truncover;
  input Group $ Series_title_1 $ Series_title_2 $ Series_title_3 $ period :yymmn6. Data_value;
datalines4;
Industry by employment variable,Filled jobs,Health Care and Social Assistance,Actual,201603,210000
Industry by employment variable,Filled jobs,Health Care and Social Assistance,Actual,201612,215500
Industry by employment variable,Filled jobs,Health Care and Social Assistance,Actual,201703,221000
Industry by employment variable,Filled jobs,Health Care and Social Assistance,Actual,201712,228000
Industry by employment variable,Filled jobs,Professional Scientific and Technical Services,Actual,201603,180000
Industry by employment variable,Filled jobs,Professional Scientific and Technical Services,Actual,201612,184000
Industry by employment variable,Filled jobs,Professional Scientific and Technical Services,Actual,201703,189000
Industry by employment variable,Filled jobs,Professional Scientific and Technical Services,Actual,201712,193500
Industry by employment variable,Filled jobs,Retail Trade,Actual,201603,205000
Industry by employment variable,Filled jobs,Retail Trade,Actual,201612,208000
Industry by employment variable,Filled jobs,Retail Trade,Actual,201703,209500
Industry by employment variable,Filled jobs,Retail Trade,Actual,201712,211000
Industry by employment variable,Total earnings,Health Care and Social Assistance,Actual,201612,4200
Industry by employment variable,Total earnings,Health Care and Social Assistance,Actual,201712,4500
Industry by employment variable,Total earnings,Retail Trade,Actual,201612,3100
Industry by employment variable,Total earnings,Retail Trade,Actual,201712,3300
Industry by employment variable,Filled jobs,Total Industry,Actual,201612,900000
Industry by employment variable,Total earnings,Total Industry,Actual,201712,58000
;;;;
run;

/* From test.sas (question 3_1): average filled jobs per industry via PROC SQL,
   mean() aggregate with a formatted alias, grouped and ordered by the average. */
proc sql;
create table question3_1 as
select  Series_title_2,mean(Data_value) as avg_d format 9.2
from business
where group = 'Industry by employment variable'
and Series_title_1 = 'Filled jobs'
and Series_title_3 = 'Actual'
group by Series_title_2
order by 2 desc
;
quit;
proc print data=question3_1; run;
