/*
--------------------------------------------------------------------------------
Highway_Assignment.s - Version 2.3 / 3722 TAZ traffic assignment
(File renamed to highway_assignment.s) Developed from the
assignment process from V2.2 CTP2step_Highway_Assignment.S (1/7/11 rjm)

Added added "Vol[6]" to the NonHOV assignment "V=..." statement (RM)

Updated to write out user market-specific period volumes as well as
total period volumes- This is done for iteration 4 only (JC,RM  10/18/11)
--------------------------------------------------------------------------------
Four time-of-day trip tables are used:
   AM peak period   3 Hrs. (6 AM - 9 AM)  AM
   Midday  period   6 Hrs. (9 AM - 3 PM)  MD
   PM peak period   4 Hrs. (3 PM - 7 PM)  PM
   Night   period  11 Hrs. (7 PM - 6 AM)  NT

The AM and PM periods are considered "peak"
The MD and NT periods are considered "off peak"

Tables on input trip table file:
          1- SOV
          2- HOV2-Occ
          3- HOV3+Occ
          4- Commercial Vehicles
          5- Medium/Heavy Truck
          6- Airport Auto Driver

Structure of the script:

  Step 1: Execute peak-period traffic assignments (AM & PM)
          NonHOV3+ traffic assignment
          HOV3+    traffic assignment

  Step 2: Execute off-peak-period traffic assignments (midday/MD & evening/OP)
          Off-peak (midday & evening) traffic assignment

  Step 3: Calculate restrained speed/perform MSA volume averaging
          Loop thru 1 (AM) and 2 (PM);  Each pk per. includes NonHOV3+ and HOV3+
          Loop thru 3 (midday, NT) and 4 (evening/off-peak, OP)

  Step 4: Summarize 24-hour VMT of current AM, PM, MD & NT assignments

Traffic assignment is done on a period-specific basis (not peak hour), so hourly
capacities are converted to period-specific capacities.  By contrast, all period-
specific speeds actually represent the peak hour of the given period.

Period-specific trip tables representing more than one hour are assigned, but
link capacities are specified in vehicles per hour.  A peak-hour factor (PHF),
which is the percent of traffic in the peak hour of the period, is used to relate
the hourly capacities to the multiple-hour trip tables.  See Barton-Aschman
Associates, Inc. and Cambridge Systematics, Inc., Model Validation and
Reasonableness Checking Manual, February 1997, pp. 78-81.

Environment Variables (set in the "run_ModelSteps" batch file)
   _iter_       Iteration indicator = 'pp','i1' - 'i4'
   _relGap_     Relative gap (e.g., 10^-3 = 0.001)
   _maxUeIter_  Maximum number of user equilibrium iterations

2011-02-11 msm  V/C ratio tabulation now goes from 0 to 5 (was 0 to 2), i.e., "0-5-0.1"
2011-07-25 rm   Added iteration report text file to be written in the the converge phase
                --the following reports are written:
                    "UE_Iteration_Report_NonHOV_%_iter_%_@Prd@.txt"    -Peak nonHOV assignments
                    "UE_Iteration_Report_HOV_%_iter_%_@Prd@.txt"       -Peak HOV assignments
                    "UE_Iteration_Report_%_iter_%_@Prd@.txt"
2012-11-07 msm  Standardized names of relative gap report files
                    "ue_iteration_report_%_iter_%_@prd@_nonHov.txt"    -Peak period (AM|PM) nonHOV assignment
                    "ue_iteration_report_%_iter_%_@prd@_hov.txt"       -Peak period (AM|PM) HOV    assignment
                    "ue_iteration_report_%_iter_%_@prd@.txt"           -Off-pk per  (MD|NT)        assignment
2012-12-04 msm  Standardized names of relative gap report files
                    "%_iter_%_ue_iteration_report_@prd@_nonHov.txt"    -Peak period (AM|PM) nonHOV assignment
                    "%_iter_%_ue_iteration_report_@prd@_hov.txt"       -Peak period (AM|PM) HOV    assignment
                    "%_iter_%_ue_iteration_report_@prd@.txt"           -Off-pk per  (MD|NT)        assignment

2013-02-22 RJM  Added time penality (timepen) to the path impedance function. the timepen variable is
                defined in the V2.3_Highway_Build.s script.

2016-05-10 DNQ  Modified the PRINT LIST for the @prd@CHK.LKLOOP files: "TIMEPEN(5.2)"" becomes "LI.TIMEPEN(5.2)"" 
                to fix the error ? in the printed file (Cube 6.4.1 warns, not Cube 6.1 SP1)
2017-03-16 DNQ  Modified to prohibit airport trips using HOV3+ and correct LIMIT code 1 ->0
2019-04-15 RQN  Revised line 1923 to fix a bug of the model using <ITER>_HWY.net
                incorrectly when the model crash at a certain step
2019-05-20 RQN	Modified to fix the misleading subnodes names by 
                separating AM and MD subnodes to AM, PM, MD, and NT subnodes
2019-08-27 RJM Script has been modified to DISALLOW bridge penalties from being used within the traffic assigment process
           for example:  This line command:         LW.SOV@PRD@IMP = TIME  + LI.TIMEPEN   + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
                         has been changed to this:  LW.SOV@PRD@IMP = TIME                 + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
           The change affected 28 line commands in all



*/

CLUSTER SERVER=LOCALHOST, NUMPROCESSES=%TotalClusterProcesses%,
  WAIT=60, NOHIDE=F
  
/*  **** Set up tokens in Voyager Pilot step ***** */

PAGEHEIGHT=32767 ; preclude insertion of page headers

;  useIdp = t (true) or f (false);  this is set in the wrapper batch file
; distribute intrastep=%useIdp% multistep=%useMdp%

; Choose traffic assignment type, using "enhance=" keyword
;   enhance=0 Frank-Wolfe
;   enhance=1 Conjugate Frank-Wolfe
;   enhance=2 Bi-conjugate Frank-Wolfe
assignType=2

;;;*****************************************************************************
;;; Step 1: Execute peak-period traffic assignments (AM & PM)
;;;         AM nonHOV, HOV and PM nonHOV and HOV Assignemnts
;;;*****************************************************************************


