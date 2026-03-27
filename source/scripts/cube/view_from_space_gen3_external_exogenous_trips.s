*del voya*.prn
*del summary*.*
;=========================================================================================
;    Program: view_from_space_gen3_external_exogenous_trips.s
;    Programmer: fxie
;    Date:       10/29/24
;    Purpose:    To create Global Summary of external and exogenous autodriver/vehicle trips
;                for the Gen3 Model.
;====================================================================================================
;
ZONESIZE    = 3722               ; Matrix Size                 ** DO NOT MODIFY **

PATH='%SCEN_DIRECTORY%'
RUN PGM=MATRIX
  ZONES=@zonesize@

  MATI[1] = @PATH@\outputs\auxiliary\i4_am_MISC.tt  ; AM Prd Misc Trips:t1-10(AM_XXTrk,AM_XXAdr,AM_TxAdr,AM_VtAdr,AM_ScAdr,AM_MedTk,AM_HvyTk,AM_APAdr,AM_ComVe)
  MATI[2] = @PATH@\outputs\auxiliary\i4_md_MISC.tt  ; MD Prd Misc Trips:
  MATI[3] = @PATH@\outputs\auxiliary\i4_pm_MISC.tt  ; PM Prd Misc Trips:
  MATI[4] = @PATH@\outputs\auxiliary\i4_nt_MISC.tt  ; NT Prd Misc Trips:

  MATI[9]  = @PATH@\outputs\hwy_assign\i4_am.vtt        ; AM Vehicle trips-     t1-6, sovs, hov2s, hov3+s,comm,  trks, aprt adrs
  MATI[10] = @PATH@\outputs\hwy_assign\i4_pm.vtt        ; MD Vehicle trips-     t1-6, sovs, hov2s, hov3+s,comm,  trks, aprt adrs
  MATI[11] = @PATH@\outputs\hwy_assign\i4_md.vtt        ; PM Vehicle trips-     t1-6, sovs, hov2s, hov3+s,comm,  trks, aprt adrs
  MATI[12] = @PATH@\outputs\hwy_assign\i4_nt.vtt        ; NT Vehicle trips-     t1-6, sovs, hov2s, hov3+s,comm,  trks, aprt adrs

  mw[1]  = mi.1.1   + mi.2.1   + mi.3.1   + mi.4.1   ;xxTrk (Med/Hvy)
  mw[2]  = mi.1.2   + mi.2.2   + mi.3.2   + mi.4.2   ;xxAuto/CV
  mw[3]  = mi.1.3   + mi.2.3   + mi.3.3   + mi.4.3   ;taxi
  mw[4]  = mi.1.4   + mi.2.4   + mi.3.4   + mi.4.4   ;visi
  mw[5]  = mi.1.5   + mi.2.5   + mi.3.5   + mi.4.5   ;schl
  mw[6]  = mi.1.6   + mi.2.6   + mi.3.6   + mi.4.6   ;Mtrk
  mw[7]  = mi.1.7   + mi.2.7   + mi.3.7   + mi.4.7   ;Htrk
  mw[8]  = mi.1.8   + mi.2.8   + mi.3.8   + mi.4.8   ;AirPx
  mw[9]  = mi.1.9   + mi.2.9   + mi.3.9   + mi.4.9   ;CV


  MW[101] =  Mi.9.1  + Mi.9.2 +  Mi.9.3 +  Mi.9.4 +  Mi.9.5 +  Mi.9.6 +  ;  All  Vehicles     (Inputs to assign)
            Mi.10.1 + Mi.10.2 + Mi.10.3 + Mi.10.4 + Mi.10.5 + Mi.10.6 +  ;
            Mi.11.1 + Mi.11.2 + Mi.11.3 + Mi.11.4 + Mi.11.5 + Mi.11.6 +  ;
            Mi.12.1 + Mi.12.2 + Mi.12.3 + Mi.12.4 + Mi.12.5 + Mi.12.6    ;

  FILEO MATO[1] = "%SCEN_DIRECTORY%\outputs\auxiliary\Misc_Daily.VTT" ,MO=1-9, NAME=xxTrk xxAutocv,taxi,visi,schl,Mtk,Htk,AirPx,CV
        MATO[2] = "%SCEN_DIRECTORY%\outputs\auxiliary\TA_Vehs.VTT"   ,MO=101,dec=3  NAME=TA_Vehs

ENDRUN



  ;===============================
  ; Define Trip Matrix Files
  ;===============================
