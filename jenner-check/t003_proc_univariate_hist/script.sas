/* From test.sas: the %summary_m macro (quarterly distribution histogram) and a
   call for 'Filled jobs'. PROC UNIVARIATE HISTOGRAM with a fitted normal curve. */
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

%summary_m(Filled jobs,150000,230000,20000);
