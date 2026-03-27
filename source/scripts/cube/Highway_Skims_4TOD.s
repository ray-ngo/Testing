;///////////////////////////////////////////////////////////;
;  Highway_Skims_4TOD.S                                        //;
;  MWCOG Version 2.4_PT Model                                //;
;                                                         //;
;  Build AM Peak/Off-Peak Highway Skims                   //;
;  the Current Iteration Assignment                      //;
;  AM and Off-Pk Skims are built in 2 separate HWYLOAD    //;
;  programs.                                              //;
;  Three files are created, per SOV, HOV2, and HOV3 paths.//;
;                                                         //;
;          1) Time     (xx.xx minutes)                    //;
;          2) Distance (implied tenths of mi., xx.xx)     //;
;          3) Toll     (in 2007 cents, xx.xx)             //;
;
; 6/30/03 MODIFICATIONS FOR IMPROVED TOLL MODELING MADE  rjm
;
; 1/25/08 Changes made to create special changes to mode choice skims
; 1/31/08 generalized toll used in pathtracing changed to be mode-specific
;         e.g.       MW[3] =PATHTRACE(LI.@PRD@TOLL),       NOACCESS=0,
; ..was changed to>  MW[3] =PATHTRACE(LW.SOV@PRD@TOLL),    NOACCESS=0,
;
;                    MW[6] =PATHTRACE(LI.@PRD@TOLL),       NOACCESS=0, ;
; ..was changed to>  MW[6] =PATHTRACE(LW.HV2@PRD@TOLL),    NOACCESS=0, ;
;
;                    MW[9] =PATHTRACE(LI.@PRD@TOLL),       NOACCESS=0, ;
; ..was changed to>  MW[9] =PATHTRACE(LW.HV3@PRD@TOLL),    NOACCESS=0, ;
;
;  4/25/08  Modifications for Truck model wga/rm
;           Note Time is not rounded (to whole mintes) any more
; 02/22/13  Added 'timepen' (now a link attribute in the highway net) to the impedance calculation
; 02/22/13  Added 'timepen' (now a link attribute in the highway net) to both impedance * time skim calculation
;
; 02/23/21 FXIE: Develop highway skims for 4 time-of-day periods instead of 2
;          Calculate intrazonal distances and include them in the distance skims
;///////////////////////////////////////////////////////////;
;
;
;   Environment Variables:
;     _iter_  (Iteration indicator = 'pp','i1'-'i4')
;
;
pageheight=32767  ; Preclude header breaks
NETIN    = 'outputs\hwy_net\%_iter_%_hwy.net'
K        = 4  ; This variable is used to calculate average distance to K nearest zones
			  ; Intrazonal_dist = Factor * mean (distance to K nearest zones) 
			  ; Where Factor is typically 0.5 and K is 3 or 4. (we chose 4) 

; Output special truck skim only for off-peak conditions

