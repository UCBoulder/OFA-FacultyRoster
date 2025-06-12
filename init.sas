%let snapdate=01JUN2025 ;  	* snap date. **MUST** be in ddMMMyyyy format! ;
%let status = DRAFT ; 		* set DRAFT or FINAL date;

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
