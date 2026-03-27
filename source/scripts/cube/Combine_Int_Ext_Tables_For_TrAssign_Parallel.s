; Combine_Int_Ext_Tables_For_TrAssign_Parallel.s
; Nov 2021
; Converts ActivitySim generated transit trip tables to TRP format and combines
; them with fixed external and visitor trips tables
;---------------------------------------------------------------


;*** Copy ActivitySim TRANSIT OMX matrices to TRP format

CONVERTMAT FROM="outputs\activitysim\trn_trips_am.omx" TO="outputs\trn_assign\%_iter_%_AMMS.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\trn_trips_md.omx" TO="outputs\trn_assign\%_iter_%_MDMS.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\trn_trips_pm.omx" TO="outputs\trn_assign\%_iter_%_PMMS.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="outputs\activitysim\trn_trips_nt.omx" TO="outputs\trn_assign\%_iter_%_NTMS.TRP" FORMAT=TPP COMPRESSION=0


RUN PGM=MATRIX
MATI[1] = 'outputs\trn_assign\%_iter_%_AMMS.TRP' ;ActivitySim AM
MATI[2] = 'outputs\trn_assign\%_iter_%_MDMS.TRP' ;ActivitySim MD
MATI[3] = 'outputs\trn_assign\%_iter_%_PMMS.TRP' ;ActivitySim PM
MATI[4] = 'outputs\trn_assign\%_iter_%_NTMS.TRP' ;ActivitySim NT

MATI[5] = 'inputs\trn\External_Visitor_Transit\AM_External.TRP' ;Fixed External AM
MATI[6] = 'inputs\trn\External_Visitor_Transit\MD_External.TRP' ;Fixed External MD
MATI[7] = 'inputs\trn\External_Visitor_Transit\PM_External.TRP' ;Fixed External PM
MATI[8] = 'inputs\trn\External_Visitor_Transit\NT_External.TRP' ;Fixed External NT

MATI[9] = 'inputs\trn\External_Visitor_Transit\AM_Visitor.TRP' ;Fixed Visitor AM
MATI[10] = 'inputs\trn\External_Visitor_Transit\MD_Visitor.TRP' ;Fixed Visitor MD
MATI[11] = 'inputs\trn\External_Visitor_Transit\PM_Visitor.TRP' ;Fixed Visitor PM
MATI[12] = 'inputs\trn\External_Visitor_Transit\NT_Visitor.TRP' ;Fixed Visitor NT


; Note: There are 18 tables on the *.TRP files, since, for CR, KNR and PNR are combined
MATO[1]='outputs\trn_assign\%_iter_%_AMMS_all.TRP',MO=01-18,
  NAME = KNRE_AB, KNRE_BM, KNRE_MR, KNR_AB, KNR_BM, KNR_MR, PNRE_AB, PNRE_BM, PNRE_CR, PNRE_MR, PNR_AB, PNR_BM, PNR_CR, PNR_MR, WALK_AB, WALK_BM, WALK_CR, WALK_MR

MATO[2]='outputs\trn_assign\%_iter_%_MDMS_all.TRP',MO=19-36,
  NAME = KNRE_AB, KNRE_BM, KNRE_MR, KNR_AB, KNR_BM, KNR_MR, PNRE_AB, PNRE_BM, PNRE_CR, PNRE_MR, PNR_AB, PNR_BM, PNR_CR, PNR_MR, WALK_AB, WALK_BM, WALK_CR, WALK_MR

MATO[3]='outputs\trn_assign\%_iter_%_PMMS_all.TRP',MO=37-54,
  NAME = KNRE_AB, KNRE_BM, KNRE_MR, KNR_AB, KNR_BM, KNR_MR, PNRE_AB, PNRE_BM, PNRE_CR, PNRE_MR, PNR_AB, PNR_BM, PNR_CR, PNR_MR, WALK_AB, WALK_BM, WALK_CR, WALK_MR

MATO[4]='outputs\trn_assign\%_iter_%_NTMS_all.TRP',MO=55-72,
  NAME = KNRE_AB, KNRE_BM, KNRE_MR, KNR_AB, KNR_BM, KNR_MR, PNRE_AB, PNRE_BM, PNRE_CR, PNRE_MR, PNR_AB, PNR_BM, PNR_CR, PNR_MR, WALK_AB, WALK_BM, WALK_CR, WALK_MR

;AM TRIP MATRICES
MW[1]=MI.1.1+MI.5.1+MI.9.1            ; AM KNRE_AB
MW[2]=MI.1.2+MI.5.2+MI.9.2            ; AM KNRE_BM
MW[3]=MI.1.3+MI.5.3+MI.9.3            ; AM KNRE_MR
MW[4]=MI.1.4+MI.5.4+MI.9.4            ; AM KNR_AB
MW[5]=MI.1.5+MI.5.5+MI.9.5            ; AM KNR_BM
MW[6]=MI.1.6+MI.5.6+MI.9.6            ; AM KNR_MR
MW[7]=MI.1.7+MI.5.7+MI.9.7            ; AM PNRE_AB
MW[8]=MI.1.8+MI.5.8+MI.9.8            ; AM PNRE_BM
MW[9]=MI.1.9+MI.5.9+MI.9.9            ; AM PNRE_CR
MW[10]=MI.1.10+MI.5.10+MI.9.10        ; AM PNRE_MR
MW[11]=MI.1.11+MI.5.11+MI.9.11        ; AM PNR_AB
MW[12]=MI.1.12+MI.5.12+MI.9.12        ; AM PNR_BM
MW[13]=MI.1.13+MI.5.13+MI.9.13        ; AM PNR_CR
MW[14]=MI.1.14+MI.5.14+MI.9.14        ; AM PNR_MR
MW[15]=MI.1.15+MI.5.15+MI.9.15        ; AM WALK_AB
MW[16]=MI.1.16+MI.5.16+MI.9.16        ; AM WALK_BM
MW[17]=MI.1.17+MI.5.17+MI.9.17        ; AM WALK_CR
MW[18]=MI.1.18+MI.5.18+MI.9.18        ; AM WALK_MR

