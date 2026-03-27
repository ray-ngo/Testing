*del voya*prn
;PT_NetProcess_PT.S

; Script File Name: PT_NetProcess.S
; This file is to update the transit network and generate Non-transit leg files used for
;    PT skim and assignment process
; 11/9/2017 rqn Corrected line 119 the location of @PERIOD@_PT_NET.NET (under scenario, not /Inputs/
; 
;; fxie 2/9/21
;; a. Staff enhanced the PNR NT leg (mode 19) generation process by doing the following:
;; 1) staff explicitly excluded KNR access links(Mode 14 and Mode 17) from PNR NT leg generation; 
;; Only Mode 0, Mode 11 and Mode 15 links are included when generating a PNR-access NT leg.

;; 2) The existing process specified minimum PNR parking costs of 200 cents (AM) and 100 cents (OP) 
;; for both Metrorail and Commuter Rail stations. This is inaccurate as many commuter rail stations in
;; this region provide free parking. Staff changed the process so that the minimum parking costs of 
;; 200/100 apply only to Metrorail stations. For commuter rail stations, a nominal minimum parking 
;; cost of 1 cent is used in consistence with the TRNBUILD process.
 
;; b. Staff also revised the KNR access leg generation. Staff noted the following:
;; 1) the existing process uses links with LIMIT=9 when generating KNR access NT legs. This is partly
;; because the access links to bus PNR stations (mode 17) are currently coded with LIMIT=9. This, however,
;; also allows the KNR access leg to use unused highway links with LIMIT=9, which is not reasonable.
;; As a fix, staff changed the limit code for mode 17 links to 0 and excluded all links with LIMIT=9 from
;; KNR access leg (mode 18) generation. This change may also be implemented in the geo-database later.
;; 
;; 2) the existing process included highway to PNR lot access links (Mode 11) or PNR lot-to-station  
;; links (Mode 15) when generating KNR access NT legs. This is incorrect as a KNR drop-off should not
;; incur PNR parking cost or other lot-to-station transferring cost on Mode 15 links 
;; As a fix, staff explicitly excluded Mode 11 and Mode 15 links from KNR access NT leg generation.

;; c. Staff also revisited the FROMNODE and TONODE ranges in all GENERATE statements and made the following
;; two changes:
;; 1) Staff expanded the ranges from existing nodes (e.g., 8001-8098 for Metrorail Stations) to all allocated 
;; nodes (e.g., 8000-8999 for Metrorail). That way, when new stop nodes are added in the transit networks,
;; they will not be neglected in NT leg generation.
;;
;; 2) The existing KNR-access NT leg generation specifies a TONODE range (8001-8012,8019-8030,8034,
;; 8038-8040,8042-8065,8073-8087,8089,8091-8094,8096-8097) that explicitly excludes Metrorail 
;; stations with an NCT code of 9. An NCT code of 9 prevents KNR-access links from being generated to
;; Metrorail, Light Rail, and BRT/Streetcar stations that dont have a parking lot. The problem is that
;; every time the station.dbf file gets updated this range needs to revisited and may be subject to manual change.
;; The revised process automatically considers the NCT-related restriction coded in "station.dbf" when generating
;; KNR-access NT legs: for all mode 12,13,14,17 links that go to a station with an NCT code of 9,
;; make NCT9=1 and exclude those links from the generation of KNR-access NT leg by including "(lw.NCT9=1)" 
;; in the"EXCLUDELINK" subkeyword. 

;; fxie 10/10/25 Added two link variables PNRPARKCOST and DRV_DISTANCE and use them to update the COST function
;; for PNR/KNR NT leg generation.

; SET VOT VALUES
  _VOTperHr = 10.00
  _VOTperMin = _VOTperHr/60.0
  _MinPerDoll = 1.0/_VOTPerMin

  _OpCost = 10 ; highway operation cost of 10cents/mile
  
; 01/20/2021 RSG made changes to generate separate access and egress NT Legs for KNR and PNR																							
; ********************************************************************************************************
; I: Extract the station parking cost, walk time, and shadow cost information from the station file
;   and file the data in a temporary file for skimming and assignment process
; ********************************************************************************************************
;

RUN PGM=MATRIX
ZONES=1
FILEI DBI[1]="INPUTS\trn\STATION.DBF"
;FILEO PRINTO[1] = "outputs\trn_net\_RAILSTATIONS.TXT"



