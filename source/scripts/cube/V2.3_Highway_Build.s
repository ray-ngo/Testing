*del voya*.prn
;=========================================================================
;  HIGHWAY_BUILD_TOLL.S
;
;  MWCOG Version 2.3 Model  - Highway Network Building Program
;  Toll-DBF lookup file used
;;========================================================================
;;  2/26/24 rn read zone.dbf file from the output subfolder. This file is generated in AreaType_File.s
;;  12/4/12 rm added 'timepen' varible to output network
;;  3/13/13   timepen = 11 if screen=20 or screen = 36 zero otherwise (Bridge Ks removed in set_factors.s)
;;           (these are the potomac river bridges from WWB to the Harpers Ferry Bridge)
;;  3/09/22 based on updated code by fxie at 'Z:\ModelRuns\fy22\Gen3_Model_Runs\source\scripts\cube\',
;;          This file is followed by his update.
;;
;;========================================================================

; PARAMETERS :
  ZONESIZE  =  3722                        ; Max. TAZ No.            (Param)
  LSTITAZ   =  3675                        ; Last Internal Zone No.  (Param)
  FstHwyNode = 20000                       ; First Highway node      (Param)

; I/O Files :
  NODEFILE  = 'inputs\hwy\NODE.dbf'            ; Node X/Y File           (I/P file)
  LINKFILE  = 'inputs\hwy\LINK.dbf'            ; Link File               (I/P file)
  ZONEFILE  = 'outputs\landuse\ZONE.dbf'            ; Zonal Land Use File     (I/P file)
  ;;AT_OVR    = 'AREAOVER.ASC'             ; Area Type Override file (I/P file)
  ATYPFILE  = 'outputs\landuse\AreaType_File.dbf'          ; Zonal Area Type file    (I/P file)

  AMSPD     = '..\support\AM_SPD_LKP.txt'       ; AM       Speed lookup ATxFT   (I/P file)
  MDSPD     = '..\support\MD_SPD_LKP.txt'       ; Midday   Speed lookup ATxFT   (I/P file)

  TOLL_Esc  = 'inputs\hwy\TOLL_Esc.dbf'        ; INPUT Toll Escalation Param file
  HWY_Defl  = 'outputs\reports\HWY_Deflator.txt'           ; INPUT Default Highway Deflator (I/P file)
  LKTAZFILE = 'outputs\hwy_net\LinkTAZ.DBF'                ; Nearest Taz to each link file(O/P file)
  OU_BSNET  = 'outputs\hwy_net\ZONEHWY.NET'                ; OUTPUT BUILT network FILE

;--------------------------------------------------------------------------------
; Associate each link in the network to its nearest TAZ
 RUN PGM=MATRIX
 ZONES=1

 FILEI DBI[1]     = "@LINKFILE@"                                   ; highway links
 FILEO RECO[1]    = "@LKTAZFILE@",fields = A(8),B(8),AB(15),TAZ(8) ; output a/b & nearest TAZ

 FileI LOOKUPI[1] = "@nodefile@"
 LOOKUP LOOKUPI=1, NAME=nodexys,
        LOOKUP[1] = N, RESULT=x,   ;
        LOOKUP[2] = N, RESULT=y,   ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

 LOOP L= 1,dbi.1.NUMRECORDS
          y=DBIReadRecord(1,L)
          A = di.1.A
          B = di.1.B

 ;
 ; The TAZ designated for the link is that with the minimum distance
 ; to either the A-node or the B-node
 ;
     If      (A <= @ZONESIZE@)
              TAZ =A
      elseIf (B <= @ZONESIZE@)
              TAZ =B
      else
            Ax =nodexys(1,A)
            Ay =nodexys(2,A)
            bx =nodexys(1,B)
            by =nodexys(2,B)
            TAZ= 0

            IF  (AX > 0 && BX > 0)
              midx  = (Ax+ Bx)/2.0
              midy  = (Ay+ By)/2.0
              mindist = 9999999.
              TAZ=0
              loop tdx=1,@LstITAZ@
                   CURDIST=  SQRT( (midx - nodexys(1,tdx))**2 + (midy - nodexys(2,tdx))**2 )/ 5280.
                   if (curdist < mindist)
                       mindist = curdist
                       TAZ = TDX
                   ENDIF
              endloop
            Endif
      Endif
      ;;Let's check this
        if (L= 1-10, 10000-10100,30000-30100)
            print form=10   list = A, B, TAZ, ';;; A XY: ',Ax,Ay,' B XY: ', Bx,By,' MidXY: ', midx,midy, file= outputs\hwy_net\Link_Taz_Check.txt
        endif

        ro.A    = A
        ro.B    = B
        ro.AB   = A*100000 + B
        ro.TAZ  = TAZ
        WRITE RECO= 1
 ENDLOOP
 endrun