;;
;;--------------------------------------------------------------------
;; Next, accumulate zonal demographics, and trips by purpose and mode
;;--------------------------------------------------------------------
;;
RUN PGM=MATRIX
  ZONES=@zonesize@

  ;===============================
  ; Define Trip Matrix Files
  ;===============================
  
  MATI[1] = @PATH@\outputs\auxiliary\i4_am_adr.mat ; AM IXXI auto drv trips t1-3, 1,2,3+ Occ. 
  MATI[2] = @PATH@\outputs\auxiliary\i4_md_adr.mat ; MD IXXI auto drv trips t1-3, 1,2,3+ Occ. 
  MATI[3] = @PATH@\outputs\auxiliary\i4_pm_adr.mat ; PM IXXI auto drv trips t1-3, 1,2,3+ Occ. 
  MATI[4] = @PATH@\outputs\auxiliary\i4_nt_adr.mat ; NT IXXI auto drv trips t1-3, 1,2,3+ Occ.   

  MATI[6] = @PATH@\outputs\auxiliary\i4_COMMER.PTT        ; COM Trip distibution output t1-3
  MATI[7] = @PATH@\outputs\auxiliary\i4_MTRUCK.PTT        ; MTK Trip distibution output t1-3
  MATI[8] = @PATH@\outputs\auxiliary\i4_HTRUCK.PTT        ; HTK Trip distibution output t1-3

  MATI[14] = @PATH@\outputs\hwy_assign\i4_Asim_AM.VTT         ; Internal AM Auto Drv trips-t1-3, 1,2,3+ Occ. from ActivitySim
  MATI[15] = @PATH@\outputs\hwy_assign\i4_Asim_MD.VTT         ; Internal MD Auto Drv trips-t1-3, 1,2,3+ Occ. from ActivitySim
  MATI[16] = @PATH@\outputs\hwy_assign\i4_Asim_PM.VTT         ; Internal PM Auto Drv trips-t1-3, 1,2,3+ Occ. from ActivitySim
  MATI[17] = @PATH@\outputs\hwy_assign\i4_Asim_NT.VTT         ; Internal NT Auto Drv trips-t1-3, 1,2,3+ Occ. from ActivitySim


  MATI[19] = "%SCEN_DIRECTORY%\outputs\auxiliary\Misc_Daily.VTT"           ; Daily Misc tabs (from above step)
                                      ; t1-9(xxTrk,xxauto,taxi, visi, school, Mtrk, Htrk,AirPx, CV)

  MATI[20] = "%SCEN_DIRECTORY%\outputs\auxiliary\TA_Vehs.VTT"             ; Daily modeled vehicle trips into the assignment
 ;------------------------------------------------------------------------------

     MW[115] = MI.14.1 + MI.14.2 + MI.14.3                                  ;  AM  internal Auto drivers from ActivitySim 
     MW[215] = MI.15.1 + MI.15.2 + MI.15.3                                  ;  MD  internal Auto drivers from ActivitySim 
     MW[315] = MI.16.1 + MI.16.2 + MI.16.3                                  ;  PM  internal Auto drivers from ActivitySim 
     MW[415] = MI.17.1 + MI.17.2 + MI.17.3                                  ;  NT  internal Auto drivers from ActivitySim 

     MW[615] = MW[115] + MW[215] + MW[315] + MW[415]                        ;  All internal Auto drivers (Post ActivitySim model)

     MW[698] = Mi.20.1                                                      ;  All Vehicles     ( trips input to traffic assignment)

     MW[715] = MI.6.3                                                       ;  All  Com Vehs   out of trip dist.
     MW[815] = MI.7.3                                                       ;  All  Med Trucks out of trip dist.
     MW[915] = MI.8.3                                                       ;  All  Hvy Trucks out of trip dist.


     MW[616] = mw[615]                                                      ;  All INTL Auto drivers
     MW[716] = MI.6.1                                                       ;  All Intl Com Vehs   out of trip dist.
     MW[816] = MI.7.1                                                       ;  All Intl Med Trucks out of trip dist.
     MW[916] = MI.8.1                                                       ;  All Intl Hvy Trucks out of trip dist.


     MW[617] = MI.1.1 + MI.1.2 + MI.1.3 + MI.2.1 + MI.2.2 + MI.2.3 + MI.3.1 + MI.3.2 + MI.3.3 + MI.4.1 + MI.4.2 + MI.4.3 ;  All EXTL Auto drivers out of trip dist.
     MW[717] = MI.6.2                                                       ;  All EXTL CV out of trip dist.
     MW[817] = MI.7.2                                                       ;  All EXTL Med Trucks out of trip dist.
     MW[917] = MI.8.2                                                       ;  All EXTL Hvy Trucks out of trip dist.


 ;; put daily exogenous trips in MWs 901,...,909
     MW[901] = MI.19.1                                                      ;  XX Truck   (am+md+pm+nt)
     MW[902] = MI.19.2                                                      ;  XX AutoCV  (am+md+pm+nt)
     MW[903] = MI.19.3                                                      ;  Taxi Adr   (am+md+pm+nt)
     MW[904] = MI.19.4                                                      ;  VisiTourAdr(am+md+pm+nt)
     MW[905] = MI.19.5                                                      ;  School Adr (am+md+pm+nt)
     MW[906] = MI.19.6                                                      ;  Medium Trk (am+md+pm+nt)
     MW[907] = MI.19.7                                                      ;  Heavy  Trk (am+md+pm+nt)
     MW[908] = MI.19.8                                                      ;  AirPax Adr (am+md+pm+nt)
     MW[909] = MI.19.9                                                      ;  Comm. Veh. (am+md+pm+nt)

  ;===============================
  ; Define Zonal Files
  ;===============================

  ZDATI[7] = @PATH@\inputs\auxiliary\Ext_PsAs.dbf
   ;; vars used in the abovefile: TAZ    AAWT_CTL CNTFTR   AUTO_XI  AUTO_IX  AUTO_XX  CV_XX
   ;;                                    HBW_XI   HBS_XI   HBO_XI   NHB_XI   CV_XI
   ;;                                    HBW_IX   HBS_IX   HBO_IX   NHB_IX   CV_IX
   ;;                                    TRCK_XX  TRCK_XI  TRCK_IX  MTK_XI   HTK_XI



  ;
  ;===================================
  ; Accumulate All Regional Totals
  ;===================================
  

