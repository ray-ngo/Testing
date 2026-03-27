*del voya*.prn
;
;=====================================================================================================
;  Prepare_Internal_Ends.s                                                                           =
;  This process prepares Internal auto & truck-related Ps and As.                                    =
;  The zonal level internal Ps & As are scaled (or balanced) to match external As & Ps, respecti vely
;=====================================================================================================

ZONESIZE       =  3722                       ;  No. of TAZs
Purps          =  8                          ;  No. of purposes
LastIZn        =  3675                       ;  Last Internal TAZ no.


;Inp_ExtHBW    ='%_iter_%_HBWext.ptt       '  ; INPUT External HBW trips
;Inp_ExtHBS    ='%_iter_%_HBSext.ptt       '  ; INPUT External HBS trips
;Inp_ExtHBO    ='%_iter_%_HBOext.ptt       '  ; INPUT External HBO trips
;Inp_ExtNHW    ='%_iter_%_NHWext.ptt       '  ; INPUT External NHW trips
;Inp_ExtNHO    ='%_iter_%_NHOext.ptt       '  ; INPUT External NHO trips
Inp_ExtCOM    ='outputs\auxiliary\%_iter_%_COMext.vtt       '  ; INPUT External COM trips
Inp_ExtMTK    ='outputs\auxiliary\%_iter_%_MTKext.vtt       '  ; INPUT External MTK trips
Inp_ExtHTK    ='outputs\auxiliary\%_iter_%_HTKext.vtt       '  ; INPUT External HTK trips

Final_IntPsAs ='outputs\auxiliary\%_iter_%_Final_Int_Motor_PsAs.dbf'  ; OUTPUT Internal zonal Ps,As file, HBW,HBS,HBO,NHW,NHO, comm, mtk, htk purposes

;; -------------------------------------------------------------------------------------------------------------------------
;; First extract zonal Ps, As, from the external trip tables
;; The external Ps (X-I trips) will be subsequently subtracted from Total As and
;; The external As (I-X trips) will be subsequently subtracted from Total Ps and
;;--------------------------------------------------------------------------------------------------------------------------

RUN PGM=MATRIX
zones=@zonesize@

;MATI[1] =   @Inp_ExtHBW@   ;   Input external person/vehicle trip tabs by purpose
;MATI[2] =   @Inp_ExtHBS@   ;
;MATI[3] =   @Inp_ExtHBO@   ;
;MATI[4] =   @Inp_ExtNHW@   ;
;MATI[5] =   @Inp_ExtNHO@   ;
MATI[6] =   @Inp_ExtCOM@   ;
MATI[7] =   @Inp_ExtMTK@   ;
MATI[8] =   @Inp_ExtHTK@   ;

MW[100] = 1.0
MW[200] = 1.0

IF (I <=  @LastIzn@) MW[200] = 0.0 ; screen matrix for ExtPs   (X-I movements)
IF (I  >  @LastIzn@) MW[100] = 0.0 ; screen matrix for Ext As  (I-X movements)

;MW[11] = mi.1.1 * MW[100]  MW[12] = mi.1.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
;MW[21] = mi.2.1 * MW[100]  MW[22] = mi.2.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
;MW[31] = mi.3.1 * MW[100]  MW[32] = mi.3.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
;MW[41] = mi.4.1 * MW[100]  MW[42] = mi.4.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
;MW[51] = mi.5.1 * MW[100]  MW[52] = mi.5.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
MW[61] = mi.6.1 * MW[100]  MW[62] = mi.6.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
MW[71] = mi.7.1 * MW[100]  MW[72] = mi.7.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table
MW[81] = mi.8.1 * MW[100]  MW[82] = mi.8.1 * MW[200] ; HBW X-I trip table & HBW X-I trip table


mato[1]=outputs\auxiliary\ext.tem, mo = 11,12,21,22,31,32,41,42,51,52,61,62,71,72,81,82

ENDRUN

RUN PGM=MATRIX
zones=@zonesize@
MATI[1] = outputs\auxiliary\ext.tem

;MW[11] = mi.1.1     MW[12] = mi.1.2.T   ; <--  HBW matrix, HBW matrix X-posed
;MW[21] = mi.1.3     MW[22] = mi.1.4.T   ; <--  HBS matrix, HBS matrix X-posed
;MW[31] = mi.1.5     MW[32] = mi.1.6.T   ; <--  HBO matrix, HBO matrix X-posed
;MW[41] = mi.1.7     MW[42] = mi.1.8.T   ; <--  NHW matrix, NHW matrix X-posed
;MW[51] = mi.1.9     MW[52] = mi.1.10.T  ; <--  NHO matrix, NHO matrix X-posed
MW[61] = mi.1.11    MW[62] = mi.1.12.T  ; <--  COM matrix, COM matrix X-posed
MW[71] = mi.1.13    MW[72] = mi.1.14.T  ; <--  MTK matrix, MTK matrix X-posed
MW[81] = mi.1.15    MW[82] = mi.1.16.T  ; <--  HTK matrix, HTK matrix X-posed

