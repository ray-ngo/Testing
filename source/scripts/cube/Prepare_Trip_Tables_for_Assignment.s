; Prepare_Trip_tables_for_Assignment.s
;4/3/12  three decimals maintained in output files ("dec=6*3" added to MATO statement)
;Oct 2021: Modified by RSG for Gen 3 Model
;---------------------------------------------------------------
;   Step 1 - Modeled & Non-Modeled Trip Table Consolidation
;            for the Version 2.3 Highway Assignment
;
;            - 4 Trip files built for AM, Midday, PM, Off-Peak Time Periods
;            - I-I resident demand comes from ActivitySim, all other Misc demand is held static from Ver 2.3
;            - Each file has 6 Trip tables:
;                1) 1-occ adrs
;                2) 2-occ adrs
;                3) 3+occ adrs
;                4) Commercial Vehicle
;                5) Trucks (Medium and Heavy)
;                6) Airport Pax Adrs
;---------------------------------------------------------------
;
;---------------------------------------------------------------
; Convert trip tables from ActivitySim in right format
;---------------------------------------------------------------

;*** Convert ActivitySim auto OMX matrices to VTT format ***

CONVERTMAT FROM="outputs\activitysim\auto_trips_am.omx" TO="outputs\hwy_assign\%_iter_%_Asim_AM.VTT" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\auto_trips_md.omx" TO="outputs\hwy_assign\%_iter_%_Asim_MD.VTT" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\auto_trips_pm.omx" TO="outputs\hwy_assign\%_iter_%_Asim_PM.VTT" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\auto_trips_nt.omx" TO="outputs\hwy_assign\%_iter_%_Asim_NT.VTT" FORMAT=TPP COMPRESSION=0



;---------------------------------------------------------------

; I/P ActivitySim trip tables:
ASimAM  = 'outputs\hwy_assign\%_iter_%_Asim_AM.VTT'
ASimMD  = 'outputs\hwy_assign\%_iter_%_Asim_MD.VTT'
ASimPM  = 'outputs\hwy_assign\%_iter_%_Asim_PM.VTT'
ASimNT  = 'outputs\hwy_assign\%_iter_%_Asim_NT.VTT'

; I/P Auto Dr. Pct. tables:
ADRAM  = 'outputs\auxiliary\%_iter_%_am_adr.mat'
ADRMD  = 'outputs\auxiliary\%_iter_%_md_adr.mat'
ADRPM  = 'outputs\auxiliary\%_iter_%_pm_adr.mat'
ADRNT  = 'outputs\auxiliary\%_iter_%_nt_adr.mat'
;
; I/P MISC Auto Dr.Tables:
MISCAM  = 'outputs\auxiliary\%_iter_%_am_misc.tt'
MISCMD  = 'outputs\auxiliary\%_iter_%_md_misc.tt'
MISCPM  = 'outputs\auxiliary\%_iter_%_pm_misc.tt'
MISCNT  = 'outputs\auxiliary\%_iter_%_nt_misc.tt'
;
;
; O/P  Vehicle  Trips:
AM_VT   = 'outputs\hwy_assign\%_iter_%_AM.VTT'
MD_VT   = 'outputs\hwy_assign\%_iter_%_MD.VTT'
PM_VT   = 'outputs\hwy_assign\%_iter_%_PM.VTT'
NT_VT   = 'outputs\hwy_assign\%_iter_%_NT.VTT'
;
;
; avg xx auto occ. is 1.72 basis for:    //
XXAD1OCC = 0.5021       ; ASSUMED SHARE OF THRU ADRS Which are  1-OCC vehs.
XXAD2OCC = 0.3426       ; ASSUMED SHARE OF THRU ADRS Which are  2-OCC vehs.
XXAD3OCC = 0.1553       ; ASSUMED SHARE OF THRU ADRS Which are  3+OCC vehs.
;/////////////////////////////////////////////////////////////////////



ZONESIZE       =  3722                       ;  No. of TAZs
LastIZn        =  3675                       ;  Last Internal TAZ no.
ExtZones       =  '3676-3722'                ;  External Zones



RUN PGM=MATRIX

;; Input files:

;;  IX/XI Auto Driver Trips (only using SOV)
    MATI[1]=@ADRAM@   ;; AM Modeled Auto Drivers
    MATI[2]=@ADRMD@
    MATI[3]=@ADRPM@
    MATI[4]=@ADRNT@

