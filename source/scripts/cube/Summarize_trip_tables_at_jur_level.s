;---------------------------------------------------------------------------------------------------;;
; compare_trip_tables_at_jur_level.s:  Script to compare the results of two sets of Gen3 Model final
;                   final iteration resident person trip tables from ActivitySim .
;                  Trip tables are prepared by purpose and mode at juris. level.
;                   Note: The script calls the extrtab.exe program so make sure it's in the same subdir.
; fxie 11/30/22
; fxie 4/10/24
;---------------------------------------------------------------------------------------------------;;



descript = 'Scenario: %_year_%' ; descriptive lable to be put on each table
printfilename = '%SCEN_DIRECTORY%\outputs\hwy_assign\Trip_tables_at_jur_level.csv'
bse = ' '




;---------------------------------------------------------------
; Summarize the Mode Choice Model Output File to Juris. Level
;---------------------------------------------------------------

LOOP PURP=1,11  ; Outer Loop for Each Tour Purpose
				; 'work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr','atwork','all_purp'
IF (PURP=1)
    PURPOSE ='work'
ELSEIF (PURP=2)
    PURPOSE ='univ'
ELSEIF (PURP=3)
    PURPOSE ='school'
ELSEIF (PURP=4)
    PURPOSE ='escort'
ELSEIF (PURP=5)
    PURPOSE ='shopping'
ELSEIF (PURP=6)
    PURPOSE ='othmaint'
ELSEIF (PURP=7)
    PURPOSE ='eatout'
ELSEIF (PURP=8)
    PURPOSE ='social'
ELSEIF (PURP=9)
    PURPOSE ='othdiscr'
ELSEIF (PURP=10)
    PURPOSE ='atwork'
ELSEIF (PURP=11)
    PURPOSE ='all_purp'

ENDIF

LOOP MOD=1,20  ; Inner Loop for Each Trip Mode
				; 'DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'WALK_AB', 'WALK_BM', 'WALK_MR', 'WALK_CR',
                ; 'PNR_AB', 'PNR_BM', 'PNR_MR', 'PNR_CR', 'KNR_AB', 'KNR_BM', 'KNR_MR', 'SCHOOLBUS',
                ; 'TAXI', 'TNC','ALL_MODE'
IF (MOD=1)
    MODE ='DRIVEALONE'
ELSEIF (MOD=2)
    MODE ='SHARED2'
ELSEIF (MOD=3)
    MODE ='SHARED3'
ELSEIF (MOD=4)
    MODE ='WALK'
ELSEIF (MOD=5)
    MODE ='BIKE'
ELSEIF (MOD=6)
    MODE ='WALK_AB'
ELSEIF (MOD=7)
    MODE ='WALK_BM'
ELSEIF (MOD=8)
    MODE ='WALK_MR'
ELSEIF (MOD=9)
    MODE ='WALK_CR'
ELSEIF (MOD=10)
    MODE ='PNR_AB'
ELSEIF (MOD=11)
    MODE ='PNR_BM'
ELSEIF (MOD=12)
    MODE ='PNR_MR'
ELSEIF (MOD=13)
    MODE ='PNR_CR'
ELSEIF (MOD=14)
    MODE ='KNR_AB'
ELSEIF (MOD=15)
    MODE ='KNR_BM'
ELSEIF (MOD=16)
    MODE ='KNR_MR'
ELSEIF (MOD=17)
    MODE ='SCHOOLBUS'
ELSEIF (MOD=18)
    MODE ='TAXI'
ELSEIF (MOD=19)
    MODE ='TNC'
ELSEIF (MOD=20)
    MODE ='ALL_MODE'


ENDIF
;
COPY FILE=DJ.EQV
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
  ZONES=3722
  MATI[1]= %SCEN_DIRECTORY%\outputs\hwy_assign\final_trips_@PURPOSE@.trp


  MW[1]= MI.1.@MODE@



  FILEO MATO[1]  = %SCEN_DIRECTORY%\outputs\hwy_assign\TEMP.TRP MO=1

 ; renumber OUT.MAT according to DJ.EQV
  RENUMBER FILE=DJ.EQV, MISSINGZI=M, MISSINGZO=W