LOOP Period=1,4         ;  We are looping through the skimming process
                        ;  four times: (1) for the AM Peak & (2) the Midday (3) PM Peak (4) Night Time


 in_tmin = '..\support\toll_minutes.txt'                        ;; read in toll minutes equiv file
 in_AMTfac   = 'inputs\hwy\AM_Tfac.dbf'                             ;;  AM Toll Factors by Veh. Type
 in_MDTfac   = 'inputs\hwy\MD_Tfac.dbf'                             ;;  MD Toll Factors by Veh. Type
 in_PMTfac   = 'inputs\hwy\PM_Tfac.dbf'                             ;;  PM Toll Factors by Veh. Type
 in_NTTfac   = 'inputs\hwy\NT_Tfac.dbf'                             ;;  NT Toll Factors by Veh. Type 

  IF (Period=1)          ; AM Highway Skim tokens
    PRD       = 'AM'
    MATOUT1   = 'outputs\skims\%_iter_%_am_sov.skm '
    MATOUT2   = 'outputs\skims\%_iter_%_am_hov2.skm'
    MATOUT3   = 'outputs\skims\%_iter_%_am_hov3.skm'

    MATOUTMC1 = 'outputs\skims\%_iter_%_am_sov_MC.skm '
    MATOUTMC2 = 'outputs\skims\%_iter_%_am_hov2_MC.skm'
    MATOUTMC3 = 'outputs\skims\%_iter_%_am_hov3_MC.skm'

    MYID      = '%_iter_% AM skims'

    TT        = ';'
    MATOUT4   = ' '
    SKMTOT    = ' '

  ELSEIF (Period=2)     ; MD Highway Skim tokens
    PRD       = 'MD'
    MATOUT1   = 'outputs\skims\%_iter_%_md_sov.skm'
    MATOUT2   = 'outputs\skims\%_iter_%_md_hov2.skm'
    MATOUT3   = 'outputs\skims\%_iter_%_md_hov3.skm'

    MATOUTMC1 = 'outputs\skims\%_iter_%_md_sov_MC.skm '
    MATOUTMC2 = 'outputs\skims\%_iter_%_md_hov2_MC.skm'
    MATOUTMC3 = 'outputs\skims\%_iter_%_md_hov3_MC.skm'

    TT        = ' '
    MATOUT4   = 'outputs\skims\%_iter_%_md_truck.skm'
    SKMTOT    = 'outputs\skims\%_iter_%_skimtot.txt'

    MYID    = '%_iter_% MD skims'
	
  ELSEIF (Period=3)          ; PM Highway Skim tokens
    PRD       = 'PM'
    MATOUT1   = 'outputs\skims\%_iter_%_pm_sov.skm '
    MATOUT2   = 'outputs\skims\%_iter_%_pm_hov2.skm'
    MATOUT3   = 'outputs\skims\%_iter_%_pm_hov3.skm'

    MATOUTMC1 = 'outputs\skims\%_iter_%_pm_sov_MC.skm '
    MATOUTMC2 = 'outputs\skims\%_iter_%_pm_hov2_MC.skm'
    MATOUTMC3 = 'outputs\skims\%_iter_%_pm_hov3_MC.skm'

    MYID      = '%_iter_% PM skims'

    TT        = ';'
    MATOUT4   = ' '
    SKMTOT    = ' '

  ELSEIF (Period=4)     ; MD Highway Skim tokens
    PRD       = 'NT'
    MATOUT1   = 'outputs\skims\%_iter_%_nt_sov.skm '
    MATOUT2   = 'outputs\skims\%_iter_%_nt_hov2.skm'
    MATOUT3   = 'outputs\skims\%_iter_%_nt_hov3.skm'

    MATOUTMC1 = 'outputs\skims\%_iter_%_nt_sov_MC.skm '
    MATOUTMC2 = 'outputs\skims\%_iter_%_nt_hov2_MC.skm'
    MATOUTMC3 = 'outputs\skims\%_iter_%_nt_hov3_MC.skm'

    TT        = ';'
    MATOUT4   = ' '
    SKMTOT    = ' '

    MYID    = '%_iter_% NT skims'	
  ENDIF


RUN PGM=HIGHWAY
;
;
  NETI   =@NETIN@                          ; Pk Prd TP+ network
  MATO[1]=@MATOUT1@, MO=1,2,3,13, NAME=TIME,DIST10,TOLL,TOLLVP  ; LOV   skims: time, dist, total tolls, VP tolls (default output precision is 2 decimal places)
  MATO[2]=@MATOUT2@, MO=4,5,6,16, NAME=TIME,DIST10,TOLL,TOLLVP  ; HOV2  skims: time, dist, total tolls, VP tolls
  MATO[3]=@MATOUT3@, MO=7,8,9,19, NAME=TIME,DIST10,TOLL,TOLLVP  ; HOV3+ skims: time, dist, total tolls, VP tolls
  @TT@ MATO[4]=@MATOUT4@, MO=10,20,21,22  NAME=TKTM,DIST10,TOLL,TOLLVP   ; Truck skims

  ID=@MYID@
;-
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=2,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N
		
		
  FileI  LOOKUPI[3] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=3,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N
		
;-

  PHASE=LINKREAD
       SPEED        =  LI.%_iter_%@PRD@SPD ;Restrained speed (min)
       IF (SPEED = 0)
          T1 = 0
       ELSE
          T1 = (LI.DISTANCE / SPEED * 60.0) + LI.TIMEPEN
       ENDIF
