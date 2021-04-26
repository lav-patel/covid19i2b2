ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
set linesize 32000
set pagesize 0  -- No header rows
set trimspool on -- remove trailing blanks
set feedback off
set markup csv on
spool Labs-KUMC.csv
set colsep ','
select SITEID || ',' || LOINC || ',' || DAYS_SINCE_ADMISSION || ',' || UNITS || ',' || NUM_PATIENTS_ALL || ',' || MEAN_VALUE_ALL || ',' || STDEV_VALUE_ALL || ',' || MEAN_LOG_VALUE_ALL || ',' || STDEV_LOG_VALUE_ALL || ',' || NUM_PATIENTS_EVER_SEVERE || ',' || MEAN_VALUE_EVER_SEVERE || ',' || STDEV_VALUE_EVER_SEVERE || ',' || MEAN_LOG_VALUE_EVER_SEVERE || ',' || STDEV_LOG_VALUE_EVER_SEVERE from COVID_LABS;
spool off;
exit;