itr = '%_iter_%'   ;;

; The Input Network Depends on the previous Iteration network

;; IF     (itr      = 'pp')
;;   INPNET = 'ZONEHWY.NET'
;; ELSE
;;   INPNET = '%_prev_%_HWY.NET'
;;ENDIF

INPNET = 'outputs\hwy_net\ZONEHWY.NET'
in_tmin     = '..\support\toll_minutes.txt'                    ;;  read in toll minutes equiv file
in_AMTfac   = 'inputs\hwy\AM_Tfac.dbf'                             ;;  AM Toll Factors by Veh. Type
in_PMTfac   = 'inputs\hwy\PM_Tfac.dbf'                             ;;  PM Toll Factors by Veh. Type
in_MDTfac   = 'inputs\hwy\MD_Tfac.dbf'                             ;;  MD Toll Factors by Veh. Type
in_NTTfac   = 'inputs\hwy\NT_Tfac.dbf'                             ;;  NT Toll Factors by Veh. Type


in_capSpd = '..\support\hwy_assign_capSpeedLookup.s'         ;;     FT x AT Speed & Capacity lookup
VDF_File  = '..\support\hwy_assign_Conical_VDF.s'            ;;     Volume Delay Functions file
; Turnpen  = 'inputs\turnpen.pen'                ; turn penalty file

; DistributeMULTISTEP ProcessID='AM', ProcessNum=1
DISTRIBUTEMULTISTEP ALIAS='AM'

PRD    =  'AM'         ;
PCTADT =   41.7        ; %_AMPF_%  AM PHF (% of traffic in pk hr of period)


CAPFAC=1/(PCTADT/100)     ;  Capacity Factor = 1/(PCTADT/100)


;

;;;*****************************************************************************
;;; Step 1.1: Assign AM NonHOV3+ trip tables only
;;;           (SOV, HOV2, CV, TRUCK & AIRPORT PASSENGER TRIPS)
;;;*****************************************************************************

  RUN PGM=HIGHWAY  ; NonHOV3+ traffic assignment
; distributeIntrastep processId='AM', ProcessList=%AMsubnode%
distributeIntrastep MAXPROCESSES=%AMClusterProcesses%

  FILEI NETI     =  @INPNET@                          ; TP+ Network
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\TEMP1_@PRD@.NET          ; Output loaded network of current iter/time prd.
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion

  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@
  ;
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  ;
  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ;
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                                    ; Congested Time (TC)specification:
    V = VOL[1] + VOL[2] + VOL[4] + VOL[5] + VOL[6]
    TC[1]= T0*VCRV(1,V/C)  ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,V/C)  ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,V/C)  ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,V/C)  ;   VDF function is based on ((V/C)
    TC[5]= T0*VCRV(5,V/C)  ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,V/C)  ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,V/C)  ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
;  MAXITERS=3       ;
;  GAP  = 0.0       ;
;  AAD  = 0.0       ;
;  RMSE = 0.0       ;
;  RAAD = 0.0       ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.SOV@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(1,LI.TOLLGRP)  ; SOV       TOLLS in 2018 cents
        LW.HV2@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(2,LI.TOLLGRP)  ; HOV 2 occ TOLLS in 2018 cents
;;      LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP)  ; HOV 3+occ TOLLS in 2018 cents
        LW.CV@PRD@TOLL  = LI.@PRD@TOLL * @PRD@_TFAC(4,LI.TOLLGRP)  ; CV        TOLLS in 2018 cents
        LW.TRK@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(5,LI.TOLLGRP)  ; Truck     TOLLS in 2018 cents
        LW.APX@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(6,LI.TOLLGRP)  ; AP Pax    TOLLS in 2018 cents

;;   ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;       LW.SOV@PRD@IMP = T0    + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
;;       LW.HV2@PRD@IMP = T0    + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;;       LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;       LW.CV@PRD@IMP  = T0    + (LW.CV@PRD@TOLL/100.0)*  CV@PRD@EQM ;CV IMP
;;       LW.TRK@PRD@IMP = T0    + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
;;       LW.APX@PRD@IMP = T0    + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP
;;
;;       IF (LI.@PRD@TOLL > 0)
;;          PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;         ' DISTANCE: ',LI.DISTANCE(6.2),
;;         ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;         ' FFSPEED: ',                                    SPEED(5.2),
;;         ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;         ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;         ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
;;         ' T0: ',                                            T0(5.2),
;;         ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
;;          file = @prd@CHK.LKREAD
;;       ENDIF
;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        0        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.SOV@PRD@IMP = TIME + LI.TIMEPEN + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
         LW.HV2@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;        LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;-->>   LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
         LW.CV@PRD@IMP  = TIME + LI.TIMEPEN + (LW.CV@PRD@TOLL/100.0) * CV@PRD@EQM ;CV    IMP
         LW.TRK@PRD@IMP = TIME + LI.TIMEPEN + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
         LW.APX@PRD@IMP = TIME + LI.TIMEPEN + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP

          IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF
     ENDLINKLOOP

   ENDIF