;Extl Ps and As
;; HBW_XI   HBS_XI   HBO_XI   NHB_XI   CV_XI
;; HBW_IX   HBS_IX   HBO_IX   NHB_IX   CV_IX
;; TRCK_XX  TRCK_XI  TRCK_IX  MTK_XI   HTK_XI

TOT_HBWAutoDrXI    =  TOT_HBWAutoDrXI   +  HBW_XI
TOT_HBSAutoDrXI    =  TOT_HBSAutoDrXI   +  HBS_XI
TOT_HBOAutoDrXI    =  TOT_HBOAutoDrXI   +  HBO_XI
TOT_NHBAutoDrXI    =  TOT_NHBAutoDrXI   +  NHB_XI

TOT_CVXI           =         TOT_CVXI   +   CV_XI
TOT_TruckXI        =      TOT_TruckXI   +   MTK_XI + HTK_XI
TOT_AutoDrXI       =     TOT_AutoDrXI   +  HBW_XI + HBS_XI + HBO_XI + NHB_XI + CV_XI

TOT_HBWAutoDrIX    =  TOT_HBWAutoDrIX   +  HBW_IX
TOT_HBSAutoDrIX    =  TOT_HBSAutoDrIX   +  HBS_IX
TOT_HBOAutoDrIX    =  TOT_HBOAutoDrIX   +  HBO_IX
TOT_NHBAutoDrIX    =  TOT_NHBAutoDrIX   +  NHB_IX

TOT_CVIX           =         TOT_CVIX   +   CV_IX
TOT_TruckIX        =      TOT_TruckIX   +   MTK_XI + HTK_XI ;; same as XI
TOT_AutoDrIX       =     TOT_AutoDrIX   +  HBW_IX + HBS_IX + HBO_IX + NHB_IX + CV_IX


; Total (Intl/Extl) Auto Driver/vehicle trip totals:
Tot_ALLAdr_MC      = Tot_ALLAdr_MC  + ROWSUM(615)
Tot_TrfAssVehs     = Tot_TrfAssVehs + ROWSUM(698)
Tot_CV             = Tot_CV         + ROWSUM(715)
Tot_Mtk            = Tot_Mtk        + ROWSUM(815)
Tot_Htk            = Tot_Htk        + ROWSUM(915)

; Internal Auto Driver/vehicle trip totals:

Tot_iALLAdr         = Tot_iALLAdr + ROWSUM(616)
Tot_iCV             = Tot_iCV     + ROWSUM(716)
Tot_iMtk            = Tot_iMtk    + ROWSUM(816)
Tot_iHtk            = Tot_iHtk    + ROWSUM(916)

; External Auto Driver/vehicle trip totals:

Tot_xALLAdr         = Tot_xALLAdr + ROWSUM(617)
Tot_xCV             = Tot_xCV     + ROWSUM(717)
Tot_xMtk            = Tot_xMtk    + ROWSUM(817)
Tot_xHtk            = Tot_xHtk    + ROWSUM(917)


