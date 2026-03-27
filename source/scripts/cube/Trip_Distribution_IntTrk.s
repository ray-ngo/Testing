;*del voya*.prn

; Trip_Distribution_Internal.s  - Version 2.3 Trip Distribution
;
ZONESIZE  =  3722                 ; Max. TAZ No.            (Param)
LSTITAZ   =  3675                 ; Last Internal Zone No.  (Param)

AMSOVSKM = 'outputs\skims\%_prev_%_am_sov.skm'             ;  AM  HWY TIME SKIMS
MDSOVSKM = 'outputs\skims\%_prev_%_md_sov.skm'             ;  MD  HWY TIME SKIMS


ATYPFILE = 'outputs\landuse\AreaType_File.dbf'             ; Zonal Area Type file    (I/P file)
HWYTERM  = 'outputs\auxiliary\ztermtm.asc'                   ;  Zonal HWY TERMINAL TIME file (created in THIS script)


AWTRNSKM = 'outputs\skims\%_iter_%_am_wk_MR_wk.ttt'         ;  AM WK (Metrorail only) ACC TRN TIME SKIMS
ADTRNSKM = 'outputs\skims\%_iter_%_am_dr_MR_wk.ttt'         ;  AM DR (Metrorail Only) ACC TRN TIME SKIMS

MWTRNSKM = 'outputs\skims\%_iter_%_md_wk_MR_wk.ttt'         ;  OP WK (Metrorail only) ACC TRN TIME SKIMS
MDTRNSKM = 'outputs\skims\%_iter_%_md_dr_MR_wk.ttt'         ;  OP DR (Metrorail Only) ACC TRN TIME SKIMS

