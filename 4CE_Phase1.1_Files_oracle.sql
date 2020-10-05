set echo on;

--Cleanup scripts if necessary

WHENEVER SQLERROR CONTINUE;
  drop table covid_config purge;
  drop table covid_code_map purge;
  drop table covid_lab_map purge;
   --LP
  drop table covid_lab_scale_factor purge;
  drop table obs_fact_labs_converted purge;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

--------------------------------------------------------------------------------
-- General settings
--------------------------------------------------------------------------------
create table covid_config (
	siteid varchar(20), -- Up to 20 letters or numbers, must start with letter, no spaces or special characters.
	include_race number(1), -- 1 if your site collects race/ethnicity data; 0 if your site does not collect this.
	race_in_fact_table number(1), -- 1 if race in observation_fact.concept_cd; 0 if in patient_dimension.race_cd
	hispanic_in_fact_table number(1), -- 1 if Hispanic/Latino in observation_fact.concept_cd; 0 if in patient_dimension.race_cd
	death_data_accurate number(1), -- 1 if the patient_dimension.death_date field is populated and is accurate
	code_prefix_icd9cm varchar(50), -- prefix (scheme) used in front of a ICD9CM diagnosis code [required]
	code_prefix_icd10cm varchar(50), -- prefix (scheme) used in front of a ICD10CM diagnosis code [required]
	code_prefix_icd9proc varchar(50), -- prefix (scheme) used in front of a ICD9 procedure code [required]
	code_prefix_icd10pcs varchar(50), -- prefix (scheme) used in front of a ICD10 procedure code [required]
	obfuscation_blur number(8,0), -- Add random number +/-blur to each count (0 = no blur)
	obfuscation_small_count_mask number(8,0), -- Replace counts less than mask with -99 (0 = no small count masking)
	obfuscation_small_count_delete number(1), -- Delete rows with small counts (0 = no, 1 = yes)
	obfuscation_demographics number(1), -- Replace combination demographics and total counts with -999 (0 = no, 1 = yes)
	output_as_columns number(1), -- Return the data in tables with separate columns per field
	output_as_csv number(1) -- Return the data in tables with a single column containing comma separated values
);
insert into COVID_CONFIG
	select 'KUMC', -- siteid
		1, -- include_race
		1, -- race_in_fact_table
		1, -- hispanic_in_fact_table
		1, -- death_data_accurate
		'ICD9:', -- code_prefix_icd9cm   -- TOOD: Ask them what if we are using local code example dx_id
		'ICD10:', -- code_prefix_icd10cm --select concept_cd from  Nightherondata.concept_dimension   where concept_path like '\i2b2\Diagnoses\ICD10\A20098492\A20160670\A18924177\%'
		'ICD9:', -- code_prefix_icd9proc -- select concept_cd from  Nightherondata.CONCEPT_DIMENSION   where concept_path LIKE '\PCORI\PROCEDURE\09\(08-16.99) Ope~jf1y\(15) Operation~pru9\%'
		'ICD10:', -- code_prefix_icd10pcs --select concept_cd from  Nightherondata.CONCEPT_DIMENSION   where concept_path LIKE '\PCORI\PROCEDURE\10\(4) Measuremen~ge9w\(4A) Measureme~dxgz\(4A1) Measurem~49bf\(4A13) Measure~djxw\%'
		0, -- obfuscation_blur
		11, -- obfuscation_small_count_mask
		0, -- obfuscation_small_count_delete
		0, -- obfuscation_demographics
		0, -- output_as_columns
		1 -- output_as_csv
    from dual;    
commit;
-- TODO:??
-- ! If your ICD codes do not start with a prefix (e.g., "ICD:"), then you will
-- ! need to customize the query that populates the covid_diagnoses table so that
-- ! only diagnosis codes are selected from the observation_fact table.
-- TODO: what if diag and proc same prefix?
--------------------------------------------------------------------------------
-- Code mappings (excluding labs and meds)
-- * Don't change the "code" value.
-- * Modify the "local_code" to match your database.
-- * Repeat a code multiple times if you have more than one local code.
--------------------------------------------------------------------------------
create table COVID_CODE_MAP (
	code varchar(50) not null,
	local_code varchar(50) not null,
    constraint COVID_CODEMAP_PK PRIMARY KEY (code, local_code)
);

