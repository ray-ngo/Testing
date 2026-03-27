; SKM_to_OMX.s
; Jan 2022, RSG
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

TOD_PRD='%TOD_PERIOD%'
SKM_GROUP='%SKM_GROUP%'

IF (TOD_PRD = 'AM')
  IF (SKM_GROUP = '1')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/HWY_Non_Motorized.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/HWY_Non_Motorized.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_DR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_DR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_DR_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_DR_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_DR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_DR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_DR_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_DR_CR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_DR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_DR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_KR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_KR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '2')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_KR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_KR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_KR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_KR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_AB_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_AB_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_AB_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_AB_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_ALL_TRANSIT_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_ALL_TRANSIT_DR.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '3')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_BM_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_BM_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_BM_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_BM_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_CR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_CR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_CR_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSE
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_MR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_MR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_MR_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_MR_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_AM_WK_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_AM_WK_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_AM_hov2.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_AM_hov2.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_AM_hov3.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_AM_hov3.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_AM_sov.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_AM_sov.omx" FORMAT=OMX COMPRESSION=4
  ENDIF
ELSEIF (TOD_PRD = 'MD')
  IF (SKM_GROUP = '1')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_DR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_DR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_DR_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_DR_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_DR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_DR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_DR_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_DR_CR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_DR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_DR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_KR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_KR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '2')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_KR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_KR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_KR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_KR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_AB_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_AB_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_AB_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_AB_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_ALL_TRANSIT_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_ALL_TRANSIT_DR.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '3')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_BM_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_BM_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_BM_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_BM_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_CR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_CR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_CR_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSE
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_MR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_MR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_MR_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_MR_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_MD_WK_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_MD_WK_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_MD_hov2.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_MD_hov2.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_MD_hov3.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_MD_hov3.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_MD_sov.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_MD_sov.omx" FORMAT=OMX COMPRESSION=4
  ENDIF
ELSEIF (TOD_PRD = 'PM')
  IF (SKM_GROUP = '1')
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_DR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_DR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_DR_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_DR_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_DR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_DR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_DR_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_DR_CR_WK.omx" FORMAT=OMX COMPRESSION=4
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_DR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_DR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
   CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_KR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_KR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '2')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_KR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_KR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_KR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_KR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_AB_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_AB_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_AB_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_AB_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_ALL_TRANSIT_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_ALL_TRANSIT_DR.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '3')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_BM_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_BM_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_BM_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_BM_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_CR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_CR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_CR_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSE
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_MR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_MR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_MR_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_MR_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_PM_WK_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_PM_WK_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_PM_hov2.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_PM_hov2.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_PM_hov3.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_PM_hov3.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_PM_sov.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_PM_sov.omx" FORMAT=OMX COMPRESSION=4
  ENDIF
ELSE
  IF (SKM_GROUP = '1')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_DR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_DR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_DR_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_DR_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_DR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_DR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_DR_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_DR_CR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_DR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_DR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_KR_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_KR_AB_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '2')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_KR_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_KR_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_KR_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_KR_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_AB_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_AB_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_AB_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_AB_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_AB_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_AB_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_ALL_TRANSIT_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_ALL_TRANSIT_DR.omx" FORMAT=OMX COMPRESSION=4
  ELSEIF (SKM_GROUP = '3')
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_ALL_TRANSIT_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_ALL_TRANSIT_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_BM_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_BM_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_BM_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_BM_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_BM_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_BM_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_CR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_CR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_CR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_CR_WK.omx" FORMAT=OMX COMPRESSION=4
  ELSE
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_MR_DR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_MR_DR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_MR_KR.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_MR_KR.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_iter_%_NT_WK_MR_WK.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_iter_%_NT_WK_MR_WK.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_NT_hov2.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_NT_hov2.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_NT_hov3.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_NT_hov3.omx" FORMAT=OMX COMPRESSION=4
    CONVERTMAT FROM="%SCEN_DIRECTORY%/outputs/skims/%_prev_%_NT_sov.SKM" TO="%SCEN_DIRECTORY%/outputs/skims/OMX_Skims/%_prev_%_NT_sov.omx" FORMAT=OMX COMPRESSION=4
  ENDIF
ENDIF