ENDRUN

DCML=0                    ; decimal specification
TABTYPE=1                 ; table type(1/2)-involves 1 or 2 trip tables
SCALE=1                   ; scale factor to be applied (if desired)
OPER='-'                  ; operation(if tabtype=2) Tab1(?)Tab2=Result

RUN PGM=MATRIX
  ZONES=23
  FILEI MATI = %SCEN_DIRECTORY%\outputs\hwy_assign\TEMP.TRP
  ARRAY CSUM=23,CSUM1=23,CSUM2=23
; ---------------------------------------------------------------
; --  Table Cell Value decalaration or computation (in MW[1])
; ---------------------------------------------------------------

  FILLMW MW[2]=MI.1.1     ;    read input set1,2 tables  in MW 2,3

                               ; compute Cell Values in mw 1
     JLOOP                                        ;
        @bse@ MW[1]=MW[2]

     ENDJLOOP                                     ;


; -----------------------------------------------------
; ---- ROW Marginal declaration or computation --------
; -----------------------------------------------------
  RSUM   =     ROWSUM(1)            ; 'normal' table- row summary value

                                             ; compute the row marginal(%)

; -------------------------------------------------------
; ---- COLUMN/Total Marginal Accumulation            ----
; ---- The computation (if necessary) is done below  ----
; -------------------------------------------------------

  JLOOP                            ; COL/Total Accumulation
    CSUM[J] = CSUM[J] +  MW[1][J]  ; for 'normal' table
    TOTAL   = TOTAL   +  MW[1]     ;
  ENDJLOOP

  IF (I==1)      ; print header
  PRINT CSV=T LIST='      ', FILE=@printfilename@, APPEND=T
  PRINT CSV=T LIST='      ', FILE=@printfilename@, APPEND=T

  PRINT CSV=T LIST='@DESCRIPT@', FILE=@printfilename@, APPEND=T
  PRINT CSV=T LIST='Purpose: @PURPOSE@; MODE: @MODE@', FILE=@printfilename@, APPEND=T
  PRINT CSV=T LIST='      '

   PRINT CSV=T LIST='      ', ' ',  'DESTINATION', FILE=@printfilename@, APPEND=T
   PRINT CSV=T LIST=' ORIGIN', '|',
              '      1','      2','      3','      4',
              '      5','      6','      7','      8','      9',
              '     10','     11','     12','     13','     14',
              '     15','     16','     17','     18','     19',
              '     20','     21','     22','     23','|', '  TOTAL', FILE=@printfilename@, APPEND=T



   PRINT CSV=T LIST='=========','=','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=','=========', FILE=@printfilename@, APPEND=T


  ENDIF

  IF (I=1)
   CURDIST=STR(I,2,1)+' DC CR' ; Make row header
  ELSEIF (I=2)
   CURDIST=STR(I,2,1)+' DC NC' ; Make row header
  ELSEIF (I=3)
   CURDIST=STR(I,2,1)+' MTG  ' ; Make row header
  ELSEIF (I=4)
   CURDIST=STR(I,2,1)+' PG   ' ; Make row header
  ELSEIF (I=5)
   CURDIST=STR(I,2,1)+' ARLCR' ; Make row header
  ELSEIF (I=6)
   CURDIST=STR(I,2,1)+' ARNCR' ; Make row header
  ELSEIF (I=7)
   CURDIST=STR(I,2,1)+' ALX  '; Make row header
  ELSEIF (I=8)
   CURDIST=STR(I,2,1)+' FFX  ' ; Make row header
  ELSEIF (I=9)
   CURDIST=STR(I,2,1)+' LDN  ' ; Make row header
  ELSEIF (I=10)
   CURDIST=STR(I,2,1)+' PW   ' ; Make row header
  ELSEIF (I=11)
   CURDIST=STR(I,2,1)+' FRD  ' ; Make row header
  ELSEIF (I=12)
   CURDIST=STR(I,2,1)+' CAR  ' ; Make row header
  ELSEIF (I=13)
   CURDIST=STR(I,2,1)+' HOW  ' ; Make row header
  ELSEIF (I=14)
   CURDIST=STR(I,2,1)+' AAR  ' ; Make row header
  ELSEIF (I=15)
   CURDIST=STR(I,2,1)+' CAL  ' ; Make row header
  ELSEIF (I=16)
   CURDIST=STR(I,2,1)+' STM  ' ; Make row header
  ELSEIF (I=17)
   CURDIST=STR(I,2,1)+' CHS  ' ; Make row header
  ELSEIF (I=18)
   CURDIST=STR(I,2,1)+' FAU  ' ; Make row header
  ELSEIF (I=19)
   CURDIST=STR(I,2,1)+' STA  ' ; Make row header
  ELSEIF (I=20)
   CURDIST=STR(I,2,1)+' CL/JF' ; Make row header
  ELSEIF (I=21)
   CURDIST=STR(I,2,1)+' SP/FB' ; Make row header
  ELSEIF (I=22)
   CURDIST=STR(I,2,1)+' KGEO ' ; Make row header
  ELSEIF (I=23)
   CURDIST=STR(I,2,1)+' EXTL ' ; Make row header
  ELSE ;;(I=24)
   CURDIST=STR(I,2,1)+' TOTAL' ; Make row header
  ENDIF

  PRINT CSV=T FORM=7.@DCML@ LIST=CURDIST,'|'(1), MW[1][1],MW[1][2],MW[1][3],MW[1][4],MW[1][5],
                    MW[1][6],MW[1][7],MW[1][8],MW[1][9],MW[1][10],
                    MW[1][11],MW[1][12],MW[1][13],MW[1][14],MW[1][15],
                    MW[1][16],MW[1][17],MW[1][18],MW[1][19],MW[1][20],
                    MW[1][21],MW[1][22],MW[1][23],'|'(1),RSUM, FILE=@printfilename@, APPEND=T

  IF (I==ZONES)