LOOP K = 1,dbi.1.NUMRECORDS
      x = DBIReadRecord(1,k)

          MM          = di.1.MM          ;  Mode code ('M','C,','B','L','N')
          NCT         = di.1.NCT         ;  NCT code		  
          STAPARK     = di.1.STAPARK     ;  Station Parking lot flag ('Y' or blank)
          STAUSE      = di.1.STAUSE      ;  Station Active flag      ('Y' or blank)
          STAT        = di.1.STAT        ;  Station node         (9000 - 11999 series)
          STAZ        = di.1.STAZ        ;  Nearest TAZ centroid (   1 -  3722 series)
          STAC        = di.1.STAC        ;  Station centroid    ( 5000 -  8000 series)
          STAP        = di.1.STAP        ;  Station PNR node    (12000 - 14999 series)
          STAN1       = di.1.STAN1       ;  Bus Node connector
          STAPCAP     = di.1.STAPCAP     ;  Parking lot capacity
          STAPKCOST   = di.1.STAPKCOST   ;  AM Pk daily parking cost
          STAOPCOST   = di.1.STAOPCOST   ;  Offpk       parking cost
          STAPKSHAD   = di.1.STAPKSHAD   ;  AM    Shadow parking cost
          STAOPSHAD   = di.1.STAOPSHAD   ;  Offpk Shadow parking cost
	      STWALKTM    = di.1.STWALKTM    ;  Rail station walk time (new data field)
          STACnt      =  dbi.1.NUMRECORDS


 ; IF ((MM = 'M' || MM ='C') && STAPARK = 'Y' && STAUSE = 'Y')
 IF ((MM = 'M' || MM ='C') && STAUSE = 'Y')

     _stwalktm = STWALKTM
	 
	if(MM='M') ; fxie @2/8
		 _parkpk = INT(max(200.0,(STAPKCOST/2.0)))   ; One-way AM     period parking cost
		 _parkop = INT(max(100.0,(STAOPCOST/2.0)))   ; One-way Off Pk period parking cost
	else
		 _parkpk = INT(max(1.0,(STAPKCOST/2.0)))     ; One-way AM     period parking cost
		 _parkop = INT(max(1.0,(STAOPCOST/2.0)))     ; One-way Off Pk period parking cost
	endif
	
     _walkpk= 0
     _walkop= 0
    if (STAPARK = 'Y')
     _walkpk = 200.00                            ; minimum walk time 2 mintues
     _walkop = 200.00
      IF (STAPCAP >  500) _Walkpk = 250.0        ; PNR walk times are longer for stations with larger lots
      IF (STAPCAP > 1000) _Walkpk = 350.0        ;
      IF (STAPCAP > 1500) _Walkpk = 400.0        ;
      IF (STAPCAP > 2000) _Walkpk = 500.0        ;
    endif
      _timepk = (_Walkpk + _parkpk/1.5 *@_MinPerDoll@ + STAPKSHAD)/100.   ; Peak PNR link composite impedance in min.

      _timeop = (_Walkop + _parkop/1.5 *@_MinPerDoll@ + STAOPSHAD)/100.   ; Peak PNR link composite impedance in min.

;;
;; the factor 1.5 in above statements is the pnr access time factor
;; The values STATION(X._STANOB) is actually the parking, we dont want to weight this term by 1.5 during the skimming process
;; So we devide the value by 1.5 to offset the weighting factor
;;


     PRINT LIST = STAT(6), _timepk(6.2), _timeop(6.2), _parkpk(6), _parkop(6), _stwalktm(6), ;
     FILE = "outputs\trn_net\_RAILSTATIONS.TXT"
 ENDIF
 
 ;; Create a lookup table for stations with an NCT code of 9 -fxie
 IF (NCT = 9)
     PRINT LIST = STAT(6), NCT(3), ;
     FILE = "outputs\trn_net\_STATIONNCT.TXT"
 ENDIF
ENDLOOP
ENDRUN


; ********************************************************************************************************
; II: update the transit network file with revised rail link travel time and PnR station
; ********************************************************************************************************

