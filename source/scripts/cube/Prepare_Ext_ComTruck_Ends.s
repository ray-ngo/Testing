*del voya*.prn
;
;=====================================================================================================
;  Prepare_Ext_ComTrk_Ends.s                                                                           =
;  This process prepares CV and Truck-related external Ps, As for the External Trip Distribution Process     =
;  The zonal level internal Ps & As are scaled (or balanced) to match external As & Ps, respectively =
;=====================================================================================================

ZONESIZE       =  3722                       ;  No. of TAZs
Purps          =  3                          ;  No. of purposes
LastIZn        =  3675                       ;  Last Internal TAZ no.
Scaled_IntPsAs  ='outputs\auxiliary\%_iter_%_Ext_CVTruck_Gen_PsAs.dbf'  ;; OUTPUT external zonal Ps,As file, HBW,HBS,HBO,NHW,NHO purposes

RUN PGM=MATRIX
ZONES=1

Fileo printo[1] ='outputs\auxiliary\%_iter_%_Ext_CVTruck_Gen_PsAs.txt' ;; report file

Array ZProdA   = 5,3722     ; input zonal productions array /Unscaled
Array ZAttrA   = 5,3722     ; input zonal attractions array /Unscaled

Array S_ZProdA = 5,3722     ; output zonal productions /  intls  scaled to extl attr. totals
Array S_ZAttrA = 5,3722     ; output zonal attractions /  intls  scaled to extl prod. totals

Array TotProda=5, IntProda=5, ExtProda=5, TotscaleP=5, TotscaleA=5
Array TotAttra=5, IntAttra=5, ExtAttra=5, Pscale=5,Ascale=5, IntScaleP=5, IntScaleA=5

;; INPUT Zonal trip productions

;;INPUT Zonal comm, med truck, heavy truck trip ends
FILEI DBI[1] = "outputs\auxiliary\%_iter_%_ComVeh_Truck_Ends.dbf"
;; variables in file:
;  TAZ     COMM_VEH        MED_TRUCK       HVY_TRUCK


;; Read productions into zonal array and accumulate, totals, internals, and externals by purpose
LOOP K = 1,dbi.1.NUMRECORDS
         x = DBIReadRecord(1,k)
              ZProda[1][di.1.TAZ]    =   di.1.Comm_Veh
              ZProda[2][di.1.TAZ]    =   di.1.Med_Truck
              ZProda[3][di.1.TAZ]    =   di.1.Hvy_Truck

;;       Accumulate total, internal and external P's by purpose
              TotProda[1]  =  TotProda[1]  +  ZProda[1][di.1.TAZ]
              TotProda[2]  =  TotProda[2]  +  ZProda[2][di.1.TAZ]
              TotProda[3]  =  TotProda[3]  +  ZProda[3][di.1.TAZ]
              TotProdaSum  =  TotProdaSum  +  ZProda[1][di.1.TAZ] + ZProda[2][di.1.TAZ] + ZProda[3][di.1.TAZ]

          IF (K <= @LastIZn@)
              IntProda[1]  =  IntProda[1]  +  ZProda[1][di.1.TAZ]
              IntProda[2]  =  IntProda[2]  +  ZProda[2][di.1.TAZ]
              IntProda[3]  =  IntProda[3]  +  ZProda[3][di.1.TAZ]
              IntProdaSum  =  IntProdaSum  +  ZProda[1][di.1.TAZ] + ZProda[2][di.1.TAZ] + ZProda[3][di.1.TAZ]
           ELSE
              ExtProda[1]  =  ExtProda[1]  +  ZProda[1][di.1.TAZ]
              ExtProda[2]  =  ExtProda[2]  +  ZProda[2][di.1.TAZ]
              ExtProda[3]  =  ExtProda[3]  +  ZProda[3][di.1.TAZ]
              ExtProdaSum  =  ExtProdaSum  +  ZProda[1][di.1.TAZ] + ZProda[2][di.1.TAZ] + ZProda[3][di.1.TAZ]
          ENDIF
 ENDLOOP

;; Read attractions into zonal array and accumulate, totals, internals, and externals by purpose
LOOP K = 1,dbi.1.NUMRECORDS
         x = DBIReadRecord(1,k)
              ZAttra[1][di.1.TAZ]    =   di.1.Comm_Veh
              ZAttra[2][di.1.TAZ]    =   di.1.Med_Truck
              ZAttra[3][di.1.TAZ]    =   di.1.Hvy_Truck

