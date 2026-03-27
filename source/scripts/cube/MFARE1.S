;=================================================================
;  MFARE1.S
;   V2.3 Model
;       Script Version of MFARE1 script
;   Walk and Drive Access Metrorail Sta. to Sta. fares developed
;    for AM Peak and off-peak periods
;
;   Programmer: Milone; fxie
;   Date:      1/11/07; 7/8/20
;   Metro station XY file name corrected (12/13/2006)
;   Export station-to-station AM/OP farematrix (7/8/2020)
;=================================================================
;


STATSIZE        =   150               ;  No. of Metrorail Stations (Note: Max is 999)
MR_DST_FTR      =  0.01               ;  Factor to convert input skimmed Metrorail distance units to whole miles

;----------------------------------------------------------------------
;  Filenames:

MSTA_XYs        = 'inputs\trn\MFARE1.A1'                   ;  Metrorail Sta XYs coords scaled so computed units are in 1/100ths of miles
MSTA_Dst_Skims  = 'outputs\skims\RLDIST.SKM'                  ;  Metrorail Sta/Sta Distance Skims (Distance units:        1/100ths of miles
MSTA_Discount   = 'INPUTS\trn\mfare1_Sta_Disc.ASC'  ;  Metrorail Sta fare discount array in cents
MSTA_Tariff     = 'INPUTS\trn\tariff.txt'           ;  WMATA tariff policy

AM_Sta_Fares    = 'outputs\trn_net\AM_Metrorail_Fares.TXT'      ;  Output AM Statio-to-Station Fares -text file
OP_Sta_Fares    = 'outputs\trn_net\OP_Metrorail_Fares.TXT'      ;  Output OP Statio-to-Station Fares -text file


RUN PGM=MATRIX
ZONES=@STATSIZE@
read FILE=@MSTA_Tariff@
MATO[1]=outputs\trn_net\Metrorail_Fare.mat, mo=100,200

;
; Set up zone arrays for accumulating I/O variables
;
;
;
;==============================================================
; Read Station Coordinate file                                =
;==============================================================
;
      LOOKUP Name=StaXYS,
             LOOKUP[1]   = 1,Result = 2, ; Xcrds
             LOOKUP[2]   = 1,Result = 3, ; YCrds
             Interpolate = N, FAIL=0,0,0,list=Y,file=@MSTA_XYS@

;
;==============================================================
; Read Station Fare Discount Lookup                           =
;   - The station-specific discount values are in cents.      =
;     The discounts are subtracted from the final             =
;     computed fares to/from the station                      =
;==============================================================
;
      LOOKUP Name=StaDSC,
             LOOKUP[1]   = 1,Result = 2,   ;  AM Fare Discount in cents
             LOOKUP[2]   = 1,Result = 3,   ;  OP Fare Discount in cents
             Interpolate = N, FAIL=0,0,0,list=Y,file=@MSTA_Discount@


;==============================================================
; Over-the Rail Distance Skims                                =
;==============================================================

     FILEI MATI = outputs\skims\RLDIST.SKM
           MW[1]= MI.1.1     ;   (Over-the-rail distance in 1/100s mi)

           ROWSUM1 = ROWSUM(1)
;==============================================================
; Now, loop through each station i/j, compute composite distance,
;      and compute AM and Off peak fares.  Use generalized cost
;      calculation:
;
; FARE = (incremental cost + Rate*Distance) <-Per short  Distance  +
;        (incremental cost + Rate*Distance) <-Per medium Distance  +
;        (incremental cost + Rate*Distance) <-Per long   Distance
;
;==============================================================
  IF (rowsum1 > 0)      ; exclude unused stations
    JLOOP

     IF (MW[1] !=0 || I=J )   ; exclude station i/js that are unused

;     Calculate airline distance (MW[2]) in 100s of miles
      IxCrd  = StaXYS(1,I)
      JxCrd  = StaXYS(1,J)
      IyCrd  = StaXYS(2,I)
      JyCrd  = StaXYS(2,J)
      MW[2]  = ((IxCrd-JxCrd)^2 + (IyCrd-JyCrd)^2 )^ 0.5

;     Calculate Composite (airline/over-the rail) distance MW[3] in whole miles
      MW[3]  =          ((MW[1]  + MW[2]) / 2.0) * @MR_Dst_Ftr@

;     Calculate peak (MW[10]) and off-peak fares (MW[20]) based on comp distance
;     Fares computed units in non-defalted cents


;   Peak Fare Calculation:  ------------------------------------------------------------------------

      PkDist1 = Pk_Fare_Dist1
      PkDist2 = Pk_Fare_Dist1 + Pk_Fare_Dist2


      IF       (MW[3] <= PkDist1)

                 MW[10] = Pk_Fare_Incr1 + (Pk_Fare_Rate1 * MW[3])

        ELSEIF (MW[3] >  PkDist1 && MW[3] <= PkDist2)

                 MW[10] = Pk_Fare_Incr1 + (Pk_Fare_Rate1 *  Pk_Fare_Dist1)   +
                          Pk_Fare_Incr2 + (Pk_Fare_Rate2 * (MW[3] - PkDist1))

        ELSEIF (MW[3] >  PkDist2)

                 MW[10] = Pk_Fare_Incr1 + (Pk_Fare_Rate1 *  Pk_Fare_Dist1)   +
                          Pk_Fare_Incr2 + (Pk_Fare_Rate2 *  Pk_Fare_Dist2)   +
                          Pk_Fare_Incr3 + (Pk_Fare_Rate3 * (MW[3] - PkDist2))
      ENDIF

;     Round computed AM fare MW[10] to nearest nickle as in original program Final Fare
;     is 'FinAMFare'
                    FARE        = MW[10]
                    temp1       = INT(Fare/10.0)
                    temp2       = temp1  * 10.0
                    DiffCheck   = Fare - temp2
                    IF        (DiffCheck < 2.5)
                         FinAMFare = temp2
                      ELSEIF  (DiffCheck > 7.5)
                         FinAMFare = temp2 + 10.0
                      ElSE
                         FinAMFare = temp2 +  5.0
                    ENDIF

;     Impose Max Fare rule
                 If (FinAMFare > Pk_Fare_Max)  FinAMFare = Pk_Fare_Max

;     Apply AM station discounts if used
                    FinAMFare = FinAMFare - StaDSC(1,I) - StaDsc(1,J)
					MW[100]   = FinAMFare*0.01
;     Compute IJ Index so station-to-station fares can be read in as a lookup
;     Index merges separate I/J numbers into one number (index for  station 1 to station 1 is '1001')
                    IJindex = (I * 1000.0)  + J

;    Write out the AM Fares:
      Print List =  I(5),J(5), FinAMFare(6),IJindex(7),' ; ', MW[10](6), MW[1](10.0),MW[2](10.0),MW[3](10.2),
                    IxCrd(7), JxCrd(7), IyCrd(7), JyCrd(7),
                    PkDist1(10.2),PkDist2(10.2),
               ';< I/J/AM_Fare_n5/AM_Fare/R_Dst100s/A_Dst100s/CmpDstMi/iXcrd/jXcrd/iYcrd/jYcrdI/Dist1/Dist2',
                File=@AM_Sta_Fares@



;     END of Peak Fare Calculation ----------------------------------------------------------------

;    Off-Peak Calculation:  ------------------------------------------------------------------------

      OpDist1 = Op_Fare_Dist1
      OpDist2 = Op_Fare_Dist1 + Op_Fare_Dist2


      IF       (MW[3] <= OpDist1)

                 MW[20] = Op_Fare_Incr1 + (Op_Fare_Rate1 * MW[3])

        ELSEIF (MW[3] >  OpDist1 && MW[3] <= OpDist2)

                 MW[20] = Op_Fare_Incr1 + (Op_Fare_Rate1 *  Op_Fare_Dist1)   +
                          Op_Fare_Incr2 + (Op_Fare_Rate2 * (MW[3] - OpDist1))

        ELSEIF (MW[3] >  OpDist2)

                 MW[20] = Op_Fare_Incr1 + (Op_Fare_Rate1 *  Op_Fare_Dist1)   +
                          Op_Fare_Incr2 + (Op_Fare_Rate2 *  Op_Fare_Dist2)   +
                          Op_Fare_Incr3 + (Op_Fare_Rate3 * (MW[3] - OpDist2))
      ENDIF

;     Round computed Off-peak fare MW[20] to nearest nickle as in original program Final Fare
;     is 'FinOPFare'
                    FARE        = MW[20]
                    temp1       = INT(Fare/10.0)
                    temp2       = temp1  * 10.0
                    DiffCheck   = Fare - temp2
                    IF        (DiffCheck < 2.5)
                         FinOPFare = temp2
                      ELSEIF  (DiffCheck > 7.5)
                         FinOPFare = temp2 + 10.0
                      ElSE
                         FinOPFare = temp2 +  5.0
                    ENDIF


;     Impose Max Fare rule
                 If (FinOPFare > Op_Fare_Max)  FinOPFare = Op_Fare_Max

;     Apply Off-pk station discounts if used
                    FinOPFare = FinOPFare - StaDSC(2,I) - StaDsc(2,J)
					MW[200]   = FinOPFare*0.01
;     Compute IJ Index so station-to-station fares can be read in as a lookup
;     Index merges separate I/J numbers into one number (index for  station 1 to station 1 is '1001')
                    IJindex = (I * 1000.0)  + J

;     Write out the Off-Pk Fares:
      Print List =  I(5),J(5),FinOPFare(6),IJindex(7),' ; ', MW[20](6), MW[1](10.0),MW[2](10.0),MW[3](10.2),
                    IxCrd(7), JxCrd(7), IyCrd(7), JyCrd(7),
                    OpDist1(10.2),OpDist2(10.2),
               ';< I/J/OP_Fare/R_Dst100s/A_Dst100s/CmpDstMi/iXcrd/jXcrd/iYcrd/jYcrdI/Dist1/Dist2',
                File=@OP_Sta_Fares@



;     END of Off Peak Fare Calculation --------------------------------------------------------------


     ENDIF
    ENDJLOOP
   endif
ENDRUN

;==============================================================
; Read VRE FARES IN A FAREZONE MATRIX                         =
;==============================================================

RUN PGM=MATRIX 
FILEI MATI=Inputs\trn\VRE_Fare.DAT PATTERN=IJ:V FIELDS=#1,0,2-10
FILEO MATO=outputs\trn_net\VRE_Fare.mat MO=1 
PAR ZONES=9 
MW[1]=mi.1.1
ENDRUN

;==============================================================
; Read MARC FARES IN A FAREZONE MATRIX                         =
;==============================================================

RUN PGM=MATRIX 
FILEI MATI=Inputs\trn\MARC_Fare.DAT PATTERN=IJ:V FIELDS=#1,0,2-54
FILEO MATO=outputs\trn_net\MARC_Fare.mat MO=1 
PAR ZONES=53 
MW[1]=mi.1.1
ENDRUN