;
;=================================================================
;
;  Highway Building Part 1 - Develop Area type, Spdclass/CapClass Vars
;
;=================================================================
;
RUN PGM = NETWORK
ZONES=@ZONESIZE@

; Node Coordinate File
; XY Units are NAD83 (in whole feet)
FILEI NODEI=@Nodefile@
        ; Node
        ; X Crd
        ; Y Crd

; Highway Links
FILEI LINKI=@LINKFILE@
        ; A-Node Number
        ; B-Node Number
        ; Distance in whole miles (xx.xx)
        ; Speed Class(optional)
        ; Capacity Class(optional)
        ; Observed AAWDT in 1000's
        ; Count Type 0,1,2,6,7
        ; Jurisdiction Code (0-23)
        ; Screenline Code   (1-36)
        ; Facility Type Code (0-6)
        ; Current year Toll Value in cents
        ; Toll Group code (1-10)
        ; AM Peak Prd. No. of Lanes
        ; AM Peak Period Operation Code (0-9)
        ; PM Peak Prd. No. of Lanes
        ; PM Peak Period Operation Code (0-9)
        ; Off-Peak Prd. No. of Lanes
        ; Off-Peak Period Operation Code (0-9)
        ; EDGEID
        ; Project ID String
        ; Code

;   Note:
;   The Standard SPDCLASS(1-67), CAPCLASS(1-67),& TAZ defined below
;
NETO=TEMP.NET  ; TEMPORARY NETWORK TO BE PASSED ONTO NEXT STEP


;-------------------------------------------------------------
; Develop Link Area type/ Spdclass/ Capclass Attributes      -
;-------------------------------------------------------------

;
; Zonal Area Type Lookup (produced above)
;
FileI LOOKUPI[1] ="@atypfile@"
LOOKUP LOOKUPI=1, NAME=ZNAT,
       LOOKUP[1] = TAZ, RESULT=AType,   ;
       INTERPOLATE=N, FAIL= 0,0,0, LIST=N

FileI LOOKUPI[2] ="@lktazfile@"
LOOKUP LOOKUPI=2, NAME=lktaz,
       LOOKUP[1] = ab, RESULT=TAZ,   ;
       INTERPOLATE=N, FAIL= 0,0,0, LIST=N

 FileI LOOKUPI[3] = "@TOLL_ESC@"
 LOOKUP LOOKUPI=3, NAME=Toll_Esc,
        LOOKUP[1]= TOLLGrp, result=EscFAC,     ;
        LOOKUP[2]= TOLLGrp, result=DstFAC,     ;
        LOOKUP[3]= TOLLGrp, result=AM_TFtr,    ;
        LOOKUP[4]= TOLLGrp, result=PM_TFtr,    ;
        LOOKUP[5]= TOLLGrp, result=OP_TFtr,    ;
        LOOKUP[6]= TOLLGrp, result=AT_Min,     ; x
        LOOKUP[7]= TOLLGrp, result=AT_Max,     ; x
        LOOKUP[8]= TOLLGrp, result=TollType,   ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

_ABJoined = A*100000 + B

;; Ensure Centroids have lanes coded
; IF (MODE <> 0) DELETE

IF (A<= 3722 || B <= 3722)
              SCREEN   =0     ; Screenline Code   (1-36)
              FTYPE    =0     ; Facility Type Code (0-6)
              TOLL     =0     ; Current year Toll Value in cents
              TOLLGRP  =0     ; Toll Group code (1-10)
              AMLANE   =7     ; AM Peak Prd. No. of Lanes
              AMLIMIT  =0     ; AM Peak Period Operation Code (0-9)
              PMLANE   =7     ; PM Peak Prd. No. of Lanes
              PMLIMIT  =0     ; PM Peak Period Operation Code (0-9)
              OPLANE   =7     ; Off-Peak Prd. No. of Lanes
              OPLIMIT  =0     ; Off-Peak Period Operation Code (0-9)
ENDIF


TAZ      = LKTAZ(1,_ABJOINED)
AType    = ZNAT(1,TAZ)            ;  Area Type
;
;
;  Here we will override the standard default Area Type code for any link with a
;  TOLLGRP code - user's option
;  area type override range (Min, Max)
;  (via TG_ATOVR lookup table in the TOLL Group lookup file)

           _TG_ATMin  =    Toll_Esc(6,tollgrp)
           _TG_ATMax  =    Toll_Esc(7,tollgrp)
           _DefaultAT =    AType

           IF (_TG_ATMin > 0 && _DefaultAT < _TG_ATMin) AType  = _TG_ATMin
           IF (_TG_ATMax > 0 && _DefaultAT > _TG_ATMax) AType  = _TG_ATMax


   ;;      IF (AType < 1 || AType > 7)
   ;;          print list= 'A: ',A(5),' B: ',B(5),' TAZ: ',TAZ: ',TAZ(3),' Area Type: ', AType(3)
   ;;          ABORT
   ;;      ENDif
