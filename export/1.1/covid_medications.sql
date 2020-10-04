ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
set linesize 32000
set pagesize 0  -- No header rows
set trimspool on -- remove trailing blanks
set feedback off
set markup csv on
spool covid_medications.csv
set colsep ','
select SITEID || ',' || MED_CLASS || ',' || NUM_PAT_ALL_BEFORE_ADMISSION || ',' || NUM_PAT_ALL_SINCE_ADMISSION || ',' || NUM_PAT_EVER_SEVERE_BEFORE_ADM || ',' || NUM_PAT_EVER_SEVERE_SINCE_ADM from COVID_MEDICATIONS;
spool off;
exit;
