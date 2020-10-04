set -x

sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_clinical_course.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_daily_counts.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_demographics.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_diagnoses.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_labs.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_medications.sql


sed -i 1i"SITEID,DAYS_SINCE_ADMISSION,NUM_PAT_ALL_CUR_IN_HOSP,NUM_PAT_EVER_SEVERE_CUR_HOSP" covid_clinical_course.sql
sed -i 1i"SITEID,CALENDAR_DATE,CUMULATIVE_PATIENTS_ALL,CUMULATIVE_PATIENTS_SEVERE,CUMULATIVE_PATIENTS_DEAD,NUM_PAT_IN_HOSP_ON_DATE,NUM_PAT_IN_HOSPSEVERE_ON_DATE" covid_daily_counts.sql
sed -i 1i"SITEID,SEX,AGE_GROUP,RACE,NUM_PATIENTS_ALL,NUM_PATIENTS_EVER_SEVERE" covid_demographics.sql
sed -i 1i"SITEID,ICD_CODE_3CHARS,ICD_VERSION,NUM_PAT_ALL_BEFORE_ADMISSION,NUM_PAT_ALL_SINCE_ADMISSION,NUM_PAT_EVER_SEVERE_BEFORE_ADM,NUM_PAT_EVER_SEVERE_SINCE_ADM" covid_diagnoses.sql
sed -i 1i"SITEID,LOINC,DAYS_SINCE_ADMISSION,UNITS,NUM_PATIENTS_ALL,MEAN_VALUE_ALL,STDEV_VALUE_ALL,MEAN_LOG_VALUE_ALL,STDEV_LOG_VALUE_ALL,NUM_PATIENTS_EVER_SEVERE,MEAN_VALUE_EVER_SEVERE,STDEV_VALUE_EVER_SEVERE,MEAN_LOG_VALUE_EVER_SEVERE,STDEV_LOG_VALUE_EVER_SEVERE" covid_labs.sql
sed -i 1i"SITEID,MED_CLASS,NUM_PAT_ALL_BEFORE_ADMISSION,NUM_PAT_ALL_SINCE_ADMISSION,NUM_PAT_EVER_SEVERE_BEFORE_ADM,NUM_PAT_EVER_SEVERE_SINCE_ADM" covid_medications.sql

exit 0
# code to generate sql for export and header
select table_name ,
'select '|| listagg(column_name,' || '','' || ') within group( order by column_id ) || ' from ' || table_name || ';' sql

,listagg(column_name,',') within group( order by column_id ) header
from all_tab_cols
where OWNER ='LPATEL'
    and table_name in (
    'COVID_CLINICAL_COURSE'
    ,'COVID_DAILY_COUNTS'
    ,'COVID_DEMOGRAPHICS'
    ,'COVID_DIAGNOSES'
    ,'COVID_LABS'
    ,'COVID_MEDICATIONS'
    )
group by table_name;