;;  Miscellaneaous Trips by time period
;;
;; Each file contains 8 tables -
;;   1/xx truck,2/xx autodr,3/taxi adr,4/visitor-tourist adr,
;;   5/med.truck, 6/hvy truck, 7/air passenger adr, 8/comm veh.
    MATI[5]=@MISCAM@
    MATI[6]=@MISCMD@
    MATI[7]=@MISCPM@
    MATI[8]=@MISCNT@
    
;;  ActivitySim Auto trips by time period
;;   each file contains 3 tables (1-occ, 2-occ., and 3+occ auto trips)
    MATI[9]= @ASimAM@   ;; AM ActivitySim Auto Trips
    MATI[10]=@ASimMD@
    MATI[11]=@ASimPM@
    MATI[12]=@ASimNT@


;AM Modeled Auto Drivers:
    MW[101]= MI.1.1 + MI.9.1          ;  1-Occ adrs
    MW[102]= MI.1.2 + MI.9.2          ;  2-Occ adrs
    MW[103]= MI.1.3 + MI.9.3          ;  3+Occ adrs
;MD Modeled Auto Drivers:
    MW[201]= MI.2.1 + MI.10.1         ;  1-Occ adrs
    MW[202]= MI.2.2 + MI.10.2         ;  2-Occ adrs
    MW[203]= MI.2.3 + MI.10.3         ;  3+Occ adrs
;PM Modeled Auto Drivers:
    MW[301]= MI.3.1 + MI.11.1         ;  1-Occ adrs
    MW[302]= MI.3.2 + MI.11.2         ;  2-Occ adrs
    MW[303]= MI.3.3 + MI.11.3         ;  3+Occ adrs

;OP Modeled Auto Drivers:
    MW[401]= MI.4.1 + MI.12.1         ;  1-Occ adrs
    MW[402]= MI.4.2 + MI.12.2         ;  2-Occ adrs
    MW[403]= MI.4.3 + MI.12.3         ;  3+Occ adrs
;
; AM Peak Period MISC Trips
 MW[111] = MI.5.1            ;  Thru     Truck
 MW[112] = MI.5.2*@XXAD1OCC@ ;  Thru     Auto Driver-1 OCC
 MW[113] = MI.5.2*@XXAD2OCC@ ;  Thru     Auto Driver-2 OCC
 MW[114] = MI.5.2*@XXAD3OCC@ ;  Thru     Auto Driver-3+OCC
 MW[115] = MI.5.3            ;  Taxi     Auto Driver
 MW[116] = MI.5.4            ;  Visitor  Auto Driver
 MW[117] = MI.5.6            ;  I-I,I-E,E-I Medium Truck
 MW[118] = MI.5.7            ;  I-I,I-E,E-I Heavy  Truck
 MW[119] = MI.5.8            ;  Air Pax     Auto Driver
 MW[120] = MI.5.9            ;  I-I,I-E,E-I Comm. Veh
 MW[121] = MI.5.5            ;  School  Auto Driver

;
; MD Peak Period MISC Trips
 MW[211] = MI.6.1            ;  Thru     Truck
 MW[212] = MI.6.2*@XXAD1OCC@ ;  Thru     Auto Driver-1 OCC
 MW[213] = MI.6.2*@XXAD2OCC@ ;  Thru     Auto Driver-2 OCC
 MW[214] = MI.6.2*@XXAD3OCC@ ;  Thru     Auto Driver-3+OCC
 MW[215] = MI.6.3            ;  Taxi     Auto Driver
 MW[216] = MI.6.4            ;  Visitor  Auto Driver
 MW[217] = MI.6.6            ;  I-I,I-E,E-I Medium Truck
 MW[218] = MI.6.7            ;  I-I,I-E,E-I Heavy  Truck
 MW[219] = MI.6.8            ;  Air Pax     Auto Driver
 MW[220] = MI.6.9            ;  I-I,I-E,E-I Comm. Veh
 MW[221] = MI.6.5            ;  School   Auto Driver