;
;
; With the TAZ designated, now the speed/capacity class is defined as
; a two-digit code-- facility type & areatype
;
           SPDCLASS =  FTYPE*10 + AType      ;  Speed Class
           CAPCLASS =  FTYPE*10 + AType      ;  Capacity Class

;
;
; Check that TOLLGRP is coded for any link coded with a TOLL value-
;  IF TOLLGRP is not coded with non-zero value, then give it a default
;  value of '1.0'
;
          IF (TOLL > 0.0 && TOLLGRP = 0.0)
              TOLLGRP = 1.0
          ENDIF
;
;
;  Set the Night (NT) and Midday (MD) lanes, limits equal to the Off-peak
;  values read in on the link
       MDLANE  =    OPLANE
       MDLIMIT =    OPLIMIT

       NTLANE  =    OPLANE
       NTLIMIT =    OPLIMIT

;
ENDRUN


;=================================================================
;
;  Highway Building Part 2 - develop deflated highway tolls and
;                            pump prime speeds
;
;=================================================================
;
RUN PGM = NETWORK

ZONES=@ZONESIZE@

NETI=TEMP.NET
; output network in TP+ format
NETO = outputs\hwy_net\zonehwy_unbuild.net
;
; Compute AM, PM, Off-Peak Tolls
; The tolls are read in as undeflated, based on the coded TOLL value on the
;  link and/or as a function of a distance based rate;
;  The deflation is handled below.  If the 'escfac' lookup (in the TOLL_Esc.dbf file)
;  is non-zero, then it is used to deflate.  If it is zero, then the the default
;  highway deflator 'DEFLATION' (calculated in the SET_Factors.s script) is used.
;  The recommended appraoch is to set the 'escfac' lookup array to zero and use
;  HWY_Deflator
;
FileI LOOKUPI[1]= "@TOLL_ESC@"
LOOKUP LOOKUPI=1, NAME=Toll_Esc,
        LOOKUP[1]= TOLLGrp, result=EscFAC,     ; x
        LOOKUP[2]= TOLLGrp, result=DstFAC,     ; x
        LOOKUP[3]= TOLLGrp, result=AM_TFtr,    ; x
        LOOKUP[4]= TOLLGrp, result=PM_TFtr,    ; x
        LOOKUP[5]= TOLLGrp, result=OP_TFtr,    ; x
        LOOKUP[6]= TOLLGrp, result=AT_Min,     ;
        LOOKUP[7]= TOLLGrp, result=AT_Max,     ;
        LOOKUP[8]= TOLLGrp, result=TollType,   ; x
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


READ FILE=@HWY_Defl@

; deflated toll based on escfac:
AMTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(3,tollgrp)*Toll_Esc(1,tollgrp)
PMTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(4,tollgrp)*Toll_Esc(1,tollgrp)
OPTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(5,tollgrp)*Toll_Esc(1,tollgrp)


; if escfac set to zero then deflate based on HWY_Deflator:
  IF (AMTOLL = 0)
      AMTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(3,tollgrp)*DEFLATIONFTR
  ENDIF
  IF (PMTOLL = 0)
      PMTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(4,tollgrp)*DEFLATIONFTR
  ENDIF
  IF (OPTOLL = 0)
      OPTOLL=(TOLL+(Toll_Esc(2,tollgrp)*DISTANCE))*Toll_Esc(5,tollgrp)*DEFLATIONFTR
  ENDIF
; ----------------------------------------------------------------------------
; 1/25/08/ rm  Changes made to develop special travel times/tolls for the MC
;              program regarding variably priced facilities

   AMTOLL_VP = 0
   PMTOLL_VP = 0
   OPTOLL_VP = 0



; Check that coded tolls have a TOLLTYPE designation
;  then define tolls on variably priced facilities ONLY
  _TOLLTP   =  Toll_Esc(8,tollgrp)        ;
  IF ((AMTOLL > 0 || PMTOLL > 0 || OPTOLL>0) && _TOLLTP = 0)
      LIST=' non-zero TOLL exists on a link has a zero TOLLTYPE code'
      abort
   ELSEIF (_TOLLTP = 2)
      AMTOLL_VP = AMTOLL
      PMTOLL_VP = PMTOLL
      OPTOLL_VP = OPTOLL
  ENDIF
; ----------------------------------------------------------------------------

