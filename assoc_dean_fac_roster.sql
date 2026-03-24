with job as(
    select EMPLOYEE_ID,
           JOB_DEPT_ID,
           JOB_POSITION_NUM,
           job_jb_code,
           JOB_ENTRY_DATE,
           JOB_STD_HOURS,
           EMPLOYMENT_REC_NUM
        from ARTEMIS.HRMS_JOB_TBL
                where job_jb_code IN ('1428', '1435')
                and JOB_EXPIRATION_DATE > sysdate
                and JOB_EFFECTIVE_DATE <= sysdate
                and JOB_DEPT_ID like ('1%')
                and JOB_EMPLMNT_STATUS_CODE IN ('A','P','L')
    ),
pers as(
    select employee_id, EMPLOYEE_NAME, EMPLOYEE_CONSTITUENT_ID from ARTEMIS.HRMS_PERSONAL_TBL
),
department as(
    select  DEPT_ID,
            DEPT_DESC
    from ARTEMIS.GL_ORG_TBL
    where DEPT_EFFECTIVE_DATE <= sysdate
        and DEPT_EXPIRATION_DATE > sysdate
),
employment as(
        select employee_id,
               EMPLOYMENT_REPORTS_TO_NUM,
               EMPLOYMENT_REC_NUM,
               EMPLOYMENT_SUPERVISOR_ID
        from ARTEMIS.HRMS_EMPLOYMENT_TBL
                 ),
jobdetail as (select distinct jb_code, jb_desc from
                ARTEMIS.HRMS_JOB_CODE_TBL
                where JB_EFFECTIVE_DATE <= sysdate and
                      JB_EXPIRATION_DATE > sysdate)
select distinct
                pers.EMPLOYEE_NAME ,
                job.EMPLOYEE_ID Empl_ID,
                jobdetail.JB_DESC as Title,
                dept.DEPT_DESC as Department,
                job.JOB_DEPT_ID as Dept_ID,
                job.job_jb_code as Job_Code,
                pers.EMPLOYEE_CONSTITUENT_ID,
                sysdate as rundate

    from job

    left join pers
        on job.employee_id = pers.employee_id

    left join employment
        on job.employee_id = employment.employee_id
        and job.EMPLOYMENT_REC_NUM = employment.EMPLOYMENT_REC_NUM

    left join jobdetail
        on job.job_jb_code = jobdetail.JB_CODE

    left join department dept
    on job.JOB_DEPT_ID = dept.DEPT_ID

order by jobdetail.JB_DESC, job.EMPLOYEE_ID
