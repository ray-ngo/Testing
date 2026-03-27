*DEL voya*.prn

;; Post_Toll_Search.S - This script grabs the Pump Prime Toll_Esc.dbf file and the three TOD
;;                      text files resulting from JC Park's toll search process and compiles all information into a
;;                      Final Toll_Esc.dbf file

;; User defined I/O files and parameters are defined here:

;; Input Files
PP_Toll_Esc       = '..\..\inputs\hwy\Toll_Esc.dbf'
AM_TollSearch_Out = '..\AM\%AMTOLL%'
PM_TollSearch_Out = '..\PM\%PMTOLL%'
MD_TollSearch_Out = '..\MD\%MDTOLL%'

;; Output File
Final_Toll_Esc    = 'Final_Toll_Esc.dbf'

MaxTG             =  %MAXTGRPS%         ;; MAX Toll Group Parameter

RUN PGM=MATRIX
ZONES=1

;; Read input pp_Toll_Esc file and time period toll search outputs from JC's process 
;; as Look-up tables
FileI  LOOKUPI[1] ="@PP_Toll_Esc@"
LOOKUP LOOKUPI=1,  NAME=PP_Toll_Esc,
       LOOKUP[1] = Tollgrp, RESULT=Escfac,     ;
       LOOKUP[2] = Tollgrp, RESULT=DSTFAC,     ;
       LOOKUP[3] = Tollgrp, RESULT=AM_TFTR,    ;
       LOOKUP[4] = Tollgrp, RESULT=PM_TFTR,    ;
       LOOKUP[5] = Tollgrp, RESULT=OP_TFTR,    ;
       LOOKUP[6] = Tollgrp, RESULT=AT_Min,     ;
       LOOKUP[7] = Tollgrp, RESULT=AT_Max,     ;
       LOOKUP[8] = Tollgrp, RESULT=Tolltype,   ;
       INTERPOLATE=N, FAIL= 0,0,0, LIST=N      ;

lookup name = FinalAMToll,      ; AM TOLL Search Output
       lookup[1] = 1,result=2,  ; Toll group
       lookup[2] = 1,result=3,  ; Facility Type
       lookup[3] = 1,result=4,  ; Unadjusted Toll
       lookup[4] = 1,result=5,  ; Adjusted Toll
       lookup[5] = 1,result=6,  ; Speed-VMT Product
       lookup[6] = 1,result=7,  ; avg vc ratio
       lookup[7] = 1,result=8,  ; VMT
       lookup[8] = 1,result=9,  ; difference lb vc - avg vc ratio
       lookup[9] = 1,result=10, ; TOGGLE SWITCH to keep toll
       interpolate=N,fail=0,0,0,file=@AM_TollSearch_Out@

lookup name = FinalPMToll,      ; PM TOLL Search Output
       lookup[1] = 1,result=2,  ; Toll group
       lookup[2] = 1,result=3,  ; Facility Type
       lookup[3] = 1,result=4,  ; Unadjusted Toll
       lookup[4] = 1,result=5,  ; Adjusted Toll
       lookup[5] = 1,result=6,  ; Speed-VMT Product
       lookup[6] = 1,result=7,  ; avg vc ratio
       lookup[7] = 1,result=8,  ; VMT
       lookup[8] = 1,result=9,  ; difference lb vc - avg vc ratio
       lookup[9] = 1,result=10, ; TOGGLE SWITCH to keep toll
       interpolate=N,fail=0,0,0,file=@PM_TollSearch_Out@

lookup name = FinalMDToll,      ; MD TOLL Search Output
       lookup[1] = 1,result=2,  ; Toll group
       lookup[2] = 1,result=3,  ; Facility Type
       lookup[3] = 1,result=4,  ; Unadjusted Toll
       lookup[4] = 1,result=5,  ; Adjusted Toll
       lookup[5] = 1,result=6,  ; Speed-VMT Product
       lookup[6] = 1,result=7,  ; avg vc ratio
       lookup[7] = 1,result=8,  ; VMT
       lookup[8] = 1,result=9,  ; difference lb vc - avg vc ratio
       lookup[9] = 1,result=10, ; TOGGLE SWITCH to keep toll
       interpolate=N,fail=0,0,0,file=@MD_TollSearch_Out@

;;All done reading inputs!
;;Define the final DBF output file attributes 
FILEO RECO[1]    = "@Final_Toll_Esc@",fields =
                  TollGrp, Escfac(12.6), DSTFAC(12.6), AM_TFTR(12.6), PM_TFTR(12.6), OP_TFTR(12.6), AT_Min(12.6), AT_Max(12.6), Tolltype(12.6) ;
                  
;;Loop through toll groups and write output
LOOP TG=1,@MaxTG@

     ro.TollGRP    = TG
     ;;If toll group equals 1 or 2 write what is in the input file
     IF (TG = 1 || TG = 2)
        ro.Escfac     = PP_Toll_Esc(1,TG)
        ro.DSTFAC     = PP_Toll_Esc(2,TG)
        ro.AM_TFTR    = PP_Toll_Esc(3,TG)
        ro.PM_TFTR    = PP_Toll_Esc(4,TG)
        ro.OP_TFTR    = PP_Toll_Esc(5,TG)
        ro.AT_Min     = PP_Toll_Esc(6,TG)
        ro.AT_Max     = PP_Toll_Esc(7,TG)
        ro.Tolltype   = PP_Toll_Esc(8,TG)
        WRITE RECO=1
        
      ;;Else write out JC's toll values for TollGRPs above 2 and less than or equal to MaxTG param 
      ELSEIF (FinalAMToll(4,TG) > 0)

        ro.Escfac     = PP_Toll_Esc(1,TG)
        ro.DSTFAC     = FinalAMToll(4,TG)
        ro.AM_TFTR    = 1.00
        ro.PM_TFTR    = FinalPMToll(4,TG)/FinalAMToll(4,TG)
        ro.OP_TFTR    = FinalMDToll(4,TG)/FinalAMToll(4,TG)
        ro.AT_Min     = PP_Toll_Esc(6,TG)
        ro.AT_Max     = PP_Toll_Esc(7,TG)
        ro.Tolltype   = PP_Toll_Esc(8,TG)
        WRITE RECO=1
 ENDIF



 ENDLOOP
;;All Done!
ENDRUN


*Copy voya*.prn Post_Toll_Search.rpt