FILEO RECO[1] = "outputs\auxiliary\ExternalPsAs.dbf",
      FIELDS  = TAZ, COMXPs, COMXAs,
                     MTKXPs,  MTKXAs, HTKXPs, HTKXAs
					 ;HBWXPs,  HBWXAs, HBSXPs, HBSXAs, HBOXPs, HBOXAs,
                     ;NHWXPs,  NHWXAs, NHOXPs, NHOXAs, 

   TAZ=i

   ;HBWXPs = ROWSUM(12)  ;HBW X-I movements
   ;HBSXPs = ROWSUM(22)  ;HBS
   ;HBOXPs = ROWSUM(32)  ;HBO
   ;NHWXPs = ROWSUM(42)  ;NHW
   ;NHOXPs = ROWSUM(52)  ;NHO
   COMXPs = ROWSUM(62)  ;COM
   MTKXPs = ROWSUM(72)  ;MTK
   HTKXPs = ROWSUM(82)  ;HTK

   ;HBWXAs = ROWSUM(11)  ;HBW I-X movements
   ;HBSXAs = ROWSUM(21)  ;HBS
   ;HBOXAs = ROWSUM(31)  ;HBO
   ;NHWXAs = ROWSUM(41)  ;NHW
   ;NHOXAs = ROWSUM(51)  ;NHO
   COMXAs = ROWSUM(61)  ;COM
   MTKXAs = ROWSUM(71)  ;MTK
   HTKXAs = ROWSUM(81)  ;HTK

   WRITE RECO = 1


ENDRUN

;; -------------------------------------------------------------------------------------------------------------------------
;; Now Read TOTAL Ps and As by Purpose, from the Trip_Generation.s and Truck_Com_Trip_Generation.s scripts,
;; and subtract the external trip ends from above to arrive at zonal internal P's and A's
;; to be used in the internal Trip Distribution process
;;--------------------------------------------------------------------------------------------------------------------------


RUN PGM=MATRIX
ZONES=1

Fileo printo[1] ='outputs\auxiliary\%_iter_%_Prepare_Internal_Ends.txt' ;; report file

Array TMProdA   = 8,3722     ; input TOTAL zonal motorized      productions array (8 purposes)
Array TMAttrA   = 8,3722     ; input TOTAL zonal motorized      attractions array
Array TNMProdA  = 8,3722     ; input TOTAL zonal non-motorized  productions array (8 purposes)
Array TNMAttrA  = 8,3722     ; input TOTAL zonal non-motorized  attractions array
Array TMNMProdA = 8,3722     ; input TOTAL zonal motor&non-motr productions array (8 purposes)
Array TMNMAttrA = 8,3722     ; input TOTAL zonal motor&non-motr attractions array
Array TProdIncA = 3,3722,4   ; input TOTAL zonal motorized      productions array (3 stratified purposes, 4 Inc groups)
Array TAttrIncA = 3,3722,4   ; input TOTAL zonal motorized      attractions array (3 stratified purposes, 4 Inc groups)

Array XProdA    = 8,3722     ; input EXTERNAL zonal productions array   (8 purposes)
Array XAttrA    = 8,3722     ; input EXTERNAL zonal attractions array

Array IMProdA    = 8,3722    ; output INTERNAL motorized zonal     productions array (8 purposes)
Array IMAttrA    = 8,3722    ; output INTERNAL motorized zonal     attractions array
Array INMProdA   = 8,3722    ; output INTERNAL non-motorized zonal productions array (8 purposes)
Array INMAttrA   = 8,3722    ; output INTERNAL non-motorized zonal attractions array
Array IMNMProdA  = 8,3722    ; output INTERNAL motor&non-motrzonal productions array (8 purposes)
Array IMNMAttrA  = 8,3722    ; output INTERNAL motor&non-motrzonal attractions array
Array IProdIncA  = 3,3722,4  ; output INTERNAL  zonal motorized    productions array (3 stratified purposes, 4 Inc groups)
Array IAttrIncA  = 3,3722,4  ; output INTERNAL  zonal motorized    attractions array (3 stratified purposes, 4 Inc groups)

Array ScIMAttra  = 8,3722    ; output Scaled INTERNAL motorized     zonal attractions array
Array ScINMAttra = 8,3722    ; output Scaled INTERNAL non-motorized zonal attractions array
Array ScIMNMAttra= 8,3722    ; output Scaled INTERNAL motor&non-Motrzonal attractions array

;; Sum of total, external, internal Motorized Ps, As by purpose:
Array SUMTOTMP = 8, SUMTOTNMP =8, SUMTOTMNMP = 8
Array SumTotMA = 8, SumExtMP = 8, SumExtMA = 8, SumIntMP = 8, SumIntMA = 8, AttScalFtr = 8, SumScIntMA=8

;; Sum of total, Non-Motorized Ps, As by purpose:
Array SUMINTNMP  = 8, SUMINTNMA = 8, SumScIntNMA=8, SumScIntMNMA=8

;; Sum of total, Non-Motorized Ps, As by purpose:
Array SUMINTMNMP = 8, SUMINTMNMA = 8
Array SUMTOTNMA  = 8, SUMTOTMNMA = 8
;;=======================================================================================================================
;;=======================================================================================================================


;; INPUT TOTAL Zonal trip productions
;;FILEI DBI[1] = "outputs\auxiliary\%_iter_%_Trip_Gen_productions_Comp.dbf"
;;variables in file:
;;TAZ     HBW_MTR_PS      HBW_NMT_PS      HBW_ALL_PS      HBWMTRP_I1      HBWMTRP_I2      HBWMTRP_I3      HBWMTRP_I4
;;        HBS_MTR_PS      HBS_NMT_PS      HBS_ALL_PS      HBSMTRP_I1      HBSMTRP_I2      HBSMTRP_I3      HBSMTRP_I4
;;        HBO_MTR_PS      HBO_NMT_PS      HBO_ALL_PS      HBOMTRP_I1      HBOMTRP_I2      HBOMTRP_I3      HBOMTRP_I4
;;        NHW_MTR_PS      NHW_NMT_PS      NHW_ALL_PS      NHO_MTR_PS      NHO_NMT_PS      NHO_ALL_PS