;MD TRIP MATRICES
MW[19]=MI.2.1+MI.6.1+MI.10.1            ; MD KNRE_AB
MW[20]=MI.2.2+MI.6.2+MI.10.2            ; MD KNRE_BM
MW[21]=MI.2.3+MI.6.3+MI.10.3            ; MD KNRE_MR
MW[22]=MI.2.4+MI.6.4+MI.10.4            ; MD KNR_AB
MW[23]=MI.2.5+MI.6.5+MI.10.5            ; MD KNR_BM
MW[24]=MI.2.6+MI.6.6+MI.10.6            ; MD KNR_MR
MW[25]=MI.2.7+MI.6.7+MI.10.7            ; MD PNRE_AB
MW[26]=MI.2.8+MI.6.8+MI.10.8            ; MD PNRE_BM
MW[27]=MI.2.9+MI.6.9+MI.10.9            ; MD PNRE_CR
MW[28]=MI.2.10+MI.6.10+MI.10.10        ; MD PNRE_MR
MW[29]=MI.2.11+MI.6.11+MI.10.11        ; MD PNR_AB
MW[30]=MI.2.12+MI.6.12+MI.10.12        ; MD PNR_BM
MW[31]=MI.2.13+MI.6.13+MI.10.13        ; MD PNR_CR
MW[32]=MI.2.14+MI.6.14+MI.10.14        ; MD PNR_MR
MW[33]=MI.2.15+MI.6.15+MI.10.15        ; MD WALK_AB
MW[34]=MI.2.16+MI.6.16+MI.10.16        ; MD WALK_BM
MW[35]=MI.2.17+MI.6.17+MI.10.17        ; MD WALK_CR
MW[36]=MI.2.18+MI.6.18+MI.10.18        ; MD WALK_MR

;PM TRIP MATRICES
MW[37]=MI.3.1+MI.7.1+MI.11.1            ; PM KNRE_AB
MW[38]=MI.3.2+MI.7.2+MI.11.2            ; PM KNRE_BM
MW[39]=MI.3.3+MI.7.3+MI.11.3            ; PM KNRE_MR
MW[40]=MI.3.4+MI.7.4+MI.11.4            ; PM KNR_AB
MW[41]=MI.3.5+MI.7.5+MI.11.5            ; PM KNR_BM
MW[42]=MI.3.6+MI.7.6+MI.11.6            ; PM KNR_MR
MW[43]=MI.3.7+MI.7.7+MI.11.7            ; PM PNRE_AB
MW[44]=MI.3.8+MI.7.8+MI.11.8            ; PM PNRE_BM
MW[45]=MI.3.9+MI.7.9+MI.11.9            ; PM PNRE_CR
MW[46]=MI.3.10+MI.7.10+MI.11.10        ; PM PNRE_MR
MW[47]=MI.3.11+MI.7.11+MI.11.11        ; PM PNR_AB
MW[48]=MI.3.12+MI.7.12+MI.11.12        ; PM PNR_BM
MW[49]=MI.3.13+MI.7.13+MI.11.13        ; PM PNR_CR
MW[50]=MI.3.14+MI.7.14+MI.11.14        ; PM PNR_MR
MW[51]=MI.3.15+MI.7.15+MI.11.15        ; PM WALK_AB
MW[52]=MI.3.16+MI.7.16+MI.11.16        ; PM WALK_BM
MW[53]=MI.3.17+MI.7.17+MI.11.17        ; PM WALK_CR
MW[54]=MI.3.18+MI.7.18+MI.11.18        ; PM WALK_MR

;NT TRIP MATRICES
MW[55]=MI.4.1+MI.8.1+MI.12.1            ; NT KNRE_AB
MW[56]=MI.4.2+MI.8.2+MI.12.2            ; NT KNRE_BM
MW[57]=MI.4.3+MI.8.3+MI.12.3            ; NT KNRE_MR
MW[58]=MI.4.4+MI.8.4+MI.12.4            ; NT KNR_AB
MW[59]=MI.4.5+MI.8.5+MI.12.5            ; NT KNR_BM
MW[60]=MI.4.6+MI.8.6+MI.12.6            ; NT KNR_MR
MW[61]=MI.4.7+MI.8.7+MI.12.7            ; NT PNRE_AB
MW[62]=MI.4.8+MI.8.8+MI.12.8            ; NT PNRE_BM
MW[63]=MI.4.9+MI.8.9+MI.12.9            ; NT PNRE_CR
MW[64]=MI.4.10+MI.8.10+MI.12.10        ; NT PNRE_MR
MW[65]=MI.4.11+MI.8.11+MI.12.11        ; NT PNR_AB
MW[66]=MI.4.12+MI.8.12+MI.12.12        ; NT PNR_BM
MW[67]=MI.4.13+MI.8.13+MI.12.13        ; NT PNR_CR
MW[68]=MI.4.14+MI.8.14+MI.12.14        ; NT PNR_MR
MW[69]=MI.4.15+MI.8.15+MI.12.15        ; NT WALK_AB
MW[70]=MI.4.16+MI.8.16+MI.12.16        ; NT WALK_BM
MW[71]=MI.4.17+MI.8.17+MI.12.17        ; NT WALK_CR
MW[72]=MI.4.18+MI.8.18+MI.12.18        ; NT WALK_MR

ENDRUN