;-
   ; Define AM /MD link level TOTAL tolls by vehicle type here:
       LW.SOV@PRD@TOLL    = LI.@PRD@TOLL    * @PRD@_TFAC(1,LI.TOLLGRP)           ;  SOV       TOTAL TOLLS in 2018 cents
       LW.HV2@PRD@TOLL    = LI.@PRD@TOLL    * @PRD@_TFAC(2,LI.TOLLGRP)           ;  HOV 2 occ TOTAL TOLLS in 2018 cents
       LW.HV3@PRD@TOLL    = LI.@PRD@TOLL    * @PRD@_TFAC(3,LI.TOLLGRP)           ;  HOV 3+occ TOTAL TOLLS in 2018 cents
       LW.TRK@PRD@TOLL    = LI.@PRD@TOLL    * @PRD@_TFAC(4,LI.TOLLGRP)           ;  Truck     TOTAL TOLLS in 2018 cents
       LW.APX@PRD@TOLL    = LI.@PRD@TOLL    * @PRD@_TFAC(5,LI.TOLLGRP)           ;  AP Pax    TOTAL TOLLS in 2018 cents

       LW.SOV@PRD@TOLL_VP = LI.@PRD@TOLL_VP * @PRD@_TFAC(1,LI.TOLLGRP)           ;  SOV       VarPr TOLLS in 2018 cents
       LW.HV2@PRD@TOLL_VP = LI.@PRD@TOLL_VP * @PRD@_TFAC(2,LI.TOLLGRP)           ;  HOV 2 occ VarPr TOLLS in 2018 cents
       LW.HV3@PRD@TOLL_VP = LI.@PRD@TOLL_VP * @PRD@_TFAC(3,LI.TOLLGRP)           ;  HOV 3+occ VarPr TOLLS in 2018 cents
       LW.TRK@PRD@TOLL_VP = LI.@PRD@TOLL_VP * @PRD@_TFAC(4,LI.TOLLGRP)           ;  Truck     VarPr TOLLS in 2018 cents
       LW.APX@PRD@TOLL_VP = LI.@PRD@TOLL_VP * @PRD@_TFAC(5,LI.TOLLGRP)           ;  AP Pax    VarPr TOLLS in 2018 cents

   ; Define AM /MD IMPEDANCE by vehicle type here:
      LW.SOV@PRD@IMP= T1 + ((LW.SOV@PRD@TOLL/100.0)*   SV@PRD@EQM);SOV   IMP
      LW.HV2@PRD@IMP= T1 + ((LW.HV2@PRD@TOLL/100.0)*   H2@PRD@EQM);HOV 2 IMP
      LW.HV3@PRD@IMP= T1 + ((LW.HV3@PRD@TOLL/100.0)*   H3@PRD@EQM);HOV 3+IMP
      LW.TRK@PRD@IMP= T1 + ((LW.TRK@PRD@TOLL/100.0)*   TK@PRD@EQM);Truck IMP
      LW.APX@PRD@IMP= T1 + ((LW.APX@PRD@TOLL/100.0)*   AP@PRD@EQM);APAX  IMP

;
;  Define the three path types here:
;
;
; limit codes used:
;  1=no prohibitions
;  2=prohibit  1/occ autos,trucks
;  3=prohibit  1&2occ autos,trucks
;  4=prohibit  trucks
;  5=prohibit non-airport access trips
;  6-8=unused
;  9=prohibit all traffic use

    IF (LI.@PRD@LIMIT = 2,3,5-9) ADDTOGROUP=1 ; SOV   prohibited links
    IF (LI.@PRD@LIMIT = 3,5-9)   ADDTOGROUP=2 ; HOV2  prohibited links
    IF (LI.@PRD@LIMIT = 5-9)     ADDTOGROUP=3 ; HOV3+ prohibited links
    IF (LI.@PRD@LIMIT = 4)       ADDTOGROUP=4 ; Truck prohibited links

;
  ENDPHASE
