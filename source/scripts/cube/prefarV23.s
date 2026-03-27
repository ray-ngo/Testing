;=================================================================
;  PREFAREV23.S
;   Program to read Zone File Used for MFARE2 Program (without walk pcts)
;       and to merge in walk pct. information
;      (Conversion of FORTRAN program Prefaretp.FOR)
;       Program also prepares the Z-file for the NL Mode Choice model (File 8)
;
;   Programmer: Milone
;   Date:        12/11/10
;
;    The program reads 3 files:
;               - a GIS-based walk area file containing short and
;                 long walk areas to all rail stations
;                 (rail includes metro & commuter rail).  The file also
;                 contains the sht,lng distances to the nearest metrorail
;                 station.  Note: the walk distance is based on 1.0 mile
;                 radius per the V2 models (NOT 7/10 mile per V1 models)
;               - a zone file containing bus fare zone/station equivs and
;                 jurisdiction code information.  This is essentially
;                 an A2 deck without walk percentages
;               - the 'final' zonal walk percentage file written
;                 by the wlklnktp.exe program.  This will suppress
;                 metrorail walk percentages to be consistent with
;                 the walk access links built previously
;    It writes out:
;               - A 'complete' A2 file for the MFARE2.S
;                  process
;    1/31/08 rm / a quality control check section added at the bottom
;    4/10/08 rm / added procedure to prepare the A1 file for the NL Mode choice
;                 application (Note: must use updated Ctl files)
;    4/07/23 fxie Modified the script for the Gen3 Model.
;
ZONESIZE        =  3675                  ;  internal zones

ATYPFILE        = 'outputs\landuse\AreaType_File.dbf'    ;  Zonal Area Type file    (I/P file)

LastIZN     =       3675                  ;  Last Internal TAZ no.

OFilem       = 'outputs\landuse\ZONEV2.A2F  '         ; Output ZFile for the NL Mode Choice Model


;==================================================================
;/////////////////////////////////////////////////////////////////=
;==================================================================
;          Begin TP+ Matrix Routine :                             =
;==================================================================
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\=
;==================================================================

RUN PGM=MATRIX
ZONES=@ZONESIZE@


;==========================================
; Read Zonal Area Type Lookup file        =
;=========================================
;
;
FileI LOOKUPI[1] ="@atypfile@"
LOOKUP LOOKUPI=1, NAME=ZNAT,
       LOOKUP[1] = TAZ, RESULT=AType,   ;
       LOOKUP[2] = TAZ, RESULT=EMPDEN,   ;
       INTERPOLATE=N, FAIL= 0,0,0, LIST=N


;=====================================================================================================
; End of LookUps  Now read the input files                                                           =
;=====================================================================================================

;; First initialize all current values to zero:

         HBWParkCost = 0
         HBSParkCost = 0
         HBOParkCost = 0
         NHBParkCost = 0
         HB_TermTime = 0
         NHB_TermTime= 0




 ;;-----------------------------------------------
 ;; Define hwy terminal times based on Area Type
 ;;-----------------------------------------------

     _AType      = ZNAT(1,I)         ;  Area Type
     _FEmpDen    = ZNAT(2,I)         ;  Floating 1-mi zonal Employment density
     if (_Atype = 1 ) Termtm= 5.0
     if (_Atype = 2 ) Termtm= 4.0
     if (_Atype = 3 ) Termtm= 3.0
     if (_Atype = 4 ) Termtm= 2.0
     if (_Atype = 5 ) Termtm= 1.0
     if (_Atype = 6 ) Termtm= 1.0

     if (I > @LastIZN@)    Termtm = 0.0

     HB_TermTime   =  TermTm
     NHB_TermTime  =  TermTm


 ;;-------------------------------------------------------------------
 ;; Define hwy Parking costs based on Area Type --ALL IN 2018 CENTS
 ;;-------------------------------------------------------------------
     ;; HBW 8-Hour Parking Cost
      IF (_Atype >0 && _Atype <= 3)
            HBWParkCost    = MAX( (217.24  * (Ln(_FEmpDen)) - 1553.3), 0.0 )
         ELSE
            HBWParkCost    = 0.0
      ENDIF

     ;; non-HBW 1-Hour Parking Cost
            IF (_Atype = 1)
                  HrNonWkPkCost =  200.0
               ELSEIF (_Atype = 2)
                  HrNonWkPkCost =  100.0
               ELSEIF (_Atype = 3)
                  HrNonWkPkCost =   25.0
               ELSE
                  HrNonWkPkCost =    0.0
            ENDIF


            HBSParkCost = HrNonWkPkCost        ; Assume 1-Hour parking duration for HBS trips
            HBOParkCost = HrNonWkPkCost * 2.0  ; Assume 2-Hour parking duration for HBO trips
            NHBParkCost = HrNonWkPkCost * 2.0  ; Assume 2-Hour parking duration for NHB trips


;-----------------------------------------------------------------------
;Write out zonal files here  ...
;-----------------------------------------------------------------------

 Print file=@ofilem@, form = 5 List=  I,
                                     HBWParkCost,
                                     HBSParkCost,
                                     HBOParkCost,
                                     NHBParkCost,
                                     HB_TermTime,
                                     NHB_TermTime

ENDRUN