Tot_XX_Truck     = Tot_XX_Truck     + ROWSUM(901)
Tot_XX_AutoCV    = Tot_XX_AutoCV    + ROWSUM(902)
Tot_Taxi_Adr     = Tot_Taxi_Adr     + ROWSUM(903)
Tot_Visi_Adr     = Tot_Visi_Adr     + ROWSUM(904)
Tot_Schl_Adr     = Tot_Schl_Adr     + ROWSUM(905)
Tot_Medium_Trk   = Tot_Medium_Trk   + ROWSUM(906)
Tot_Heavy_Trk    = Tot_Heavy_Trk    + ROWSUM(907)
Tot_AirPax_Adr   = Tot_AirPax_Adr   + ROWSUM(908)
Tot_Comm_Veh     = Tot_Comm_Veh     + ROWSUM(909)


;-----------------------------------------------------------------
; If at the end, compute regional rates:
;-----------------------------------------------------------------

IF (I= 1)
	print CSV=T form=20.0 list = '  VFS_ITEM#    ','Description         ','    Autodriver Trips', FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
ENDIF

IF (I= @ZONESIZE@ )

;----------------------------------------------------------------------------------------
; Print out the current summary
;
;----------------------------------------------------------------------------------------


print CSV=T form=20.0 list = '  20                ','Inp_HBWAutoDrXI     ',Tot_HBWAutoDrXI       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' , APPEND=T
print CSV=T form=20.0 list = '  21                ','Inp_HBSAutoDrXI     ',Tot_HBSAutoDrXI       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  22                ','Inp_HBOAutoDrXI     ',Tot_HBOAutoDrXI       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  23                ','Inp_NHBAutoDrXI     ',Tot_NHBAutoDrXI       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  24                ','Inp_CVXI            ',Tot_CVXI              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  25                ','Inp_TruckXI         ',Tot_TruckXI           , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  26                ','Inp_AutoDrXI        ',Tot_AutoDrXI          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 

print CSV=T form=20.0 list = '  27                ','Inp_HBWAutoDrIX     ',Tot_HBWAutoDrIX       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  28                ','Inp_HBSAutoDrIX     ',Tot_HBSAutoDrIX       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  29                ','Inp_HBOAutoDrIX     ',Tot_HBOAutoDrIX       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  30                ','Inp_NHBAutoDrIX     ',Tot_NHBAutoDrIX       , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  31                ','Inp_CVIX            ',Tot_CVIX              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = '  32                ','Inp_TruckIX         ',Tot_TruckIX           , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  33                ','Inp_AutoDrIX        ',Tot_AutoDrIX          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'

print CSV=T form=20.0 list = '  75                ','Ext_ALLAdr          ',Tot_xALLAdr           , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = '  76                ','Ext_ComVeh          ',Tot_xCV               , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = '  77                ','Ext_Medium_Trk      ',Tot_xMtk              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = '  78                ','Ext_Heavy_Trk       ',Tot_xHtk              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 

print CSV=T form=20.0 list = ' 139                ','Int_CommVeh         ',Tot_iCV               , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 140                ','Int_Med_Truck       ',Tot_iMtk              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 141                ','Int_Hvy_Truck       ',Tot_iHtk              , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'

print CSV=T form=20.0 list = ' 149                ','ALL_CV              ',Tot_CV                , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = ' 150                ','ALL_Mtk             ',Tot_Mtk               , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 151                ','ALL_Htk             ',Tot_Htk               , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 152                ','THRU_Truck          ',Tot_XX_Truck          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = ' 153                ','THRU_Auto&CV        ',Tot_XX_AutoCV         , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 154                ','Taxi_AutoDrv        ',Tot_Taxi_Adr          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = ' 155                ','Visitor/Tourist Adr ',Tot_Visi_Adr          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = ' 156                ','School AutroDrv     ',Tot_Schl_Adr          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 
print CSV=T form=20.0 list = ' 157                ','Final_Medium_Truck  ',Tot_Medium_Trk        , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 158                ','Final_Heavy_Truck   ',Tot_Heavy_Trk         , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 159                ','AirPax_AutoDrv      ',Tot_AirPax_Adr        , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv'
print CSV=T form=20.0 list = ' 160                ','Final_Comm_Veh      ',Tot_Comm_Veh          , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 

print CSV=T form=20.0 list = ' 163                ','All_Vehs_Assigned   ',Tot_TrfAssVehs        , FILE = '%SCEN_DIRECTORY%\outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv' 


;; END
ENDIF
ENDRUN
