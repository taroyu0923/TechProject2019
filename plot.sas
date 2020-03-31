/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: 2020年3月31日     TIME: 上午 11:48:26
PROJECT: 專案
PROJECT PATH: D:\WORK5\大專生研究計畫\專案.egp
---------------------------------------- */

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=PNG;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///D:/Program%20Files/SAS/SASEnterpriseGuide/7.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: 匯入資料 (tigerair_monsta.csv)   */

GOPTIONS ACCESSIBLE;
/* --------------------------------------------------------------------
   SAS 工作產生的程式碼
   
   在 2020年3月30日 的 下午 03:58:43
   由這個工作產生:     匯入資料精靈
   
   來源檔案: C:\Users\ASUS\Desktop\tigerair_monsta.csv
   伺服器:      本機檔案系統
   
   輸出資料: WORK.tigerair_monsta
   伺服器:      Local
   -------------------------------------------------------------------- */

DATA WORK.tigerair_monsta;
    LENGTH
        month              8
        posts              8
        likes              8
        comments           8
        shares             8
        reaction           8
        avg_likes          8
        avg_comments       8
        avg_shares         8
        avg_reactions      8 ;
    FORMAT
        month            DATE9.
        posts            BEST2.
        likes            BEST5.
        comments         BEST5.
        shares           BEST5.
        reaction         BEST6.
        avg_likes        BEST11.
        avg_comments     BEST11.
        avg_shares       BEST11.
        avg_reactions    BEST11. ;
    INFORMAT
        month            DATE9.
        posts            BEST2.
        likes            BEST5.
        comments         BEST5.
        shares           BEST5.
        reaction         BEST6.
        avg_likes        BEST11.
        avg_comments     BEST11.
        avg_shares       BEST11.
        avg_reactions    BEST11. ;
    INFILE 'C:\Users\ASUS\AppData\Local\Temp\SEG11372\tigerair_monsta-9b297a0cbe3947c0bfef26ccf271567a.txt'
        LRECL=83
        ENCODING="MS-950"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        month            : ?? ANYDTDTE7.
        posts            : ?? BEST2.
        likes            : ?? BEST5.
        comments         : ?? BEST5.
        shares           : ?? BEST5.
        reaction         : ?? BEST6.
        avg_likes        : ?? COMMA11.
        avg_comments     : ?? COMMA11.
        avg_shares       : ?? COMMA11.
        avg_reactions    : ?? COMMA11. ;
RUN;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:45
   工作: 折線圖

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TIGERAIR_MONSTA(KEEP=month posts)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT posts * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (2)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:48
   工作: 折線圖 (2)

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TIGERAIR_MONSTA(KEEP=month likes)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT likes * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (3)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:49
   工作: 折線圖 (3)

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TIGERAIR_MONSTA(KEEP=month likes comments shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL3
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT likes * month comments * month shares * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 標準化資料   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:50
   工作: 標準化資料

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP0TempTableKeepOldVarNames,
		WORK.STNDStandardized);
/* -------------------------------------------------------------------
   排序資料集 Local:WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT *
	FROM WORK.TIGERAIR_MONSTA
;
QUIT;

/* -------------------------------------------------------------------
   建立新輸出變數
   ------------------------------------------------------------------- */
DATA WORK.TMP0TempTableKeepOldVarNames;
	SET WORK.SORTTempTableSorted;
	stnd_posts = posts;
	LABEL stnd_posts="標準化 posts: 平均值 = 0 標準差 = 1";
	stnd_reaction = reaction;
	LABEL stnd_reaction="標準化 reaction: 平均值 = 0 標準差 = 1";
	stnd_avg_likes = avg_likes;
	LABEL stnd_avg_likes="標準化 avg_likes: 平均值 = 0 標準差 = 1";
	stnd_avg_comments = avg_comments;
	LABEL stnd_avg_comments="標準化 avg_comments: 平均值 = 0 標準差 = 1";
	stnd_avg_shares = avg_shares;
	LABEL stnd_avg_shares="標準化 avg_shares: 平均值 = 0 標準差 = 1";
	stnd_avg_reactions = avg_reactions;
	LABEL stnd_avg_reactions="標準化 avg_reactions: 平均值 = 0 標準差 = 1";
	stnd_likes = likes;
	LABEL stnd_likes="標準化 likes: 平均值 = 0 標準差 = 1";
	stnd_comments = comments;
	LABEL stnd_comments="標準化 comments: 平均值 = 0 標準差 = 1";
	stnd_shares = shares;
	LABEL stnd_shares="標準化 shares: 平均值 = 0 標準差 = 1";
