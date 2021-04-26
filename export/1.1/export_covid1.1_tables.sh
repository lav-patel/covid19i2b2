set -x
SITEID='KUMC'
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_clinical_course.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_daily_counts.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_demographics.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_diagnoses.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_labs.sql
sqlplus $USER_NAME/$USER_PASSWORD@$ORACLE_SID @covid_medications.sql


sed -i 1i"siteid,days_since_admission,num_patients_all_still_in_hospital,num_patients_ever_severe_still_in_hospital" ClinicalCourse-${SITEID}.csv

sed -i 1i"siteid,calendar_date,cumulative_patients_all,cumulative_patients_severe,cumulative_patients_dead,num_patients_in_hospital_on_this_date,num_patients_in_hospital_and_severe_on_this_date" DailyCounts-${SITEID}.csv

sed -i 1i"siteid,sex,age_group,race,num_patients_all,num_patients_ever_severe" Demographics-${SITEID}.csv

sed -i 1i"siteid,icd_code_3chars,icd_version,num_patients_all_before_admission,num_patients_all_since_admission,num_patients_ever_severe_before_admission,num_patients_ever_severe_since_admission" Diagnoses-${SITEID}.csv

sed -i 1i"siteid,loinc,days_since_admission,units,num_patients_all,mean_value_all,stdev_value_all,mean_log_value_all,stdev_log_value_all,num_patients_ever_severe,mean_value_ever_severe,stdev_value_ever_severe,mean_log_value_ever_severe,stdev_log_value_ever_severe" Labs-${SITEID}.csv

sed -i 1i"siteid,med_class,num_patients_all_before_admission,num_patients_all_since_admission,num_patients_ever_severe_before_admission,num_patients_ever_severe_since_admission" Medications-${SITEID}.csv

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