;
; PM Peak Period MISC Trips
 MW[311] = MI.7.1            ;  Thru     Truck
 MW[312] = MI.7.2*@XXAD1OCC@ ;  Thru     Auto Driver-1 OCC
 MW[313] = MI.7.2*@XXAD2OCC@ ;  Thru     Auto Driver-2 OCC
 MW[314] = MI.7.2*@XXAD3OCC@ ;  Thru     Auto Driver-3+OCC
 MW[315] = MI.7.3            ;  Taxi     Auto Driver
 MW[316] = MI.7.4            ;  Visitor  Auto Driver
 MW[317] = MI.7.6            ;  I-I,I-E,E-I Medium Truck
 MW[318] = MI.7.7            ;  I-I,I-E,E-I Heavy  Truck
 MW[319] = MI.7.8            ;  Air Pax     Auto Driver
 MW[320] = MI.7.9            ;  I-I,I-E,E-I Comm. Veh
 MW[321] = MI.7.5            ;  School   Auto Driver

;
; OP Peak Period MISC Trips
 MW[411] = MI.8.1            ;  Thru     Truck
 MW[412] = MI.8.2*@XXAD1OCC@ ;  Thru     Auto Driver-1 OCC
 MW[413] = MI.8.2*@XXAD2OCC@ ;  Thru     Auto Driver-2 OCC
 MW[414] = MI.8.2*@XXAD3OCC@ ;  Thru     Auto Driver-3+OCC
 MW[415] = MI.8.3            ;  Taxi     Auto Driver
 MW[416] = MI.8.4            ;  Visitor  Auto Driver
 MW[417] = MI.8.6            ;  I-I,I-E,E-I Medium Truck
 MW[418] = MI.8.7            ;  I-I,I-E,E-I Heavy  Truck
 MW[419] = MI.8.8            ;  Air Pax     Auto Driver
 MW[420] = MI.8.9            ;  I-I,I-E,E-I Comm. Veh
 MW[421] = MI.8.5            ;  School   Auto Driver



;  Add up vehicle tables into the appropriate TOD Categories
;  AM
 MW[151] =  MW[101] + MW[112] + MW[121]            ; SOV   Vehicle Trips
 MW[152] =  MW[102] + MW[113] + MW[115] + MW[116]  ; HOV2  Vehicle Trips
 MW[153] =  MW[103] + MW[114]                      ; HOV3+ Vehicle Trips
 MW[154] =  MW[120]                                ; Comm. Vehs
 MW[155] =  MW[111] + MW[117] + MW[118]            ; Med/Hvy Truck Trips
 MW[156] =  MW[119]                                ; Airport Pax Adr Trips

;  MD
 MW[251] =  MW[201] + MW[212] + MW[221]            ; SOV   Vehicle Trips
 MW[252] =  MW[202] + MW[213] + MW[215] + MW[216]  ; HOV2  Vehicle Trips
 MW[253] =  MW[203] + MW[214]                      ; HOV3+ Vehicle Trips
 MW[254] =  MW[220]                                ; Comm. Vehs
 MW[255] =  MW[211] + MW[217] + MW[218]            ; Med/Hvy Truck Trips
 MW[256] =  MW[219]                                ; Airport Pax Adr Trips

;  PM
 MW[351] =  MW[301] + MW[312] + MW[321]            ; SOV   Vehicle Trips
 MW[352] =  MW[302] + MW[313] + MW[315] + MW[316]  ; HOV2  Vehicle Trips
 MW[353] =  MW[303] + MW[314]                      ; HOV3+ Vehicle Trips
 MW[354] =  MW[320]                                ; Comm. Vehs
 MW[355] =  MW[311] + MW[317] + MW[318]            ; Med/Hvy Truck Trips
 MW[356] =  MW[319]                                ; Airport Pax Adr Trips

;  OP
 MW[451] =  MW[401] + MW[412] + MW[421]            ; SOV   Vehicle Trips
 MW[452] =  MW[402] + MW[413] + MW[415] + MW[416]  ; HOV2  Vehicle Trips
 MW[453] =  MW[403] + MW[414]                      ; HOV3+ Vehicle Trips
 MW[454] =  MW[420]                                ; Comm. Vehs
 MW[455] =  MW[411] + MW[417] + MW[418]            ; Med/Hvy Truck Trips
 MW[456] =  MW[419]                                ; Airport Pax Adr Trips

