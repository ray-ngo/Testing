; ==============================================
;V2.5_PTNet_Build
;rogram: Build PT Network for Version 2.5
; rn	10-20-2017	Adding the external process to the model.
; sko   03-09-2022 based on fxie's update, this file followed the change: PT_NET.NET should be built from zonehwy_unbuild.net instead of the link/node files,
;					because the facility type, number of lanes and limit codes of many centroid connectors
;                   have been updated when building zonehwy_unbuild.net in V2.3_Highway_Build.s

*del voya*prn

RUN PGM = NETWORK   ; PRNFILE = "PTNET_BUILD.PRN"
ZONES=3722

;	FILEI NODEI=Inputs\hwy\NODE.dbf
;	FILEI LINKI=Inputs\hwy\LINK.dbf
	NETI=outputs\hwy_net\zonehwy_unbuild.net
	NETO=outputs\trn_net\PT_NET.NET


ENDRUN

LOOP period = 1,2
	IF (period=1)
		PRD = 'AM'
		time = 'AM'
	ELSE
		PRD = 'OP'
		time = 'MD'
	ENDIF
	
	RUN PGM=NETWORK
	
	  NETI[2]  = inputs\trn\i4_Assign_Output.NET          ; Previous CLRP_Final Loaded Hwy Net of the same scenario year (e.g V2.3.66)
	  NETI[1]  = outputs\trn_net\PT_Net.NET                    				

	  NETO= outputs\trn_net\@PRD@_PT_Net.Net include = a,b,distance,jur,screen,FTYPE,
	                                              toll,tollgrp,amlane,amlimit,pmlane,pmlimit,oplane,oplimit, edgeid,
	                                              LINKID,NETYEAR,Shape_LENG,Projectid,TRANTIME,WKTIME,MODE,
	                                              I4@PRD@SPD,I4@PRD@_HTIME
	  MERGE record = F
	
	  IF (li.1.a =li.2.a && li.1.b = li.2.b)
	     I4@time@SPD      = li.2.I4@time@SPD
	     I4@time@_HTIME   = (li.2.distance*60.0)/li.2.I4@time@SPD
	     TRANTIME     = I4@time@_HTIME
	  ENDIF
	ENDRUN

ENDLOOP

; |\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
; |///  Added step to create station name file for the Linesum \\\| 
; |///  program directly from scenario specific station file   \\\| 
; |\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|


;Program step to write a station names file (used by the LINSESUM program) directly from
;the "Station.dbf" file.  The O/P file will be sent to the inputs subdirectory; make sure
;that this is reflected in the LINESUM_MR_Access.ctl file

;Input file:
    Sta_File    =  'inputs\trn\Station.dbf'  ; Std. Station file


; Output File:
    Sta_Names   =  'outputs\trn_net\station_names.dbf' ;
 
 
RUN PGM=MATRIX
Zones=1
FILEI DBI[1]    ="@Sta_File@"
FILEO RECO[1]   ="@Sta_Names@", Fields= ID(12.0),Station(c35)
;
LOOP  K = 1,dbi.1.NUMRECORDS
      x = DBIReadRecord(1,k)
          idx         = dbi.1.recno  ;
          STAT        = di.1.STAT    ; Station no.
          STAN1       = di.1.STAN1   ; First Bus Node no.
          MM          = di.1.MM      ; Mode Code (M,C,L,B,N)
          SNAME       = di.1.SNAME   ; Mode Code (M,C,L,B,N)
          ;
          ; Index = STAT unless mode = "B"- in that case the Station will equal STAN1
                        RO.ID       = STAT
          IF (MM = 'B') RO.ID       = STAN1
                        RO.STATION  = SNAME
          WRITE  RECO = 1
ENDLOOP

ENDRUN