RUN;

/* -------------------------------------------------------------------
   執行標準化程序
   ------------------------------------------------------------------- */
PROC STANDARD
DATA=WORK.TMP0TempTableKeepOldVarNames
OUT=WORK.STNDStandardized(LABEL="標準化 WORK.TIGERAIR_MONSTA")
	MEAN=0
	STD=1
	;
	VAR stnd_posts stnd_reaction stnd_avg_likes stnd_avg_comments stnd_avg_shares stnd_avg_reactions stnd_likes stnd_comments stnd_shares;

RUN;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP0TempTableKeepOldVarNames);
TITLE; FOOTNOTE;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (4)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:52
   工作: 折線圖 (4)

   輸入資料: Local:WORK.STNDSTANDARDIZED
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.STNDSTANDARDIZED
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.STNDSTANDARDIZED(KEEP=month stnd_avg_likes stnd_avg_comments stnd_avg_shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL3
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT stnd_avg_likes * month stnd_avg_comments * month stnd_avg_shares * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (8)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:50
   工作: 折線圖 (8)

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TIGERAIR_MONSTA(KEEP=month shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT shares * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (9)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:51
   工作: 折線圖 (9)

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TIGERAIR_MONSTA(KEEP=month comments)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT comments * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 摘要統計   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:52
   工作: 摘要統計

   輸入資料: Local:WORK.TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 Local:WORK.TIGERAIR_MONSTA
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT T.posts, T.likes, T.comments, T.shares
	FROM WORK.TIGERAIR_MONSTA as T
;
QUIT;
/* -------------------------------------------------------------------
   執行平均值程序
   ------------------------------------------------------------------- */
TITLE;
TITLE1 "摘要統計";
TITLE2 "結果";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC MEANS DATA=WORK.SORTTempTableSorted
	FW=12
	PRINTALLTYPES
	CHARTYPE
	QMETHOD=OS
	VARDEF=DF 	
		MEAN 
		STD NONOBS 	
		P10 
		Q1 
		MEDIAN 
		Q3 
		P90	;
	VAR posts likes comments shares;

RUN;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 匯入資料 (EvaAir_monsta.csv)   */

GOPTIONS ACCESSIBLE;
/* --------------------------------------------------------------------
   SAS 工作產生的程式碼
   
   在 2020年3月30日 的 下午 03:58:53
   由這個工作產生:     匯入資料精靈
   
   來源檔案: C:\Users\ASUS\Desktop\EvaAir_monsta.csv
   伺服器:      本機檔案系統
   
   輸出資料: WORK.EvaAir_monsta
   伺服器:      Local
   -------------------------------------------------------------------- */

DATA WORK.EvaAir_monsta;
    LENGTH
        month              8
        likes              8
        comments           8
        shares             8
        post               8
        reaction           8
        avg_likes          8
        avg_comments       8
        avg_shares         8
        avg_reactions      8 ;
    FORMAT
        month            DATE9.
        likes            BEST6.
        comments         BEST5.
        shares           BEST4.
        post             BEST2.
        reaction         BEST6.
        avg_likes        BEST11.
        avg_comments     BEST11.
        avg_shares       BEST11.
        avg_reactions    BEST11. ;
    INFORMAT
        month            DATE9.
        likes            BEST6.
        comments         BEST5.
        shares           BEST4.
        post             BEST2.
        reaction         BEST6.
        avg_likes        BEST11.
        avg_comments     BEST11.
        avg_shares       BEST11.
        avg_reactions    BEST11. ;
    INFILE 'C:\Users\ASUS\AppData\Local\Temp\SEG11372\EvaAir_monsta-01739e52275d40ebbd3c877446eff25e.txt'
        LRECL=82
        ENCODING="MS-950"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        month            : ?? ANYDTDTE7.
        likes            : ?? BEST6.
        comments         : ?? BEST5.
        shares           : ?? BEST4.
        post             : ?? BEST2.
        reaction         : ?? BEST6.
        avg_likes        : ?? COMMA11.
        avg_comments     : ?? COMMA11.
        avg_shares       : ?? COMMA11.
        avg_reactions    : ?? COMMA11. ;
RUN;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 查詢產生器   */
%LET _CLIENTTASKLABEL='查詢產生器';
%LET _CLIENTPROCESSFLOWNAME='處理流程';
%LET _CLIENTPROJECTPATH='D:\WORK5\大專生研究計畫\專案.egp';
%LET _CLIENTPROJECTPATHHOST='DESKTOP-P8OTMB4';
%LET _CLIENTPROJECTNAME='專案.egp';

GOPTIONS ACCESSIBLE;
%put 錯誤: 無法取得 SAS 程式碼。 無法開啟輸入資料;


GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (13)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:59
   工作: 折線圖 (13)

   輸入資料: Local:WORK.QUERY_FOR_TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.QUERY_FOR_TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_TIGERAIR_MONSTA(KEEP=month avg_likes_T avg_likes_E)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=CXFF9900

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=GREEN

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT avg_likes_T * month avg_likes_E * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (14)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:59:01
   工作: 折線圖 (14)

   輸入資料: Local:WORK.QUERY_FOR_TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.QUERY_FOR_TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_TIGERAIR_MONSTA(KEEP=month avg_comments_T avg_comments_E)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=CXFF9900

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=GREEN

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT avg_comments_T * month avg_comments_E * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (15)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:59:02
   工作: 折線圖 (15)

   輸入資料: Local:WORK.QUERY_FOR_TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.QUERY_FOR_TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_TIGERAIR_MONSTA(KEEP=month avg_shares_T avg_shares_E)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=CXFF9900

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=GREEN

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT avg_shares_T * month avg_shares_E * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (16)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:59:02
   工作: 折線圖 (16)

   輸入資料: Local:WORK.QUERY_FOR_TIGERAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.QUERY_FOR_TIGERAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_TIGERAIR_MONSTA(KEEP=month avg_reactions_T avg_reactions_E)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=CXFF9900

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2
	CI=GREEN

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT avg_reactions_T * month avg_reactions_E * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (5)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:54
   工作: 折線圖 (5)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.EVAAIR_MONSTA(KEEP=month post)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT post * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (6)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:55
   工作: 折線圖 (6)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.EVAAIR_MONSTA(KEEP=month likes)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT likes * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (7)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:55
   工作: 折線圖 (7)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.EVAAIR_MONSTA(KEEP=month comments)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT comments * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (10)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:56
   工作: 折線圖 (10)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.EVAAIR_MONSTA(KEEP=month shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT shares * month  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (11)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:57
   工作: 折線圖 (11)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.EVAAIR_MONSTA(KEEP=month likes comments shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL3
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT likes * month comments * month shares * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 標準化資料 (2)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:57
   工作: 標準化資料 (2)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP0TempTableKeepOldVarNames,
		WORK.STNDSTANDARDIZED_0000);
/* -------------------------------------------------------------------
   排序資料集 Local:WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT *
	FROM WORK.EVAAIR_MONSTA
;
QUIT;

/* -------------------------------------------------------------------
   建立新輸出變數
   ------------------------------------------------------------------- */
DATA WORK.TMP0TempTableKeepOldVarNames;
	SET WORK.SORTTempTableSorted;
	stnd_post = post;
	LABEL stnd_post="標準化 post: 平均值 = 0 標準差 = 1";
	stnd_reaction = reaction;
	LABEL stnd_reaction="標準化 reaction: 平均值 = 0 標準差 = 1";
	stnd_avg_likes = avg_likes;
	LABEL stnd_avg_likes="標準化 avg_likes: 平均值 = 0 標準差 = 1";
	stnd_avg_comments = avg_comments;
	LABEL stnd_avg_comments="標準化 avg_comments: 平均值 = 0 標準差 = 1";
	stnd_avg_shares = avg_shares;
	LABEL stnd_avg_shares="標準化 avg_shares: 平均值 = 0 標準差 = 1";
	stnd_avg_reactions = avg_reactions;
	LABEL stnd_avg_reactions="標準化 avg_reactions: 平均值 = 0 標準差 = 1";
	stnd_likes = likes;
	LABEL stnd_likes="標準化 likes: 平均值 = 0 標準差 = 1";
	stnd_comments = comments;
	LABEL stnd_comments="標準化 comments: 平均值 = 0 標準差 = 1";
	stnd_shares = shares;
	LABEL stnd_shares="標準化 shares: 平均值 = 0 標準差 = 1";
RUN;

/* -------------------------------------------------------------------
   執行標準化程序
   ------------------------------------------------------------------- */
PROC STANDARD
DATA=WORK.TMP0TempTableKeepOldVarNames
OUT=WORK.STNDSTANDARDIZED_0000(LABEL="標準化 WORK.EVAAIR_MONSTA")
	MEAN=0
	STD=1
	;
	VAR stnd_post stnd_reaction stnd_avg_likes stnd_avg_comments stnd_avg_shares stnd_avg_reactions stnd_likes stnd_comments stnd_shares;

RUN;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP0TempTableKeepOldVarNames);
TITLE; FOOTNOTE;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 折線圖 (12)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:59:03
   工作: 折線圖 (12)

   輸入資料: Local:WORK.STNDSTANDARDIZED_0000
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 WORK.STNDSTANDARDIZED_0000
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.STNDSTANDARDIZED_0000(KEEP=month stnd_avg_likes stnd_avg_comments stnd_avg_shares)
	OUT=WORK.SORTTempTableSorted
	;
	BY month;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL2
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
SYMBOL3
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Legend1
	FRAME
	;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "折線圖";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC GPLOT DATA = WORK.SORTTempTableSorted
;
PLOT stnd_avg_likes * month stnd_avg_comments * month stnd_avg_shares * month  /
 OVERLAY
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME	LEGEND=LEGEND1
;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 線性迴歸   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 04:03:38
   工作: 線性迴歸

   輸入資料: Local:WORK.STNDSTANDARDIZED_0000
   伺服器: Local
   ------------------------------------------------------------------- */
ODS GRAPHICS ON;

%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP1TempTableForPlots);
/* -------------------------------------------------------------------
   判斷資料集的類型特性 (如果已定義特性)，
   並準備將它增加到資料集/檢視，
   而此資料集/檢視是以下列步驟產生。
   ------------------------------------------------------------------- */
DATA _NULL_;
	dsid = OPEN("WORK.STNDSTANDARDIZED_0000", "I");
	dstype = ATTRC(DSID, "TYPE");
	IF TRIM(dstype) = " " THEN
		DO;
		CALL SYMPUT("_EG_DSTYPE_", "");
		CALL SYMPUT("_DSTYPE_VARS_", "");
		END;
	ELSE
		DO;
		CALL SYMPUT("_EG_DSTYPE_", "(TYPE=""" || TRIM(dstype) || """)");
		IF VARNUM(dsid, "_NAME_") NE 0 AND VARNUM(dsid, "_TYPE_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_TYPE_ _NAME_");
		ELSE IF VARNUM(dsid, "_TYPE_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_TYPE_");
		ELSE IF VARNUM(dsid, "_NAME_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_NAME_");
		ELSE
			CALL SYMPUT("_DSTYPE_VARS_", "");
		END;
	rc = CLOSE(dsid);
	STOP;
RUN;

/* -------------------------------------------------------------------
   不需要排序資料集 WORK.STNDSTANDARDIZED_0000。
   ------------------------------------------------------------------- */
DATA WORK.SORTTempTableSorted &_EG_DSTYPE_ / VIEW=WORK.SORTTempTableSorted;
	SET WORK.STNDSTANDARDIZED_0000(KEEP=likes shares comments post &_DSTYPE_VARS_);
RUN;
TITLE;
TITLE1 "線性迴歸結果";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC REG DATA=WORK.SORTTempTableSorted
		PLOTS(ONLY)=ALL
	;
	Linear_Regression_Model: MODEL likes = shares comments post
		/		SELECTION=NONE
	;
RUN;
QUIT;

/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted,
		WORK.TMP1TempTableForPlots);
TITLE; FOOTNOTE;
ODS GRAPHICS OFF;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: 摘要統計 (2)   */

GOPTIONS ACCESSIBLE;
/* -------------------------------------------------------------------
   SAS 工作產生的程式碼

   產生日期: 2020年3月30日，下午 03:58:58
   工作: 摘要統計 (2)

   輸入資料: Local:WORK.EVAAIR_MONSTA
   伺服器: Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTempTableSorted);
/* -------------------------------------------------------------------
   排序資料集 Local:WORK.EVAAIR_MONSTA
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTempTableSorted AS
		SELECT T.likes, T.comments, T.shares, T.post
	FROM WORK.EVAAIR_MONSTA as T
;
QUIT;
/* -------------------------------------------------------------------
   執行平均值程序
   ------------------------------------------------------------------- */
TITLE;
TITLE1 "摘要統計";
TITLE2 "結果";
FOOTNOTE;
FOOTNOTE1 "由 SAS 系統 (&_SASSERVERNAME, &SYSSCPL) 於 %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.)) 產生";
PROC MEANS DATA=WORK.SORTTempTableSorted
	FW=12
	PRINTALLTYPES
	CHARTYPE
	QMETHOD=OS
	VARDEF=DF 	
		MEAN 
		STD NONOBS 	
		P10 
		Q1 
		MEDIAN 
		Q3 
		P90	;
	VAR likes comments shares post;

RUN;
/* -------------------------------------------------------------------
   工作程式碼結尾
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTempTableSorted);
TITLE; FOOTNOTE;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