;
;
; Now let's accumulate totals for neat regional summaries
jloop
     vehs   = vehs + (MW[151]+MW[152]+MW[153]+MW[154]+MW[155]+MW[156]) + ;
                     (MW[251]+MW[252]+MW[253]+MW[254]+MW[255]+MW[256]) + ;
                     (MW[351]+MW[352]+MW[353]+MW[354]+MW[355]+MW[356]) + ;
                     (MW[451]+MW[452]+MW[453]+MW[454]+MW[455]+MW[456])   ;   daily vehs

      comveh = comveh + mw[120] + mw[220] + mw[320] + mw[420]    ;   daily CVs


;AM group
   amvehs   = amvehs   +(MW[151]+MW[152]+MW[153]+MW[154]+MW[155]+MW[156]) ; all am vehs
   am1occ   = am1occ   + MW[151]                       ; am modeled 1-occveh's
   am2occ   = am2occ   + MW[152]                       ; am modeled 2-occveh's
   am3occ   = am3occ   + MW[153]                       ; am modeled 3+occveh's
   amtrks   = amtrks   + MW[155]                       ; am trucks
   amapax   = amapax   + MW[156]                       ; am airpax adrs
   am1occad = am1occad + MW[101]                       ; am 1occ adr
   am2occad = am2occad + MW[102]                       ; am 2occ adr
   am3occad = am3occad + MW[103]                       ; am 3+occ adr
   amadr    = amadr    + MW[101] + MW[102] + MW[103]   ; am total adr(modeled)
   amxxtrk  = amxxtrk  + MW[111]                       ; am Thru     Truck
   amxxad1  = amxxad1  + MW[112]                       ; am Thru 1occ Adr
   amxxad2  = amxxad2  + MW[113]                       ; am Thru 2occ Adr
   amxxad3  = amxxad3  + MW[114]                       ; am Thru 3+occAdr
   amxxadr  = amxxadr  + MW[112]+MW[113]+MW[114]       ; am total xx adr
   amtaxi   = amtaxi   + MW[115]                       ; am Taxi     ADr
   amvisi   = amvisi   + MW[116]                       ; am visitor  ADr
   amschl   = amschl   + MW[121]                       ; am School   ADr
   ammtrk   = ammtrk   + MW[117]                       ; am int,ext MedTk
   amhtrk   = amhtrk   + MW[118]                       ; am int,ext HvyTk
   amairpax = amairpax + MW[119]                       ; am air pax auto dr
   amcomveh = amcomveh + MW[120]                       ; am int,ext,ComVeh


;MD group
   mdvehs   = mdvehs   +(MW[251]+MW[252]+MW[253]+MW[254]+MW[255]+MW[256]) ; all md vehs
   md1occ   = md1occ   + MW[251]                       ; md modeled 1-occveh's
   md2occ   = md2occ   + MW[252]                       ; md modeled 2-occveh's
   md3occ   = md3occ   + MW[253]                       ; md modeled 3+occveh's
   mdtrks   = mdtrks   + MW[255]                       ; md trucks
   mdapax   = mdapax   + MW[256]                       ; md airpax adrs
   md1occad = md1occad + MW[201]                       ; md 1occ adr
   md2occad = md2occad + MW[202]                       ; md 2occ adr
   md3occad = md3occad + MW[203]                       ; md 3+occ adr
   mdadr    = mdadr    + MW[201] + MW[202] + MW[203]   ; md total adr(modeled)
   mdxxtrk  = mdxxtrk  + MW[211]                       ; md Thru     Truck
   mdxxad1  = mdxxad1  + MW[212]                       ; md Thru 1occ Adr
   mdxxad2  = mdxxad2  + MW[213]                       ; md Thru 2occ Adr
   mdxxad3  = mdxxad3  + MW[214]                       ; md Thru 3+occAdr
   mdxxadr  = mdxxadr  + MW[212] + MW[213] + MW[214]   ; md total xx adr
   mdtaxi   = mdtaxi   + MW[215]                       ; md Taxi     ADr
   mdvisi   = mdvisi   + MW[216]                       ; md visitor  ADr
   mdSchl   = mdSchl   + MW[221]                       ; md School   ADr
   mdmtrk   = mdmtrk   + MW[217]                       ; md int,ext MedTk
   mdhtrk   = mdhtrk   + MW[218]                       ; md int,ext HvyTk
   mdairpax = mdairpax + MW[219]                       ; md air pax auto dr
   mdcomveh = mdcomveh + MW[220]                       ; md int,ext,ComVeh