;;INPUT TOTAL Zonal trip attractions
;;FILEI DBI[2] = "outputs\auxiliary\%_iter_%_Trip_Gen_Attractions_Comp.dbf"
;;variables in file:
;;TAZ     HBW_MTR_AS      HBW_NMT_AS      HBW_ALL_AS      HBWMTRA_I1      HBWMTRA_I2      HBWMTRA_I3      HBWMTRA_I4
;;        HBS_MTR_AS      HBS_NMT_AS      HBS_ALL_AS      HBSMTRA_I1      HBSMTRA_I2      HBSMTRA_I3      HBSMTRA_I4
;;        HBO_MTR_AS      HBO_NMT_AS      HBO_ALL_AS      HBOMTRA_I1      HBOMTRA_I2      HBOMTRA_I3      HBOMTRA_I4
;;        NHW_MTR_AS      NHW_NMT_AS      NHW_ALL_AS      NHO_MTR_AS      NHO_NMT_AS      NHO_ALL_AS


;;INPUT Zonal comm, med truck, heavy truck trip ends
FILEI DBI[3] = "outputs\auxiliary\%_iter_%_ComVeh_Truck_Ends.dbf"
;; variables in file:
;  TAZ     COMM_VEH        MED_TRUCK       HVY_TRUCK


;;INPUT EXTERNAL Ps, As
FILEI DBI[4] = "outputs\auxiliary\ExternalPsAs.dbf"
;;      FIELDS  = TAZ, COMXPs, COMXAs,
;;                     MTKXPs,  MTKXAs, HTKXPs, HTKXAs
;;HBWXPs,  HBWXAs, HBSXPs, HBSXAs, HBOXPs, HBOXAs,
;;                     NHWXPs,  NHWXAs, NHOXPs, NHOXAs, 

;;OUTPUT Internal Motorized P/A file:
 FILEO RECO[1] = "@Final_IntPsAs@",
       FIELDS  = TAZ,    COMIP,  COMIA,
                         MTKIP,  MTKIA,
                         HTKIP,  HTKIA
						 ;HBWMIP, HBWNMIP, HBWMNMIP,
                         ;HBWMIP1,HBWMIP2, HBWMIP3, HBWMIP4,
                         ;HBWMIA, HBWNMIA, HBWMNMIA,
                         ;HBWMIA1,HBWMIA2, HBWMIA3, HBWMIA4,
                         ;HBSMIP, HBSNMIP, HBSMNMIP,
                         ;HBSMIP1,HBSMIP2, HBSMIP3, HBSMIP4,
                         ;HBSMIA, HBSNMIA, HBSMNMIA,
                         ;HBSMIA1,HBSMIA2, HBSMIA3, HBSMIA4,
                         ;HBOMIP, HBONMIP, HBOMNMIP,
                         ;HBOMIP1,HBOMIP2, HBOMIP3, HBOMIP4,
                         ;HBOMIA, HBONMIA, HBOMNMIA,
                         ;HBOMIA1,HBOMIA2, HBOMIA3, HBOMIA4,
                         ;NHWMIP, NHWNMIP, NHWMNMIP,
                         ;NHWMIA, NHWNMIA, NHWMNMIA,
                         ;NHOMIP, NHONMIP, NHOMNMIP,
                         ;NHOMIA, NHONMIA, NHOMNMIA,


