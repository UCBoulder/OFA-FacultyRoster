libname lib 'L:\IR\facstaff\OFA\Faculty Roster';
%fisdb;

data lib.fis_crosswalk_view;
	set fisdb.fis_crosswalk_view;
run;

data lib.fis_degree ;
	set fisdb.fis_degree;
run;

data lib.fis_degree_name;
	set fisdb.fis_degree_name;
run;

data lib.fis_institution ;
	set fisdb.fis_institution ;
run;

data lib.vivo_etl_person;
	set fisdb.vivo_etl_person;
run;