;PM group
   pmvehs   = pmvehs   +(MW[351]+MW[352]+MW[353]+MW[354]+MW[355]+MW[356]) ; all pm vehs
   pm1occ   = pm1occ   + MW[351]                       ; pm modeled 1-occveh's
   pm2occ   = pm2occ   + MW[352]                       ; pm modeled 2-occveh's
   pm3occ   = pm3occ   + MW[353]                       ; pm modeled 3+occveh's
   pmtrks   = pmtrks   + MW[355]                       ; pm trucks
   pmapax   = pmapax   + MW[356]                       ; pm airpax adrs
   pm1occad = pm1occad + MW[301]                       ; pm 1occ adr
   pm2occad = pm2occad + MW[302]                       ; pm 2occ adr
   pm3occad = pm3occad + MW[303]                       ; pm 3+occ adr
   pmadr    = pmadr    + MW[301] + MW[302] + MW[303]   ; pm total adr(modeled)
   pmxxtrk  = pmxxtrk  + MW[311]                       ; pm Thru     Truck
   pmxxad1  = pmxxad1  + MW[312]                       ; pm Thru 1occ Adr
   pmxxad2  = pmxxad2  + MW[313]                       ; pm Thru 2occ Adr
   pmxxad3  = pmxxad3  + MW[314]                       ; pm Thru 3+occAdr
   pmxxadr  = pmxxadr  + MW[312] + MW[313] + MW[314]   ; pm total xx adr
   pmtaxi   = pmtaxi   + MW[315]                       ; pm Taxi     ADr
   pmvisi   = pmvisi   + MW[316]                       ; pm visitor  ADr
   pmschl   = pmschl   + MW[321]                       ; pm school   ADr
   pmmtrk   = pmmtrk   + MW[317]                       ; pm int,ext MedTk
   pmhtrk   = pmhtrk   + MW[318]                       ; pm int,ext HvyTk
   pmairpax = pmairpax + MW[319]                       ; pm air pax auto dr
   pmcomveh = pmcomveh + MW[320]                       ; pm int,ext,ComVeh


;OP group
   opvehs   = opvehs   +(MW[451]+MW[452]+MW[453]+MW[454]+MW[455]+MW[456]) ; all op/nt vehs
   op1occ   = op1occ   + MW[451]                       ; op/nt modeled 1-occveh's
   op2occ   = op2occ   + MW[452]                       ; op/nt modeled 2-occveh's
   op3occ   = op3occ   + MW[453]                       ; op/nt modeled 3+occveh's
   optrks   = optrks   + MW[455]                       ; op/nt trucks
   opapax   = opapax   + MW[456]                       ; op/nt airpax adrs
   op1occad = op1occad + MW[401]                       ; op/nt 1occ adr
   op2occad = op2occad + MW[402]                       ; op/nt 2occ adr
   op3occad = op3occad + MW[403]                       ; op/nt 3+occ adr
   opadr    = opadr    + MW[401] + MW[402] + MW[403]   ; op/nt total adr(modeled)
   opxxtrk  = opxxtrk  + MW[411]                       ; op/nt Thru     Truck
   opxxad1  = opxxad1  + MW[412]                       ; op/nt Thru 1occ Adr
   opxxad2  = opxxad2  + MW[413]                       ; op/nt Thru 2occ Adr
   opxxad3  = opxxad3  + MW[414]                       ; op/nt Thru 3+occAdr
   opxxadr  = opxxadr  + MW[412] + MW[413] + MW[414]   ; op/nt total xx adr
   optaxi   = optaxi   + MW[415]                       ; op/nt Taxi     ADr
   opvisi   = opvisi   + MW[416]                       ; op/nt visitor  ADr
   opschl   = opschl   + MW[421]                       ; op/nt school   ADr
   opmtrk   = opmtrk   + MW[417]                       ; op/nt int,ext MedTk
   ophtrk   = ophtrk   + MW[418]                       ; op/nt int,ext HvyTk
   opairpax = opairpax + MW[419]                       ; op/nt air pax auto dr
   opcomveh = opcomveh + MW[420]                       ; op/nt int,ext,ComVeh

