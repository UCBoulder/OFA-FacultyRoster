%let year = 2024; 
/*
CourseLeaf ID 
FIS ID 
EmplID 
First name 
Middle name 
Last name 
Suffix name 
Displayname (Preferred Name) 
Lastfirstname 
Academic Rank 
Academic rank no display title 
Url 
Home dept 
Primary affiliation 
Fis employment status 
Degrees (top one) 
Academic Positions  
	
	Tenure/Tenure-Track Appointments
		1101, 1102, 1103 
	Teaching/Clinical/Librarian Faculty Appointments
		1107, 1108, 1109, 1201, 1202, 1203, 1204, 1205, 1211, 1212, 1213, 1214, 1215, 1221, 1222, 1223, 1224
	Research Professor Series 
		1301, 1302, 1303, 1304, 1311, 
	In-Residence Appointments 
	Emeritus Appointments
		5102 
	Temporary Appointments (Lecturers)
		1419 
	Distinguished Appointments
		1100 
	Administrative Appointments 
	 	1446 Director-Institute
	 	2205 Chancellor
	 	2206 Executive Vice Chancellor/VP
	 	2207 Provost
	 	2208 Executive Vice Chancellor
	 	2209 Vice Chancellor
	 	2210 Assoc Vice Chancellor
	 	2214 Dean
	Endowed Appointments 
		1450, 1451
*/

/* EID x FISID Crosswalk */
proc sql; 
	create table id as
	select distinct
	FIS_ID, EMPLID as EID
	from fisdb.fis_crosswalk_view
	order by EMPLID;
quit;

/* Name */
proc sql; 
	create table name as
	select distinct
	EMPLOYEE_ID as EID,
	EMPLOYEE_NAME as NAME,
	EMPLOYEE_FIRST_NAME as FIRST,
	EMPLOYEE_MIDDLE_NAME as MIDDLE,
	EMPLOYEE_LAST_NAME as LAST,
	EMPLOYEE_PREF_FIRST_NAME as PREF_FIRST,
	EMPLOYEE_PREF_MIDDLE_NAME as PREF_MIDDLE,
	EMPLOYEE_PREF_LAST_NAME as PREF_LAST,
	EMPLOYEE_PREF_NAME as PREF_NAME,
	EMPLOYEE_NAME_SUFFIX as SUFFIX
	from ciwdb.HRMS_PERSONAL_TBL;
quit;

/* Home Dept */
proc sql; 
	create table department as
	select distinct
	EMPLOYEE_ID as EID,
	EMPLOYEE_HOME_DEPT_ID
	from ciwdb.HRMS_PERSONAL_TBL;
quit;

/* Degree */
data degree;
set fisdb.fis_degree;
run;
	
proc sort data=degree;
    by FIS_ID descending DEGREE_YEAR;
run;

data top_degree (keep = FIS_ID DEGREE_YEAR DEGREE_NAME);
    set degree;
    by FIS_ID descending DEGREE_YEAR;
    if first.FIS_ID;
run;

/* CU Experts URL */
/* Check that all accounts slated to be exported to CU Experts. From Vance Howard */
proc sql; 
	create table expert_link as
	select FIS_ID 
		from fisdb.vivo_etl_person where export_to_vivo = 'Y';
quit;

/* EXPERTS LINK:
	https://experts.colorado.edu/display/fisid_[FISID] */
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
	create table job_category as
	select distinct
	jobcode,
	jobtitle,
		CASE
	    WHEN jobcode IN ('1101', '1102', '1103') THEN 'TTT'
	    WHEN jobcode IN ('1107', '1108', '1109', '1201', '1202', '1203', '1204', '1205', 
	                     '1211', '1212', '1213', '1214', '1215', '1221', '1222', '1223', '1224') THEN 'TCL'
	    WHEN jobcode IN ('1301', '1302', '1303', '1304', '1311') THEN 'Research Professor'
	    WHEN jobcode = '1442' THEN 'In-Residence'
	    WHEN jobcode = '5102' THEN 'Emeritus'
	    WHEN jobcode = '1419' THEN 'Temporary'
	    WHEN jobcode = '1100' THEN 'Distinguished'
	    WHEN jobcode IN ('1446', '2205', '2206', '2207', '2208', '2209', '2210', '2214') THEN 'Administrative'
	    WHEN jobcode IN ('1450', '1451') THEN 'Endowed'
	    ELSE 'Unknown'
	END AS job_category
	from edb.pers&year.
	where calculated job_category ne 'Unknown'
group by jobcode;
quit;