;; Read Total Internal productions into zonal array and accumulate internals by purpose
;LOOP K = 1,dbi.1.NUMRECORDS
;         x = DBIReadRecord(1,k)
;         IF (K <= @LastIZn@)
;              TMProda[1][di.1.TAZ]       =   di.1.HBW_Mtr_Ps
;              TMProda[2][di.1.TAZ]       =   di.1.HBS_Mtr_Ps
;              TMProda[3][di.1.TAZ]       =   di.1.HBO_Mtr_Ps
;              TMProda[4][di.1.TAZ]       =   di.1.NHW_Mtr_Ps
;              TMProda[5][di.1.TAZ]       =   di.1.NHO_Mtr_Ps
;
;              TNMProda[1][di.1.TAZ]      =   di.1.HBW_NMt_Ps
;              TNMProda[2][di.1.TAZ]      =   di.1.HBS_NMt_Ps
;              TNMProda[3][di.1.TAZ]      =   di.1.HBO_NMt_Ps
;              TNMProda[4][di.1.TAZ]      =   di.1.NHW_NMt_Ps
;              TNMProda[5][di.1.TAZ]      =   di.1.NHO_NMt_Ps
;
;              TMNMProda[1][di.1.TAZ]     =   di.1.HBW_Mtr_Ps + di.1.HBW_ALL_Ps
;              TMNMProda[2][di.1.TAZ]     =   di.1.HBS_Mtr_Ps + di.1.HBS_ALL_Ps
;              TMNMProda[3][di.1.TAZ]     =   di.1.HBO_Mtr_Ps + di.1.HBO_ALL_Ps
;              TMNMProda[4][di.1.TAZ]     =   di.1.NHW_Mtr_Ps + di.1.NHW_ALL_Ps
;              TMNMProda[5][di.1.TAZ]     =   di.1.NHO_Mtr_Ps + di.1.NHO_ALL_Ps
;
;              TProdInca[1][di.1.TAZ][1]  =   di.1.HBWMTRP_I1
;              TProdInca[1][di.1.TAZ][2]  =   di.1.HBWMTRP_I2
;              TProdInca[1][di.1.TAZ][3]  =   di.1.HBWMTRP_I3
;              TProdInca[1][di.1.TAZ][4]  =   di.1.HBWMTRP_I4
;
;              TProdInca[2][di.1.TAZ][1]  =   di.1.HBSMTRP_I1
;              TProdInca[2][di.1.TAZ][2]  =   di.1.HBSMTRP_I2
;              TProdInca[2][di.1.TAZ][3]  =   di.1.HBSMTRP_I3
;              TProdInca[2][di.1.TAZ][4]  =   di.1.HBSMTRP_I4
;
;              TProdInca[3][di.1.TAZ][1]  =   di.1.HBOMTRP_I1
;              TProdInca[3][di.1.TAZ][2]  =   di.1.HBOMTRP_I2
;              TProdInca[3][di.1.TAZ][3]  =   di.1.HBOMTRP_I3
;              TProdInca[3][di.1.TAZ][4]  =   di.1.HBOMTRP_I4
;
;              ;; Accumulate total Ps by purpose
;              SumTotMP[1]     =  SumTotMP[1]   +  TMProda[1][di.1.TAZ]
;              SumTotMP[2]     =  SumTotMP[2]   +  TMProda[2][di.1.TAZ]
;              SumTotMP[3]     =  SumTotMP[3]   +  TMProda[3][di.1.TAZ]
;              SumTotMP[4]     =  SumTotMP[4]   +  TMProda[4][di.1.TAZ]
;              SumTotMP[5]     =  SumTotMP[5]   +  TMProda[5][di.1.TAZ]
;
;              SumTotNMP[1]    =  SumTotNMP[1]  +  TNMProda[1][di.1.TAZ]
;              SumTotNMP[2]    =  SumTotNMP[2]  +  TNMProda[2][di.1.TAZ]
;              SumTotNMP[3]    =  SumTotNMP[3]  +  TNMProda[3][di.1.TAZ]
;              SumTotNMP[4]    =  SumTotNMP[4]  +  TNMProda[4][di.1.TAZ]
;              SumTotNMP[5]    =  SumTotNMP[5]  +  TNMProda[5][di.1.TAZ]
;
;              SumTotMNMP[1]   =  SumTotMNMP[1] +  TMProda[1][di.1.TAZ] +  TNMProda[1][di.1.TAZ]
;              SumTotMNMP[2]   =  SumTotMNMP[2] +  TMProda[2][di.1.TAZ] +  TNMProda[2][di.1.TAZ]
;              SumTotMNMP[3]   =  SumTotMNMP[3] +  TMProda[3][di.1.TAZ] +  TNMProda[3][di.1.TAZ]
;              SumTotMNMP[4]   =  SumTotMNMP[4] +  TMProda[4][di.1.TAZ] +  TNMProda[4][di.1.TAZ]
;              SumTotMNMP[5]   =  SumTotMNMP[5] +  TMProda[5][di.1.TAZ] +  TNMProda[5][di.1.TAZ]
;          ENDIF
; ENDLOOP
;
;;; Read Total Internal attractions into zonal array and accumulate internals by prupose
;LOOP K = 1,dbi.2.NUMRECORDS
;         x = DBIReadRecord(2,k)
;         IF (K <= @LastIZn@)
;              TMAttra[1][di.2.TAZ]        =   di.2.HBW_Mtr_As
;              TMAttra[2][di.2.TAZ]        =   di.2.HBS_Mtr_As
;              TMAttra[3][di.2.TAZ]        =   di.2.HBO_Mtr_As
;              TMAttra[4][di.2.TAZ]        =   di.2.NHW_Mtr_As
;              TMAttra[5][di.2.TAZ]        =   di.2.NHO_Mtr_As
;
;              TNMAttra[1][di.2.TAZ]       =   di.2.HBW_NMt_As
;              TNMAttra[2][di.2.TAZ]       =   di.2.HBS_NMt_As
;              TNMAttra[3][di.2.TAZ]       =   di.2.HBO_NMt_As
;              TNMAttra[4][di.2.TAZ]       =   di.2.NHW_NMt_As
;              TNMAttra[5][di.2.TAZ]       =   di.2.NHO_NMt_As
;
;              TMNMAttra[1][di.2.TAZ]      =   di.2.HBW_Mtr_As + di.2.HBW_NMt_As
;              TMNMAttra[2][di.2.TAZ]      =   di.2.HBS_Mtr_As + di.2.HBS_NMt_As
;              TMNMAttra[3][di.2.TAZ]      =   di.2.HBO_Mtr_As + di.2.HBO_NMt_As
;              TMNMAttra[4][di.2.TAZ]      =   di.2.NHW_Mtr_As + di.2.NHW_NMt_As
;              TMNMAttra[5][di.2.TAZ]      =   di.2.NHO_Mtr_As + di.2.NHO_NMt_As
;
;
;              TAttrInca[1][di.2.TAZ][1]  =   di.2.HBWMTRA_I1
;              TAttrInca[1][di.2.TAZ][2]  =   di.2.HBWMTRA_I2
;              TAttrInca[1][di.2.TAZ][3]  =   di.2.HBWMTRA_I3
;              TAttrInca[1][di.2.TAZ][4]  =   di.2.HBWMTRA_I4
;
;              TAttrInca[2][di.2.TAZ][1]  =   di.2.HBSMTRA_I1
;              TAttrInca[2][di.2.TAZ][2]  =   di.2.HBSMTRA_I2
;              TAttrInca[2][di.2.TAZ][3]  =   di.2.HBSMTRA_I3
;              TAttrInca[2][di.2.TAZ][4]  =   di.2.HBSMTRA_I4
;
;              TAttrInca[3][di.2.TAZ][1]  =   di.2.HBOMTRA_I1
;              TAttrInca[3][di.2.TAZ][2]  =   di.2.HBOMTRA_I2
;              TAttrInca[3][di.2.TAZ][3]  =   di.2.HBOMTRA_I3
;              TAttrInca[3][di.2.TAZ][4]  =   di.2.HBOMTRA_I4
;
;              ;; Accumulate total Ps by purpose
;              SumTotMA[1]   =  SumTotMA[1]   +  TMAttra[1][di.2.TAZ]
;              SumTotMA[2]   =  SumTotMA[2]   +  TMAttra[2][di.2.TAZ]
;              SumTotMA[3]   =  SumTotMA[3]   +  TMAttra[3][di.2.TAZ]
;              SumTotMA[4]   =  SumTotMA[4]   +  TMAttra[4][di.2.TAZ]
;              SumTotMA[5]   =  SumTotMA[5]   +  TMAttra[5][di.2.TAZ]
;
;              SumTotNMA[1]  =  SumTotNMA[1]  +  TNMAttra[1][di.2.TAZ]
;              SumTotNMA[2]  =  SumTotNMA[2]  +  TNMAttra[2][di.2.TAZ]
;              SumTotNMA[3]  =  SumTotNMA[3]  +  TNMAttra[3][di.2.TAZ]
;              SumTotNMA[4]  =  SumTotNMA[4]  +  TNMAttra[4][di.2.TAZ]
;              SumTotNMA[5]  =  SumTotNMA[5]  +  TNMAttra[5][di.2.TAZ]
;
;              SumTotMNMA[1] =  SumTotMNMA[1] +  TMNMAttra[1][di.2.TAZ]
;              SumTotMNMA[2] =  SumTotMNMA[2] +  TMNMAttra[2][di.2.TAZ]
;              SumTotMNMA[3] =  SumTotMNMA[3] +  TMNMAttra[3][di.2.TAZ]
;              SumTotMNMA[4] =  SumTotMNMA[4] +  TMNMAttra[4][di.2.TAZ]
;              SumTotMNMA[5] =  SumTotMNMA[5] +  TMNMAttra[5][di.2.TAZ]
;
;          ENDIF
; ENDLOOP

