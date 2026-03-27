; ====================================================================
;  Misc_Time-of-Day.s
;  MWCOG Version 2.3 Model - 3722 TAZ System
;
;  Distribute Truck and  Miscellaneous (non-modeled) trips among
;              among three time periods:
;              -  AM peak    6:00 AM -  8:59 AM  (3 Hrs)
;              -  Midday     9:00 AM -  2:59 PM  (6 Hrs)
;              -  PM peak    3:00 PM -  6:59 PM  (4 Hrs)
;              -  Night      All remaining hrs. (11 Hrs)
;
; Note: The miscellaneous purpose 'School Auto Dr.' is no longer used in V2.3
;
; ====================================================================
;
; Environment Variable:
;               _iter_  (Iteration indicator = 'pp','i1'-'i6'
;
;/////////////////////////////////////////////////////////////////////
; Parameters:
;                                                                   //
ZONESIZE    =       3722              ;  No. of TAZs                //
LastIZN     =       3675              ;  Last Internal TAZ no.      //
FExt        =       LastIZN + 1       ;  First External TAZ no.     //
;/////////////////////////////////////////////////////////////////////

; Input/Output filenames:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; COM/TRK Calibration Adjustment Tables                                    //
TKDELTA  = '..\support\tkdelta_3722.trp '   ; MTK/HTK delta               //
CVDELTA  = '..\support\cvdelta_3722.trp'   ; COM delta       ;                                                                   //
; I/P Truck & Exogenous trip Tables:                                //
XXCVTRK  = 'inputs\auxiliary\XXCVT.vtt'        ;  Com/Mtk/Htk XX Trips (t1-3) //
XXAUTDR  = 'inputs\auxiliary\xxaut.vtt'        ;  Auto Dr XX Trips (t1)    //
;                                                                  //
TAXIADR  = 'inputs\auxiliary\taxi.adr'         ;  TAXI Auto Dr Trips       //
VISIADR  = 'inputs\auxiliary\visi.adr'         ;  Visitor A.Dr Trips       //

;
COMTDOUT = 'outputs\auxiliary\%_iter_%_commer.ptt'         ;  Comm Vehs t1-Intl, t2-Extl
MTKTDOUT = 'outputs\auxiliary\%_iter_%_mtruck.ptt'         ;  Med  Trks t1-Intl, t2-Extl
HTKTDOUT = 'outputs\auxiliary\%_iter_%_htruck.ptt'         ;  Hvy  Trks t1-Intl, t2-Extl  /
;
APXADR   = 'inputs\auxiliary\airpax.adr'          ;  Air Passenger Auto Dr.   //
;
;O/P Truck and Exogenous Tabs by time of day                       //
MISCAM  = 'outputs\auxiliary\%_iter_%_am_misc.tt'           ; AM     Non-Modeled Trips  //
MISCMD  = 'outputs\auxiliary\%_iter_%_md_misc.tt'           ; Midday Non-Modeled Trips  //
MISCPM  = 'outputs\auxiliary\%_iter_%_pm_misc.tt'           ; PM     Non-Modeled Trips  //
MISCNT  = 'outputs\auxiliary\%_iter_%_nt_misc.tt'           ; Night  Non-Modeled Trips  //
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Each output file contains 8 tables -                              //
; 1/xx truck,2/xx autodr,3/taxi adr,4/visitor adr,
; 5/med. truck, 6/hvy truck, 7/air passenger adr, 8/comm veh
;/////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------
;;========================================================
;;  Begin com veh, med, hvy truck time of day processing
;;========================================================
run pgm=matrix
  pageheight=32767  ; Preclude header breaks
  id = "Commercial time of day + delta

  mati[1] = @COMTDOUT@
  mati[2] = @XXCVTRK@
  mati[3] = @CVDELTA@

  mato    = tempcom.trp, mo=61-68


 ; set up mtx 100, 200 to identify I-X, and X-I ijs respectively
  MW[100] = 0
  MW[200] = 0
  if (I=1-@LastIzn@)
      MW[100] = 1, include= @FExt@-@zonesize@
     else
      MW[200] = 1, include= 1-@LastIzn@
  endif

; I/I trips are already balanced, so we can apply a single factor
;  to all trips.  Apply separate P/A and A/P factors to externals.
;  Assume externals are 70/30 inbound (X/I, or A/P) in the morning,
;  70/30 outbound (I/X, P/A) in the evening.  Off-peak is 50/50.
;
; Note: the External(I-X,X-I) trips are multiplied by 2.0 as the CV model
; (i.e., delta table) was developed this way - rm 4/30/08

  mw[1] = mi.1.1              ; I/I CV trips
  mw[2] = mi.1.2   * mw[100]  ; Int P/ Ext A (outbound)     Delta trip table reflects 1/2 total trips
  mw[3] = mi.1.2   * mw[200]  ; Ext A/ Int P (inbound)      Delta trip table reflects 1/2 total trips

; Also add in the X/X's.
  mw[4] = mi.2.1

; Read and transpose the external delta
  mw[11] = mi.3.1 ; I/I
  mw[12] = mi.3.2 ; Int P/ Ext A (outbound)
  mw[13] = mi.3.2.t ; Ext A/ Int P (inbound)

; Add in the deltas.  First, for I/I and I/X.
  if (i = 1-@LastIZN@)
    jloop
      mw[21] = max(mw[1] + mw[11],0)
      mw[22] = max(mw[2] + mw[12],0)
    endjloop
  endif

  if (i > @LastIZN@)
; Now for Ext transposed (X/I).
    mw[23] = max(mw[3] + mw[13],0), include = 1-@LastIZN@

; Now for X/X.
    mw[24] = max(mw[4] + mw[12],0), include = @FExt@-@ZONESIZE@
  endif

; Sum I/I and External here (Total auto drv. distribution from 2018/08 HTS)
  mw[61]  = 0.18700  * (mw[21] + 0.70 * mw[23] + 0.30 * mw[22])  ; AM  Commercial Vehs.
  mw[62]  = 0.32630  * (mw[21] + 0.50 * mw[23] + 0.50 * mw[22])  ; MD  Commercial Vehs.
  mw[63]  = 0.32890  * (mw[21] + 0.30 * mw[23] + 0.70 * mw[22])  ; PM  Commercial Vehs.
  mw[64]  = 0.15780  * (mw[21] + 0.50 * mw[23] + 0.50 * mw[22])  ; NT  Commercial Vehs.

; Keep X/X separate
  mw[65]  = 0.18700  *  mw[24]
  mw[66]  = 0.32630  *  mw[24]
  mw[67]  = 0.32890  *  mw[24]
  mw[68]  = 0.15780  *  mw[24]

endrun

;--------------------------------------------------------------------
run pgm=matrix

  id = "Truck time of day + delta

  mati[1] = @MTKTDOUT@
  mati[4] = @HTKTDOUT@
  mati[2] = @XXCVTRK@
  mati[3] = @TKDELTA@

  mato    = temptrk.trp, mo=71-86


 ; set up mtx 100, 200 to identify I-X, and X-I ijs respectively
  MW[100] = 0
  MW[200] = 0
  if (I=1-@LastIzn@)
      MW[100] = 1, include= @FExt@-@zonesize@
     else
      MW[200] = 1, include= 1-@LastIzn@
  endif

; I/I trips are already balanced, so we can apply a single factor
;  to all trips.  Apply separate P/A and A/P factors to externals.
;  Assume externals are 70/30 inbound (X/I, or A/P) in the morning,
;  70/30 outbound (I/X, P/A) in the evening.  Off-peak is 50/50.
  mw[1] = mi.1.1                   ; MTK I/I
  mw[2] = mi.1.2    * mw[100]      ; MTK Int P/ Ext A (outbound)  Delta trip table reflects 1/2 total trips
  mw[3] = mi.1.2    * mw[200]      ; MTK Ext A/ Int P (inbound)   Delta trip table reflects 1/2 total trips

  mw[4] = mi.4.1                   ; HTK I/I
  mw[5] = mi.4.2    * mw[100]      ; HTK Int P/ Ext A (outbound)  Delta trip table reflects 1/2 total trips
  mw[6] = mi.4.2    * mw[200]      ; HTK Ext A/ Int P (inbound)   Delta trip table reflects 1/2 total trips

; Also add in the X/X's.
  mw[7] = mi.2.2 ; MTK
  mw[8] = mi.2.3 ; HTK

; Read and transpose the external delta.
  mw[21] = mi.3.1           ;  mi.3.mtkii
  mw[22] = mi.3.2           ;  mi.3.mtkext
  mw[23] = mi.3.2.t         ;  mi.3.mtkext.t
  mw[24] = mi.3.3           ;  mi.3.mtkxx
                            ;
  mw[25] = mi.3.4           ;  mi.3.htkii
  mw[26] = mi.3.5           ;  mi.3.htkext
  mw[27] = mi.3.5.t         ;  mi.3.htkext.t
  mw[28] = mi.3.6           ;  mi.3.htkxx

; Add in the deltas.  First, for I/I and I/X.
  if (i = 1-@LastIZN@)
    jloop
      mw[31] = max(mw[1] + mw[21],0)   ;mtk ii
      mw[32] = max(mw[2] + mw[22],0)   ;mtk ix

      mw[35] = max(mw[4] + mw[25],0)   ;htk ii
      mw[36] = max(mw[5] + mw[26],0)   ;htk ix
    endjloop
  endif

  if (i > @LastIZN@)

; Now for X/I.
    mw[33] = max(mw[3] + mw[23],0), include = 1-@LastIZN@   ; xi mtk
    mw[37] = max(mw[6] + mw[27],0), include = 1-@LastIZN@   ; xi htk

; Now for X/X.
    mw[34] = max(mw[7] + mw[24],0), include = @FExt@-@ZONESIZE@   ; xx mtk
    mw[38] = max(mw[8] + mw[28],0), include = @FExt@-@ZONESIZE@   ; xx htk
  endif

; Sum I/I and External here
;  MTK
  mw[71] = 0.250  * (mw[31] + 0.7 * mw[33] + 0.3 * mw[32])  ; AM
  mw[72] = 0.450  * (mw[31] + 0.5 * mw[33] + 0.5 * mw[32])  ; MD
  mw[73] = 0.200  * (mw[31] + 0.3 * mw[33] + 0.7 * mw[32])  ; PM
  mw[74] = 0.100  * (mw[31] + 0.5 * mw[33] + 0.5 * mw[32])  ; NT

;  HTK
  mw[75] = 0.200  * (mw[35] + 0.7 * mw[37] + 0.3 * mw[36])  ; AM
  mw[76] = 0.500  * (mw[35] + 0.5 * mw[37] + 0.5 * mw[36])  ; MD
  mw[77] = 0.100  * (mw[35] + 0.3 * mw[37] + 0.7 * mw[36])  ; PM
  mw[78] = 0.200  * (mw[35] + 0.5 * mw[37] + 0.5 * mw[36])  ; NT

; Keep X/X separate
;  MTK
  mw[79] = 0.250  * mw[34]
  mw[80] = 0.450  * mw[34]
  mw[81] = 0.200  * mw[34]
  mw[82] = 0.100  * mw[34]

;  HTK
  mw[83] = 0.200  * mw[38]
  mw[84] = 0.500  * mw[38]
  mw[85] = 0.100  * mw[38]
  mw[86] = 0.200  * mw[38]
endrun
;;========================================================
;;  end of com veh, med, hvy truck time of day processing
;;========================================================
RUN PGM=MATRIX                   ; Read in Daily Miscellaneous Trips
    MATI[1]=@XXAUTDR@            ; Thru            Auto Driver Trips
    MATI[2]=@TAXIADR@            ; Taxi            Auto Driver Trips
    MATI[3]=@VISIADR@            ; Visitor/Tourist Auto Driver Trips
    MATI[5]=@APXADR@             ; Air Passenger auto driver   Trips

; Read in COM/TRK trips, already split by time period above.
    MATI[6]=tempcom.trp
    MATI[7]=temptrk.trp

; Put Misc Trips in Work Mats 2-8 (it simplifies the
;  numbering of the other tables, below).
  MW[2]  = MI.1.1 ; XX Auto
  MW[3]  = MI.2.1 ; Taxi
  MW[4]  = 0      ; School (no longer used)
  MW[5]  = MI.3.1 ; Visitor

  MW[8]  = MI.5.1 ; Airport Passenger

; Put COM/TRK trips by TOD in their proper work matrices.  We're just
;  passing them through from the steps above.

  MW[110] = MI.7.9           ; AM X/X MTK
  MW[111] = MI.7.13          ; AM X/X HTK
  MW[112] = MI.7.9  + MI.7.13; AM X/X TRK
  MW[116] = MI.7.1           ; AM I/I + EXT MTK
  MW[117] = MI.7.5           ; AM I/I + EXT HTK
  MW[119] = MI.6.1           ; AM I/I + EXT COM

  MW[140] = MI.7.10          ; MD X/X MTK
  MW[141] = MI.7.14          ; MD X/X HTK
  MW[142] = MI.7.10 + MI.7.14; MD X/X TRK
  MW[146] = MI.7.2           ; MD I/I + EXT MTK
  MW[147] = MI.7.6           ; MD I/I + EXT HTK
  MW[149] = MI.6.2           ; MD I/I + EXT COM

  MW[120] = MI.7.11          ; PM X/X MTK
  MW[121] = MI.7.15          ; PM X/X HTK
  MW[122] = MI.7.11 + MI.7.15; PM X/X TRK
  MW[126] = MI.7.3           ; PM I/I + EXT MTK
  MW[127] = MI.7.7           ; PM I/I + EXT HTK
  MW[129] = MI.6.3           ; PM I/I + EXT COM

  MW[130] = MI.7.12          ; NT X/X MTK
  MW[131] = MI.7.16          ; NT X/X HTK
  MW[132] = MI.7.12 + MI.7.16; NT X/X TRK
  MW[136] = MI.7.4           ; NT I/I + EXT MTK
  MW[137] = MI.7.8           ; NT I/I + EXT HTK
  MW[139] = MI.6.4           ; NT I/I + EXT COM

; Apply TOD Factors
; put AM       trips in work mats 10-19
; put MD       trips in work mats 40-49
; put PM       trips in work mats 20-29
; put Off-Peak trips in work mats 30-39
;
 JLOOP
   ; AM Peak Period Trips ----------------------------------------------------
    MW[12] =  0.18700   * MW[2]  + MI.6.5[J] ; AM Thru     Auto Driver + COM
    MW[13] =  0.18700   * MW[3]    ; AM Taxi     Auto Driver
    MW[14] =  0.18700   * MW[5]    ; AM Visitor  Auto Driver
    MW[15] =  0.18700   * MW[4]    ; AM School   Auto Driver

    MW[18] =  0.2310    * MW[8]    ; AM Air Pax  Auto Driver

   ; Midday   Period Trips ---------------------------------------------------
    MW[42] =  0.32630   * MW[2]  + MI.6.6[J] ; MD Thru     Auto Driver + COM
    MW[43] =  0.32630   * MW[3]  ; MD Taxi     Auto Driver
    MW[44] =  0.32630   * MW[5]  ; MD Visitor  Auto Driver
    MW[45] =  0.32630   * MW[4]  ; MD School   Auto Driver

    MW[48] =  0.3657    * MW[8]  ; MD Air Pax  Auto Driver

   ; PM Peak Period Trips  ---------------------------------------------------
    MW[22] = 0.32890    * MW[2]  + MI.6.7[J] ; PM Thru     Auto Driver + COM
    MW[23] = 0.32890    * MW[3]  ; PM Taxi     Auto Driver
    MW[24] = 0.32890    * MW[5]  ; PM Visitor  Auto Driver
    MW[25] = 0.32890    * MW[4]  ; PM School   Auto Driver

    MW[28] = 0.2538     * MW[8]  ; PM Air Pax  Auto Driver

   ; Nighttime Period Trips ----------------------------------------------------
    MW[32] = 0.15780    * MW[2]  + MI.6.8[J] ; NT Thru     Auto Driver + COM
    MW[33] = 0.15780    * MW[3]  ; NT Taxi     Auto Driver
    MW[34] = 0.15780    * MW[5]  ; NT Visitor  Auto Driver
    MW[35] = 0.15780    * MW[4]  ; NT School   Auto Driver

    MW[38] = 0.1495     * MW[8]  ; NT Air Pax  Auto Driver

 ENDJLOOP

; LET'S SUMMARIZE NEATLY
 jloop
    DAYXXMTK = DAYXXMTK + MW[110] + MW[120] + MW[130] + MW[140]    ; ACCUMULATE TOTAL DAILY Medium THRU TRUCKS
    DAYXXHTK = DAYXXHTK + MW[111] + MW[121] + MW[131] + MW[141]    ; ACCUMULATE TOTAL DAILY Heavy  THRU TRUCKS
    DAYXXAD  = DAYXXAD + MW[2] + MI.6.5[J] + MI.6.6[J] + MI.6.7[J] + MI.6.8[J]; ACCUMULATE TOTAL DAILY THRU AUTO DRV + COM
    DAYTXAD  = DAYTXAD + MW[3]                                     ; ACCUMULATE TOTAL DAILY TAXI    ADR TRIPS
    DAYVSAD  = DAYVSAD + MW[5]                                     ; ACCUMULATE TOTAL DAILY VISITOR ADR TRIPS
    DAYScAD  = DAYScAD + MW[4]                                     ; ACCUMULATE TOTAL DAILY School  ADR TRIPS

    DAYMTRK  = DAYMTRK + MW[116] + MW[126] + MW[136] + MW[146]; ACCUMULATE TOTAL DAILY MED. TRUCK TRIPS
    DAYHTRK  = DAYHTRK + MW[117] + MW[127] + MW[137] + MW[147]; ACCUMULATE TOTAL DAILY HVY. TRUCK TRIPS
    DAYAPAX  = DAYAPAX + MW[8]                                ; ACCUMULATE TOTAL DAILY AIR PAX ADR TRIPS
    DAYCOM   = DAYCOM  + MW[119] + MW[129] + MW[139] + MW[149]; ACCUMULATE TOTAL DAILY COMMERCIAL TRIPS
 ;;---
    AMXXMTK  = AMXXMTK + MW[110]  ; ACCUMULATE TOTAL AM XX Medium TRUCKS
    AMXXHTK  = AMXXHTK + MW[111]  ; ACCUMULATE TOTAL AM XX Heavy  TRUCKS
    AMXXAD   = AMXXAD  + MW[12]   ; ACCUMULATE TOTAL AM XX ADR + XX COM  TRIPS
    AMTXAD   = AMTXAD  + MW[13]   ; ACCUMULATE TOTAL AM TAXI  ADR  TRIPS
    AMVSAD   = AMVSAD  + MW[14]   ; ACCUMULATE TOTAL AM VISIT ADR  TRIPS
    AMScAD   = AMScAD  + MW[15]   ; ACCUMULATE TOTAL AM SchoolADR  TRIPS

    AMMTRK   = AMMTRK  + MW[116]  ; ACCUMULATE TOTAL AM MED TRUCK  TRIPS
    AMHTRK   = AMHTRK  + MW[117]  ; ACCUMULATE TOTAL AM HVY TRUCK  TRIPS
    AMAPAX   = AMAPAX  + MW[18]   ; ACCUMULATE TOTAL AM AIR PAX ADR   TRIPS
    AMCOM    = AMCOM   + MW[119]  ; ACCUMULATE TOTAL AM COMMERCIAL TRIPS
 ;;---
    MDXXMTK  = MDXXMTK + MW[140]  ; ACCUMULATE TOTAL MD XX Medium TRUCKS
    MDXXHTK  = MDXXHTK + MW[141]  ; ACCUMULATE TOTAL MD XX Heavy  TRUCKS
    MDXXAD   = MDXXAD  + MW[42]   ; ACCUMULATE TOTAL MD XX ADR + XX COM  TRIPS
    MDTXAD   = MDTXAD  + MW[43]   ; ACCUMULATE TOTAL MD TAXI  ADR  TRIPS
    MDVSAD   = MDVSAD  + MW[44]   ; ACCUMULATE TOTAL MD VISIT ADR  TRIPS
    MDScAD   = MDScAD  + MW[45]   ; ACCUMULATE TOTAL MD SchoolADR  TRIPS

    MDMTRK   = MDMTRK  + MW[146]  ; ACCUMULATE TOTAL MD MED TRUCK  TRIPS
    MDHTRK   = MDHTRK  + MW[147]  ; ACCUMULATE TOTAL MD HVY TRUCK  TRIPS
    MDAPAX   = MDAPAX  + MW[48]   ; ACCUMULATE TOTAL MD AIRPAX ADR   TRIPS
    MDCOM    = MDCOM   + MW[149]  ; ACCUMULATE TOTAL MD COMMERCIAL TRIPS
 ;;---
    PMXXMTK  = PMXXMTK + MW[120]  ; ACCUMULATE TOTAL PM XX Medium TRUCKS
    PMXXHTK  = PMXXHTK + MW[121]  ; ACCUMULATE TOTAL PM XX Heavy  TRUCKS
    PMXXAD   = PMXXAD  + MW[22]   ; ACCUMULATE TOTAL PM XX ADR + XX COM  TRIPS
    PMTXAD   = PMTXAD  + MW[23]   ; ACCUMULATE TOTAL PM TAXI  ADR  TRIPS
    PMVSAD   = PMVSAD  + MW[24]   ; ACCUMULATE TOTAL PM VISIT ADR  TRIPS
    PMScAD   = PMScAD  + MW[25]   ; ACCUMULATE TOTAL PM SchoolADR  TRIPS

    PMMTRK   = PMMTRK  + MW[126]  ; ACCUMULATE TOTAL PM MED TRUCK  TRIPS
    PMHTRK   = PMHTRK  + MW[127]  ; ACCUMULATE TOTAL PM HVY TRUCK  TRIPS
    PMAPAX   = PMAPAX  + MW[28]   ; ACCUMULATE TOTAL PM AIR PAX ADR   TRIPS
    PMCOM    = PMCOM   + MW[129]  ; ACCUMULATE TOTAL PM COMMERCIAL TRIPS
 ;;---
    NTXXMTK  = NTXXMTK + MW[130]  ; ACCUMULATE TOTAL NT XX Medium TRUCKS
    NTXXHTK  = NTXXHTK + MW[131]  ; ACCUMULATE TOTAL NT XX Heavy  TRUCKS
    NTXXAD   = NTXXAD  + MW[32]   ; ACCUMULATE TOTAL NT XX ADR + XX COM  TRIPS
    NTTXAD   = NTTXAD  + MW[33]   ; ACCUMULATE TOTAL NT TAXI  ADR  TRIPS
    NTVSAD   = NTVSAD  + MW[34]   ; ACCUMULATE TOTAL NT VISIT ADR  TRIPS
    NTScAD   = NTScAD  + MW[35]   ; ACCUMULATE TOTAL NT SchoolADR  TRIPS

    NTMTRK   = NTMTRK  + MW[136]  ; ACCUMULATE TOTAL NT MED TRUCK  TRIPS
    NTHTRK   = NTHTRK  + MW[137]  ; ACCUMULATE TOTAL NT HVY TRUCK  TRIPS
    NTAPAX   = NTAPAX  + MW[38]   ; ACCUMULATE TOTAL NT AIR PAX ADR   TRIPS
    NTCOM    = NTCOM   + MW[139]  ; ACCUMULATE TOTAL NT COMMERCIAL TRIPS
  ;;---

; total input misc trips
  ipmisc     = ipmisc + MW[02]    + MW[03]    + MW[04]    + MW[05]   + MW[08]  +
                        MW[110]   + MW[111]   + MW[116]   + MW[117]  + MW[119] +
                        MW[120]   + MW[121]   + MW[126]   + MW[127]  + MW[129] +
                        MW[130]   + MW[131]   + MW[136]   + MW[137]  + MW[139] +
                        MW[140]   + MW[141]   + MW[146]   + MW[147]  + MW[149] +
                        MI.6.5[J] + MI.6.6[J] + MI.6.7[J] + MI.6.8[J]

; total output misc trips
  ntmisc  = ntmisc +
   MW[110]+MW[111]   +MW[12]+MW[13]+MW[14]+MW[15]+MW[116]+MW[117] +MW[18]+MW[119]+
   MW[120]+MW[121]   +MW[22]+MW[23]+MW[24]+MW[25]+MW[126]+MW[127] +MW[28]+MW[129]+
   MW[130]+MW[131]   +MW[32]+MW[33]+MW[34]+MW[35]+MW[136]+MW[137] +MW[38]+MW[139]+
   MW[140]+MW[141]   +MW[42]+MW[43]+MW[44]+MW[45]+MW[146]+MW[147] +MW[48]+MW[149]

 ENDJLOOP

IF (I=ZONES)  ;  LIST OUT THE TOTALS IF AT THE END OF THE I-LOOP
; get regional I/O differences
diff = ntmisc-ipmisc ;

LIST = '/bt          '
LIST = '  MISCELLANEOUS/TRUCK TIME-OF-DAY TOTALS ','\n',
list = ' '

list = 'Input  Misc/Truck Total: ',ipmisc(10.0c)
list = 'Output Misc/Truck Total: ',ntmisc(10.0c)
list = 'Diff.  (Output-Input):   ',diff(10.0)
list = ' '

LIST = 'DAILY XX MedTrk:'   ,dayxxmtk(9.0c),' AM, MD, PM, NT: ',AMXXmTK(9.0c),',',MDXXmTK(9.0c),',',PMXXmTK(9.0c),',',NTXXmTK(9.0c)
LIST = 'DAILY XX HvyTrk:'   ,dayxxhtk(9.0c),' AM, MD, PM, NT: ',AMXXhTK(9.0c),',',MDXXhTK(9.0c),',',PMXXhTK(9.0c),',',NTXXhTK(9.0c)
LIST = 'DAILY XX ADR/CV:'   ,dayxxAD(9.0c), ' AM, MD, PM, NT: ',AMXXAD(9.0c), ',',MDXXAD(9.0c), ',',PMXXAD(9.0c), ',',NTXXAD(9.0c)
LIST = 'DAILY TAXI ADRS:'   ,dayTxAD(9.0c), ' AM, MD, PM, NT: ',AMTXAD(9.0c), ',',MDTXAD(9.0c), ',',PMTXAD(9.0c), ',',NTTXAD(9.0c)
LIST = 'DAILY VISI ADRS:'   ,dayVSAD(9.0c), ' AM, MD, PM, NT: ',AMVSAD(9.0c), ',',MDVSAD(9.0c), ',',PMVSAD(9.0c), ',',NTVSAD(9.0c)
LIST = 'DAILY Schl ADRS:'   ,dayScAD(9.0c), ' AM, MD, PM, NT: ',AMScAD(9.0c), ',',MDScAD(9.0c), ',',PMScAD(9.0c), ',',NTScAD(9.0c)
LIST = 'DAILY COM VEHS: '   ,dayCOM(9.0c),  ' AM, MD, PM, NT: ',AMCOM(9.0c),  ',',MDCOM(9.0c),  ',',PMCOM(9.0c),  ',',NTCOM(9.0c)
LIST = 'DAILY MED TRKS: '   ,dayMTRK(9.0c), ' AM, MD, PM, NT: ',AMMTRK(9.0c), ',',MDMTRK(9.0c), ',',PMMTRK(9.0c), ',',NTMTRK(9.0c)
LIST = 'DAILY HVY TRKS: '   ,dayHTRK(9.0c), ' AM, MD, PM, NT: ',AMHTRK(9.0c), ',',MDHTRK(9.0c), ',',PMHTRK(9.0c), ',',NTHTRK(9.0c)
LIST = 'DAILY APX ADRS: '   ,dayAPAX(9.0c), ' AM, MD, PM, NT: ',AMAPAX(9.0c), ',',MDAPAX(9.0c), ',',PMAPAX(9.0c), ',',NTAPAX(9.0c)

LIST = '/et          '
endif
;  Write out the Miscellaneous Trips in time period-specific files
   MATO[1] = @MISCAM@, MO=112,12,13,14,15,116,117,18,119,   ; AM MISC Trips
                       name=AM_XXTrk,AM_XXAdr,AM_TxAdr,AM_VtAdr,AM_ScAdr,AM_MedTk,AM_HvyTk,AM_APAdr,AM_ComVe

   MATO[2] = @MISCMD@, MO=142,42,43,44,45,146,147,48,149,   ; MD MISC Trips
                       name=MD_XXTrk,MD_XXAdr,MD_TxAdr,MD_VtAdr,MD_ScAdr,MD_MedTk,MD_HvyTk,MD_APAdr,MD_ComVe

   MATO[3] = @MISCPM@, MO=122,22,23,24,25,126,127,28,129,   ; PM MISC Trips
                       name=PM_XXTrk,PM_XXAdr,PM_TxAdr,PM_VtAdr,PM_ScAdr,PM_MedTk,PM_HvyTk,PM_APAdr,PM_ComVe

   MATO[4] = @MISCNT@, MO=132,32,33,34,35,136,137,38,139,   ; NT MISC Trips
                       name=NT_XXTrk,NT_XXAdr,NT_TxAdr,NT_VtAdr,NT_ScAdr,NT_MedTk,NT_HvyTk,NT_APAdr,NT_ComVe
ENDRUN
;
*del tempcom.trp
*del temptrk.trp