; Multi-user class or multiclass assignment implemented through volume sets (vol[#])

    PATHLOAD PATH=LW.SOV@PRD@IMP,  EXCLUDEGROUP=2,3,5,6,7,  VOL[1]=MI.1.1   ;  SOV veh
    PATHLOAD PATH=LW.HV2@PRD@IMP,  EXCLUDEGROUP=3,5,6,7,    VOL[2]=MI.1.2   ;  HOV 2
;;  PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3
    PATHLOAD PATH=LW.CV@PRD@IMP,   EXCLUDEGROUP=2,3,5,6,7,  VOL[4]=MI.1.4   ;  CVs
    PATHLOAD PATH=LW.TRK@PRD@IMP,  EXCLUDEGROUP=2,3,4,5,6,7,VOL[5]=MI.1.5   ;  Trucks
    PATHLOAD PATH=LW.APX@PRD@IMP,  EXCLUDEGROUP=6,7,3,      VOL[6]=MI.1.6   ;  Airport

ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@_nonHov.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN
;;;*****************************************************************************
;;; Step 1.2: Assign AM HOV3+ only
;;;*****************************************************************************



  RUN PGM=HIGHWAY  ; HOV3+    traffic assignment
; distributeIntrastep processId='AM', ProcessList=%AMsubnode%
distributeIntrastep MAXPROCESSES=%AMClusterProcesses%
  FILEI NETI     = outputs\hwy_net\TEMP1_@PRD@.NET                    ; TP+ Network
  ;;  TURNPENI = @TURNPEN@                         ; HOV turn penalty at Gallows Road Ramp
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\TEMP2_@PRD@.NET          ; Output loaded network of current iter/time prd.
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion
  ;
  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@

;$
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                                                    ; Congested Time (TC)specification:
    V = VOL[3]                                                                  ;
    TC[1]= T0*VCRV(1,((V+LW.V_1)/C))   ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,((V+LW.V_1)/C))   ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,((V+LW.V_1)/C))   ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,((V+LW.V_1)/C))   ;   VDF function is based on (V+LI.V_1)/C
    TC[5]= T0*VCRV(5,((V+LW.V_1)/C))   ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,((V+LW.V_1)/C))   ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,((V+LW.V_1)/C))   ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
  ;MAXITERS=3      ;
  ;GAP  = 0.0      ;
  ;AAD  = 0.0      ;
  ;RMSE = 0.0      ;
  ;RAAD = 0.0      ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      T1    = LI.TIME_1
      LW.V_1 = LI.V_1
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP) ; HOV 3+occ TOLLS in 2018 cents

;;;  ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;;      LW.HV3@PRD@IMP = T0 + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;;
;;;      IF (LI.@PRD@TOLL > 0)
;;;         PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;;        ' DISTANCE: ',LI.DISTANCE(6.2),
;;;        ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;;        ' FFSPEED: ',                                    SPEED(5.2),
;;;        ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;;        ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;;        ' LW.HV3@PRD@TOLL: ',                  LW.HV3@PRD@TOLL(5.2),
;;;        ' T0: ',                                            T0(5.2),
;;;        ' LW.HV3@PRD@IMP',                      LW.HV3@PRD@IMP(5.2),
;;;         file = @prd@CHK.LKREAD
;;;      ENDIF
;;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        0        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.HV3@PRD@IMP = TIME + LI.TIMEPEN+ (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP

        IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.HV3@PRD@TOLL: ',                  LW.HV3@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.HV3@PRD@IMP',                      LW.HV3@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF

     ENDLINKLOOP

   ENDIF
;
;

; There is only one volume set, so this is not a multi-user class or multiclass assignm.

    PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3


ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@_hov.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN
ENDDistributeMULTISTEP

; DistributeMULTISTEP ProcessID='PM', ProcessNum=1
DISTRIBUTEMULTISTEP ALIAS='PM'

PRD    =  'PM'         ;
PCTADT =   29.4        ; %_AMPF_%  AM PHF (% of traffic in pk hr of period)


CAPFAC=1/(PCTADT/100)     ;  Capacity Factor = 1/(PCTADT/100)


;

;;;*****************************************************************************
;;; Step 1.3: Assign PM NonHOV3+ trip tables only
;;;           (SOV, HOV2, CV, TRUCK & AIRPORT PASSENGER TRIPS)
;;;*****************************************************************************

  RUN PGM=HIGHWAY  ; NonHOV3+ traffic assignment
; distributeIntrastep processId='PM', ProcessList=%PMsubnode%
distributeIntrastep MAXPROCESSES=%PMClusterProcesses%
  FILEI NETI     =  @INPNET@                          ; TP+ Network
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\TEMP1_@PRD@.NET          ; Output loaded network of current iter/time prd.
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion

  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@
  ;
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  ;
  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ;
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                                    ; Congested Time (TC)specification:
    V = VOL[1] + VOL[2] + VOL[4] + VOL[5] + VOL[6]
    TC[1]= T0*VCRV(1,V/C)  ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,V/C)  ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,V/C)  ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,V/C)  ;   VDF function is based on ((V/C)
    TC[5]= T0*VCRV(5,V/C)  ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,V/C)  ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,V/C)  ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
;  MAXITERS=3       ;
;  GAP  = 0.0       ;
;  AAD  = 0.0       ;
;  RMSE = 0.0       ;
;  RAAD = 0.0       ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.SOV@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(1,LI.TOLLGRP)  ; SOV       TOLLS in 2018 cents
        LW.HV2@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(2,LI.TOLLGRP)  ; HOV 2 occ TOLLS in 2018 cents
;;      LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP)  ; HOV 3+occ TOLLS in 2018 cents
        LW.CV@PRD@TOLL  = LI.@PRD@TOLL * @PRD@_TFAC(4,LI.TOLLGRP)  ; CV        TOLLS in 2018 cents
        LW.TRK@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(5,LI.TOLLGRP)  ; Truck     TOLLS in 2018 cents
        LW.APX@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(6,LI.TOLLGRP)  ; AP Pax    TOLLS in 2018 cents

;;   ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;       LW.SOV@PRD@IMP = T0    + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
;;       LW.HV2@PRD@IMP = T0    + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;;       LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;       LW.CV@PRD@IMP  = T0    + (LW.CV@PRD@TOLL/100.0)*  CV@PRD@EQM ;CV IMP
;;       LW.TRK@PRD@IMP = T0    + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
;;       LW.APX@PRD@IMP = T0    + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP
;;
;;       IF (LI.@PRD@TOLL > 0)
;;          PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;         ' DISTANCE: ',LI.DISTANCE(6.2),
;;         ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;         ' FFSPEED: ',                                    SPEED(5.2),
;;         ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;         ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;         ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
;;         ' T0: ',                                            T0(5.2),
;;         ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
;;          file = @prd@CHK.LKREAD
;;       ENDIF
;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        0        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.SOV@PRD@IMP = TIME + LI.TIMEPEN + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
         LW.HV2@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;        LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;-->>   LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
         LW.CV@PRD@IMP  = TIME + LI.TIMEPEN + (LW.CV@PRD@TOLL/100.0) * CV@PRD@EQM ;CV    IMP
         LW.TRK@PRD@IMP = TIME + LI.TIMEPEN + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
         LW.APX@PRD@IMP = TIME + LI.TIMEPEN + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP

          IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF
     ENDLINKLOOP

   ENDIF

