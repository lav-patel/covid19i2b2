ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
set linesize 32000
set pagesize 0  -- No header rows
set trimspool on -- remove trailing blanks
set feedback off
set markup csv on
spool covid_daily_counts.csv
set colsep ','
select SITEID || ',' || CALENDAR_DATE || ',' || CUMULATIVE_PATIENTS_ALL || ',' || CUMULATIVE_PATIENTS_SEVERE || ',' || CUMULATIVE_PATIENTS_DEAD || ',' || NUM_PAT_IN_HOSP_ON_DATE || ',' || NUM_PAT_IN_HOSPSEVERE_ON_DATE from COVID_DAILY_COUNTS;spool off;
exit;