;
; Now do the path skimming, per the three path types.  Time, distance,
; and Toll skims created.  Scaling to the desired specified below.
; All skims are based on minimum time paths.
;
; Note that override values of 0 will be inserted for disconnected ijs
; (i.e. cells associated with 'unused' zones and intrazonal cells).
; I dont like the TP+ default value of 1,000,000 for these situations
;
; 1/25/08 added skim tabs created:
;        (t13,t16,t19) tolls on variably priced facilities only

  PHASE=ILOOP



     PATHLOAD PATH=LW.SOV@PRD@IMP, EXCLUDEGRP=1,                ; SOV   paths
              MW[1] =PATHTRACE(TIME),               NOACCESS=0, ; -excluding links
              MW[2] =PATHTRACE(DIST),               NOACCESS=0, ; w/LIMIT=2,3,5-9
              MW[3] =PATHTRACE(LW.SOV@PRD@TOLL),    NOACCESS=0, ;
              MW[13]=PATHTRACE(LW.SOV@PRD@TOLL_VP), NOACCESS=0 ;

     PATHLOAD PATH=LW.HV2@PRD@IMP, EXCLUDEGRP=2,                ; HOV2  paths
              MW[4] =PATHTRACE(TIME),               NOACCESS=0, ; -excluding links
              MW[5] =PATHTRACE(DIST),               NOACCESS=0, ; w/LIMIT=3,5-9
              MW[6] =PATHTRACE(LW.HV2@PRD@TOLL),    NOACCESS=0, ;
              MW[16]=PATHTRACE(LW.HV2@PRD@TOLL_VP), NOACCESS=0  ;

     PATHLOAD PATH=LW.HV3@PRD@IMP, EXCLUDEGRP=3,                ; HOV3+ paths
              MW[7] =PATHTRACE(TIME),               NOACCESS=0, ; -excluding links
              MW[8] =PATHTRACE(DIST),               NOACCESS=0, ; w/LIMIT=5-9
              MW[9] =PATHTRACE(LW.HV3@PRD@TOLL),    NOACCESS=0, ;
              MW[19]=PATHTRACE(LW.HV3@PRD@TOLL_VP), NOACCESS=0  ;

  @TT@ PATHLOAD PATH=LW.TRK@PRD@IMP, EXCLUDEGRP=1,4,            ; Truck paths
  @TT@          MW[10]=PATHTRACE(TIME),   NOACCESS=0,
  @TT@          MW[20]=PATHTRACE(DIST),   NOACCESS=0,
  @TT@          MW[21]=PATHTRACE(LW.TRK@PRD@TOLL),   NOACCESS=0,
  @TT@          MW[22]=PATHTRACE(LW.TRK@PRD@TOLL_VP),   NOACCESS=0  

	; Calculate average distance to K nearest zones
	; Intrazonal_dist = Factor * mean (distance to K nearest zones) 
	; Where Factor is typically 0.5 and K is 3 or 4. (we chose 4) 	
	INTRAZONAL MW[1] = 0.5 * LOWEST(1, @K@, 0.01, 99999)/@K@
	INTRAZONAL MW[2] = 0.5 * LOWEST(2, @K@, 0.01, 99999)/@K@
	INTRAZONAL MW[4] = 0.5 * LOWEST(4, @K@, 0.01, 99999)/@K@
	INTRAZONAL MW[5] = 0.5 * LOWEST(5, @K@, 0.01, 99999)/@K@
	INTRAZONAL MW[7] = 0.5 * LOWEST(7, @K@, 0.01, 99999)/@K@
	INTRAZONAL MW[8] = 0.5 * LOWEST(8, @K@, 0.01, 99999)/@K@	
;----------------------------------------------------------------------
; scaling, rounding of skim tables done here!!
;----------------------------------------------------------------------

     mw[2] = ROUND(MW[2]*10)                   ; FACTOR/ROUND DIST.
     mw[5] = ROUND(MW[5]*10)                   ; SKIMS TO IMPLICIT
     mw[8] = ROUND(MW[8]*10)                   ; 1/10THS OF MILES

     mw[3] = ROUND(MW[3])                      ; ROUND Total TOLL
     mw[6] = ROUND(MW[6])                      ; SKIMS TO 2018
     mw[9] = ROUND(MW[9])                      ; WHOLE CENTS

     mw[13] = ROUND(MW[13])                    ; ROUND Variable priced TOLL
     mw[16] = ROUND(MW[16])                    ; SKIMS TO 2018
     mw[19] = ROUND(MW[19])                    ; WHOLE CENTS

;;
;----------------------------------------------------------------------
; Print selected rows of skim files
; for checking.
;----------------------------------------------------------------------


     IF (i = 1-2)                        ;  for select rows (Is)
         printrow MW=1-3, j=1-3722       ;  print work matrices 1-3
     ENDIF                               ;  row value to all Js.
  ENDPHASE
ENDRUN

IF (Period=2)
	RUN PGM=MATRIX
		READ FILE = @in_tmin@     ; read toll time eqv param file
													   ; -- INPUT SKIMS --
		MATI[1] = @MATOUT1@                                ; SOV  skims (tm,dst,total toll, VP toll)
		MATI[2] = @MATOUT2@                                ; HOV2 skims (tm,dst,total toll, VP toll)
		MATI[3] = @MATOUT3@                                ; HOV3+skims (tm,dst,total toll, VP toll)

		MATI[4] = @MATOUT4@                                ; read in trk skim (op per only)
		MW[99] = MI.4.1
		; For the skim total, put a large value in unconnected O/D pairs
		JLOOP
			IF (MW[99] = 0) MW[99] = 100000
		ENDJLOOP
		REPORT MARGINREC = Y, FILE = @SKMTOT@, FORM=15, LIST=J(5),R99,C99
	ENDRUN 
ENDIF

ENDLOOP
