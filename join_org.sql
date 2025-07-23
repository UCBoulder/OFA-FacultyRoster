create or replace table 
TEST.BLD_OIT_DNA_IR.RPT_FACULTY_ROSTER_AND_CATALOG as 
select roster.*,
    CASE org.collegedesc
        WHEN 'COLLEGE ARTS & SCIENCES' THEN 'College of Arts & Sciences'
        WHEN 'DN,CE & AVC, SUMMR SESS' THEN 'Summer Session'
        WHEN 'COLLEGE MEDIA,COMM&INFO' THEN 'CMDI (formerly CMCI)'
        WHEN 'LEEDS SCHOOL OF BUSINESS' THEN 'Leeds School of Business'
        WHEN 'SCHOOL OF EDUCATION'      THEN 'School of Education'
        WHEN 'COLLEGE OF ENGR&APPLIED SCI' THEN 'College of Eng & Applied Sci'
        WHEN 'COLLEGE OF ENGR&APPLIED SCI' THEN 'College of Eng & Applied Sci'
        WHEN 'SCHOOL OF LAW'            THEN 'School of Law'
        WHEN 'LIBRARIES'                THEN 'Libraries'
        WHEN 'COLLEGE OF MUSIC'         THEN 'College of Music'
        ELSE 'NA'
    END AS collegedesc_new,
    CASE org.ASDIV
        WHEN 'SS' THEN 'Social Sciences'
        WHEN 'NS' THEN 'Natural Sciences'
        WHEN 'AH' THEN 'Arts & Humanities'
        ELSE ''
    END AS ASDIV_new
from TEST.BLD_OIT_DNA_IR.RPT_FACULTY_ROSTER_AND_CATALOG_ORIGINAL roster
left join CU_ORG org
on roster.deptid = org.deptid
;