;; Read internal commercial, truck Ps/As zonal array and accumulate, totals, internals, and externals by purpose
LOOP K = 1,dbi.3.NUMRECORDS
         x = DBIReadRecord(3,k)
         IF (K <= @LastIZn@)
              TMProda[6][di.3.TAZ]    =   di.3.Comm_Veh
              TMProda[7][di.3.TAZ]    =   di.3.Med_Truck
              TMProda[8][di.3.TAZ]    =   di.3.Hvy_Truck

              TMAttra[6][di.3.TAZ]    =   di.3.Comm_Veh
              TMAttra[7][di.3.TAZ]    =   di.3.Med_Truck
              TMAttra[8][di.3.TAZ]    =   di.3.Hvy_Truck

              TMNMProda[6][di.3.TAZ]    =   di.3.Comm_Veh
              TMNMProda[7][di.3.TAZ]    =   di.3.Med_Truck
              TMNMProda[8][di.3.TAZ]    =   di.3.Hvy_Truck

              TMNMAttra[6][di.3.TAZ]    =   di.3.Comm_Veh
              TMNMAttra[7][di.3.TAZ]    =   di.3.Med_Truck
              TMNMAttra[8][di.3.TAZ]    =   di.3.Hvy_Truck

              ;; Accumulate total Ps by purpose
              SumTotMP[6]   =  SumTotMP[6]   +  TMProda[6][di.3.TAZ]
              SumTotMP[7]   =  SumTotMP[7]   +  TMProda[7][di.3.TAZ]
              SumTotMP[8]   =  SumTotMP[8]   +  TMProda[8][di.3.TAZ]

              SumTotMA[6]   =  SumTotMA[6]   +  TMAttra[6][di.3.TAZ]
              SumTotMA[7]   =  SumTotMA[7]   +  TMAttra[7][di.3.TAZ]
              SumTotMA[8]   =  SumTotMA[8]   +  TMAttra[8][di.3.TAZ]

              ;; Accumulate total Ps by purpose
              SumTotMNMP[6]   =  SumTotMP[6]   +  TMProda[6][di.3.TAZ]
              SumTotMNMP[7]   =  SumTotMP[7]   +  TMProda[7][di.3.TAZ]
              SumTotMNMP[8]   =  SumTotMP[8]   +  TMProda[8][di.3.TAZ]

              SumTotMNMA[6]   =  SumTotMA[6]   +  TMAttra[6][di.3.TAZ]
              SumTotMNMA[7]   =  SumTotMA[7]   +  TMAttra[7][di.3.TAZ]
              SumTotMNMA[8]   =  SumTotMA[8]   +  TMAttra[8][di.3.TAZ]
          ENDIF
 ENDLOOP



;; Read ALL External Ps and As zonal array and accumulate totals
LOOP K = 1,dbi.4.NUMRECORDS
         x = DBIReadRecord(4,k)
              ;XProda[1][di.4.TAZ]    =   di.4.HBWXps
              ;XProda[2][di.4.TAZ]    =   di.4.HBSXps
              ;XProda[3][di.4.TAZ]    =   di.4.HBOXps
              ;XProda[4][di.4.TAZ]    =   di.4.NHWXps
              ;XProda[5][di.4.TAZ]    =   di.4.NHOXps
              XProda[6][di.4.TAZ]    =   di.4.COMXps
              XProda[7][di.4.TAZ]    =   di.4.MTKXps
              XProda[8][di.4.TAZ]    =   di.4.HTKXps

              ;XAttra[1][di.4.TAZ]    =   di.4.HBWXas
              ;XAttra[2][di.4.TAZ]    =   di.4.HBSXas
              ;XAttra[3][di.4.TAZ]    =   di.4.HBOXas
              ;XAttra[4][di.4.TAZ]    =   di.4.NHWXas
              ;XAttra[5][di.4.TAZ]    =   di.4.NHOXas
              XAttra[6][di.4.TAZ]    =   di.4.COMXas
              XAttra[7][di.4.TAZ]    =   di.4.MTKXas
              XAttra[8][di.4.TAZ]    =   di.4.HTKXas