; Now at the end of Processed zone matrix

;  End of final Column/Grand Total Computations

   PRINT CSV=T LIST='=========','=','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=========','=========',
              '=========','=========','=========','=========','=========','=','=========', FILE=@printfilename@, APPEND=T



    PRINT CSV=T FORM=8.@DCML@,
    LIST=' TOTAL ',' '(1),CSUM[1],CSUM[2],CSUM[3],
    CSUM[4],CSUM[5],CSUM[6],CSUM[7],CSUM[8],CSUM[9],
    CSUM[10],CSUM[11],CSUM[12],CSUM[13],CSUM[14],CSUM[15],
    CSUM[16],CSUM[17],CSUM[18],CSUM[19],CSUM[20],CSUM[21],
    CSUM[22],CSUM[23],'|'(1),TOTAL, FILE=@printfilename@, APPEND=T


 ENDIF

/*
  IF (I==1)      ; print header
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      '
  PRINT LIST='      ','@DESCRIPT@',
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
  ELSE ;;(I=24)
   CURDIST=STR(I,2,1)+' TOTAL'+ '|' ; Make row header
  ENDIF

  PRINT FORM=7.@DCML@ LIST=CURDIST, MW[1][1],MW[1][2],MW[1][3],MW[1][4],MW[1][5],
                    MW[1][6],MW[1][7],MW[1][8],MW[1][9],MW[1][10],
                    MW[1][11],MW[1][12],MW[1][13],MW[1][14],MW[1][15],
                    MW[1][16],MW[1][17],MW[1][18],MW[1][19],MW[1][20],
                    MW[1][21],MW[1][22],MW[1][23],' |',RSUM

  IF (I==ZONES)
; Now at the end of Processed zone matrix

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
*/
ENDRUN

ENDLOOP ; End 'Inner' Loop
ENDLOOP ; End 'Outer' Loop