; Multi-user class or multiclass assignment implemented through volume sets (vol[#])

    PATHLOAD PATH=LW.SOV@PRD@IMP,  EXCLUDEGROUP=2,3,5,6,7,  VOL[1]=MI.1.1   ;  SOV veh
    PATHLOAD PATH=LW.HV2@PRD@IMP,  EXCLUDEGROUP=3,5,6,7,    VOL[2]=MI.1.2   ;  HOV 2
;;  PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3
    PATHLOAD PATH=LW.CV@PRD@IMP,   EXCLUDEGROUP=2,3,5,6,7,  VOL[4]=MI.1.4   ;  CVs
    PATHLOAD PATH=LW.TRK@PRD@IMP,  EXCLUDEGROUP=2,3,4,5,6,7,VOL[5]=MI.1.5   ;  Trucks
    PATHLOAD PATH=LW.APX@PRD@IMP,  EXCLUDEGROUP=6,7,3,      VOL[6]=MI.1.6   ;  Airport

ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@_nonHov.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN
;;;*****************************************************************************
;;; Step 1.4: Assign PM HOV3+ only
;;;*****************************************************************************



  RUN PGM=HIGHWAY  ; HOV3+    traffic assignment
; distributeIntrastep processId='PM', ProcessList=%PMsubnode%
distributeIntrastep MAXPROCESSES=%PMClusterProcesses%
  FILEI NETI     = outputs\hwy_net\TEMP1_@PRD@.NET                    ; TP+ Network
  ;;  TURNPENI = @TURNPEN@                         ; HOV turn penalty at Gallows Road Ramp
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\TEMP2_@PRD@.NET          ; Output loaded network of current iter/time prd.
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion
  ;
  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@

;$
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                                                    ; Congested Time (TC)specification:
    V = VOL[3]                                                                  ;
    TC[1]= T0*VCRV(1,((V+LW.V_1)/C))   ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,((V+LW.V_1)/C))   ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,((V+LW.V_1)/C))   ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,((V+LW.V_1)/C))   ;   VDF function is based on (V+LI.V_1)/C
    TC[5]= T0*VCRV(5,((V+LW.V_1)/C))   ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,((V+LW.V_1)/C))   ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,((V+LW.V_1)/C))   ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
  ;MAXITERS=3      ;
  ;GAP  = 0.0      ;
  ;AAD  = 0.0      ;
  ;RMSE = 0.0      ;
  ;RAAD = 0.0      ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      T1    = LI.TIME_1
      LW.V_1 = LI.V_1
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP) ; HOV 3+occ TOLLS in 2018 cents

;;;  ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;;      LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;;
;;;      IF (LI.@PRD@TOLL > 0)
;;;         PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;;        ' DISTANCE: ',LI.DISTANCE(6.2),
;;;        ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;;        ' FFSPEED: ',                                    SPEED(5.2),
;;;        ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;;        ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;;        ' LW.HV3@PRD@TOLL: ',                  LW.HV3@PRD@TOLL(5.2),
;;;        ' T0: ',                                            T0(5.2),
;;;        ' LW.HV3@PRD@IMP',                      LW.HV3@PRD@IMP(5.2),
;;;         file = @prd@CHK.LKREAD
;;;      ENDIF
;;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        0        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP

        IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.HV3@PRD@TOLL: ',                  LW.HV3@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.HV3@PRD@IMP',                      LW.HV3@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF

     ENDLINKLOOP

   ENDIF
;
;

; There is only one volume set, so this is not a multi-user class or multiclass assignm.

    PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3


ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@_hov.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN
ENDDistributeMULTISTEP




;;;*****************************************************************************
;;; Step 2: Execute off-peak-period traffic assignments (midday/MD & night/NT)
;;;         All 6 trip tables are assigned together.
;;;*****************************************************************************

; DistributeMULTISTEP ProcessID='MD', ProcessNum=1
DISTRIBUTEMULTISTEP ALIAS='MD'



            ; Off-Peak Period
PRD    =  'MD'         ;
PCTADT =   17.7        ; %_MDPF_%  Midday PHF (% of traffic in pk hr of period)

CAPFAC=1/(PCTADT/100)                  ; Capacity Factor = 1/(PCTADT/100)


  RUN PGM=HIGHWAY  ; Off-peak (midday & evening) traffic assignment
; distributeIntrastep processId='MD', ProcessList=%MDsubnode%
distributeIntrastep MAXPROCESSES=%MDClusterProcesses%
FILEI NETI     = @INPNET@                          ; TP+ Network
  ;; TURNPENI = @TURNPEN@                         ; HOV turn penalty at Gallows Road Ramp
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\temp2_@PRD@.net          ; Output loaded network of current iter/time prd. FOR OFF PEAK
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion
  ;
  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@

;$
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                ; Congested Time (TC)specification:
	V = VOL[1] + VOL[2] + VOL[3] + VOL[4] + VOL[5] + VOL[6]
    TC[1]= T0*VCRV(1,VC)   ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,VC)   ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,VC)   ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,VC)   ;   VDF function is based on VC
    TC[5]= T0*VCRV(5,VC)   ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,VC)   ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,VC)   ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
  ;MAXITERS=3      ;
  ;GAP  = 0.0      ;
  ;AAD  = 0.0      ;
  ;RMSE = 0.0      ;
  ;RAAD = 0.0      ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.SOV@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(1,LI.TOLLGRP) ; SOV       TOLLS in 2018 cents
        LW.HV2@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(2,LI.TOLLGRP) ; HOV 2 occ TOLLS in 2018 cents
        LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP) ; HOV 3+occ TOLLS in 2018 cents
        LW.CV@PRD@TOLL  = LI.@PRD@TOLL * @PRD@_TFAC(4,LI.TOLLGRP) ; CV        TOLLS in 2018 cents
        LW.TRK@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(5,LI.TOLLGRP) ; Truck     TOLLS in 2018 cents
        LW.APX@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(6,LI.TOLLGRP) ; AP Pax    TOLLS in 2018 cents