--MW: If patients was in ED than become IP, it should be flagged as IP
/*
	212706
UN	11948
AV	991376
ED	43266
OT	99673
IP	17761
EI	20018
OS	779
OA	3021348
*/
-- Inpatient visits (visit_dimension.inout_cd)
insert into  COVID_CODE_MAP
	select 'inpatient', 'IP' from dual -- select inout_cd, count (*) from nightherondata.visit_dimension group by inout_cd; --IP	17761
;

commit;    
-- Sex (patient_dimension.sex_cd) -- select sex_cd, count(*) from nightherondata.patient_dimension group by sex_cd;
insert into  COVID_CODE_MAP
	select 'male', 'm' from dual
        union all 
    select 'female', 'f' from dual
    ;
commit;    
-- Race (field based on covid_config.race_in_fact_table; ignore if you don't collect race/ethnicity)
insert into  COVID_CODE_MAP
	select 'american_indian', 'DEM|RACE:amerian ind' from dual
        union all 
    select 'asian', 'DEM|RACE:asian' from dual
        union all 
    select 'black', 'DEM|RACE:black' from dual
        union all 
    select 'hawaiian_pacific_islander', 'DEM|RACE:pac islander' from dual
        union all 
    select 'white', 'DEM|RACE:white' from dual;
commit; 

-- Hispanic/Latino (field based on covid_config.hispanic_in_fact_table; ignore if you don't collect race/ethnicity)
insert into  COVID_CODE_MAP
	select 'hispanic_latino', 'DEM|ETHNICITY:hispanic' from dual
        union all 
    select 'hispanic_latino', 'DEM|ETHNICITY:his' from dual;
commit; 

-- Codes that indicate a positive COVID-19 test result (use either option #1 and/or option #2)
-- COVID-19 Positive Option #1: individual concept_cd values
    insert into  COVID_CODE_MAP
	select 'covidpos', 'ICD10CM:U07.1' from dual;
commit;

-- COVID-19 Positive Option #2: an ontology path (the example here is the COVID ACT "Any Positive Test" path)
insert into  COVID_CODE_MAP
	select distinct 'covidpos', concept_cd
	from nightherondata.concept_dimension c
	where ( concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1335447\%'
            or
            concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\SNOMED_3947183016\ICD10CM_U07.1\%'
          )
		and concept_cd is not null
		and not exists (select * from COVID_CODE_MAP m where m.code='covidpos' and m.local_code=c.concept_cd);
commit;        
--------------------------------------------------------------------------------
-- Lab mappings
-- * Do not change the loinc column or the lab_units column.
-- * Modify the local_code column for the code you use.
-- * Add another row for a lab if you use multiple codes (e.g., see PaO2).
-- * Delete a row if you don't have that lab.
-- * Change the scale_factor if you use different units.
-- * The lab value will be multiplied by the scale_factor
-- *   to convert from your units to the 4CE units.
--eye ball it (Danc)
/*
select replace(lm.local_lab_code,'KUH|COMPONENT_ID:','') from COVID_LAB_MAP lm
left join dconnolly.counts_by_concept cbc on cbc.concept_cd = lm.local_lab_code
--order by lm.lab_name, patients desc
where cbc.facts is null;
3761
51154
52032
52182
51082
51418
51988
51066
51936
1
*/
-- TOD0: Apply scale_factor
-- TOD0: find remaing labs
/*
with cp as 
(
select concept_path
from  NightHeronData.concept_dimension
where concept_cd in (
'LOINC:48066-5',
'LOINC:3255-7'
,'LOINC:2276-4'
,'LOINC:2019-8'
,'LOINC:2703-7'
)
)
select *
from NightHeronData.concept_dimension cd
join cp
    on cd.concept_path like  cp.concept_path|| '%'
order by cd.concept_path
;
*/


--with f_unit as
--(
--select  f.concept_cd , f.units_cd, f.nval_num
--from nightherondata.observation_fact f
--where
--f.concept_cd in (
--'KUH|COMPONENT_ID:2065',
--'KUH|COMPONENT_ID:51082',
--'KUH|COMPONENT_ID:1',
--'KUH|COMPONENT_ID:2023',
--'KUH|COMPONENT_ID:51066',
--'KUH|COMPONENT_ID:2064',
--'KUH|COMPONENT_ID:51154',
--'KUH|COMPONENT_ID:2024',
--'KUH|COMPONENT_ID:52182',
--'KUH|COMPONENT_ID:3186',
--'KUH|COMPONENT_ID:3761',
--'KUH|COMPONENT_ID:4003',
--'KUH|COMPONENT_ID:4004',
--'KUH|COMPONENT_ID:51936',
--'KUH|COMPONENT_ID:2009',
--'KUH|COMPONENT_ID:51418',
--'KUH|COMPONENT_ID:3176',
--'KUH|COMPONENT_ID:2070',
--'KUH|COMPONENT_ID:4005',
--'KUH|COMPONENT_ID:4006',
--'KUH|COMPONENT_ID:51988',
--'KUH|COMPONENT_ID:3093',
--'KUH|COMPONENT_ID:664',
--'KUH|COMPONENT_ID:3094',
--'KUH|COMPONENT_ID:2326',
--'KUH|COMPONENT_ID:2327',
--'KUH|COMPONENT_ID:52032',
--'KUH|COMPONENT_ID:2328',
--'KUH|COMPONENT_ID:3009',
--'KUH|COMPONENT_ID:3016',
--'KUH|COMPONENT_ID:3012'
--)
--)
--select concept_cd , units_cd, count(*), avg(nval_num),MEDIAN(nval_num), stddev(nval_num)
--from f_unit
--group by concept_cd , units_cd
--order by concept_cd , count(*) DESC;

--------------------------------------------------------------------------------
create table COVID_LAB_MAP (
	loinc varchar(20) not null, 
	local_lab_code varchar(50) not null, 
	scale_factor numeric(4), 
	lab_units varchar(20), 
	lab_name varchar(100),
    constraint COVID_LABMAP_PK PRIMARY KEY (loinc, local_lab_code)
);

insert into COVID_LAB_MAP
	select loinc, 'KUH|COMPONENT_ID:'||local_lab_code,  -- Change "LOINC:" to your local LOINC code prefix (scheme)
		scale_factor, lab_units, lab_name
	from (
		select '6690-2' loinc, '3009' local_lab_code, 1 scale_factor, '10*3/uL' lab_units, 'white blood cell count (Leukocytes)' lab_name from dual   
            union 
        select '751-8','3012',1,'10*3/uL','neutrophil count' from dual
            union 
        select '731-0','3016',1,'10*3/uL','lymphocyte count' from dual
            union 
--        select '1751-7','1',1,'g/dL','albumin' from dual
--            union 
        select '1751-7','2023',1,'g/dL','albumin' from dual
            union 
--        select '1751-7','51066',1,'g/dL','albumin' from dual
--            union 
        select '2532-0','2070',1,'U/L','lactate dehydrogenase (LDH)' from dual
            union 
        select '1742-6','2065',1,'U/L','alanine aminotransferase (ALT)' from dual
            union 
--        select '1742-6','51082',1,'U/L','alanine aminotransferase (ALT)' from dual
--            union 
        select '1920-8','2064',1,'U/L','aspartate aminotransferase (AST)' from dual
            union 
--        select '1920-8','51154',1,'U/L','aspartate aminotransferase (AST)' from dual
--            union 
        select '1975-2','2024',1,'mg/dL','total bilirubin' from dual
            union 
--        select '1975-2','52182',1,'mg/dL','total bilirubin' from dual
--            union 
        select '2160-0','2009',1,'mg/dL','creatinine' from dual
            union 
--        select '2160-0','51418',1,'mg/dL','creatinine' from dual
--            union 
        select '49563-0','2326',1,'ng/mL','cardiac troponin (High Sensitivity)' from dual
            union 
        select '49563-0','2327',1,'ng/mL','cardiac troponin (High Sensitivity)' from dual
            union 
        select '6598-7','2328',1,'ug/L','cardiac troponin (Normal Sensitivity)' from dual
            union 
--        select '48065-7','48065-7',1,'ng/mL{FEU}','D-dimer (FEU)' from dual
--            union  -- dont have child of loinc ( 0 records) in HEORN
        select '48066-5','3094',1,'ng/mL{DDU}','D-dimer (DDU)' from dual
            union 
--        select '5902-2','52032',1,'s','prothrombin time (PT)' from dual
--            union 
        select '33959-8','664',1,'ng/mL','procalcitonin' from dual
            union 
        select '1988-5','3186',1,'mg/L','C-reactive protein (CRP) (Normal Sensitivity)' from dual
            union 
        select '3255-7','3093',1,'mg/dL','Fibrinogen' from dual
            union 
        select '2276-4','3176',1,'ng/mL','Ferritin' from dual
            union 
--        select '2019-8','3761',1,'mmHg','PaCO2' from dual
--            union 
        select '2019-8','4003',1,'mmHg','PaCO2' from dual
            union    
        select '2019-8','4004',1,'mmHg','PaCO2' from dual
            union
--        select '2019-8','51936',1,'mmHg','PaCO2' from dual
--            union
        select '2703-7','4005',1,'mmHg','PaO2' from dual
            union
        select '2703-7','4006',1,'mmHg','PaO2' from dual
--            union
--        select '2703-7','51988',1,'mmHg','PaO2' from dual
-- TODO: all labs are mapped but unit conversion is remaning.
	) t;
commit;

/*
select concept_cd,units_cd,count(*) cnt
from nightherondata.observation_fact
where concept_cd in 
(select local_lab_code from covid_lab_map)
group by concept_cd,units_cd
order by concept_cd,cnt DESC, units_cd;

*/
-- Use the concept_dimension to get an expanded list of local lab codes (optional).
-- Uncomment the query below to run this as part of the script.
-- This will pull in additional labs based on your existing mappings.
-- It will find paths corresponding to concepts already in the covid_lab_map table,
--   and then find all the concepts corresponding to child paths.
-- NOTE: Make sure to adjust the scale_factor if any of these additional
--   lab codes use different units than their parent code.
-- WARNING: This query might take several minutes to run.
/*
create table COVID_LAB_MAP2 as select * from COVID_LAB_MAP where 1=0;
insert into COVID_LAB_MAP2
	select distinct l.loinc, d.concept_cd, l.scale_factor, l.lab_units, l.lab_name
	from COVID_LAB_MAP l
		inner join nightherondata.concept_dimension c
			on l.local_lab_code = c.concept_cd
		inner join nightherondata.concept_dimension d
			on d.concept_path like c.concept_path ||'%'
	where not exists (
		select *
		from COVID_LAB_MAP2 t
		where t.loinc = l.loinc and t.local_lab_code = d.concept_cd
	);
commit;    
*/

create table covid_lab_scale_factor
nologging
parallel
as
with cp as 
    (
    select concept_path
    from  NightHeronData.concept_dimension
    where concept_cd in (
     'LOINC:1988-5' --KUH|COMPONENT_ID:3186
    ,'LOINC:48065-7'
    ,'LOINC:48066-5'--KUH|COMPONENT_ID:3094
    ,'LOINC:731-0' --KUH|COMPONENT_ID:3016
    )
    )
, kuh_concept as
    (
    select 
    *
    from NightHeronData.concept_dimension cd
    join cp
        on cd.concept_path like  cp.concept_path|| '%'
    order by cd.concept_path
    )
,f_unit as
    (
    select  f.concept_cd , f.units_cd,  f.nval_num
    from nightherondata.observation_fact f
    where
    f.concept_cd in ( select concept_cd from kuh_concept where  concept_cd like 'KUH|COMPONENT_ID:%')
    )
, lab_concept_stats as
    (
    select concept_cd , units_cd , count(*) cnt, avg(nval_num) average1 ,MEDIAN(nval_num) median1, stddev(nval_num)
    from f_unit h
    group by concept_cd , units_cd
    order by concept_cd , count(*) DESC
    )
select
m.loinc
,s.concept_cd
,s.units_cd
,m.scale_factor
,m.lab_units target_unit
,s.cnt
,s.median1
,s.average1
from lab_concept_stats s
join COVID_LAB_MAP m
    on s.concept_cd = m.local_lab_code
order by s.concept_cd,s.cnt DESC
;
--create table covid_lab_scale_factor_manual
--as
--select * from covid_lab_scale_factor;
--ALTER TABLE lpatel.covid_lab_scale_factor_manual MODIFY scale_factor NUMBER;
--ALTER TABLE lpatel.covid_lab_scale_factor_manual ADD id NUMBER(*,0);
-- will use id 1 to 18.
--------------------------------------------------------------------------------------
-- Create new observation fact which convert labs value to 4CE standards
--------------------------------------------------------------------------------------
create table obs_fact_labs_converted
parallel
nologging
TABLESPACE "COVID"
as
select /*+ parallel*/
f.ENCOUNTER_NUM ,
f.PATIENT_NUM ,
f.CONCEPT_CD ,
f.PROVIDER_ID ,
f.START_DATE ,
f.MODIFIER_CD ,
f.INSTANCE_NUM ,
f.VALTYPE_CD ,
f.TVAL_CHAR ,
--f.NVAL_NUM old_NVAL_NUM,
f.nval_num * COALESCE(m.scale_factor,1) nval_num,
f.VALUEFLAG_CD ,
f.QUANTITY_NUM ,
--f.UNITS_CD OLD_UNITS_CD,
m.target_unit units_cd,
f.END_DATE ,
f.LOCATION_CD ,
--f.OBSERVATION_BLOB ,
f.CONFIDENCE_NUM ,
f.UPDATE_DATE ,
f.DOWNLOAD_DATE ,
f.IMPORT_DATE ,
f.SOURCESYSTEM_CD ,
f.UPLOAD_ID ,
f.SUB_ENCOUNTER 
from nightherondata.observation_fact f 
join covid_lab_scale_factor_manual m
    on f.concept_cd= m.concept_cd
    and f.units_cd = m.units_cd
where f.concept_cd in (select distinct concept_cd from  covid_lab_scale_factor_manual)
union 
select /*+ parallel*/
f.ENCOUNTER_NUM ,
f.PATIENT_NUM ,
f.CONCEPT_CD ,
f.PROVIDER_ID ,
f.START_DATE ,
f.MODIFIER_CD ,
f.INSTANCE_NUM ,
f.VALTYPE_CD ,
f.TVAL_CHAR ,
f.NVAL_NUM,
--f.nval_num * COALESCE(m.scale_factor,1) nval_num,
f.VALUEFLAG_CD ,
f.QUANTITY_NUM ,
f.UNITS_CD ,
--m.target_unit units_cd,
f.END_DATE ,
f.LOCATION_CD ,
--f.OBSERVATION_BLOB ,
f.CONFIDENCE_NUM ,
f.UPDATE_DATE ,
f.DOWNLOAD_DATE ,
f.IMPORT_DATE ,
f.SOURCESYSTEM_CD ,
f.UPLOAD_ID ,
f.SUB_ENCOUNTER 
from nightherondata.observation_fact f
where f.concept_cd like 'KUH|COMPONENT_ID:%'
;