itr='%_iter_%'   ;*RJM*
pre='%_prev_%'   ;*RJM*


 LOOP PERIOD=1,4

 IF (PERIOD = 1)
  TIME_PERIOD = 'AM'
  AM_MODE = ' '
  MD_MODE = ';'
  PM_MODE = ';'
  NT_MODE = ';'
  PRD='AM'
 ELSEIF (PERIOD = 2)
  TIME_PERIOD = 'MD'
  AM_MODE = ';'
  MD_MODE = ' '
  PM_MODE = ';'
  NT_MODE = ';'
  PRD='MD'
 ELSEIF (PERIOD = 3)
  TIME_PERIOD = 'PM'
  AM_MODE = ';'
  MD_MODE = ';'
  PM_MODE = ' '
  NT_MODE = ';'
  PRD='PM'
 ELSE
  TIME_PERIOD = 'NT'
  AM_MODE = ';'
  MD_MODE = ';'
  PM_MODE = ';'
  NT_MODE = ' '
  PRD='NT'
 ENDIF


;; ************* Combine Transit Lines ***************

; combine bus/streetcar lines 1,2,6,7,8,9,10 (non-rail modes) to AM_Bus_Lines.lin
*copy "inputs\trn\Mode1@TIME_PERIOD@.lin" + "inputs\trn\Mode2@TIME_PERIOD@.lin" + "inputs\trn\Mode6@TIME_PERIOD@.lin" +
   "inputs\trn\Mode7@TIME_PERIOD@.lin" + "inputs\trn\Mode8@TIME_PERIOD@.lin" + "inputs\trn\Mode9@TIME_PERIOD@.lin" +
   "inputs\trn\Mode10@TIME_PERIOD@.lin"  "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"

; combine Metro and LRT 3,5 lines to @TIME_PERIOD@_MRL_Lines.lin
*copy "inputs\trn\Mode3@TIME_PERIOD@.lin" + "inputs\trn\Mode5@TIME_PERIOD@.lin"   "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"

; combine (copy) the commuter rail (mode 3) line to @TIME_PERIOD@_CRL_Lines.lin
*copy "inputs\trn\Mode4@TIME_PERIOD@.lin"  "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"


;
RUN PGM = NETWORK
ZONES=3722


NETI[1] = outputs\trn_net\@itr@_@TIME_PERIOD@_PT_INI.NET


LINKI[2] = INPUTS\trn\RAIL_LINKS.DBF

NETO=outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET, INCLUDE =DISTANCE,JUR,FTYPE,TOLL,TOLLGRP, AMLANE,AMLIMIT,PMLANE,PMLIMIT,OPLANE,OPLIMIT,
    TRANTIME,WKTIME,MODE,NCT9,PNRPARKCST,DRV_DISTANCE

; Rail station data file for lookup function - Gallop
  FILEI LOOKUPI[1]= "outputs\trn_net\_RAILSTATIONS.TXT"
  LOOKUP LOOKUPI=1, NAME= STATION, ;
  LOOKUP[1]= 1, RESULT=2, ;     AM peak PNR impedance
  LOOKUP[2]= 1, RESULT=3, ;     Off peak PNR impedance
  LOOKUP[3]= 1, RESULT=4, ;     AM parking cost
  LOOKUP[4]= 1, RESULT=5, ;     Off Peak parking cost
  LOOKUP[5]= 1, RESULT=6, ;     Station walk time
  INTERPOLATE=F, FAIL=0,0,0

; station file for lookup function
  FILEI LOOKUPI[2]= "outputs\trn_net\_STATIONNCT.TXT"
  LOOKUP LOOKUPI=2, NAME= STATIONNCT, ;
  LOOKUP[1]= 1, RESULT=2, ;     NCT code
  INTERPOLATE=F, FAIL=0,0,0

  IF (TRANTIME = 0) TRANTIME = ((DISTANCE/30) * 60)             ; ASSUMING SPEED= 30MPH if no highway speed
  IF (WKTIME = 0 && FTYPE <>1 && FTYPE <>5 && FTYPE <>6)
      WKTIME   = ((DISTANCE *60) /3)                            ; ASSUMING SPEED=3MPH FPR WALK LINKS
  ELSEIF (FTYPE =1 || FTYPE =5 || FTYPE =6)
      WKTIME   = 999
  ENDIF

 IF (MODE = 3,4) ; REVISE METRO RAIL LINK TIMES AND SPEEDS (INSTEAD OF BASED ON ASSUMED SPEED)
    TRANTIME = LI.2.TRANTIME