;;;    ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;;      LW.SOV@PRD@IMP = T0    + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
;;;      LW.HV2@PRD@IMP = T0    + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;;;      LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;;      LW.CV@PRD@IMP  = T0    + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
;;;      LW.TRK@PRD@IMP = T0    + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
;;;      LW.APX@PRD@IMP = T0    + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP
;;;
;;;      IF (LI.@PRD@TOLL > 0)
;;;         PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;;        ' DISTANCE: ',LI.DISTANCE(6.2),
;;;        ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;;        ' FFSPEED: ',                                    SPEED(5.2),
;;;        ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;;        ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;;        ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
;;;        ' T0: ',                                            T0(5.2),
;;;        ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
;;;         file = @prd@CHK.LKREAD
;;;      ENDIF
;;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        0        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.SOV@PRD@IMP = TIME + LI.TIMEPEN + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
         LW.HV2@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
         LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
         LW.CV@PRD@IMP  = TIME + LI.TIMEPEN + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
         LW.TRK@PRD@IMP = TIME + LI.TIMEPEN + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
         LW.APX@PRD@IMP = TIME + LI.TIMEPEN + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP

          IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF

     ENDLINKLOOP

   ENDIF

; Multi-user class or multiclass assignment implemented through volume sets (vol[#])

    PATHLOAD PATH=LW.SOV@PRD@IMP,  EXCLUDEGROUP=2,3,5,6,7,  VOL[1]=MI.1.1   ;  SOV veh
    PATHLOAD PATH=LW.HV2@PRD@IMP,  EXCLUDEGROUP=3,5,6,7,    VOL[2]=MI.1.2   ;  HOV 2
    PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3
    PATHLOAD PATH=LW.CV@PRD@IMP,   EXCLUDEGROUP=2,3,5,6,7,  VOL[4]=MI.1.4   ;  CVs
    PATHLOAD PATH=LW.TRK@PRD@IMP,  EXCLUDEGROUP=2,3,4,5,6,7,VOL[5]=MI.1.5   ;  Trucks
    PATHLOAD PATH=LW.APX@PRD@IMP,  EXCLUDEGROUP=6,7,3,      VOL[6]=MI.1.6   ;  Airport

;$

ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN

ENDDistributeMULTISTEP

; DistributeMULTISTEP ProcessID='NT', ProcessNum=1
DISTRIBUTEMULTISTEP ALIAS='NT'
PRD    =  'NT'         ;
PCTADT =   15.0        ; %_NTPF_%  NT PHF (% of traffic in pk hr of period)


CAPFAC=1/(PCTADT/100)                  ; Capacity Factor = 1/(PCTADT/100)

  RUN PGM=HIGHWAY  ; Off-peak (midday & evening) traffic assignment
;distributeIntrastep processId='NT', ProcessList=%NTsubnode%
distributeIntrastep MAXPROCESSES=%NTClusterProcesses%
FILEI NETI     = @INPNET@                          ; TP+ Network
  ;; TURNPENI = @TURNPEN@                         ; HOV turn penalty at Gallows Road Ramp
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=outputs\hwy_assign\%_iter_%_@prd@.VTT ;
  ;
  FILEO NETO=outputs\hwy_net\temp2_@PRD@.net          ; Output loaded network of current iter/time prd. FOR OFF PEAK
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@
  PARAMETERS RELATIVEGAP=%_relGap_%   ; Set a relative gap tolerance
  PARAMETERS MAXITERS=%_maxUeIter_%      ; We control on relative gap.  This is backup criterion
  ;
  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@

;$
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_AMtfac@"
  LOOKUP LOOKUPI=1,           NAME=AM_Tfac,
        LOOKUP[1]= TOLLGrp, result=AMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=AMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=AMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=AMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=AMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=AMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[2] =         "@in_PMtfac@"
  LOOKUP LOOKUPI=2,           NAME=PM_Tfac,
        LOOKUP[1]= TOLLGrp, result=PMSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=PMHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=PMHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=PMCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=PMTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=PMAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

  FileI  LOOKUPI[3] =         "@in_MDtfac@"
  LOOKUP LOOKUPI=3,           NAME=MD_Tfac,
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  FileI  LOOKUPI[4] =         "@in_NTtfac@"
  LOOKUP LOOKUPI=4,           NAME=NT_Tfac,
        LOOKUP[1]= TOLLGrp, result=NTSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=NTHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=NTHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=NTCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=NTTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=NTAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N


  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                ; Congested Time (TC)specification:
	V = VOL[1] + VOL[2] + VOL[3] + VOL[4] + VOL[5] + VOL[6]
    TC[1]= T0*VCRV(1,VC)   ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,VC)   ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,VC)   ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,VC)   ;   VDF function is based on VC
    TC[5]= T0*VCRV(5,VC)   ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,VC)   ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,VC)   ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
  ;MAXITERS=3      ;
  ;GAP  = 0.0      ;
  ;AAD  = 0.0      ;
  ;RMSE = 0.0      ;
  ;RAAD = 0.0      ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.SOV@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(1,LI.TOLLGRP) ; SOV       TOLLS in 2018 cents
        LW.HV2@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(2,LI.TOLLGRP) ; HOV 2 occ TOLLS in 2018 cents
        LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP) ; HOV 3+occ TOLLS in 2018 cents
        LW.CV@PRD@TOLL  = LI.@PRD@TOLL * @PRD@_TFAC(4,LI.TOLLGRP) ; CV        TOLLS in 2018 cents
        LW.TRK@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(5,LI.TOLLGRP) ; Truck     TOLLS in 2018 cents
        LW.APX@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(6,LI.TOLLGRP) ; AP Pax    TOLLS in 2018 cents