;  Sum up output trip table totals
;  AM
    AMSOVs     =     AMSOVs     + MW[151]
    AMHOV2s    =     AMHOV2s    + MW[152]
    AMHOV3s    =     AMHOV3s    + MW[153]
    AMComVehs  =     AMComVehs  + MW[154]
    AMTrucks   =     AMTrucks   + MW[155]
    AMAirPaxs  =     AMAirPaxs  + MW[156]

;  MD
    MDSOVs     =     MDSOVs     + MW[251]
    MDHOV2s    =     MDHOV2s    + MW[252]
    MDHOV3s    =     MDHOV3s    + MW[253]
    MDComVehs  =     MDComVehs  + MW[254]
    MDTrucks   =     MDTrucks   + MW[255]
    MDAirPaxs  =     MDAirPaxs  + MW[256]

;  PM
    PMSOVs     =     PMSOVs     + MW[351]
    PMHOV2s    =     PMHOV2s    + MW[352]
    PMHOV3s    =     PMHOV3s    + MW[353]
    PMComVehs  =     PMComVehs  + MW[354]
    PMTrucks   =     PMTrucks   + MW[355]
    PMAirPaxs  =     PMAirPaxs  + MW[356]

; OP
    OPSOVs     =     OPSOVs     + MW[451]
    OPHOV2s    =     OPHOV2s    + MW[452]
    OPHOV3s    =     OPHOV3s    + MW[453]
    OPComVehs  =     OPComVehs  + MW[454]
    OPTrucks   =     OPTrucks   + MW[455]
    OPAirPaxs  =     OPAirPaxs  + MW[456]
endjloop

if (i=zones)   ; print out results
Print list = '/bt      '
Print list = '%_iter_% Iter. Pre-Traffic Assignment Trip Table Prep. Report',file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                                           ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt

Print list = 'AM-Peak Totals: '                                 ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am modeled 1-occvehs  ',am1occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am modeled 2-occvehs  ',am2occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am modeled 3+occvehs  ',am3occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am trucks             ',amtrks   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am 1occ adr           ',am1occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am 2occ adr           ',am2occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am 3+occ adr          ',am3occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am total adr(modeled) ',amadr    ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am Thru     Truck     ',amxxtrk  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am Thru 1occ Adr      ',amxxad1  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am Thru 2occ Adr      ',amxxad2  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am Thru 3+occAdr      ',amxxad3  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am total xx adr       ',amxxadr  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am Taxi     ADr       ',amtaxi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am visitor  ADr       ',amvisi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am School   ADr       ',amschl   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am int,ext MedTk      ',ammtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am int,ext HvyTk      ',amhtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am air pax auto dr    ',amairpax ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   am int,ext,ComVeh     ',amcomveh ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   all am vehs           ',amvehs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt


   ;MD group
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = 'Midday  Totals: '                                 ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md modeled 1-occvehs  ',md1occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md modeled 2-occvehs  ',md2occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md modeled 3+occvehs  ',md3occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md trucks             ',mdtrks   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md 1occ adr           ',md1occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md 2occ adr           ',md2occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md 3+occ adr          ',md3occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md total adr(modeled) ',mdadr    ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md Thru     Truck     ',mdxxtrk  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md Thru 1occ Adr      ',mdxxad1  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md Thru 2occ Adr      ',mdxxad2  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md Thru 3+occAdr      ',mdxxad3  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md total xx adr       ',mdxxadr  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md Taxi     ADr       ',mdtaxi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md visitor  ADr       ',mdvisi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md school   ADr       ',mdschl   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md int,ext MedTk      ',mdmtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md int,ext HvyTk      ',mdhtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md air pax auto dr    ',mdairpax ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   md int,ext,ComVeh     ',mdcomveh ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   all md vehs           ',mdvehs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt


   ;PM group
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = 'PM-Peak Totals: '                                 ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm modeled 1-occvehs  ',pm1occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm modeled 2-occvehs  ',pm2occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm modeled 3+occvehs  ',pm3occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm trucks             ',pmtrks   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm 1occ adr           ',pm1occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm 2occ adr           ',pm2occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm 3+occ adr          ',pm3occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm total adr(modeled) ',pmadr    ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm Thru     Truck     ',pmxxtrk  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm Thru 1occ Adr      ',pmxxad1  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm Thru 2occ Adr      ',pmxxad2  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm Thru 3+occAdr      ',pmxxad3  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm total xx adr       ',pmxxadr  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm Taxi     ADr       ',pmtaxi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm visitor  ADr       ',pmvisi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm school   ADr       ',pmschl   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm int,ext MedTk      ',pmmtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm int,ext HvyTk      ',pmhtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm air pax auto dr    ',pmairpax ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   pm int,ext,ComVeh     ',pmcomveh ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   all pm vehs           ',pmvehs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt


   ;OP group
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = 'Off-Peak Totals: '                                ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt modeled 1-occvehs  ',op1occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt modeled 2-occvehs  ',op2occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt modeled 3+occvehs  ',op3occ   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt trucks             ',optrks   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt 1occ adr           ',op1occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt 2occ adr           ',op2occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt 3+occ adr          ',op3occad ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt total adr(modeled) ',opadr    ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt Thru     Truck     ',opxxtrk  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt Thru 1occ Adr      ',opxxad1  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt Thru 2occ Adr      ',opxxad2  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt Thru 3+occAdr      ',opxxad3  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt total xx adr       ',opxxadr  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt Taxi     ADr       ',optaxi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt visitor  ADr       ',opvisi   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt school   ADr       ',opschl   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt int,ext MedTk      ',opmtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt int,ext HvyTk      ',ophtrk   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt air pax auto dr    ',opairpax ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   nt int,ext,ComVeh     ',opcomveh ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   all nt vehs           ',opvehs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt

Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   SUM OF ALL VEHICLES:  ',vehs     ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '%_iter_% Trip Table Output Totals: '              ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
;  AM
Print form= 12.0csv list = '   AMSOVs                ',AMSOVs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   AMHOV2s               ',AMHOV2s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   AMHOV3s               ',AMHOV3s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   AMComVehs             ',AMComVehs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   AMTrucks              ',AMTrucks ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   AMAirPaxs             ',AMAirPaxs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt

;  MD
Print form= 12.0csv list = '   MDSOVs                ',MDSOVs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   MDHOV2s               ',MDHOV2s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   MDHOV3s               ',MDHOV3s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   MDComVehs             ',MDComVehs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   MDTrucks              ',MDTrucks ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   MDAirPaxs             ',MDAirPaxs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt

;  PM
Print form= 12.0csv list = '   PMSOVs                ',PMSOVs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   PMHOV2s               ',PMHOV2s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   PMHOV3s               ',PMHOV3s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   PMComVehs             ',PMComVehs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   PMTrucks              ',PMTrucks ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   PMAirPaxs             ',PMAirPaxs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt

;  OP
Print form= 12.0csv list = '   NTSOVs                ',OPSOVs   ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   NTHOV2s               ',OPHOV2s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   NTHOV3s               ',OPHOV3s  ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   NTComVehs             ',OPComVehs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   NTTrucks              ',OPTrucks ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   NTAirPaxs             ',OPAirPaxs,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print form= 12.0csv list = '   SUM OF ALL VEHICLES:  ',vehs     ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '  '                                               ,file=outputs\reports\%_iter_%_Prepare_Trip_Tables_For_Assignment.txt
Print list = '/et      '
 endif



;  Write out the auto driver tables by time period
 MATO[1] = @AM_VT@,  MO=151-156,                                ; AM Veh Trips 1,2,3+occ, comveh, trucks,Air Pax Vehs
           name=AM_SOVs,AM_HV2s,AM_HV3s,AM_COMs,AM_TRKs,AM_APVs, dec=6*3

 MATO[2] = @MD_VT@,  MO=251-256,                                ; MD Veh Trips 1,2,3+occ, comveh, trucks,Air Pax Vehs
           name=MD_SOVs,MD_HV2s,MD_HV3s,MD_COMs,MD_TRKs,MD_APVs, dec=6*3

 MATO[3] = @PM_VT@,  MO=351-356,                                ; PM Veh Trips 1,2,3+occ, comveh, trucks,Air Pax Vehs
           name=PM_SOVs,PM_HV2s,PM_HV3s,PM_COMs,PM_TRKs,PM_APVs, dec=6*3

 MATO[4] = @NT_VT@,  MO=451-456,                                ; NT Veh Trips 1,2,3+occ, comveh, trucks,Air Pax Vehs
           name=NT_SOVs,NT_HV2s,NT_HV3s,NT_COMs,NT_TRKs,NT_APVs, dec=6*3

ENDRUN
