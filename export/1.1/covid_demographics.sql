ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
set linesize 32000
set pagesize 0  -- No header rows
set trimspool on -- remove trailing blanks
set feedback off
set markup csv on
spool covid_demographics.csv
set colsep ','
select SITEID || ',' || SEX || ',' || AGE_GROUP || ',' || RACE || ',' || NUM_PATIENTS_ALL || ',' || NUM_PATIENTS_EVER_SEVERE from COVID_DEMOGRAPHICS;
spool off;
exit;
