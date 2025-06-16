%let snapdate=01JUN2025 ;  	* snap date. **MUST** be in ddMMMyyyy format! ;
%let status = DRAFT ; 		* set DRAFT or FINAL date;


%let campus_tool_jobcodes = 
    '1100','1101','1101FF','1102','1102FF','1103','1103FF','1104','1104FF','1105','1105FF','1106FF',
    '1107','1107FF','1108','1108FF','1109','1109FF',
    '1201','1202','1203','1204','1205',
    '1211','1211C','1212','1212C','1213','1213C','1214','1214C','1215','1215C',
    '1301','1302','1303','1304','1311',
    '1401','1402','1403','1405','1420','1422','1425',
    '1423','1428','1433','1434','1435','1436','1439',
    '1442','1446','1448','1449','1450','1451','1452','1453','1454','1455','1456','1457',
    '1600','1601','2100','2186','2205','2206','2207','2208','2209','2210','2214',
    '2900','2901','2902','5102','XXXX';

%let catalog_jobcodes = 
    '1100','1101','1102','1103',
    '1107','1108','1109',
    '1201','1202','1203','1204','1205',
    '1211','1211C','1212','1212C','1213','1213C','1214','1214C','1215','1215C',
    '1301','1302','1303','1304','1311',
    '1442','1449';

*************************************************************************************;

%let snapdate=%upcase(&snapdate) ;		* e.g., 01NOV2017 ;
%let snapdt=%substr(&snapdate,1,5) ; 	* e.g., 01NOV ;
%let dsstatus = %sysfunc( ifc(%upcase(&status)=DRAFT,.DEF,%str()) ) ;  * If status=DRAFT, set dsstatus=.DEF. If NOT DRAFT (i.e., FINAL), set dsstatus= ;
%let dstitle=%sysfunc(ifc(&snapdt=01NOV,
					      %substr(&snapdate,6,4), 								/* e.g., 2017, if 01NOV snapday */
						  %substr(&snapdate,6,4)%substr(&snapdate,1,5))) ;		/* e.g., 201701MAY if 01MAY snapday */

%let lib = E&dsstatus. ;
%let ln = %sysfunc(compress(&lib.,'.')) ;
%put &ln.db.appts&dstitle.;
 
libname lib 'L:\IR\facstaff\OFA\Faculty Roster';

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

data fis_degree;
set fisdb.fis_degree;
run;
	
proc sort data=fis_degree;
    by FIS_ID descending DEGREE_YEAR;
run;

data fis_top_degree (keep = FIS_ID DEGREE_YEAR DEGREE_NAME);
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
	case when id.EID in (select distinct clientfacultyid from aa_degree)
		then aa.degreetypename
	else fis.DEGREE_NAME
	end as DegreeName,
	case when id.EID in (select distinct clientfacultyid from aa_degree)
		then aa.degreeyear
	else fis.DEGREE_YEAR
	end as DegreeYear,
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
    create table roster as
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
	select distinct jobtitle, jobcode from roster where Campus_Tool_Flag = 1 order by jobcode; quit;

title "Catalog Only";
proc sql; 
	select distinct jobtitle, jobcode from roster where Catalog_Flag = 1 order by jobcode; quit;

/* Copy to library */
proc copy in=work out=lib;
    select roster;  
run;

%xlsexport(L:\IR\facstaff\OFA\Faculty Roster\tool_roster.xlsx,lib.roster);