; -------------------------------------------------------------------
; Equivalent minutes (min/'07$) by income level (for toll modeling)
toll_inc = '..\support\equiv_toll_min_by_inc.s'    ; Equivalent minutes (min/'07$) by period & income level (for toll modeling)
in_tmin = '..\support\toll_minutes.txt'                        ;; read in toll minutes equiv file

FFsFile   = '..\SUPPORT\ver23_f_factors.dbf'  ; F-Factors for all modeled purposes
;;Variables in the dbf file:
; IMP     HBWINC1 HBWINC2 HBWINC3 HBWINC4 HBWEI HBWEA    ;
;         HBSINC1 HBSINC2 HBSINC3 HBSINC4 HBSEI HBSEA    ;
;         HBOINC1 HBOINC2 HBOINC3 HBOINC4 HBOEI HBOEA    ;
;         NHW     NHO     NHBEI   NHBEA                  ;
;         ICOM    IMTK    IHTK    EXTCOM  EXTMTK  EXTHTK ;
;
;

;;===============================================================
;;===============================================================
;; ALL Internal Motorized Ps AND As, by purpose
PsAs = 'outputs\auxiliary\%_iter_%_Final_Int_Motor_PsAs.dbf'
;;Variables in dbf file:
;;TAZ,    COMIP,COMIA,
;;        MTKIP,MTKIA,
;;        HTKIP,HTKIA
;;===============================================================
;;===============================================================

;; External trip tables, by purpose- developed in earlier trip distribution step
;;
COM_EXT_TRIPS = 'outputs\auxiliary\%_iter_%_COMext.VTT'
MTK_EXT_TRIPS = 'outputs\auxiliary\%_iter_%_MTKext.VTT'
HTK_EXT_TRIPS = 'outputs\auxiliary\%_iter_%_HTKext.VTT'
;
;; OUTPUT TRIP TABLES
COMTDOUT  = 'outputs\auxiliary\%_iter_%_COMMER.PTT';
MTKTDOUT  = 'outputs\auxiliary\%_iter_%_MTRUCK.PTT';
HTKTDOUT  = 'outputs\auxiliary\%_iter_%_HTRUCK.PTT';


; |\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
; |//////      Start COM/TRK Trip Distribution Here:               /////|
; |\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|

RUN PGM=TRIPDIST
  MATI[1] = outputs\skims\%_prev_%_MD_SOV.SKM       ; Off-Pk Time Imped. for COM
  MATI[2] = outputs\skims\%_prev_%_MD_TRUCK.skm       ; Off-Pk Truck Time for MTK/HTK
  MATI[3] = outputs\skims\md_sov_termIntraTime_e.skf            ; Midday Time skims for Extl trip dist.

  READ FILE = @in_tmin@

; Put impedance matrices in work tables 11-12.  Tab 11 is for COM
; trips; tab 12 is for MTK and HTK trips.  All time values are in minutes.
; Modified by fxie on 1/27/2025: cv/trk impedances now consider tolls from Midday

 MW[1] = MI.1.1 ; CV MD time
 MW[2] = MI.1.3 ; CV MD toll in cents
 MW[3] = MI.2.1 ; trk MD time
 MW[4] = MI.2.3 ; trk MD toll in cents

 MW[11]  = Round(MW[1] + ((MW[2]/100.0) * CVMDEQM))  ; com veh los  matix
 MW[12]  = Round(MW[3] + ((MW[4]/100.0) * TKMDEQM))  ; trk     los  matrix
 MW[13]  = MI.3.1  ; extl    los  matrix

ZDATI[1]  = @PsAs@

;  FFactors
FileI LOOKUPI[1] = "@FFsFile@"
LOOKUP LOOKUPI=1, NAME=FF,
       LOOKUP[1]  = IMP, RESULT=ICOM,       ; CVInt
       LOOKUP[2]  = IMP, RESULT=IMTK,       ; MTrk Intl
       LOOKUP[3]  = IMP, RESULT=IHTK,       ; HTrk Intl
       INTERPOLATE=N,SETUPPER=T,FAIL=0,0,0

;  Establish production and attraction vectors here:

SETPA P[1]=ZI.1.COMIA, P[2]=ZI.1.MTKIA, P[3]=ZI.1.HTKIA
SETPA A[1]=ZI.1.COMIA, A[2]=ZI.1.MTKIA, A[3]=ZI.1.HTKIA

MAXITERS = 9     ; specify GM iterations
MAXRMSE  = 0.0001

;  Establish gravity model run files & parameters
GRAVITY  PURPOSE  = 1, LOS=MW[11], FFACTORS= FF                    ; COM I/I
GRAVITY  PURPOSE  = 2, LOS=MW[12], FFACTORS= FF                    ; MTK I/I
GRAVITY  PURPOSE  = 3, LOS=MW[12], FFACTORS= FF                    ; HTK I/I

MATO[1] = outputs\auxiliary\COM.TEM,MO=1  ; Final COM trip tables: 1 = I/I
MATO[2] = outputs\auxiliary\MTK.TEM,MO=2  ; Final MTK trip tables: 1 = I/I
MATO[3] = outputs\auxiliary\HTK.TEM,MO=3  ; Final HTK trip tables: 1 = I/I

ENDRUN

; End COM/TRK Trip Distribution  ---
;;-------------------------------------------------------------------------------------------------------
;;Now splice the internal trip tables developed aboves with external trip tables developed              -
;;    in the earlier trip distribution step                                                             -
;;-------------------------------------------------------------------------------------------------------

RUN PGM=MATRIX
ZONES = @ZONESIZE@
MATI[5]   = outputs\auxiliary\COM.TEM    ;    1 Com  trip tables:  I/I
MATI[6]   = outputs\auxiliary\MTK.TEM    ;    1 Mtk  trip tables:  I/I
MATI[7]   = outputs\auxiliary\HTK.TEM    ;    1 Htk  trip tables:  I/I
MATI[13] = @COM_EXT_TRIPS@ ;  external COM trips
MATI[14] = @MTK_EXT_TRIPS@ ;  external MTK trips
MATI[15] = @HTK_EXT_TRIPS@ ;  external HTK trips
;

MW[601]       =mi.5.1        ; Com tabs in mw 601
MW[701]       =mi.6.1        ; Mtk tabs in mw 701
MW[801]       =mi.7.1        ; Htk tabs in mw 801

MW[605]       =mi.13.1       ; Ext COM tabs in mw 605
MW[705]       =mi.14.1       ; Ext MTK tabs in mw 705
MW[805]       =mi.15.1       ; Ext HTK tabs in mw 805

MW[906] =    MW[601] +                               MW[605]    ; Final Commercial Vehicle Trips       (II,IX,XI)
MW[907] =    MW[701] +                               MW[705]    ; Final Medium Truck Trips             (II,IX,XI)
MW[908] =    MW[801] +                               MW[805]    ; Final Heavy  Truck Trips             (II,IX,XI)

;; write out final matrices comprehensive tabs
MATO[6] = @COMTDOUT@ , MO=601,605,906            ,name=COM_Int ,COM_Ext,                           COMAllVeh
MATO[7] = @MTKTDOUT@ , MO=701,705,907            ,name=MTK_Int ,MTK_Ext,                           MTKAllVeh
MATO[8] = @HTKTDOUT@ , MO=801,805,908            ,name=HTK_Int ,HTK_Ext,                           HTKAllVeh

ENDRUN
;
;===================================================================
;
;----------------------------------------------------------
;
; Standard 23x23 Summaries
; Trip Distribution (HBW,HBS,HBO,NHB,COM,MTK,HTK) and formats
; them in neat jurisdictional summaries (23x23)
;
;
;----------------------------------------------------------
;----------------------------------------------------------

COPY FILE=outputs\auxiliary\DJ.EQV
;   -- Start of Jurisiction-to-TAZ equivalency --
D 1=1-4,6-47,49-50,52-63,65,181-209,282-287,374-381     ;  0    DC Core
D 2=5,48,51,64,66-180,210-281,288-373,382-393           ;  0    DC Noncore
D 3=394-769                                             ;  1    Montgomery
D 4=771-776,778-1404                                    ;  2    Prince George
D 5=1471-1476, 1486-1489, 1495-1497                     ;  3    ArlCore
D 6=1405-1470,1477-1485,1490-1494,1498-1545             ;  3    ArlNCore
D 7=1546-1610                                           ;  4    Alex
D 8=1611-2159                                           ;  5    FFx
D 9=2160-2441                                           ;  6    LDn
D 10=2442-2554,2556-2628,2630-2819                      ;  7    PW
D 11=2820-2949                                          ;  9    Frd
D 12=3230-3265,3268-3287                                ; 14    Car.
D 13=2950-3017                                          ; 10    How.
D 14=3018-3102,3104-3116                                ; 11    AnnAr
D 15=3288-3334                                          ; 15    Calv
D 16=3335-3409                                          ; 16    StM
D 17=3117-3229                                          ; 12    Chs.
D 18=3604-3653                                          ; 21    Fau
D 19=3449-3477,3479-3481,3483-3494,3496-3541            ; 19    Stf.
D 20=3654-3662,3663-3675                                ; 22/23 Clk,Jeff.
D 21=3435-3448,3542-3543,3545-3603                      ; 18/20 Fbg,Spots
D 22=3410-3434                                          ; 17    KG.
D 23=3676-3722                                          ;       Externals
;   -- end of Jurisiction-to-TAZ equivalency --
ENDCOPY


RUN PGM=MATRIX
  ZONES=@ZONESIZE@
  MATI[6]= @COMTDOUT@
  MATI[7]= @MTKTDOUT@
  MATI[8]= @HTKTDOUT@

  MW[6] = MI.6.3          ; COM TRIP TABLE/TAZ-LEVEL
  MW[7] = MI.7.3          ; MTK TRIP TABLE/TAZ-LEVEL
  MW[8] = MI.8.3          ; HTK TRIP TABLE/TAZ-LEVEL

  MW[16] = 0 ;                 COM TRIP TABLE/TAZ-LEVEL
  MW[17] = 0 ;                 MTK TRIP TABLE/TAZ-LEVEL
  MW[18] = 0 ;                 HTK TRIP TABLE/TAZ-LEVEL

  MATO[6]  = outputs\auxiliary\COM.SQZ MO=6,16 ; OUTPUT COM TABLE(S), SQUEEZED
  MATO[7]  = outputs\auxiliary\MTK.SQZ MO=7,17 ; OUTPUT MTK TABLE(S), SQUEEZED
  MATO[8]  = outputs\auxiliary\HTK.SQZ MO=8,18 ; OUTPUT HTK TABLE(S), SQUEEZED

  ; renumber OUT.MAT according to DJ.EQV
  RENUMBER FILE=outputs\auxiliary\DJ.EQV, MISSINGZI=M, MISSINGZO=W
ENDRUN

;
LOOP PURP=6,8 ; Loop for Each Purpose
;
; Global Variables:
;   SQFNAME    Name of squeezed modal trip table(s)
;   DESCRIPT   Description
;   PURPOSE    Purpose
;   MODE       Mode
;   DCML       Decimal specification
;   TABTYPE    Table type(1/2), i.e.,-involves 1 or 2 trip tables
;   SCALE=1    Scale factor to be applied (if desired)
;   OPER='+'   Operation(if tabtype=2) Tab1(?)Tab2=Result
;
;
DESCRIPT    = 'SIMULATION-%_iter_% Itr Year: %_year_%'
IF (PURP=1)
  SQFNAME     = 'HBW.SQZ'
  PURPOSE     = 'HBW'
  MODE        = 'MOTORIZED PERSON'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=2)
  SQFNAME     = 'HBS.SQZ'
  PURPOSE     = 'HBS'
  MODE        = 'MOTORIZED PERSON'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=3)
  SQFNAME     = 'HBO.SQZ'
  PURPOSE     = 'HBO'
  MODE        = 'MOTORIZED PERSON'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=4)
  SQFNAME     = 'NHW.SQZ'
  PURPOSE     = 'NHW'
  MODE        = 'MOTORIZED PERSON'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=5)
  SQFNAME     = 'NHO.SQZ'
  PURPOSE     = 'NHO'
  MODE        = 'MOTORIZED PERSON'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=6)
  SQFNAME     = 'outputs\auxiliary\COM.SQZ'
  PURPOSE     = 'COM'
  MODE        = 'COMMERCIAL VEH'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=7)
  SQFNAME     = 'outputs\auxiliary\MTK.SQZ'
  PURPOSE     = 'MTK'
  MODE        = 'TRUCKS'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ELSEIF (PURP=8)
  SQFNAME     = 'outputs\auxiliary\HTK.SQZ'
  PURPOSE     = 'HTK'
  MODE        = 'TRUCKS'
  DCML        = 0
  TABTYPE     = 1
  SCALE       = 1
  OPER        = '+'