;
; AM and Off-peak Initial Speed Lookup Tables...
;
; Use two lookups for AM/OP period by Facility type and Area type for now.
;
lookup name = amspd,            ;   AM Initial Speeds Atype x Ftype
       lookup[1] = 1,result=2,  ; AM CentConn Speeds (mph)
       lookup[2] = 1,result=3,  ; AM Freeway  Speeds (mph)
       lookup[3] = 1,result=4,  ; AM Maj Art  Speeds (mph)
       lookup[4] = 1,result=5,  ; AM Min Art  Speeds (mph)
       lookup[5] = 1,result=6,  ; AM Collect  Speeds (mph)
       lookup[6] = 1,result=7,  ; AM Exprway  Speeds (mph)
       lookup[7] = 1,result=8,  ; AM Ramp     Speeds (mph)
       interpolate=N,fail=0,0,0,file=@AMSPD@

lookup name = opspd,            ; Off-Pk Initial Speeds Atype x Ftype
       lookup[1] = 1,result=2,  ; Off-pk CentConn Speeds (mph)
       lookup[2] = 1,result=3,  ; Off-pk Freeway  Speeds (mph)
       lookup[3] = 1,result=4,  ; Off-pk Maj Art  Speeds (mph)
       lookup[4] = 1,result=5,  ; Off-pk Min Art  Speeds (mph)
       lookup[5] = 1,result=6,  ; Off-pk Collect  Speeds (mph)
       lookup[6] = 1,result=7,  ; Off-pk Exprway  Speeds (mph)
       lookup[7] = 1,result=8,  ; Off-pk Ramp     Speeds (mph)
       interpolate=N,fail=0,0,0,file=@MDSPD@

        _IDX    =  FTYPE + 1
        PPAMSPD= AMSPD(_IDX,AType)
        PPOPSPD= OPSPD(_IDX,AType)

;
; ESTABLISH  AM/PM/MD/NT    Highway Times (for the transit Network)
;
PPPMSPD =  PPAMSPD                  ; assume PM spd is equal to AM
IF (PPAMSPD != 0 )
  AMHTIME    =  (DISTANCE/PPAMSPD)*60.00
  PMHTIME    =  (DISTANCE/PPPMSPD)*60.00
 ELSE
  AMHTIME    =  0.01
  PMHTIME    =  0.01
ENDIF

IF (PPOPSPD != 0 )
  OPHTIME    =  (DISTANCE/PPOPSPD)*60.00
 ELSE
  OPHTIME    =  0.01
ENDIF

MDTOLL      = OPTOLL
MDTOLL_VP   = OPTOLL_VP
PPMDSPD     = PPOPSPD
MDHTIME     = OPHTIME

NTTOLL      = OPTOLL
NTTOLL_VP   = OPTOLL_VP
PPNTSPD     = PPOPSPD
NTHTIME     = OPHTIME


;;**  Create timepen variable here
;;   11 minute perceived time penalty at the Potomac River
;;    from WWB to the Harpers Ferry Bridge
timepen =0.0
IF (screen = 20 || screen = 36)

    timepen = 11.0

ENDIF

; Anacostia River Bridges
IF((A = 21211 & B = 21577) | (B = 21211 & A = 21577) | ; Benning Rd NE
   (A = 20973 & B = 21179) | (B = 20973 & A = 21179) | ; E Capitol St
   (A = 20969 & B = 21417) | (B = 20969 & A = 21417) | ; Pennsylvania Ave SE
   (A = 20965 & B = 21851) | (B = 20965 & A = 21851) | ; 11th Street SE
   (A = 20964 & B = 21296) | (B = 20964 & A = 21296) | ; MLK Bridge
   (A = 21340 & B = 21421) | (B = 21340 & A = 21421))  ; S Capitol St
   timepen = 5.0
ENDIF

;;** end timepen variable section



;  CREATE SOME FREQUENCY-CROSSTABS FOR CHECKING
_CNT= 1
_AMLANEMI= AMLANE*DISTANCE
_OPLANEMI= OPLANE*DISTANCE
_PMLANEMI= PMLANE*DISTANCE

CROSSTAB VAR=_AMLANEMI,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=ATYPE, RANGE=1-7-1, 1-7
CROSSTAB VAR=_OPLANEMI,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=ATYPE, RANGE=1-7-1, 1-7
CROSSTAB VAR=_PMLANEMI,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=ATYPE, RANGE=1-7-1, 1-7

CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=AMLANE, RANGE=1-7-1, 1-7
CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=OPLANE, RANGE=1-7-1, 1-7
CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=PMLANE, RANGE=1-7-1, 1-7

CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=AMLIMIT,RANGE=0-9-1,0-9
CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=OPLIMIT,RANGE=0-9-1,0-9
CROSSTAB VAR=_CNT,ROW=FTYPE, RANGE=1-7-1,,1-7, COL=PMLIMIT,RANGE=0-9-1,0-9

;
;


ENDRUN

RUN PGM = NETWORK

ZONES=@ZONESIZE@

NETI = outputs\hwy_net\zonehwy_unbuild.net
; output network in TP+ format
NETO = outputs\hwy_net\zonehwy.net

IF (MODE <> 0) DELETE

ENDRUN