;;       Accumulate total, internal and external P's by purpose
              TotAttra[1]  =  TotAttra[1]  +  ZAttra[1][di.1.TAZ]
              TotAttra[2]  =  TotAttra[2]  +  ZAttra[2][di.1.TAZ]
              TotAttra[3]  =  TotAttra[3]  +  ZAttra[3][di.1.TAZ]
              TotAttraSum  =  TotAttraSum  +  ZAttra[1][di.1.TAZ] + ZAttra[2][di.1.TAZ] + ZAttra[3][di.1.TAZ]

          IF (K <= @LastIZn@)
              IntAttra[1]  =  IntAttra[1]  +  ZAttra[1][di.1.TAZ]
              IntAttra[2]  =  IntAttra[2]  +  ZAttra[2][di.1.TAZ]
              IntAttra[3]  =  IntAttra[3]  +  ZAttra[3][di.1.TAZ]
              IntAttraSum  =  IntAttraSum  +  ZAttra[1][di.1.TAZ] + ZAttra[2][di.1.TAZ] + ZAttra[3][di.1.TAZ]
           ELSE
              ExtAttra[1]  =  ExtAttra[1]  +  ZAttra[1][di.1.TAZ]
              ExtAttra[2]  =  ExtAttra[2]  +  ZAttra[2][di.1.TAZ]
              ExtAttra[3]  =  ExtAttra[3]  +  ZAttra[3][di.1.TAZ]
              ExtAttraSum  =  ExtAttraSum  +  ZAttra[1][di.1.TAZ] + ZAttra[2][di.1.TAZ] + ZAttra[3][di.1.TAZ]
          ENDIF
 ENDLOOP

;; compute scaling  factors by purpose

    Loop pp= 1, @Purps@

         If (IntProda[pp]!= 0)  Pscale[pp] = ExtAttra[pp]/IntProda[pp]
         If (IntAttra[pp]!= 0)  Ascale[pp] = ExtProda[pp]/IntAttra[pp]

    ENDLOOP

;;print input P/A results by intl, external groups
   print printo=1            List =  ' Listing of INPUT Commercial Veh. and Truck P/A Totals by Purpose and computed scaling factors '
   print printo= 1 form=12.2 list = '            '

   print printo =1              list = ' Purpose>>>                     ','        Com_Veh           MedTrk         HvyTrk             ALL'
   print printo= 1              list = '            '
   print printo= 1 form=16.2csv list = ' Total Internal  Ps by purpose: ', IntProda[1],  IntProda[2], IntProda[3], IntProdaSum
   print printo= 1 form=16.2csv list = ' Total External  Ps by purpose: ', ExtProda[1],  ExtProda[2], ExtProda[3], ExtProdaSum
   print printo= 1 form=16.2csv list = ' Total Intl&Extl Ps by purpose: ', TotProda[1],  TotProda[2], TotProda[3], TotProdaSum
   print printo= 1              list = '            '
   print printo= 1 form=16.2csv list = ' Total Internal  As by purpose: ', IntAttra[1],  IntAttra[2], IntAttra[3], IntAttraSum
   print printo= 1 form=16.2csv list = ' Total External  As by purpose: ', ExtAttra[1],  ExtAttra[2], ExtAttra[3], ExtAttraSum
   print printo= 1 form=16.2csv list = ' Total Intl&Extl As by purpose: ', TotAttra[1],  TotAttra[2], TotAttra[3], TotAttraSum
   print printo= 1              list = '            '
   print printo= 1 form=16.6csv list = 'Prod_scale fts ExtAs/IntlPs:    ',   Pscale[1], Pscale[2], Pscale[3]
   print printo= 1 form=16.6csv list = 'Attr_scale fts ExtPs/ExtlPs:    ',   Ascale[1], Ascale[2], Ascale[3]
   print printo= 1              list = '            '
   print printo= 1              list = '            '
   print printo= 1              list = '            '


