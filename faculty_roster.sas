/* EID x FISID Crosswalk */
proc sql; 
	create table id as
	select distinct
	FIS_ID, EMPLID as EID
	from fisdb.fis_crosswalk_view
	order by EMPLID;
quit;

/* Degree - fis degree information highly missing. Relying on Academic Analytics for first match, then FIS if missing
	- Retrieve csv from https://portal.academicanalytics.com/resources/downloads
	> Benchmarking > aa_fd_person
	update csv file location
*/
proc import datafile="L:\IR\facstaff\OFA\Faculty Roster\aa_fd_person_2025-3-25_10-39-37.csv"
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
run;

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
	case when id.EID in (select distinct clientfacultyid from aa_degree)
		then "AA" 
		when id.EID in (select distinct EID from fis_top_degree_final) 
		then "FIS" 
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
where jobcode in (
    '1101FF',  /* PROFESSOR-FF */
    '1103',    /* ASSISTANT PROFESSOR */
    '1202',    /* CLINICAL ASSOCIATE PROFESSOR */
    '1213',    /* ASST PROFESSOR CLINICAL (C/T) */
    '1401',    /* VISITING PROFESSOR */
    '1423',    /* MUSEUM CURATOR */
    '1101',    /* PROFESSOR */
    '1104FF',  /* SENIOR INSTRUCTOR-FF */
    '1211',    /* PROFESSOR CLINICAL (C/T) */
    '1215C',   /* INSTRUCTOR CLINICAL (C/T)- 9MO */
    '1403',    /* VISITING ASSISTANT PROFESSOR */
    '1107',    /* TEACHING PROFESSOR */
    '1213C',   /* ASST PROF CLINICAL (C/T)-9MO */
    '1405',    /* SPECIAL VISITING PROFESSOR */
    '1436',    /* ASSOC CHAIR */
    '1450',    /* ENDOWED OR NAMED PROFESSOR */
    '2207',    /* PROVOST */
    '1106FF',  /* PRINCIPAL INSTRUCTOR-FF */
    '1301',    /* RESEARCH PROFESSOR */
    '1449',    /* ARTIST IN RESIDENCE */
    '5102',    /* FACULTY RETIREE EMERITUS ORP */
    '1104',    /* SENIOR INSTRUCTOR */
    '1205',    /* CLINICAL INSTRUCTOR */
    '1214',    /* SR INSTRUCTOR CLINICAL (C/T) */
    '1435',    /* CHAIR */
    '1442',    /* SCHOLAR IN RESIDENCE */
    '2208',    /* EXECUTIVE VICE CHANCELLOR */
    '1100FF',  /* DISTINGUISHED PROFESSOR-FF */
    '1302',    /* ASSOCIATE RESEARCH PROFESSOR */
    '1103FF',  /* ASSISTANT PROFESSOR-FF */
    '1303',    /* ASSISTANT RESEARCH PROFESSOR */
    '2210',    /* ASSOC VICE CHANCELLOR */
    '1108FF',  /* ASSC TEACHING PROFESSOR-FF */
    '1212C',   /* ASSC PROF CLINICAL (C/T)-9MO */
    '1451',    /* ENDOWED CHAIR */
    '1109',    /* ASSISTANT TEACHING PROFESSOR */
    '1109FF',  /* ASST TEACHING PROFESSOR-FF */
    '2205',    /* CHANCELLOR */
    '2214',    /* DEAN */
    '1304',    /* RESEARCH SCIENTIST */
    /* '1419',     LECTURER */
    '2206',    /* EXECUTIVE VICE CHANCELLOR/VP */
    '1108',    /* ASSOCIATE TEACHING PROFESSOR */
    '1428',    /* ASSOC DEAN-FACULTY */
    '1439',    /* FACULTY FELLOW */
    '1105FF',  /* INSTRUCTOR-FF */
    '1311',    /* SENIOR RESEARCH SCIENTIST */
    '1102',    /* ASSOCIATE PROFESSOR */
    '1102FF',  /* ASSOCIATE PROFESSOR-FF */
    '1203',    /* CLINICAL ASSISTANT PROFESSOR */
    '1212',    /* ASSC PROFESSOR CLINICAL (C/T) */
    '1422',    /* VISITING INSTRUCTOR */
    '1433',    /* DIRECTOR-FACULTY */
    '1100',    /* DISTINGUISHED PROFESSOR */
    '1107FF',  /* TEACHING PROFESSOR-FF */
    '1201',    /* CLINICAL PROFESSOR */
    '1214C',   /* SR INSTR CLINICAL (C/T)-9MO */
    '1402',    /* VISITING ASSOCIATE PROFESSOR */
  /*  '1420',    /* VISITING LECTURER */
    '1446',    /* DIRECTOR-INSTITUTE */
    '1105',    /* INSTRUCTOR */
    '1204',    /* CLINICAL SENIOR INSTRUCTOR */
    '1211C',   /* PROFESSOR CLINICAL (C/T)-9MO */
    '1215',    /* INSTRUCTOR CLINICAL (C/T) */
    '1425',    /* VISITING MUSEUM CURATOR */
    '1434',    /* ASSOC DIRECTOR-FACULTY */
    '2209'     /* VICE CHANCELLOR */
);

	create table retirees as
	select distinct 
	r.EID, id.FIS_ID, Name, JobCode, JobTitle, ApptPctTime as ApptFTE, DeptID, DeptName, SnapDate
	from &ln.db.retirees&dstitle. r
	left join id
		on r.EID = id.EID
	where jobcode in 
	(
    '1448',  /* EMERITUS */
    '1452',  /* EMERITUS - PROFESSOR */
    '1453',  /* EMERITUS - ASSOCIATE PROFESSOR */
    '1454',  /* EMERITUS - ASSISTANT PROFESSOR */
    '1455',  /* EMERITUS - SENIOR INSTRUCTOR */
    '1456',  /* EMERITUS - INSTRUCTOR */
    '1457',  /* DEAN EMERITUS */
    '1601',  /* OFFICER EMERITUS/A */
    '2100',  /* PRESIDENT EMERITUS */
    '2186',  /* CHANCELLOR EMERITUS */
    '2900',  /* PRESIDENT EMERITUS */
    '2901',  /* CHANCELLOR EMERITUS */
    '2902'   /* DEAN EMERITUS */
	);
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
create table 
	roster as 
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
from roster_v1 roster
left join &ln.db.div01&month.&year. org
on roster.deptid = org.deptid;
quit;

/* Copy to library */
proc copy in=work out=lib;
    select roster;  
run;

%xlsexport(L:\IR\facstaff\OFA\Faculty Roster\tool_roster.xlsx,lib.roster);