;;;    ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;;      LW.SOV@PRD@IMP = T0    + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
;;;      LW.HV2@PRD@IMP = T0    + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;;;      LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;;      LW.CV@PRD@IMP  = T0    + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
;;;      LW.TRK@PRD@IMP = T0    + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
;;;      LW.APX@PRD@IMP = T0    + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP
;;;
;;;      IF (LI.@PRD@TOLL > 0)
;;;         PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;;        ' DISTANCE: ',LI.DISTANCE(6.2),
;;;        ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;;        ' FFSPEED: ',                                    SPEED(5.2),
;;;        ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;;        ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;;        ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
;;;        ' T0: ',                                            T0(5.2),
;;;        ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
;;;         file = @prd@CHK.LKREAD
;;;      ENDIF
;;;
    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 0 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        1        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==0)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.SOV@PRD@IMP = TIME + LI.TIMEPEN + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
         LW.HV2@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
         LW.HV3@PRD@IMP = TIME + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
         LW.CV@PRD@IMP  = TIME + LI.TIMEPEN + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
         LW.TRK@PRD@IMP = TIME + LI.TIMEPEN + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
         LW.APX@PRD@IMP = TIME + LI.TIMEPEN + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP

          IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  LI.TIMEPEN(5.2),
              ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
               file = outputs\hwy_assign\@prd@CHK.LKLOOP
          ENDIF

     ENDLINKLOOP

   ENDIF

