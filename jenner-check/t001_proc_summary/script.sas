/* From test.sas: general data checking of the business employment series.
   PROC SUMMARY with NMISS/MEAN/MEDIAN/MIN/MAX, classed by industry. */
proc summary data=business NMISS MEAN MEDIAN min max PRINT;
class Series_title_2;
var Data_value;
run;
