*************************************************************************************;
%fisdb;
libname lib 'C:\Users\zacr9090\UCB-O365\Data & Analytics (D&A) Team - Analytics & IR\Tableau\Tableau Dashboards\Current\Boulder Data-Analytics\Faculty and Staff\OFA\Faculty Roster & Academic Catalog Reporting Tool';

/* EID x FISID Crosswalk */
proc sql; 
	create table id as
	select distinct
	FIS_ID, EMPLID as EID
	from fisdb.fis_crosswalk_view
	order by EMPLID;
quit;

/* Degree - fis degree information highly missing. Relying on Academic Analytics for backup if FIS record is missing
	- Retrieve csv from https://portal.academicanalytics.com/resources/downloads
	> Benchmarking > aa_fd_person
	update csv file location
*/
proc import datafile="L:\IR\facstaff\OFA\Faculty Roster\aa_fd_person_2026-3-23_9-40-23.csv"
     out=aa_degree
     dbms=csv
     replace;
run;

proc sql; 
	create table fis_degree_v1 as
	select distinct 
		degree.FIS_ID,
		degree.DEGREE_YEAR,
		name.DEGREE_NAME,
		degree.INSTITUTION_CODE
	from fisdb.fis_degree degree
		left join fisdb.fis_degree_name name
			on name.DEGREE_NAME_ID = degree.DEGREE_NAME_ID;
quit;

proc sql; 
	create table fis_degree as
	select distinct 
	d.FIS_ID, 
	d.DEGREE_YEAR, 
	d.DEGREE_NAME,
	i.INSTITUTION_NAME_DISPLAY
		from fis_degree_v1 d
	left join fisdb.fis_institution i
		on d.INSTITUTION_CODE = i.unitid_code;
quit;

proc sort data=fis_degree;
    by FIS_ID descending DEGREE_YEAR;
run;

data fis_top_degree (keep = FIS_ID DEGREE_YEAR DEGREE_NAME INSTITUTION_NAME_DISPLAY);
    set fis_degree;
    by FIS_ID descending DEGREE_YEAR;
    if first.FIS_ID;
run;

proc sql; 
	create table fis_top_degree_final as
	select id.EID, d.* 
	from fis_top_degree d
	left join id
		on d.FIS_ID = id.FIS_ID;
quit;

proc sql; 
	create table degree as
	select distinct 
	id.FIS_ID, 
	id.EID,
	case when id.EID in (select distinct EID from fis_top_degree_final)
		then fis.DEGREE_NAME 
	else aa.degreetypename
	end as DegreeName,
	case when id.EID in (select distinct EID from fis_top_degree_final)
		then fis.DEGREE_YEAR 
	else aa.degreeyear
	end as DegreeYear,

	case when id.EID in (select distinct EID from fis_top_degree_final)
		then fis.INSTITUTION_NAME_DISPLAY
	else aa.degreeinstitutionname 
	end as DEGREE_INST,
	case when id.EID in (select distinct EID from fis_top_degree_final) 
		then "FIS" 
		 when id.EID in (select distinct clientfacultyid from aa_degree)
		then "AA" 
		else "NA"
	end as DegreeSource
	from id 
	left join 
		aa_degree aa
		on id.EID = aa.clientfacultyid
	left join
		fis_top_degree_final fis
		on id.EID = fis.EID;
quit;



/* CU Experts URL */
/* Check that all accounts slated to be exported to CU Experts. From Vance Howard */
proc sql; 
	create table expert_link as
	select FIS_ID 
		from fisdb.vivo_etl_person where export_to_vivo = 'Y';
quit;

/* EXPERTS LINK:
	https://experts.colorado.edu/display/fisid_[FISID] */

/* Check that all accounts slated to be exported to CU Experts. From Vance Howard */
proc sql; 
	create table expert_link as
	select FIS_ID 
		from fisdb.vivo_etl_person where export_to_vivo = 'Y';
quit;
proc sql; 
	create table 
	url as
	select distinct
	FIS_ID,
		CASE WHEN
			FIS_ID in (select distinct FIS_ID from expert_link) then
	           'https://experts.colorado.edu/display/fisid_' || put(FIS_ID, 6.)
		ELSE 'N/A'
		end as url
	from id
	where FIS_ID;
quit;