ENDIF


 IF (MODE = 15)   ; REVISE THE PNR CONNECTOR IMPEDANCE AND ADD STATION WALK TIME
   _STANOB =LI.1.B 
   IF(LI.1.A<LI.1.B) _STANOB =LI.1.A		    ;RETRIEVE THE PNR STATION NODE NUMBER
   
   @AM_MODE@    _PNRTIME  = STATION(1,_STANOB) + STATION(5,_STANOB)/100  ;READ AM PNRTIME FROM THE LOOKUP FUNCTION.
   @MD_MODE@    _PNRTIME  = STATION(2,_STANOB) + STATION(5,_STANOB)/100  ;READ MD PNRTIME FROM THE LOOKUP FUNCTION
   @PM_MODE@    _PNRTIME  = STATION(1,_STANOB) + STATION(5,_STANOB)/100  ;READ PM PNRTIME FROM THE LOOKUP FUNCTION.
   @NT_MODE@    _PNRTIME  = STATION(2,_STANOB) + STATION(5,_STANOB)/100  ;READ NT PNRTIME FROM THE LOOKUP FUNCTION
   TRANTIME= _PNRTIME
 ENDIF
 
 IF (MODE = 12,13,14)   ; ADD STATION WALK TIME FOR RAIL STATION WALK ACCESS LINKS
   _STANOA = LI.1.A		    ;RETRIEVE THE PNR STATION NODE NUMBER
   _STANOB = LI.1.B		    ;RETRIEVE THE PNR STATION NODE NUMBER


   @AM_MODE@    _WALKTIME  =  STATION(5,_STANOA)/100 + STATION(5,_STANOB)/100 ;READ AM STATION WALK TIME
   @MD_MODE@    _WALKTIME  =  STATION(5,_STANOA)/100 + STATION(5,_STANOB)/100 ;READ MD STATION WALK TIME
   @PM_MODE@    _WALKTIME  =  STATION(5,_STANOA)/100 + STATION(5,_STANOB)/100 ;READ PM STATION WALK TIME
   @NT_MODE@    _WALKTIME  =  STATION(5,_STANOA)/100 + STATION(5,_STANOB)/100 ;READ NT STATION WALK TIME
   TRANTIME= TRANTIME + _WALKTIME
   WKTIME= WKTIME + _WALKTIME
  ENDIF

 ; fxie @2/5/2021 change the limit code of mode 17 links from 9 to 0 so that they can be used in KNR NT leg generation
 IF (MODE =17)
	AMLIMIT=0
	PMLIMIT=0
	OPLIMIT=0
 ENDIF
 
 ; fxie @2/8/2021 calculate a "NCT9" attribute for mode 12,13,14 and 17 links that go to a station with NCT=9
 NCT9=0
 IF(MODE=12,13,14,17)
	_STANOB = LI.1.B
	if(STATIONNCT(1,_STANOB)==9)NCT9=1
 ENDIF

 ; fxie @ 10/10/2025 add two link variabls PNRPARKCST and DRV_DISTANCE
 
 ; One-way parking cost associated at PNR parking lot
 IF (MODE = 15)
   _STANOB =LI.1.B 
   IF(LI.1.A<LI.1.B) _STANOB =LI.1.A		    ;RETRIEVE THE PNR STATION NODE NUMBER
   
   IF (@PERIOD@=1,3)
		PNRPARKCST = INT(max(1.0,(STATION(3,_STANOB)/2.0)))   ; One-way PK period parking cost
   ELSE
		PNRPARKCST = INT(max(1.0,(STATION(4,_STANOB)/2.0)))   ; One-way OP period parking cost
   ENDIF
 
 ELSE
 
   PNRPARKCST =0	
     
 ENDIF	

 ; DRV_DISTANCE
  IF (MODE = 0,11)
	DRV_DISTANCE=LI.1.DISTANCE
  ELSE
    DRV_DISTANCE=0  
  ENDIF	
ENDRUN

; ********************************************************************************************************
; III: Create various Non-transit Leg files
; ********************************************************************************************************


;; **************************************
;; ***** A. Create Walk Acc and Egr Legs
;; **************************************

;; Step 1 ************* Walk Acc Link from Zone Centroid to Bus stops ***************
RUN PGM=PUBLIC TRANSPORT

  FILEI NETI       = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1]   = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI    = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_WK2Bus_@TIME_PERIOD@.LEG", XN=N  ;Do not output nodes between the start and end nodes of
                                         ;nontransit legs.
  PARAMETERS TRANTIME = lw.GENTRSTIME

PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 20,
      COST=li.WKTIME,
      MAXCOST=10*30,
      FROMNODE=1-3722,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 1,
      EXCLUDELINK = (li.MODE = 1-10),   ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 2 ************* Walk Egr Link from Bus Stops to zone Centroids ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI       = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1]   = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI    = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_WK2Bus_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 21,
      COST=li.WKTIME,
      MAXCOST=10*30,
      FROMNODE=1-3722,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10),    ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN


;; Step 3 ************* Walk Acc Link from Zone Centroid  to Metro/LRT stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1]   = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI    = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_WK2MetLRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 20,
      COST=li.WKTIME,
      MAXCOST=10*45,
      FROMNODE=1-3722,
      TONODE=8000-8999,10000-10499,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10),  ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 4 ************* Walk Egr Link from Metro/LRT stations to zone Centroids ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1]   = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI    = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO     = "outputs\trn_net\Egr_WK2MetLRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 21,
      COST=li.WKTIME,
      MAXCOST=10*45,
      FROMNODE=1-3722,
      TONODE=8000-8999,10000-10499,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10),    ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 5 ********* Walk Acc Link from Zone Centroid to Commuter rail stations **********

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1]   = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI    = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_WK2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 20,
      COST=li.WKTIME,
      MAXCOST=10*45,
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10)|| ((li.mode = 12) && (li.distance >= 1) && (li.b = 9000-9999)),  ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 6 ********* Walk Egr Link from commuter rail stations to zone Centroids *********

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_WK2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 21,
      COST=li.WKTIME,
      MAXCOST=10*45,
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10) || ((li.mode = 12) && (li.distance >= 1) && (li.b = 9000-9999)),    ;Mode 1 to 10 cannot be a part of non-transit path.
      MAXNTLEGS = 10*10,
      SLACK = 10*10,
      LIST = Y
  ENDPROCESS

ENDRUN



;; *********************************
;; *****  B. Create Walk Transfer Legs
;; *********************************

;; Step 1 ********** Transfer Walk links between bus stops ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Bus2Bus_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 22,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10500-10999,20000-54999,
      TONODE=10500-10999,20000-54999,
	  DIRECTION = 3,
	  EXCLUDELINK = (li.MODE = 1-10, 11,14),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 2 ************* Transfer Walk links between buses and Metro  ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Bus2Met_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 23,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=8000-8999,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 3 ************* Transfer Walk links between buses and Commuter rail  ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Bus2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 24,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=9000-9999,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 4 ************* Transfer Walk links between buses and LRT  ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Bus2LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 25,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10000-10499,
	  TONODE=10500-10999,20000-54999,
      DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN


;; Step 5 ************* Transfer Walk links between Metro Stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Met2Met_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 33,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=8000-8999,
      TONODE=8000-8999,
	  DIRECTION = 3,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 6 ************* Transfer Walk links between Metro and Bus ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Met2Bus_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 32,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=8000-8999,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 7 ************* Transfer Walk links between Metro and Commuter rail ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Met2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 34,
      COST=li.WKTIME + 5,    ; add 5 minutes to walk transfer time
      MAXCOST=10*30,
      FROMNODE=8000-8999,
      TONODE=9000-9999,
	  DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 8************* Transfer Walk links between Metro and LRT ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Met2LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 35,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=8000-8999,
      TONODE=10000-10499,
	  DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN


;; Step 9 ************* Transfer Walk links between Commuter rail Stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Com2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 44,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=9000-9999,
      TONODE=9000-9999,
	  DIRECTION = 3,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 10 ************* Transfer Walk links between Commuter rail and buses ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Com2Bus_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 42,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=9000-9999,
      TONODE=10500-10999,20000-54999,
      DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN


;; Step 11 ************* Transfer Walk links between Commuter rail and Metro ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Com2Met_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME ; add 5 minutes walk transfer time
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 43,
      COST=li.WKTIME + 5 ,  ; add 5 minutes walk transfer time
      MAXCOST=10*30,
      FROMNODE=8000-8999,
      TONODE=9000-9999,
	  DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 12 ************* Transfer Walk links between Commuter rail and LRT Stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_Com2LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 45,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10000-10499,
      TONODE=9000-9999,
	  DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN


;; Step 13 ************* Transfer Walk links between LRT Stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_LRT2LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 55,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10000-10499,
      TONODE=10000-10499,
	  DIRECTION = 3,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 14 ************* Transfer Walk links between LRT and buses  ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"

  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_LRT2Bus_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 52,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10000-10499,
	  TONODE=10500-10999,20000-54999,
      DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 10,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 15 ************* Transfer Walk links between LRT and Metro ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_LRT2Met_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 53,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=8000-8999,
      TONODE=10000-10499,
	  DIRECTION = 2,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN

;; Step 16 ************* Transfer Walk links between LRT and Commuter rail Stations ***************

RUN PGM=PUBLIC TRANSPORT

  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\WK_LRT2Com_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
  	lw.GENTRSTIME = li.WKTIME
  ENDPROCESS

  PROCESS PHASE = DATAPREP	
    GENERATE,
      NTLEGMODE = 54,
      COST=li.WKTIME,
      MAXCOST=10*15,
      FROMNODE=10000-10499,
      TONODE=9000-9999,
	  DIRECTION = 1,
	  EXCLUDELINK = (li.MODE = 1-10, 11),
      MAXNTLEGS = 3,
      SLACK = 10*5,
      LIST = Y
  ENDPROCESS

ENDRUN



;; ************* Combine Transit Lines ***************

; combine bus/streetcar lines 1,2,6,7,8,9,10 (non-rail modes) to AM_Bus_Lines.lin
*copy "inputs\trn\Mode1@TIME_PERIOD@.lin" + "inputs\trn\Mode2@TIME_PERIOD@.lin" + "inputs\trn\Mode6@TIME_PERIOD@.lin" +
   "inputs\trn\Mode7@TIME_PERIOD@.lin" + "inputs\trn\Mode8@TIME_PERIOD@.lin" + "inputs\trn\Mode9@TIME_PERIOD@.lin" +
   "inputs\trn\Mode10@TIME_PERIOD@.lin"  "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"

; combine Metro and LRT 3,5 to @TIME_PERIOD@_MRL_Lines.lin
*copy "inputs\trn\Mode3@TIME_PERIOD@.lin" + "inputs\trn\Mode5@TIME_PERIOD@.lin"   "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"


;; *********************************
;; ***** C. Create kiss-n-Ride Legs
;; *********************************
;RSG 01/20/2020: generate access and egress NT Legs by reversing direction
;;
;; Step 1a **** Create KNR Access links for Metrorail stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_KNR_MR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
		lw.NCT9  = li.NCT9                        ; Label links with NCT restrictions
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*15,           ; gallop
      FROMNODE=1-3722,
      TONODE=8000-8999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10, 11,15)|| (LW.LIMIT = 9)|| (LW.NCT9=1),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 1b **** Create KNR Egress links for Metrorail stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
																
  FILEI FACTORI[1] = "Inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_KNR_MR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
		LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
		lw.NCT9  = li.NCT9                        ; Label links with NCT restrictions
		@AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
		@MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
		@PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
		@NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*15,           ; gallop
      FROMNODE=1-3722,
      TONODE=8000-8999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10, 11,15)|| (LW.LIMIT = 9)|| (LW.NCT9=1),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 2 **** Create KNR links for commuter rail stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_KNR_CR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*15,           ; gallop
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,11,15)|| (LW.LIMIT = 9),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 2b **** Create KNR Egress links for commuter rail stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_KNR_CR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*15,           ; gallop
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,11,15)|| (LW.LIMIT = 9),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 3 **** Create KNR links for LRT/BRT car stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_KNR_LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
		lw.NCT9  = li.NCT9                        ; Label links with NCT restrictions		
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*10,           ; gallop
      FROMNODE=1-3722,
      TONODE=10000-10999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,11,15)|| (LW.LIMIT = 9)|| (LW.NCT9=1),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 3b **** Create KNR Egress links for LRT/BRT car stations
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_KNR_LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
		lw.NCT9  = li.NCT9                        ; Label links with NCT restrictions		
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9	
	ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*10,           ; gallop
      FROMNODE=1-3722,
      TONODE=10000-10999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,11,15)|| (LW.LIMIT = 9)|| (LW.NCT9=1),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 4 **** Create KNR links for bus stations (Bus PNR stations only)
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_KNR_BUS_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*10,           ; gallop
      FROMNODE=1-3722,
      TONODE=15000-15999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10, 11,15)|| (LW.LIMIT = 9),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;;
