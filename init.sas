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

%let month = %substr(&snapdate,3,3);   /* Extracts JUN */
%let year  = %substr(&snapdate,6,4);   /* Extracts 2025 */

%put &month. &year.; 
libname lib 'L:\IR\facstaff\OFA\Faculty Roster';