ENDIF
;
RUN PGM=MATRIX
  PAGEheight=32000
  ZONES=23
  FILEI MATI=@SQFNAME@
  ARRAY CSUM=23,CSUM1=23,CSUM2=23
; ---------------------------------------------------------------
; --  Table Cell Value decalaration or computation (in MW[1])
; ---------------------------------------------------------------

  FILLMW MW[1]=MI.1.1,2     ;    read input tables in MW 2,3

 IF (@TABTYPE@ = 2)
  FILLMW MW[2]=MI.1.1,2     ;    read input tables in MW 2,3
 ENDIF

  IF (@TABTYPE@=2)                                ; Cell Value
     JLOOP                                        ; computed for
      IF (MW[3][J]>0) MW[1]=MW[2]*@SCALE@@OPER@MW[3]; special summaries-
     ENDJLOOP                                     ; calculation in MW[1]
  ENDIF

; -----------------------------------------------------
; ---- ROW Marginal declaration or computation --------
; -----------------------------------------------------
  RSUM   =     ROWSUM(1)            ; 'normal' table- row summary value

  IF (@TABTYPE@=2)
         RSUM = @SCALE@*ROWSUM(2)@OPER@ROWSUM(3)  ; non-'normal' table
  ENDIF                                    ; compute the row marginal(%)