;; Step 4b **** Create KNR Egress links for bus stations (Bus PNR stations only)
;;
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_KNR_BUS_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9	
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 18,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*10,           ; gallop
      FROMNODE=1-3722,
      TONODE=15000-15999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10, 11,15)|| (LW.LIMIT = 9),
      MAXNTLEGS = 10*5,        ;gallop
      SLACK = 10*5,           ; gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;;
;; *********************************
;; ***** D. Create Park-n-Ride legs
;; *********************************

;; Step 1 **** Create PNR access links to Metrorail station

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_PNR_MR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		

  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*60,        ;
      FROMNODE=1-3722,
      TONODE=8000-8999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*15,        ; Revise the "slack" value to 15 min. - Gallop
      LIST = Y
  ENDPROCESS  
ENDRUN

;;
;; Step 1b **** Create PNR Egress links for Metrorail stations

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\AM_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_PNR_MR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		

  ENDPROCESS

  PROCESS PHASE = DATAPREP

    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*60,        ; Revise max. cost in min. (note cost include pnr parking cost and walk time combined) - Gallop
      FROMNODE=1-3722,
      TONODE=8000-8999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*15,        ; Revise the "slack" value to 15 min. - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN

;;
;; Step 2 **** Create PNR links for Commuter rail stations

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_PNR_CR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP

    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*60,        ; Revise max. cost in min. (note cost include pnr parking cost and walk time combined) - Gallop
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*15,        ; Revise the "slack" value to 15 min. - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 2b **** Create PNR Egress links for Commuter rail stations

													
 
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\AM_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_PNR_CR_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*60,        ; Revise max. cost in min. (note cost include pnr parking cost and walk time combined) - Gallop
      FROMNODE=1-3722,
      TONODE=9000-9999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*15,        ; Revise the "slack" value to 15 min. - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 3 **** Create PNR links for LRT/BRT stations

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_PNR_LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP 
    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*30,        ; Revise max. cost in min. (note cost include pnr parking cost and walk time combined) - Gallop
      FROMNODE=1-3722,
      TONODE=10000-10999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*10,        ; Revise the "slack" value to 10 min. for LRT stations - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 3b **** Create PNR Egress links for LRT stations

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\AM_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_PNR_LRT_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME + (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*30,        ; Revise max. cost in min. (note cost include pnr parking cost and walk time combined) - Gallop
      FROMNODE=1-3722,
      TONODE=10000-10999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*10,        ; Revise the "slack" value to 10 min. for LRT stations - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;			  

;; Step 4 **** Create PNR links for Bus PnR stations
 
RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "inputs\trn\@TIME_PERIOD@_TRN.FAC"
  FILEI SYSTEMI = "inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Acc_PNR_BUS_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP
    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME +  (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*30,
      FROMNODE=1-3722,
      TONODE=15000-15999,
      DIRECTION = 1,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*10,        ; Revise the "slack" value to 10 min. for bus PnR stations - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN
;;
;; Step 4b **** Create PNR Egress links for Bus PnR stations

RUN PGM=PUBLIC TRANSPORT
  FILEI NETI = "outputs\trn_net\@itr@_@TIME_PERIOD@_PT.NET"
  FILEI LINEI[1] = "outputs\trn_net\@TIME_PERIOD@_Bus_Lines.lin"
  FILEI LINEI[2] = "outputs\trn_net\@TIME_PERIOD@_MRL_Lines.lin"
  FILEI LINEI[3] = "outputs\trn_net\@TIME_PERIOD@_CRL_Lines.lin"
  FILEI FACTORI[1] = "Inputs\trn\AM_TRN.FAC"
  FILEI SYSTEMI = "Inputs\trn\TSYSD.PTS"

  FILEO NTLEGO = "outputs\trn_net\Egr_PNR_BUS_@TIME_PERIOD@.LEG", XN=N

  PARAMETERS TRANTIME = lw.GENTRSTIME

  PROCESS PHASE = LINKREAD
        lw.GENTRSTIME = li.TRANTIME
        LW.LIMIT = 0                              ; Set link restriction code "LIMIT"
 @AM_MODE@        IF (LI.AMLIMIT= 9) LW.LIMIT = 9
 @MD_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
 @PM_MODE@        IF (LI.PMLIMIT= 9) LW.LIMIT = 9
 @NT_MODE@        IF (LI.OPLIMIT= 9) LW.LIMIT = 9		
  ENDPROCESS

  PROCESS PHASE = DATAPREP

    GENERATE,
      NTLEGMODE = 19,
      COST=li.TRANTIME +  (li.toll+li.PNRPARKCST+li.DRV_DISTANCE*@_opcost@)/100*@_MinPerDoll@,
      MAXCOST=10*30,
      FROMNODE=1-3722,
      TONODE=15000-15999,
      DIRECTION = 2,
      EXCLUDELINK = (li.Mode = 1-10,12-14,17)|| (LW.LIMIT = 9),     ; Only Mode 0, Mode 11 and Mode 15 links will be allowed -fxie
      MAXNTLEGS = 10*5,     ; Revise max. no. of legs to 5 for all transit modes, Gallop
      SLACK = 10*10,        ; Revise the "slack" value to 10 min. for bus PnR stations - Gallop
      LIST = Y
  ENDPROCESS
ENDRUN


;; ************* Combine walk access/egress/transfer Non-Transit Legs ************************************
 *copy "outputs\trn_net\ACC_WK2BUS_@TIME_PERIOD@.LEG" + "outputs\trn_net\ACC_WK2METLRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\ACC_WK2COM_@TIME_PERIOD@.LEG" "outputs\trn_net\WACC_@TIME_PERIOD@.LEG"
 *copy "outputs\trn_net\EGR_WK2BUS_@TIME_PERIOD@.LEG" + "outputs\trn_net\EGR_WK2METLRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\EGR_WK2COM_@TIME_PERIOD@.LEG" "outputs\trn_net\WEGR_@TIME_PERIOD@.LEG"
 *copy "outputs\trn_net\WK_BUS2BUS_@TIME_PERIOD@.LEG" +"outputs\trn_net\WK_BUS2COM_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_BUS2LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_BUS2MET_@TIME_PERIOD@.LEG" +
   "outputs\trn_net\WK_COM2BUS_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_COM2COM_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_COM2LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_COM2MET_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_LRT2BUS_@TIME_PERIOD@.LEG" +
    "outputs\trn_net\WK_LRT2COM_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_LRT2LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_LRT2MET_@TIME_PERIOD@.LEG" +
  "outputs\trn_net\WK_MET2BUS_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_MET2COM_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_MET2LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\WK_MET2MET_@TIME_PERIOD@.LEG" "outputs\trn_net\XFER_@TIME_PERIOD@.LEG"
;; ****************************************************************************


;; ************* Combine KNR Non-Transit Legs ************************************

;* COPY "outputs\trn_net\KNR_CR_@TIME_PERIOD@.LEG" + "outputs\trn_net\KNR_MR_@TIME_PERIOD@.LEG"  + "outputs\trn_net\KNR_LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\KNR_BUS_@TIME_PERIOD@.LEG" "outputs\trn_net\KNR_@TIME_PERIOD@.LEG"
* COPY  "outputs\trn_net\Acc_KNR_MR_@TIME_PERIOD@.LEG"  + "outputs\trn_net\Acc_KNR_LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\Acc_KNR_BUS_@TIME_PERIOD@.LEG" "outputs\trn_net\Acc_KNR_@TIME_PERIOD@.LEG"
* COPY  "outputs\trn_net\Egr_KNR_MR_@TIME_PERIOD@.LEG"  + "outputs\trn_net\Egr_KNR_LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\Egr_KNR_BUS_@TIME_PERIOD@.LEG" "outputs\trn_net\Egr_KNR_@TIME_PERIOD@.LEG"

;; ********************************************************************************
;; ************* Combine PNR Non-Transit Legs ************************************

* COPY "outputs\trn_net\Acc_PNR_CR_@TIME_PERIOD@.LEG" + "outputs\trn_net\Acc_PNR_MR_@TIME_PERIOD@.LEG"  + "outputs\trn_net\Acc_PNR_LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\Acc_PNR_BUS_@TIME_PERIOD@.LEG" "outputs\trn_net\Acc_PNR_@TIME_PERIOD@.LEG"
* COPY "outputs\trn_net\Egr_PNR_CR_@TIME_PERIOD@.LEG" + "outputs\trn_net\Egr_PNR_MR_@TIME_PERIOD@.LEG"  + "outputs\trn_net\Egr_PNR_LRT_@TIME_PERIOD@.LEG" + "outputs\trn_net\Egr_PNR_BUS_@TIME_PERIOD@.LEG" "outputs\trn_net\Egr_PNR_@TIME_PERIOD@.LEG"
;; ********************************************************************************

ENDLOOP  ; --- END PERIOD LOOP ---