;;       Accumulate total, internal and external Ps by purpose
              ;SumExtMP[1]   =  SumExtMP[1]   +  XProda[1][di.4.TAZ]
              ;SumExtMP[2]   =  SumExtMP[2]   +  XProda[2][di.4.TAZ]
              ;SumExtMP[3]   =  SumExtMP[3]   +  XProda[3][di.4.TAZ]
              ;SumExtMP[4]   =  SumExtMP[4]   +  XProda[4][di.4.TAZ]
              ;SumExtMP[5]   =  SumExtMP[5]   +  XProda[5][di.4.TAZ]
              SumExtMP[6]   =  SumExtMP[6]   +  XProda[6][di.4.TAZ]
              SumExtMP[7]   =  SumExtMP[7]   +  XProda[7][di.4.TAZ]
              SumExtMP[8]   =  SumExtMP[8]   +  XProda[8][di.4.TAZ]

              ;SumExtMA[1]   =  SumExtMA[1]   +  XAttra[1][di.4.TAZ]
              ;SumExtMA[2]   =  SumExtMA[2]   +  XAttra[2][di.4.TAZ]
              ;SumExtMA[3]   =  SumExtMA[3]   +  XAttra[3][di.4.TAZ]
              ;SumExtMA[4]   =  SumExtMA[4]   +  XAttra[4][di.4.TAZ]
              ;SumExtMA[5]   =  SumExtMA[5]   +  XAttra[5][di.4.TAZ]
              SumExtMA[6]   =  SumExtMA[6]   +  XAttra[6][di.4.TAZ]
              SumExtMA[7]   =  SumExtMA[7]   +  XAttra[7][di.4.TAZ]
              SumExtMA[8]   =  SumExtMA[8]   +  XAttra[8][di.4.TAZ]
 ENDLOOP

;;
;; compute INTERNAL Trip Ps,A by subtracting EXTERNAL Ends from TOTAL MOTORIZED&NON-MOTR.ENDS, scale Ps by income group accordingly
;;
    LOOP ZZ = 1,@LastIZn@
         LOOP PP = 1, @Purps@

              IMProda[PP][ZZ]  = MAX( 0, (TMProda[PP][ZZ] - XAttra[PP][ZZ]))
              IMAttra[PP][ZZ]  = MAX( 0, (TMAttra[PP][ZZ] - XProda[PP][ZZ]))

              ;; scale motorized trips by income level to match new Internal motorized total
              IF (PP<4)
                 if (IMProda[PP][zz] = 0)

                     IncScale = 0.0

                   Else

                    IncScale = IMProda[PP][ZZ]/TMProda[PP][ZZ]

                 ENDIF


                 IProdInca[pp][zz][1]  =  TProdInca[pp][zz][1]  * IncScale
                 IProdInca[pp][zz][2]  =  TProdInca[pp][zz][2]  * IncScale
                 IProdInca[pp][zz][3]  =  TProdInca[pp][zz][3]  * IncScale
                 IProdInca[pp][zz][4]  =  TProdInca[pp][zz][4]  * IncScale

              ENDIF


                ; Accumulate new motorized  and non-motorized Final Internal Ps, unscaled) As
                SumIntMP[PP]    =  SumIntMP[PP]    +  IMProda[PP][ZZ]
                SumIntMA[PP]    =  SumIntMA[PP]    +  IMAttra[PP][ZZ]

                SumIntNMP[PP]   =  SumIntNMP[PP]   +  TNMProda[PP][ZZ]
                SumIntNMA[PP]   =  SumIntNMA[PP]   +  TNMAttra[PP][ZZ]

                SumIntMNMP[PP]  =  SumIntMNMP[PP]  +  IMProda[PP][ZZ] +  TNMProda[PP][ZZ]
                SumIntMNMA[PP]  =  SumIntMNMA[PP]  +  IMAttra[PP][ZZ] +  TNMAttra[PP][ZZ]
         ENDLOOP
    ENDLOOP

;;
;; compute scaling factors for INTERNAL Attractions
;; - This scaling will be based on INTERNAL Motorized Ps and nonMotorized Trips
;; - Attractions are based on computed attractions from Trip Generation

   LOOP PP= 1,8
        IF ( SumTotMNMA[PP] > 0.0 )  AttScalFtr[PP] = ((SUMintMNMP[PP] + SumExtMP[PP]) - SumExtMA[PP])/ SumTotMNMA[PP]
             print form= 10.0 list = 'Purpose: ', PP,    ' SumTotMNMP[PP]: ',SumTotMNMP[PP], file = debug.txt
             print form= 10.0 list = '                   ',    ' SUMintMNMA[PP]: ',SumintMNMA[PP], file = debug.txt
             print form= 10.0 list = '                   ',    ' SumExtMP[PP]:   ',SumExtMP[PP]  , file = debug.txt
             print form= 10.0 list = '                   ',    ' SumExtMA[PP]:   ',SumExtMA[PP]  , file = debug.txt
             print form= 10.4 list = '                   ',    ' AttScalFtr[PP]  ',AttScalFtr[PP], file = debug.txt



   ENDLOOP