; -------------------------------------------------------
; ---- COLUMN/Total Marginal Accumulation            ----
; ---- The computation (if necessary) is done below  ----
; -------------------------------------------------------

  JLOOP                            ; COL/Total Accumulation
    CSUM[J] = CSUM[J] +  MW[1][J]  ; for 'normal' table
    TOTAL   = TOTAL   +  MW[1]     ;
  ENDJLOOP

IF (@TABTYPE@=2)
  JLOOP                              ; COL/Total Accumulation
    CSUM1[J] = CSUM1[J] +  MW[2][J]  ; for non-'normal' Table
    TOTAL1   = TOTAL1   +  MW[2]     ;
    CSUM2[J] = CSUM2[J] +  MW[3][J]  ;
    TOTAL2   = TOTAL2   +  MW[3]     ;
  ENDJLOOP
ENDIF

  IF (I==1)      ; print header

  PRINT LIST='/bt   ','@DESCRIPT@'
  PRINT LIST='      ','Purpose: ','@PURPOSE@','   MODE: ','@MODE@'
  PRINT LIST='      '

   PRINT LIST='           DESTINATION'
   PRINT LIST=' ORIGIN |',
              '      1','      2','      3','      4',
              '      5','      6','      7','      8','      9',
              '     10','     11','     12','     13','     14',
              '     15','     16','     17','     18','     19',
              '     20','     21','     22','     23',' |  TOTAL'



   PRINT LIST='==============',
              '==========================================',
              '==========================================',
              '==========================================',
              '======================================='


  ENDIF

  IF (I=1)
   CURDIST=STR(I,2,1)+' DC CR'+ '|' ; Make row header
  ELSEIF (I=2)
   CURDIST=STR(I,2,1)+' DC NC'+ '|' ; Make row header
  ELSEIF (I=3)
   CURDIST=STR(I,2,1)+' MTG  '+ '|' ; Make row header
  ELSEIF (I=4)
   CURDIST=STR(I,2,1)+' PG   '+ '|' ; Make row header
  ELSEIF (I=5)
   CURDIST=STR(I,2,1)+' ARLCR'+ '|' ; Make row header
  ELSEIF (I=6)
   CURDIST=STR(I,2,1)+' ARNCR'+ '|' ; Make row header
  ELSEIF (I=7)
   CURDIST=STR(I,2,1)+' ALX  '+ '|'; Make row header
  ELSEIF (I=8)
   CURDIST=STR(I,2,1)+' FFX  '+ '|' ; Make row header
  ELSEIF (I=9)
   CURDIST=STR(I,2,1)+' LDN  '+ '|' ; Make row header
  ELSEIF (I=10)
   CURDIST=STR(I,2,1)+' PW   '+ '|' ; Make row header
  ELSEIF (I=11)
   CURDIST=STR(I,2,1)+' FRD  '+ '|' ; Make row header
  ELSEIF (I=12)
   CURDIST=STR(I,2,1)+' CAR  '+ '|' ; Make row header
  ELSEIF (I=13)
   CURDIST=STR(I,2,1)+' HOW  '+ '|' ; Make row header
  ELSEIF (I=14)
   CURDIST=STR(I,2,1)+' AAR  '+ '|' ; Make row header
  ELSEIF (I=15)
   CURDIST=STR(I,2,1)+' CAL  '+ '|' ; Make row header
  ELSEIF (I=16)
   CURDIST=STR(I,2,1)+' STM  '+ '|' ; Make row header
  ELSEIF (I=17)
   CURDIST=STR(I,2,1)+' CHS  '+ '|' ; Make row header
  ELSEIF (I=18)
   CURDIST=STR(I,2,1)+' FAU  '+ '|' ; Make row header
  ELSEIF (I=19)
   CURDIST=STR(I,2,1)+' STA  '+ '|' ; Make row header
  ELSEIF (I=20)
   CURDIST=STR(I,2,1)+' CL/JF'+ '|' ; Make row header
  ELSEIF (I=21)
   CURDIST=STR(I,2,1)+' SP/FB'+ '|' ; Make row header
  ELSEIF (I=22)
   CURDIST=STR(I,2,1)+' KGEO '+ '|' ; Make row header
  ELSEIF (I=23)
   CURDIST=STR(I,2,1)+' EXTL '+ '|' ; Make row header
  ELSE  ; (I=24)
   CURDIST=STR(I,2,1)+' TOTAL'+ '|' ; Make row header
  ENDIF

  PRINT FORM=7.@DCML@ LIST=CURDIST, MW[1][1],MW[1][2],MW[1][3],MW[1][4],MW[1][5],
                    MW[1][6],MW[1][7],MW[1][8],MW[1][9],MW[1][10],
                    MW[1][11],MW[1][12],MW[1][13],MW[1][14],MW[1][15],
                    MW[1][16],MW[1][17],MW[1][18],MW[1][19],MW[1][20],
                    MW[1][21],MW[1][22],MW[1][23],' |',RSUM

  IF (I==ZONES)
