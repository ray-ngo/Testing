*del voya*.prn
;=================================================================
;  Truck_Com_Trip_Generation.s
;  Version 2.3, 3722 TAZ System  - Truck and Commercial Vehicle Trip Generation Process
;
;   RM
;   Date:      12/08/10
;
;=================================================================
;
;
;=================================================================
;Parameters and file specifications:
;=================================================================

ZONESIZE    =  3722                       ;  No. of TAZs
LastIZn     =  3675                       ;  Last Internal TAZ no.

JrCl        =  24                         ;  No. of Juris. Classes (transformed JURIS. Code 0-23 becomes 1-24)
ArCl        =   6                         ;  No. of Area Classe (ATypes)
VeCl        =   3                         ;  No. of Vehicle Classes (1/Medium Truck, 2/ Heavy Truck, 3, Comm. Vehicle


ZNFILE_IN1  = 'outputs\landuse\ZONE.dbf'                    ;  Read the dbf zonal dbf file generated from V2.3_Highway_Build.s
ZNFILE_IN2  = 'outputs\landuse\AreaType_File.dbf'                  ;  Input  Zonal Area Type File from network building
Ext_PsAs    = 'inputs\auxiliary\Ext_PsAs.dbf'                ;  External Ps, As
ZoneConnect = 'outputs\skims\%_prev_%_skimtot.txt'                ;  Zone file showing TAZs without Truck Access (generation is suppressed)



ZnFile_Ou1  = 'outputs\auxiliary\%_iter_%_ComVeh_Truck_Ends.dbf'     ;  output comm, med trk, hvy truck trip ends
ZnFile_Ou2  = 'outputs\auxiliary\%_iter_%_ComVeh_Truck_dbg.dbf'      ;  output debug file- zonal inputs and outputs

Rates_in    ='..\support\Truck_Com_Trip_Rates.DBF'    ;  Truck, Comm.Veh trip rates
reportfile  ='outputs\auxiliary\%_iter_%_Truck_Com_Trip_Generation.txt'

;=================================================================
;Program Steps
;=================================================================

 RUN PGM=MATRIX
 ZONES=1
 ARRAY OFFRateA = 3,6  ; trip rates arrayed as 3 types (Med, Hvy, CV) by 6 area types
 ARRAY RETRateA = 3,6  ;
 ARRAY INDRateA = 3,6  ;
 ARRAY OTHRateA = 3,6  ;
 ARRAY HH_RateA = 3,6  ;

 ARRAY MHC_JurA =3,24  ; jurisdictional arrays 3 TYPES (Med, Hvy, CV) by juris. code 1 to 24 (0-23)
 ARRAY MHC_AtpA =3,24  ; Area Type      arrays 3 TYPES (Med, Hvy, CV) by Area Type (1-6)


;=========================================================================

; Define Zonal Land activity as a zonal lookup table
 FileI LOOKUPI[1] = "@ZNFILE_IN1@"
 LOOKUP LOOKUPI=1, NAME=tazlu,
        LOOKUP[1] = TAZ, RESULT=OFFEMP,   ;
        LOOKUP[2] = TAZ, RESULT=RETEMP,   ;
        LOOKUP[3] = TAZ, RESULT=INDEMP,   ;
        LOOKUP[4] = TAZ, RESULT=OTHEMP,   ;
        LOOKUP[5] = TAZ, RESULT=HH,       ;
        LOOKUP[6] = TAZ, RESULT=JURCODE,  ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

; Define Zonal Truck Access indicator (sum of truck time skims to/from each TAZ)
 LOOKUP NAME=trkskims,
        LOOKUP[1] = 1, RESULT=2,   ; row sum of truck skims
        LOOKUP[2] = 1, RESULT=3,   ; col sum of truck skims
        INTERPOLATE=N, FAIL= 10000000.0, 10000000.0, 10000000.0, LIST=N,file =@zoneconnect@


; Define special truck generator TAZs - as defined in the original calibration work
; Lookup table to identify "truck zones" for 2005 (new TAZs)
  LOOKUP NAME=tzone,
  LOOKUP[1] = 2, RESULT=1,   ; row sum of truck skims
  interpolate = n, fail = 0,0,0,
  R=     '1        213',
         '1        218',
         '1        519',
         '1        520',
         '1        527',
         '1        531',
         '1        864',
         '1        865',
         '1        870',
         '1       1018',
         '1       1021',
         '1       1022',
         '1       1031',
         '1       1088',
         '1       1119',
         '1       1120',
         '1       1230',
         '1       1249',
         '1       1511',
         '1       1652',
         '1       1800',
         '1       1973',
         '1       1983',
         '1       1985',
         '1       1987',
         '1       1988',
         '1       2014',
         '1       2116',
         '1       2321',
         '1       2326',
         '1       2327',
         '1       2383',
         '1       2386',
         '1       2388',
         '1       2527',
         '1       2542',
         '1       2547',
         '1       2834',
         '1       2835',
         '1       2837',
         '1       2838',
         '1       2839',
         '1       2840',
         '1       2841',
         '1       2842',
         '1       2921',
         '1       2922',
         '1       2923',
         '1       2930',
         '1       2931',
         '1       2937',
         '1       2940',
         '1       2943',
         '1       2990',
         '1       2992',
         '1       2999',
         '1       3002',
         '1       3003',
         '1       3004',
         '1       3005',
         '1       3036',
         '1       3233',
         '1       3234',
         '1       3235',
         '1       3236',
         '1       3237',
         '1       3238',
         '1       3239',
         '1       3245',
         '1       3572',
         '1       3573',
         '1       3574',
         '1       3575',
         '1       3580',
         '1       3585'
;;;;     end


; Define zonal Area Type File as a zonal lookup table
 FileI LOOKUPI[2] = "@ZNFILE_IN2@"
 LOOKUP LOOKUPI=2,   NAME=TAZat,
        LOOKUP[1]  = TAZ, RESULT=atype,
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

; Define External trip end file as a zonal lookup table
 FileI LOOKUPI[3] = "@Ext_PsAs@"
 LOOKUP LOOKUPI=3,   NAME=ExtTAZdat,
        LOOKUP[1]  = TAZ, RESULT=CV_XI,
        LOOKUP[2]  = TAZ, RESULT=MTK_XI,
        LOOKUP[3]  = TAZ, RESULT=HTK_XI,
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

; Read in Trip rates, fill in rate array
FILEI DBI[1]     ="@Rates_in@"
LOOP K = 1,dbi.1.NUMRECORDS
      x = DBIReadRecord(1,k)
           count       = dbi.1.recno
           OFFRateA[di.1.Vtype][di.1.ATYPE]      = di.1.OFFRATE    ;;VNAME   VTYPE   ATYPE   OFFRATE RETRATE INDRATE OTHRATE HHRATE
           RETRateA[di.1.Vtype][di.1.ATYPE]      = di.1.RETRATE    ;;VNAME   VTYPE   ATYPE   OFFRATE RETRATE INDRATE OTHRATE HHRATE
           INDRateA[di.1.Vtype][di.1.ATYPE]      = di.1.INDRATE    ;;VNAME   VTYPE   ATYPE   OFFRATE RETRATE INDRATE OTHRATE HHRATE
           OTHRateA[di.1.Vtype][di.1.ATYPE]      = di.1.OTHRATE    ;;VNAME   VTYPE   ATYPE   OFFRATE RETRATE INDRATE OTHRATE HHRATE
           HH_RateA[di.1.Vtype][di.1.ATYPE]      = di.1.HHRATE     ;;VNAME   VTYPE   ATYPE   OFFRATE RETRATE INDRATE OTHRATE HHRATE
ENDLOOP

;; define output DBF file name and variables
;;       output trip file here:
FILEO RECO[1]    = "@ZNFile_ou1@",
                     fields = TAZ(5), Comm_Veh(12.2),  Med_Truck(12.2), Hvy_Truck(12.2), ;; <-- All(Int/Ext) trip ends
                                     IComm_Veh(12.2),  IMed_Truck(12.2) , IHvy_Truck(12.2)   ;; <-- Internal ONLY Trip ends

;;       output debug file here (all zonal inputs and outputs):
FILEO RECO[2]    = "@ZNFile_ou2@",
                     fields = TAZ(5), Atype(3.0),
                     Comm_Veh(8.0),  Med_Truck(8.0), Hvy_Truck(8.0),
                     Off(8.0),Ret(8.0),Ind(8.0),Oth(8.0),HH(8.0),
                     COff_Rate(8.5), CRet_Rate(8.5), CInd_Rate(8.5), COth_Rate(8.5), CHH_Rate(8.5),
                     MOff_Rate(8.5), MRet_Rate(8.5), MInd_Rate(8.5), MOth_Rate(8.5), MHH_Rate(8.5),
                     HOff_Rate(8.5), HRet_Rate(8.5), HInd_Rate(8.5), HOth_Rate(8.5), HHH_Rate(8.5),
                     tzfactm(8.2),tzfacth(8.2),supressed(4)


;; All done reading,  now compute the trips and write out zonal results:

LOOP M= 1,@LastIZn@

            _ATYPE            = TAZat(1,M)                           ;;CURRENT Area type
            _Jur              = TAZlu(6,M) + 1.0                     ;;CURRENT Jur index (=jurcode + 1, so 0-23 becomes 1-24)

            _Comm_Veh         = TAZlu(1,M) * OFFRATEA[3][_ATYPE] +   ;; compute commercial trips
                                TAZlu(2,M) * RETRATEA[3][_ATYPE] +
                                TAZlu(3,M) * INDRATEA[3][_ATYPE] +
                                TAZlu(4,M) * OTHRATEA[3][_ATYPE] +
                                TAZlu(5,M) * HH_RATEA[3][_ATYPE]

            _Med_Truck        = TAZlu(1,M) * OFFRATEA[1][_ATYPE] +   ;; compute Medium Truck trips
                                TAZlu(2,M) * RETRATEA[1][_ATYPE] +
                                TAZlu(3,M) * INDRATEA[1][_ATYPE] +
                                TAZlu(4,M) * OTHRATEA[1][_ATYPE] +
                                TAZlu(5,M) * HH_RATEA[1][_ATYPE]

            _Hvy_Truck        = TAZlu(1,M) * OFFRATEA[2][_ATYPE] +   ;; compute Heavy truck trips
                                TAZlu(2,M) * RETRATEA[2][_ATYPE] +
                                TAZlu(3,M) * INDRATEA[2][_ATYPE] +
                                TAZlu(4,M) * OTHRATEA[2][_ATYPE] +
                                TAZlu(5,M) * HH_RATEA[2][_ATYPE]

; If zone is not truck-accessible, zero out all truck trips.
          ro.supressed = 0.0
          skimout = trkskims(1,M)
          skimin  = trkskims(2,M)

          IF (SKIMOUT/@ZONESIZE@ > 2000.0 || SKIMIN/@ZONESIZE@ > 2000.0)
            _Med_Truck = 0
            _Hvy_Truck = 0
            ro.supressed = 1.0

          ENDIF

; Incorporate truck zone adjustment factors

       TZFACTM     = 1.0
       TZFACTH     = 1.0
       IF (TZONE(1,M) > 0.0)
         TZFACTM = 2.7
         TZFACTH = 5.3
       ENDIF
       _Med_Truck      = _Med_Truck * TZFACTM
       _Hvy_Truck      = _Hvy_Truck * TZFACTH


            ro.TAZ            = M                                    ;  define current zonal output vars
            ro.ATYPE          = _Atype                               ;                 atype

       ;;  com/trk trips will be written out along with extls
            ro.Comm_Veh       = _Comm_Veh                            ;                 comm  trips
            ro.Med_Truck      = _Med_Truck                           ;                 medtk trips
            ro.Hvy_Truck      = _Hvy_Truck                           ;                 hvytk trips
       ;;Internal com/trk trips will also be explicitly written for trip dist.
            ro.IComm_Veh      = _Comm_Veh                            ;                 comm  trips
            ro.IMed_Truck       = _Med_Truck                           ;                 medtk trips
            ro.IHvy_Truck       = _Hvy_Truck                           ;                 hvytk trips

            ro.Off            = TAZlu(1,M)                           ;  land activity
            ro.Ret            = TAZlu(2,M)                           ;
            ro.Ind            = TAZlu(3,M)                           ;
            ro.Oth            = TAZlu(4,M)                           ;
            ro.HH             = TAZlu(5,M)
                                                                     ; CV trip rates
            ro.COFF_Rate      = OFFRATEA[3][_ATYPE]                  ;
            ro.CRET_Rate      = RETRATEA[3][_ATYPE]                  ;
            ro.CIND_Rate      = INDRATEA[3][_ATYPE]                  ;
            ro.COTH_Rate      = OTHRATEA[3][_ATYPE]                  ;
            ro.CHH_Rate       = HH_RATEA[3][_ATYPE]

            ro.MOFF_Rate      = OFFRATEA[1][_ATYPE]   ro.HOFF_Rate = OFFRATEA[2][_ATYPE] ; truck rates
            ro.MRET_Rate      = RETRATEA[1][_ATYPE]   ro.HRET_Rate = RETRATEA[2][_ATYPE] ;
            ro.MIND_Rate      = INDRATEA[1][_ATYPE]   ro.HIND_Rate = INDRATEA[2][_ATYPE] ;
            ro.MOTH_Rate      = OTHRATEA[1][_ATYPE]   ro.HOTH_Rate = OTHRATEA[2][_ATYPE] ;
            ro.MHH_Rate       = HH_RATEA[1][_ATYPE]   ro.HHH_Rate  = HH_RATEA[2][_ATYPE] ;
            ro.TZFACTM        = TZFACTM
            ro.TZFACTH        = TZFACTH

            WRITE RECO=1                                            ;  write out current record
            WRITE RECO=2                                            ;  write out current record



         ;; accumulate Area type trip totals for reporting/checking
            MHC_AtpA[1][_Atype] = MHC_AtpA[1][_Atype] + _Med_Truck
            MHC_AtpA[2][_Atype] = MHC_AtpA[2][_Atype] + _Hvy_Truck
            MHC_AtpA[3][_Atype] = MHC_AtpA[3][_Atype] + _Comm_Veh

         ;; accumulate juris trip totals for reporting/checking
            MHC_JurA[1][_jur] = MHC_JurA[1][_jur] + _Med_Truck
            MHC_JurA[2][_jur] = MHC_JurA[2][_jur] + _Hvy_Truck
            MHC_JurA[3][_jur] = MHC_JurA[3][_jur] + _Comm_Veh

         ;; accumulate internal totals for reporting/checking
            Tot_CVs           = Tot_CVs  +  _Comm_Veh
            Tot_MTs           = Tot_MTs  +  _Med_Truck
            Tot_HTs           = Tot_HTs  +  _HVY_Truck
            Tot_OFF           = Tot_OFF  +  TAZlu(1,M)
            Tot_RET           = Tot_RET  +  TAZlu(2,M)
            Tot_IND           = Tot_IND  +  TAZlu(3,M)
            Tot_OTH           = Tot_OTH  +  TAZlu(4,M)
            Tot_HHs           = Tot_HHs  +  TAZlu(5,M)

 ENDLOOP

;; finally, write out external trips from extl file

; Read in External trip file:
firstExtl= @LastIzn@ + 1
LOOP K = firstExtl,@zonesize@


            ro.TAZ            = k                 ;                 TAZ (extl station)
            ro.Comm_Veh       = ExtTAZdat(1,k)    ;                 comm  trips
            ro.Med_Truck      = ExtTAZdat(2,k)    ;                 medtk trips
            ro.Hvy_Truck      = ExtTAZdat(3,k)    ;                 hvytk trips
            ;; Also write out null values for intl only trips to  be used in trip distribution

            ro.IComm_Veh       = 0.0               ;               int  comm  trips
            ro.IMed_Truck        = 0.0               ;               int  medtk trips
            ro.IHvy_Truck        = 0.0               ;               int  hvytk trips
            write RECO = 1

         ;; accumulate total externals for reporting/checking
            Tot_ExtCVs           = Tot_ExtCVs  +  ExtTAZdat(1,k)
            Tot_ExtMTs           = Tot_ExtMTs  +  ExtTAZdat(2,k)
            Tot_ExtHTs           = Tot_ExtHTs  +  ExtTAZdat(3,k)
ENDLOOP


         ;; sum up total internals / externals for reporting/checking
            Tot_IntExtCVs           = Tot_ExtCVs  + Tot_CVs
            Tot_IntExtMTs           = Tot_ExtMTs  + Tot_MTs
            Tot_IntExtHTs           = Tot_ExtHTs  + Tot_HTs

            Total_Emp               = Tot_Off + Tot_Ret +  Tot_Ind +  Tot_Oth
          ;; Print report and we're done



   FILEO PRINTO[1]    = "@Reportfile@"
   PRINT PRINTO=1 form=12.0csv list = '                                               '
   PRINT PRINTO=1 form=12.0csv list = ' Regional Total Truck and Commercial Trip-Ends '
   PRINT PRINTO=1 form=12.0csv list = '                                Internal     External     ALL     '
   PRINT PRINTO=1 form=12.0csv list = '                               ----------  ----------  ---------- '
   PRINT PRINTO=1 form=12.0csv list = ' Commercial Vehicle Trips: ',  Tot_CVs  ,' ', Tot_ExtCVs ,' ',Tot_IntExtCVs
   PRINT PRINTO=1 form=12.0csv list = ' Medium Truck Trips      : ',  Tot_MTs  ,' ', Tot_ExtMTs ,' ',Tot_IntExtMTs
   PRINT PRINTO=1 form=12.0csv list = ' Heavy Truck Trips       : ',  Tot_HTs  ,' ', Tot_ExtHTs ,' ',Tot_IntExtHTs

   PRINT PRINTO=1 form=12.0csv list = '                                               '
   PRINT PRINTO=1 form=12.0csv list = ' Land Activity Totals                          '
   PRINT PRINTO=1 form=12.0csv list = ' HHs                     : ',   Tot_HHs
   PRINT PRINTO=1 form=12.0csv list = ' Office     Emp.         : ',   Tot_OFF
   PRINT PRINTO=1 form=12.0csv list = ' Retail     Emp.         : ',   Tot_Ret
   PRINT PRINTO=1 form=12.0csv list = ' Industrial Emp.         : ',   Tot_Ind
   PRINT PRINTO=1 form=12.0csv list = ' Other      Emp.         : ',   Tot_Oth
   PRINT PRINTO=1 form=12.0csv list = ' Total      Emp.         : ',   Total_Emp


   PRINT PRINTO=1 form=12.0csv list = '                                               '
   PRINT PRINTO=1 form=12.0csv list = ' Truck and Comm. Veh. Internal Trip Totals by Area Type '
   PRINT PRINTO=1 form=12.0csv list = '   ATYPE  Medium Trk  Heavy Trk  Comm. Veh.  '
   PRINT PRINTO=1 form=12.0csv list = '-------- ----------- ----------- ----------- '
   Loop K= 1,6
      PRINT PRINTO=1 form=12.0csv list =  K(8), MHC_AtpA[1][K], MHC_AtpA[2][K], MHC_AtpA[3][K]
   ENDLOOP
      PRINT PRINTO=1 form=12.0csv list =  '  Total ', Tot_MTs, Tot_HTs, Tot_Cvs


   PRINT PRINTO=1 form=12.0csv list = '                                               '
   PRINT PRINTO=1 form=12.0csv list = ' Truck and Comm. Veh. Internal Trip Totals by Jurisdiction '
   PRINT PRINTO=1 form=12.0csv list = ' JurCode  Medium Trk  Heavy Trk  Comm. Veh.  '
   PRINT PRINTO=1 form=12.0csv list = '-------- ----------- ----------- ----------- '
   Loop K= 1,24
        kk = k-1.0
      PRINT PRINTO=1 form=12.0csv list =  kK(8), MHC_JurA[1][K], MHC_JurA[2][K], MHC_JurA[3][K]
   ENDLOOP
      PRINT PRINTO=1 form=12.0csv list =  '  Total ', Tot_MTs, Tot_HTs, Tot_Cvs




ENDRUN
*copy voya*.prn outputs\reports\Truck_Com_Trip_Generation.rpt
