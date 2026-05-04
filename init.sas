%let snapdate=01NOV2025 ;  	* snap date. **MUST** be in ddMMMyyyy format! ;
%let status = FINAL ; 		* set DRAFT or FINAL date;
%let month = %substr(&snapdate, 3, 3);
%let year = %substr(&snapdate, 6, 4);
%put &month &year;

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
    '2900','2901','2902','5102','XXXX', 
    '1100TE', /* IREP - 733 DISTINGUISHED PROFESSOR-TE */
	'1101TE', /* IREP - 733 PROFESSOR-TE */
	'1102TE', /* IREP - 733 ASSOCIATE PROFESSOR-TE */
	'1103TE', /* IREP - 733 ASST PROFESSOR-TE */
    '1465',   /* IREP - 733 INSTRUCTIONAL ASSOCIATE */
    '1406',   /* PROFESSOR ADJOINT*/
    '1407',   /* ASSOCIATE PROFESSOR ADJOINT */
    '1408',   /* ASSISTANT PROFESSOR ADJOINT */
    '1409',   /*PROFESSOR ADJOINT (ACADEMIC) */
    '1410',   /*ASSOCIATE PROFESSOR ADJOINT (ACADEMIC) */
    '1411',   /*ASSISTANT PROFESSOR ADJOINT (ACADEMIC) */
    '1412',   /*SR INSTR ADJOINT (ACADEMIC)*/
    '1413',   /*INSTRUCTOR ADJOINT (ACADEMIC)*/
    '1414',   /* PROFESSOR ADJOINT (ATTEND) */
    '1415',   /*ASSC PROF ADJOINT (ATTEND) */
    '1416',   /*ASST PROF ADJOINT (ATTEND) */
    '1417',   /*SR INSTR ADJOINT (ATTEND) */
    '1418',   /*INSTRUCTOR ADJOINT (ATTEND) */
    '1424',   /* MUSEUM CURATOR ADJOINT */
	'1470',   /* IREP - 733 Ajdoint */
	'1471',   /* IREP - 733 Ajdoint */
	'1472',   /* IREP - 733 Ajdoint */
	'1473',   /* IREP - 733 Ajdoint */
	'1474',   /* IREP - 733 Ajdoint */
	'1475',   /* IREP - 733 Ajdoint */
	'1476',   /* IREP - 733 Ajdoint */
	'1477',   /* IREP - 733 Ajdoint */
	'1478',   /* IREP - 733 Ajdoint */
	'1479',   /* IREP - 733 Ajdoint */
	'1480',   /* IREP - 733 Ajdoint */
    '1100CA', /* IREP - 733 Courtsey Appointment */
	'1101CA', /* IREP - 733 Courtsey Appointment */
	'1102CA', /* IREP - 733 Courtsey Appointment */
	'1103CA', /* IREP - 733 Courtsey Appointment */
	'1107CA', /* IREP - 733 Courtsey Appointment */
	'1108CA', /* IREP - 733 Courtsey Appointment */
	'1109CA', /* IREP - 733 Courtsey Appointment */

    ;

%let catalog_jobcodes = 
    '1100','1101','1102','1103',
    '1107','1108','1109',
    '1201','1202','1203','1204','1205',
    '1211','1211C','1212','1212C','1213','1213C','1214','1214C','1215','1215C',
    '1301','1302','1303','1304','1311',
    '1442','1449',
    '1100TE', /* IREP - 733 DISTINGUISHED PROFESSOR-TE */
	'1101TE', /* IREP - 733 PROFESSOR-TE */
	'1102TE', /* IREP - 733 ASSOCIATE PROFESSOR-TE */
	'1103TE' /* IREP - 733 ASST PROFESSOR-TE */
;

%let instDeptIDLst='10060' '10066' '10071' '10079' 
'10080' '10099' '10106' /*'10775'*/ '10057' '11108'
'10860' '10763' '10112' '10599' '10597' '11214';

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