; Now at the end of Processed zone matrix
;  Do final Column/Grand Total Computations
     IF (@TABTYPE@=2)
       LOOP IDX = 1,ZONES
            IF (CSUM2[IDX] = 0)
                 CSUM[IDX] = 0
            ELSE
                 CSUM[IDX] = @SCALE@* CSUM1[IDX] @OPER@ CSUM2[IDX]
            ENDIF
       ENDLOOP
     ENDIF
     IF (@TABTYPE@=2 )
            IF (TOTAL2 = 0)
                TOTAL  = 0
            ELSE
                TOTAL  = @SCALE@ *TOTAL1 @OPER@ TOTAL2
            ENDIF
     ENDIF

;  End of final Column/Grand Total Computations

   PRINT LIST='==============',
              '==========================================',
              '==========================================',
              '==========================================',
              '======================================='


    PRINT FORM=8.@DCML@,
    LIST=' TOTAL ',' ',CSUM[1],'      ' ,CSUM[3],
    '      ',CSUM[5],'      ',CSUM[7],'      ',CSUM[9],
    '      ',CSUM[11],'      ',CSUM[13],'      ',CSUM[15],
    '      ',CSUM[17],'      ',CSUM[19],'      ',CSUM[21],
    '      ',CSUM[23],' |'
    PRINT FORM=8.@DCML@,
    LIST='/et            ',CSUM[2],
    '      ' ,CSUM[4],'      ',CSUM[6],'      ',CSUM[8],
    '      ',CSUM[10],'      ',CSUM[12],'      ',CSUM[14],
    '      ',CSUM[16],'      ',CSUM[18],'      ',CSUM[20],
    '      ',CSUM[22],'       ',TOTAL(9.@DCML@)


 ENDIF
ENDRUN

ENDLOOP ; End Loop

*copy voya*.prn outputs\auxiliary\trip_distribution_intTrk.rpt