proc sql; 
	create table appts as
	select distinct 
    a.EID, id.FIS_ID, Name, jobcode, jobtitle, Time as ApptFTE, DeptID, DeptName, SnapDate 
	from &ln.db.appts&dstitle. a
	left join id
		on a.EID = id.EID
where jobcode in (&campus_tool_jobcodes) 
    or jobcode in (&catalog_jobcodes)
;

	create table retirees as
	select distinct 
	r.EID, id.FIS_ID, Name, JobCode, JobTitle, ApptPctTime as ApptFTE, DeptID, DeptName, SnapDate
	from &ln.db.retirees&dstitle. r
	left join id
		on r.EID = id.EID
	where jobcode in 
	(&retirees);
quit;

data pre_roster;
	set appts
		retirees;
run;

proc sql;
    create table roster_v1 as
    select 
        r.*, 
        d.*, 
        u.*,

        /* Campus Tool flag */
        case 
            when r.jobcode in (&campus_tool_jobcodes) then 1 else 0 
        end as Campus_Tool_Flag,

        /* Catalog for Registrar flag */
        case 
            when r.jobcode in (&catalog_jobcodes) then 1 else 0 
        end as Catalog_Flag

    from pre_roster r
    left join degree d on r.EID = d.EID
    left join url u on r.FIS_ID = u.FIS_ID
    order by r.EID, r.JobCode;
quit;

title "Campus Tool Only";
proc sql; 
	select distinct jobtitle, jobcode from roster_v1 where Campus_Tool_Flag = 1 order by jobcode; quit;

title "Catalog Only";
proc sql; 
	select distinct jobtitle, jobcode from roster_v1 where Catalog_Flag = 1 order by jobcode; quit;


proc sql;
create table roster_v2 as 
select roster.*,
    CASE 
        /* Priority 1: Check if the DeptID is in your macro list */
        WHEN org.DeptID IN (&instDeptIDLst.) THEN 'Institute'
        
        /* Priority 2: Standard College Mapping */
        WHEN org.collegedesc = 'COLLEGE ARTS & SCIENCES' THEN 'College of Arts & Sciences'
        WHEN org.collegedesc = 'DN,CE & AVC, SUMMR SESS' THEN 'Summer Session'
        WHEN org.collegedesc = 'COLLEGE MEDIA,COMM&INFO' THEN 'CMDI (formerly CMCI)'
        WHEN org.collegedesc = 'LEEDS SCHOOL OF BUSINESS' THEN 'Leeds School of Business'
        WHEN org.collegedesc = 'SCHOOL OF EDUCATION'     THEN 'School of Education'
        WHEN org.collegedesc = 'COLLEGE OF ENGR&APPLIED SCI' THEN 'College of Eng & Applied Sci'
        WHEN org.collegedesc = 'SCHOOL OF LAW'            THEN 'School of Law'
        WHEN org.collegedesc = 'LIBRARIES'                THEN 'Libraries'
        WHEN org.collegedesc = 'COLLEGE OF MUSIC'          THEN 'College of Music'
        ELSE 'NA'
    END AS collegedesc_new,
    
    CASE org.ASDIV
        WHEN 'SS' THEN 'Social Sciences'
        WHEN 'NS' THEN 'Natural Sciences'
        WHEN 'AH' THEN 'Arts & Humanities'
        ELSE ''
    END AS ASDIV_new
from roster_v1 roster
left join &ln.db.div01&month.&year. org
on roster.deptid = org.deptid
order by EID, JobCode;
quit;

data roster_v3;  
    set roster_v2;
    by EID JobCode;
    if first.EID then rowNo=1;
    else rowNo+1;
run;

proc sql;
    create table roster as
    select *, 
           count(EID) as active_appts
    from roster_v3
    group by EID;
quit;

title "Campus Tool Only";
proc sql; 
	select distinct 
	jobtitle, jobcode from roster where Campus_Tool_Flag = 1 order by jobcode; quit;

title "Catalog Only";
proc sql; 
	select distinct jobtitle, jobcode from roster where Catalog_Flag = 1 order by jobcode; quit;

/* Copy to library */
proc copy in=work out=lib;
    select roster;  
run;

%xlsexport(C:\Users\zacr9090\UCB-O365\Data & Analytics (D&A) Team - Analytics & IR\People Analysis\Requests\Faculty Affairs\Faculty Roster and Academic Catalog Reporting Tool\tool_roster.xlsx,lib.roster);