;;
;; Apply Motor & Non-Motor INTERNAL scaling factors to INTERNAL Attractions
;;
    LOOP ZZ = 1, @LastIZn@
         LOOP PP = 1, @Purps@


                ScIMAttra[PP][ZZ]    = TMAttra[PP][ZZ]   * AttScalFtr[PP]
                ScINMAttra[PP][ZZ]   = TNMAttra[PP][ZZ]  * AttScalFtr[PP]

                ScIMNMAttra[PP][ZZ]  = ScIMAttra[PP][ZZ] + ScINMAttra[PP][ZZ]

              IF (PP<4)
                 if (ScIMAttra[PP][ZZ] = 0)

                      IncScale = 0.0

                   Else

                      IncScale = ScIMAttra[PP][ZZ]/TMAttra[PP][ZZ]

                 ENDIF


                 IAttrInca[pp][zz][1]  =  TAttrInca[pp][zz][1]  * IncScale
                 IAttrInca[pp][zz][2]  =  TAttrInca[pp][zz][2]  * IncScale
                 IAttrInca[pp][zz][3]  =  TAttrInca[pp][zz][3]  * IncScale
                 IAttrInca[pp][zz][4]  =  TAttrInca[pp][zz][4]  * IncScale

              ENDIF


                ; Accumulate Internal Ps, As:

                SumScIntMA[PP]     =  SumScIntMA[PP]   +  ScIMAttra[PP][ZZ]
                SumScIntNMA[PP]    =  SumScIntNMA[PP]  +  ScINMAttra[PP][ZZ]
                SumScIntMNMA[PP]   =  SumScIntMNMA[PP] +  ScIMNMAttra[PP][ZZ]

         ENDLOOP
    ENDLOOP

;; Write out zonal INTERNAL Ps,As by purpose


  LOOP ZZ = 1,@ZONESIZE@

    RO.TAZ       = ZZ
    ;RO.HBWMIP    = IMProda[1][ZZ]
    ;RO.HBWNMIP   = TNMProda[1][ZZ]
    ;RO.HBWMNMIP  = IMProda[1][ZZ] +  TNMProda[1][ZZ]
    ;RO.HBWMIP1   = IProdInca[1][ZZ][1]
    ;RO.HBWMIP2   = IProdInca[1][ZZ][2]
    ;RO.HBWMIP3   = IProdInca[1][ZZ][3]
    ;RO.HBWMIP4   = IProdInca[1][ZZ][4]
    ;
    ;RO.HBWMIA    = ScIMAttra[1][ZZ]
    ;RO.HBWNMIA   = ScINMAttra[1][ZZ]
    ;RO.HBWMNMIA  = ScIMNMAttra[1][ZZ]
    ;RO.HBWMIA1   = IAttrInca[1][ZZ][1]
    ;RO.HBWMIA2   = IAttrInca[1][ZZ][2]
    ;RO.HBWMIA3   = IAttrInca[1][ZZ][3]
    ;RO.HBWMIA4   = IAttrInca[1][zz][4]
    ;
    ;RO.HBSMIP    = IMProda[2][ZZ]
    ;RO.HBSNMIP   = TNMProda[2][ZZ]
    ;RO.HBSMNMIP  = IMProda[2][ZZ] +  TNMProda[2][ZZ]
    ;RO.HBSMIP1   = IProdInca[2][ZZ][1]
    ;RO.HBSMIP2   = IProdInca[2][ZZ][2]
    ;RO.HBSMIP3   = IProdInca[2][ZZ][3]
    ;RO.HBSMIP4   = IProdInca[2][ZZ][4]
    ;
    ;RO.HBSMIA    = ScIMAttra[2][ZZ]
    ;RO.HBSNMIA   = ScINMAttra[2][ZZ]
    ;RO.HBSMNMIA  = ScIMNMAttra[2][ZZ]
    ;RO.HBSMIA1   = IAttrInca[2][ZZ][1]
    ;RO.HBSMIA2   = IAttrInca[2][ZZ][2]
    ;RO.HBSMIA3   = IAttrInca[2][ZZ][3]
    ;RO.HBSMIA4   = IAttrInca[2][zz][4]
    ;
    ;RO.HBOMIP    = IMProda[3][ZZ]
    ;RO.HBONMIP   = TNMProda[3][ZZ]
    ;RO.HBOMNMIP  = IMProda[3][ZZ] +  TNMProda[3][ZZ]
    ;RO.HBOMIP1   = IProdInca[3][ZZ][1]
    ;RO.HBOMIP2   = IProdInca[3][ZZ][2]
    ;RO.HBOMIP3   = IProdInca[3][ZZ][3]
    ;RO.HBOMIP4   = IProdInca[3][ZZ][4]
    ;
    ;RO.HBOMIA    = ScIMAttra[3][ZZ]
    ;RO.HBONMIA   = ScINMAttra[3][ZZ]
    ;RO.HBOMNMIA  = ScIMNMAttra[3][ZZ]
    ;RO.HBOMIA1   = IAttrInca[3][ZZ][1]
    ;RO.HBOMIA2   = IAttrInca[3][ZZ][2]
    ;RO.HBOMIA3   = IAttrInca[3][ZZ][3]
    ;RO.HBOMIA4   = IAttrInca[3][zz][4]
    ;
    ;RO.NHWMIP    = IMProda[4][ZZ]
    ;RO.NHWNMIP   = TNMProda[4][ZZ]
    ;RO.NHWMNMIP  = IMProda[4][ZZ] +  TNMProda[4][ZZ]
    ;RO.NHWMIA    = ScIMAttra[4][ZZ]
    ;RO.NHWNMIA   = ScINMAttra[4][ZZ]
    ;RO.NHWMNMIA  = ScIMNMAttra[4][ZZ]
    ;
    ;RO.NHOMIP    = IMProda[5][ZZ]
    ;RO.NHONMIP   = TNMProda[5][ZZ]
    ;RO.NHOMNMIP  = IMProda[5][ZZ] +  TNMProda[5][ZZ]
    ;RO.NHOMIA    = ScIMAttra[5][ZZ]
    ;RO.NHONMIA   = ScINMAttra[5][ZZ]
    ;RO.NHOMNMIA  = ScIMNMAttra[5][ZZ]

    RO.COMIP   = IMProda[6][ZZ]
    RO.COMIA   = ScIMAttra[6][ZZ]
    RO.MTKIP   = IMProda[7][ZZ]
    RO.MTKIA   = ScIMAttra[7][ZZ]
    RO.HTKIP   = IMProda[8][ZZ]
    RO.HTKIA   = ScIMAttra[8][ZZ]



    WRITE RECO = 1
  ENDLOOP


