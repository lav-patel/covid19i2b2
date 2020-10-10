ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
set linesize 32000
set pagesize 0  -- No header rows
set trimspool on -- remove trailing blanks
set feedback off
set markup csv on
spool ClinicalCourse.csv
set colsep ','
select SITEID || ',' || DAYS_SINCE_ADMISSION || ',' || NUM_PAT_ALL_CUR_IN_HOSP || ',' || NUM_PAT_EVER_SEVERE_CUR_HOSP from COVID_CLINICAL_COURSE;
spool off;
exit;