;;set up out file


 ;; DEFINE OUTPUT FILE & VARIABLES
 FILEO RECO[1]    = "@Scaled_IntPsAs@",
                     fields = TAZ(5),
                              SCom_VehPs(15.2), SMed_TrkPs(15.2), SHvy_TrkPs(15.2),
                              SCom_VehAs(15.2), SMed_TrkAs(15.2), SHvy_TrkAs(15.2)

 ;;
 ;; Now loop through each internal TAZ and
 ;;   1)  scale INT Attractions to EXT productions
 ;;   2)  scale INT Productions to EXT attractions
 ;;   3)  write out scaled/INT Ps As and unscaled EXT P's, As

 Loop zz= 1, @ZONESIZE@

    Loop pp= 1, @Purps@

          IF (zz <= @LastIZn@)      ;;if TAZ is internal, then scale and accumulate
            S_ZProda[pp][zz] =  ZProda[pp][zz] *   Pscale[pp]
            S_ZAttra[pp][zz] =  ZAttra[pp][zz] *   Ascale[pp]

;;          accumulate scaled internal Ps, As by purpose and for total
            IntScaleP[pp] = IntScaleP[pp] +   S_ZProda[pp][zz]
            IntScaleA[pp] = IntScaleA[pp] +   S_ZAttra[pp][zz]

            IntScalePSum  = IntScalePSum  +   S_ZProda[pp][zz]
            IntScaleASum  = IntScaleASum  +   S_ZAttra[pp][zz]

           ELSE                    ;; Else TAZ is external, final scaled P/S equals input P,A
             S_ZProda[pp][zz] =  ZProdA[pp][zz]
             S_ZAttra[pp][zz] =  ZAttrA[pp][zz]

          ENDIF                    ;;
            ;; Accum. total of scaled intls and untouched extls for reporting, by purpose and for total
            TotScaleP[pp] = TotScaleP[pp] +   S_ZProda[pp][zz]
            TotScaleA[pp] = TotScaleA[pp] +   S_ZAttra[pp][zz]

            TotScalePSum  = TotScalePSum  +   S_ZProda[pp][zz]
            TotScaleASum  = TotScaleASum  +   S_ZAttra[pp][zz]
    ENDLOOP




;;       Write out the unscaled and scaled Ps,As by purpose
;;       The scaled internal productions will equal the sum of external attractions
;;       The scaled internal attractions will equal the sum of external productions
;;       The external Ps, As will remain unchanged
          ro.TAZ        =  zz
          ro.SCom_VehPs = S_ZProda[1][zz]
          ro.SMed_TrkPs = S_ZProda[2][zz]
          ro.SHvy_TrkPs = S_ZProda[3][zz]

          ro.SCom_VehAs = S_ZAttra[1][zz]
          ro.SMed_TrkAs = S_ZAttra[2][zz]
          ro.SHvy_TrkAs = S_ZAttra[3][zz]

          WRITE RECO=1

ENDLOOP



print printo=1            List =  ' Listing of OUTPUT Commercial Veh. and Truck P/A Totals by purpose to be used in the External Trip Distribution Process '
;;print input P/A results by intl, external groups

   print printo= 1              list = '            '
   print printo =1              list = ' Purpose>>>                     ','         ComVeh           MedTrk         HvyTrk             ALL'
   print printo= 1              list = '            '
   print printo= 1 form=16.2csv list = ' Internal Ps, scaled to Extl As:', IntScaleP[1], IntScaleP[2],IntScaleP[3], IntScalePSum
   print printo= 1 form=16.2csv list = ' External Ps by purpose:        ',  ExtProda[1],  ExtProda[2], ExtProda[3], ExtProdaSum
   print printo= 1 form=16.2csv list = ' Total    Ps by purpose:        ', TotScaleP[1], TotScaleP[2],TotScaleP[3], TotScalePSum
   print printo= 1              list = '            '
   print printo= 1 form=16.2csv list = ' Internal As, scaled to Extl Ps:', IntScaleA[1], IntScaleA[2],IntScaleA[3], IntScaleASum
   print printo= 1 form=16.2csv list = ' Total External  As by purpose: ',  ExtAttra[1],  ExtAttra[2], ExtAttra[3], ExtAttraSum
   print printo= 1 form=16.2csv list = ' Total Intl&Extl As by purpose: ', TotScaleA[1], TotScaleA[2],TotScaleA[3], TotScaleASum
   print printo= 1              list = '            '

ENDRUN
*copy voya*.prn outputs\reports\mod2.rpt