;; --------------------------------------------------------------------------------------------------------------------------------
;;print input P/A results by intl, external groups

print printo=1            List =  ' Listing of OUTPUT P/A Totals by purpose to be used in the INTERNAL Trip Distribution Process '

   print printo= 1              list = '         '
   print printo =1              list = '         ',' PRODUCTIONS SUMMARY '
   print printo =1              list = '         ',' External Mtr    Internal Mtr    Internal Mtr    Internal NonMtr Internal Total '
   print printo =1              list = ' Purpose ',' As (I/P)        Ps (I/P)        Ps (O/P)        Ps (I/P&O/P)     Ps (O/P)       '
   print printo= 1              list = '         '
   print printo= 1 form=16.2csv list = ' HBW     ',  SumExtMA[1], SumTotMP[1], SumIntMP[1], SumIntNMP[1], SumIntMNMP[1]
   print printo= 1 form=16.2csv list = ' HBS     ',  SumExtMA[2], SumTotMP[2], SumIntMP[2], SumIntNMP[2], SumIntMNMP[2]
   print printo= 1 form=16.2csv list = ' HBO     ',  SumExtMA[3], SumTotMP[3], SumIntMP[3], SumIntNMP[3], SumIntMNMP[3]
   print printo= 1 form=16.2csv list = ' NHW     ',  SumExtMA[4], SumTotMP[4], SumIntMP[4], SumIntNMP[4], SumIntMNMP[4]
   print printo= 1 form=16.2csv list = ' NHO     ',  SumExtMA[5], SumTotMP[5], SumIntMP[5], SumIntNMP[5], SumIntMNMP[5]
   print printo= 1 form=16.2csv list = ' COM     ',  SumExtMA[6], SumTotMP[6], SumIntMP[6], SumIntNMP[6], SumIntMNMP[6]
   print printo= 1 form=16.2csv list = ' MTK     ',  SumExtMA[7], SumTotMP[7], SumIntMP[7], SumIntNMP[7], SumIntMNMP[7]
   print printo= 1 form=16.2csv list = ' HTK     ',  SumExtMA[8], SumTotMP[8], SumIntMP[8], SumIntNMP[8], SumIntMNMP[8]
   print printo= 1              list = '         '
   print printo =1              list = '         ',' ATTRACTIONS SUMMARY                          '
   print printo =1              list = '         ',' External Mtr    Internal Mtr    Intl NonMtr     Intl All        '
   print printo =1              list = ' Purpose ',' Ps (I/P)        As (I/P)        As (I/P)        As (I/P)        '
   print printo= 1              list = '         '
   print printo= 1 form=16.2csv list = ' HBW     ',  SumExtMP[1], SumTotMA[1], SumTotNMA[1],SumTotMNMA[1]
   print printo= 1 form=16.2csv list = ' HBS     ',  SumExtMP[2], SumTotMA[2], SumTotNMA[2],SumTotMNMA[2]
   print printo= 1 form=16.2csv list = ' HBO     ',  SumExtMP[3], SumTotMA[3], SumTotNMA[3],SumTotMNMA[3]
   print printo= 1 form=16.2csv list = ' NHW     ',  SumExtMP[4], SumTotMA[4], SumTotNMA[4],SumTotMNMA[4]
   print printo= 1 form=16.2csv list = ' NHO     ',  SumExtMP[5], SumTotMA[5], SumTotNMA[5],SumTotMNMA[5]
   print printo= 1 form=16.2csv list = ' COM     ',  SumExtMP[6], SumTotMA[6], SumTotNMA[6],SumTotMNMA[6]
   print printo= 1 form=16.2csv list = ' MTK     ',  SumExtMP[7], SumTotMA[7], SumTotNMA[7],SumTotMNMA[7]
   print printo= 1 form=16.2csv list = ' HTK     ',  SumExtMP[8], SumTotMA[8], SumTotNMA[8],SumTotMNMA[8]
   print printo= 1              list = '         '
   print printo =1              list = '         ',' Scaled Intl     Scaled Intl     Scaled Intl     Scaling '
   print printo =1              list = ' Purpose ',' Mtr As          Non-Mtr As      ALL     As      Factor  '
   print printo= 1              list = '         '
   print printo= 1 form=16.2csv list = ' HBW     ',  SumScIntMA[1], SumScIntNMA[1], SumScIntMNMA[1], AttScalFtr[1]
   print printo= 1 form=16.2csv list = ' HBS     ',  SumScIntMA[2], SumScIntNMA[2], SumScIntMNMA[2], AttScalFtr[2]
   print printo= 1 form=16.2csv list = ' HBO     ',  SumScIntMA[3], SumScIntNMA[3], SumScIntMNMA[3], AttScalFtr[3]
   print printo= 1 form=16.2csv list = ' NHW     ',  SumScIntMA[4], SumScIntNMA[4], SumScIntMNMA[4], AttScalFtr[4]
   print printo= 1 form=16.2csv list = ' NHO     ',  SumScIntMA[5], SumScIntNMA[5], SumScIntMNMA[5], AttScalFtr[5]
   print printo= 1 form=16.2csv list = ' COM     ',  SumScIntMA[6], SumScIntNMA[6], SumScIntMNMA[6], AttScalFtr[6]
   print printo= 1 form=16.2csv list = ' MTK     ',  SumScIntMA[7], SumScIntNMA[7], SumScIntMNMA[7], AttScalFtr[7]
   print printo= 1 form=16.2csv list = ' HTK     ',  SumScIntMA[8], SumScIntNMA[8], SumScIntMNMA[8], AttScalFtr[8]
ENDRUN
*copy voya*.prn outputs\reports\mod2.rpt
