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
	from edb.appts2024 a
	left join id
		on a.EID = id.EID
	where jobcode in 
(
    '1100', '1101', '1102', '1103', '1104', '1105', '1107', '1108', '1109', 
    '1201', '1202', '1203', '1204', '1205', '1211', '1211C', '1212', '1212C', 
    '1213', '1213C', '1214', '1214C', '1215', '1215C', '1442', '1449', '1301', 
    '1302', '1303', '1304', '1311', '1419', '1401', '1402', '1403', '1405', 
    '1420', '1422', '1425', '5102', '1446', '1423', '2205', '2206', 
    '2207', '2208', '2209', '2210', '1428', '2214', '1433', '1434', '1435', 
    '1436', '1439', '1100FF', '1101FF', '1102FF', '1103FF', '1104FF', '1105FF', 
    '1106FF', '1107FF', '1108FF', '1109FF', '1450', '1451'
);

	create table retirees as
	select distinct 
	r.EID, id.FIS_ID, Name, JobCode, JobTitle, ApptPctTime as ApptFTE, DeptID, DeptName, SnapDate
	from edb.retirees2024 r
	left join id
		on r.EID = id.EID
	where jobcode in ('1448', '1452', '1453', '1454', '1455', 
    '1456', '1457', '2100', '2186' '2902' '2900' '2901' '1601');
quit;

data pre_roster;
	set appts
		retirees;
run;

proc sql; 
	create table roster as
	select r.*, d.*, u.*
	from pre_roster r
	left join
		degree d
		on r.EID= d.EID
	left join url u
		on r.FIS_ID = u.FIS_ID
	order by EID, JobCode;
quit;

%xlsexport(L:\IR\facstaff\OFA\Faculty Roster\tool_roster.xlsx,roster);