; Multi-user class or multiclass assignment implemented through volume sets (vol[#])

    PATHLOAD PATH=LW.SOV@PRD@IMP,  EXCLUDEGROUP=2,3,5,6,7,  VOL[1]=MI.1.1   ;  SOV veh
    PATHLOAD PATH=LW.HV2@PRD@IMP,  EXCLUDEGROUP=3,5,6,7,    VOL[2]=MI.1.2   ;  HOV 2
    PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3
    PATHLOAD PATH=LW.CV@PRD@IMP,   EXCLUDEGROUP=2,3,5,6,7,  VOL[4]=MI.1.4   ;  CVs
    PATHLOAD PATH=LW.TRK@PRD@IMP,  EXCLUDEGROUP=2,3,4,5,6,7,VOL[5]=MI.1.5   ;  Trucks
    PATHLOAD PATH=LW.APX@PRD@IMP,  EXCLUDEGROUP=6,7,3,      VOL[6]=MI.1.6   ;  Airport

;$

ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "outputs\hwy_assign\%_iter_%_ue_iteration_report_@prd@.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN
ENDDistributeMULTISTEP
; Wait4Files Files=AM1.script.end, CheckReturnCode=T, PrintFiles=Merge, DelDistribFiles=T
; Wait4Files Files=MD1.script.end, CheckReturnCode=T, PrintFiles=Merge, DelDistribFiles=T
; Wait4Files Files=PM1.script.end, CheckReturnCode=T, PrintFiles=Merge, DelDistribFiles=T
; Wait4Files Files=NT1.script.end, CheckReturnCode=T, PrintFiles=Merge, DelDistribFiles=T
BARRIER IDLIST='AM', 'PM', 'MD', 'NT', CheckReturnCode=T, PrintFiles=Merge
;
; END OF MIDDAY and OFF PEAK ASSIGNMENT
;

;;;*****************************************************************************
;;; Step 3: Calculate restrained final Volumes, speeds, V/Cs (No MSA)
;;;*****************************************************************************

;;;*****************************************************************************
;;; Step 3.1: Loop thru 1 (AM) and 2 (PM)
;;;*****************************************************************************

LOOP PERIOD = 1,2  ; Loop thru 1 (AM) and 2 (PM);  Each pk per. includes NonHOV3+ and HOV3+

IF (PERIOD==1)
            PRD    =  'AM'         ;
            PCTADT =   41.7        ;
ELSE
            PRD    =  'PM'         ;
            PCTADT =   29.4        ;
ENDIF
;
;
CAPFAC=1/(PCTADT/100)      ; Capacity Factor = 1/(PCTADT/100)
VDF_File  = '..\support\hwy_assign_Conical_VDF.s'            ;;     Volume Delay Functions file

  RUN PGM=HWYNET                  ; Calculate restrained speed/perform MSA volume averaging
  FILEI NETI=outputs\hwy_net\temp2_@PRD@.net       ; input network from highway assignment
  FILEO NETO=outputs\hwy_net\temp_@prd@.net,       ; output/@PRD@ network with updated speeds
       EXCLUDE=V_1,TIME_1,VC_1,V1_1, V2_1, V3_1, V4_1,V5_1,  V6_1,
               VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,
               CSPD_1,VDT_1,VHT_1,
               V_2,TIME_2,VC_2,V1_2, V2_2,V3_2,V4_2,V5_2,V6_2,
               VT_2,V1T_2,V2T_2,V3T_2,V4T_2,V5T_2,V6T_2,
               WRSPD,WFFSPD
  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Rmps
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  ;
  ; to keep stratified vehicular volume
  ; only in Iteration 4
  ;
  IF ('%_iter_%' = 'I4')
      %_iter_%@PRD@SOV = V1_1
      %_iter_%@PRD@HV2 = V2_1
      %_iter_%@PRD@HV3 =  V_2
      %_iter_%@PRD@CV  = V4_1
      %_iter_%@PRD@TRK = V5_1
      %_iter_%@PRD@APX = V6_1
  ENDIF
  ;
  %_iter_%@prd@VOL = V_1 + V_2                                            ;  Final AM/PM Link Volume
  %_iter_%@prd@VMT = %_iter_%@prd@VOL * distance                          ;  Final AM/PM link VMT
  %_iter_%@prd@FFSPD  =SPEEDFOR(@prd@LANE,SPDCLASS)                       ;  Freeflow speed
  @prd@HRLKCAP=CAPACITYFOR(@prd@LANE,CAPCLASS)                            ;  Hrly Link capacity
  @prd@HRLNCAP=CAPACITYFOR(1,CAPCLASS)                                    ;  Hrly Lane capacity
  %_iter_%@prd@VC=(%_iter_%@prd@VOL*(@pctadt@/100.0)/@prd@HRLKCAP)        ;  AM/PM VC  ratio
  %_iter_%@prd@VDF = VCRV((Ftype + 1), %_iter_%@prd@VC)                   ;  AM/PM VDF
  if (%_iter_%@prd@VDF > 0)  %_iter_%@prd@SPD = %_iter_%@prd@FFSPD / %_iter_%@prd@VDF  ; AM/PM speed (No queuing)
  ATYPE=SPDCLASS%10                                                       ; Area Type
  _cnt = 1.0
;
;
;
; compute WEIGHTED restrained and freeflow SPEEDS for Aggregate summaries

      WRSPD =ROUND(%_iter_%@prd@VMT * %_iter_%@prd@SPD)
      WFfSPD=ROUND(%_iter_%@prd@VMT * %_iter_%@prd@FFSPD)

; Crosstab VMT,WrSPD,WffSPD, by FTYPE and JUR
    CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT,FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ; AVG INITIAL SPD
     COMP=WffSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; AVG FINAL SPD

; Crosstab %_iter_%@prd@VMT,WOSPD,WNSPD,_CNT2 by ATYPE and FTYPE
     CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ; AVG INITIAL SPD
     COMP=WffSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; AVG FINAL SPD


; Crosstab VMT,WOSPD,WNSPD,WFSPD,_CNT2 by EVC and FTYPE
    CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT, FORM=12cs,
     ROW=%_iter_%@prd@VC, RANGE=0-5-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ;  AVG INITIAL SPD
     COMP=WFfSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; Freeflow Speed


    ; PRINT TO check

 print LIST=A(6),' ',B(6),DISTANCE(7.2),' ',@PCTADT@(4.3),' ',@prd@LANE(2.0),' ',
     @prd@HRLKCAP(5.0),' ',@prd@HRLNCAP(5.0),' ',
     %_iter_%@prd@VOL(8.2),' ',
     %_iter_%@prd@ffspd(5.1),' ',%_iter_%@prd@VC(6.4),' ',%_iter_%@prd@VDF(6.4),' ',
     ftype(3.0),' ',ATYPE(3.0), ' ',%_iter_%@prd@SPD(5.1),
     FILE=outputs\hwy_assign\%_iter_%_@prd@_load_link.asc

;;

ENDRUN
ENDLOOP            ; Loop thru 1 (AM) and 2 (PM);  Each pk per. includes NonHOV3+ and HOV3+

;;;*****************************************************************************
;;; Step 3.2: Loop thru 3 (MD) and 4 (OP)
;;;*****************************************************************************

LOOP PERIOD = 3,4  ; Loop thru 1 (midday, MD) and 2 (evening/off-peak, OP)
IF (PERIOD==3)
            PRD    =  'MD'         ;
            PCTADT =   17.7
ELSE
            PRD    =  'NT'         ;
            PCTADT =   15.0
ENDIF
;
CAPFAC=1/(PCTADT/100)      ; Capacity Factor = 1/(PCTADT/100)

  RUN PGM=HWYNET   ; Calculate restrained speed/perform MSA volume averaging
  FILEI NETI=outputs\hwy_net\temp2_@PRD@.net             ; input network from highway assignment
  FILEO NETO=outputs\hwy_net\temp_@prd@.net,       ; output/@PRD@ network with updated speeds
       EXCLUDE=V_1,TIME_1,VC_1,V1_1, V2_1, V3_1, V4_1,V5_1,V6_1,
                          VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,
                          CSPD_1,VDT_1,VHT_1,WRSPD,WFFSPD

  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Rmps
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@
 ;
  ; to keep stratified vehicular volume
  ; only in Iteration 4
  ;

  IF ('%_iter_%' = 'I4')
      %_iter_%@PRD@SOV = V1_1
      %_iter_%@PRD@HV2 = V2_1
      %_iter_%@PRD@HV3 = V3_1
      %_iter_%@PRD@CV  = V4_1
      %_iter_%@PRD@TRK = V5_1
      %_iter_%@PRD@APX = V6_1
  ENDIF
;
;
;
 %_iter_%@prd@VOL = V_1                                                                ; Final Link Volume
 %_iter_%@prd@VMT = %_iter_%@prd@VOL * distance                                        ; Final Link VMT
 %_iter_%@prd@FFSPD  =SPEEDFOR(@prd@LANE,SPDCLASS)                                     ; Freeflow speed
 @prd@HRLKCAP=CAPACITYFOR(@prd@LANE,CAPCLASS)                                          ; Hrly LINK capacity
 @prd@HRLNCAP=CAPACITYFOR(1,CAPCLASS)                                                  ; Hrly LANE capacity
 %_iter_%@prd@VC=(%_iter_%@prd@VOL*(@pctadt@/100.0)/@prd@HRLKCAP)                      ; Period VC ratio
 %_iter_%@prd@VDF = VCRV((Ftype + 1), %_iter_%@prd@VC)                                 ; Period VDF value
 if (%_iter_%@prd@VDF > 0)  %_iter_%@prd@SPD = %_iter_%@prd@FFSPD / %_iter_%@prd@VDF   ; Restrained Link speed(no Queuing delay)
 ATYPE=SPDCLASS%10                                                                     ; area type
 _cnt = 1.0                                                                            ; counter


;;
; compute WEIGHTED restrained and freeflow SPEEDS for Aggregate summaries

      WRSPD =ROUND(%_iter_%@prd@VMT * %_iter_%@prd@SPD)
      WFfSPD=ROUND(%_iter_%@prd@VMT * %_iter_%@prd@FFSPD)

; Crosstab VMT,WrSPD,WffSPD, by FTYPE and JUR
    CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT,FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ; AVG INITIAL SPD
     COMP=WffSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; AVG FINAL SPD

; Crosstab %_iter_%@prd@VMT,WOSPD,WNSPD,_CNT2 by ATYPE and FTYPE
     CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ; AVG INITIAL SPD
     COMP=WffSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; AVG FINAL SPD


; Crosstab VMT,WOSPD,WNSPD,WFSPD,_CNT2 by EVC and FTYPE
    CROSSTAB VAR=%_iter_%@prd@VMT,WrSPD,WffSPD,_CNT, FORM=12cs,
     ROW=%_iter_%@prd@VC, RANGE=0-5-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=WrSPD/%_iter_%@prd@VMT, FORM=12.2cs,   ;  AVG INITIAL SPD
     COMP=WFfSPD/%_iter_%@prd@VMT, FORM=12.2cs     ; Freeflow Speed


    ; PRINT TO check

 print LIST=A(6),' ',B(6),DISTANCE(7.2),' ',@PCTADT@(4.3),' ',@prd@LANE(2.0),' ',
     @prd@HRLKCAP(5.0),' ',@prd@HRLNCAP(5.0),' ',
     %_iter_%@prd@VOL(8.2),' ',
     %_iter_%@prd@ffspd(5.1),' ',%_iter_%@prd@VC(6.4),' ',%_iter_%@prd@VDF(6.4),' ',
     ftype(3.0),' ',ATYPE(3.0), ' ',%_iter_%@prd@SPD(5.1),
     FILE=outputs\hwy_assign\%_iter_%_@prd@_load_link.asc

;;

ENDRUN
ENDLOOP            ; Loop thru 1 (midday, MD) and 2 (evening/off-peak, OP)


;;;*****************************************************************************
;;; Step 4: Summarize 24-hour VMT of current AM, PM, MD & NT assignments
;;;*****************************************************************************

RUN PGM=HWYNET     ; Summarize 24-hour VMT of current AM, PM, MD & OP assignments
  FILEI NETI[1]=outputs\hwy_net\temp_AM.net
  FILEI NETI[2]=outputs\hwy_net\temp_MD.net
  FILEI NETI[3]=outputs\hwy_net\temp_PM.net
  FILEI NETI[4]=outputs\hwy_net\temp_NT.net
  FILEO NETO   =outputs\hwy_net\temp1_%_iter_%_HWY.NET,
             EXCLUDE=OLDVOL1,NEWVOL1,OLDVOL2,NEWVOL2,OLDVOL3,NEWVOL3,
                     OLDVOL4,NEWVOL4,OLDVOL5,NEWVOL5,
                     OLDSPD1,OLDSPD2,OLDSPD3,OLDSPD4,OLDSPD5,%_iter_%24VMT,
                     CSPD_2,VDT_2,VHT_2

         %_iter_%amspd =  LI.1.%_iter_%amspd
         %_iter_%mdspd =  LI.2.%_iter_%mdspd
         %_iter_%pmspd =  LI.3.%_iter_%pmspd
         %_iter_%ntspd =  LI.4.%_iter_%ntspd
 ;
 ;
  _VOLAM =  LI.1.%_iter_%AMVOL
  _VOLMD =  LI.2.%_iter_%MDVOL
  _VOLPM =  LI.3.%_iter_%PMVOL
  _VOLNT =  LI.4.%_iter_%NTVOL

; COMPUTE FINAL DAILY VOLUME  ON ALL LINKS
  %_iter_%24VOL =  _VOLAM + _VOLMD + _VOLPM + _VOLNT   ; Total Daily Volume

; COMPUTE FINAL DAILY VMT ON ALL NON-CENTROID LINKS
IF (FTYPE = 0)
  %_iter_%24VMT =  0
 ELSE
  %_iter_%24VMT =  %_iter_%24VOL * DISTANCE  ; Total Daily VMT
ENDIF

;
;
IF (FTYPE=1-6)
  TVOL00=ROUND((_VOLAM + _VOLMD + _VOLPM + _VOLNT)/1000.0) ; total hwy vol in 000s
  TVMT00=TVOL00*DISTANCE                                   ; total hwy VMT in 000s
  ELSE
  TVOL00=0
  TVMT00=0                                    ;
ENDIF
;
;;IF (FTYPE=1-6 && COUNT > 0 || (AMLIMIT = 2-3 || PMLIMIT=2-3 || NTLIMIT=2-3))
;;  TVolEST=TVol00           ; total hwy vol in 000s
;;  TVolobs=count            ; total hwy vol in 000s
;;  TVMTEST=TVMT00           ; total hwy vol in 000s
;;  TVMTOBS=count*DISTANCE   ; total hwy VMT in 000s
;;  ELSE
;;  Tvmtest=0
;;  TVMTobs=0                                  ; total hwy VMT in 000s
;;ENDIF
;

  comp atype=spdclass%10       ; area type code     1-7
                               ;  its the first digit of spdclass var
;; Crosstab TVMTEST,TVMTOBS by ATYPE and FTYPE
;;    CROSSTAB VAR=TVMTEST,TVMTOBS, FORM=8cs,
;;             ROW=ATYPE, RANGE=1-7-1,,1-7,
;;             COL=FTYPE, RANGE=0-6-1,0-6,
;;             COMP=TVMTEST-TVMTOBS, FORM=8cs,   ; Difference  (est-obs)
;;             COMP=TVMTEST/TVMTOBS, FORM=8.2cs  ; Ratio       (est/obs)
;;
;; Crosstab TVMTEST,TVMTOBS by Jurisdiction and FTYPE
;;    CROSSTAB VAR=TVMTEST,TVMTOBS, FORM=8cs,
;;             ROW=JUR,   RANGE=0-23-1,,0-23,
;;             COL=FTYPE, RANGE=0-6-1,0-6,
;;             COMP=TVMTEST-TVMTOBS, FORM=8cs,   ; Difference  (est-obs)
;;             COMP=TVMTEST/TVMTOBS, FORM=8.2cs  ; Ratio       (est/obs)

;; Crosstab TVMTEST,TVMTOBS by Screenline and FTYPE
;;    CROSSTAB VAR=TVolEST,TVolOBS, FORM=8cs,
;;             ROW=SCREEN, RANGE=1-38-1,,1-38,
;;             COL=FTYPE,  RANGE=0-6-1,0-6,
;;             COMP=TVolEST-TVolOBS, FORM=8cs,   ; Difference  (est-obs)
;;             COMP=TVolEST/TVolOBS, FORM=8.2cs  ; Ratio       (est/obs)
; ---------------------------------------------------------------------
; ---------------------------------------------------------------------
;;=================================================================================
;; DAILY X-Tabs
;;=================================================================================

;;  Crosstab DAILY VMT by ATYPE and FTYPE
     CROSSTAB VAR=%_iter_%24VMT, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6


; Crosstab Total VMT by Jurisdiction and FTYPE
  CROSSTAB VAR=%_iter_%24VMT, FORM=12cs,
             ROW=JUR,   RANGE=0-23-1,,0-23,
             COL=FTYPE, RANGE=0-6-1,0-6


ENDRUN
