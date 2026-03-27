*DEL voya*.prn

;; Prepare_Base_Toll_Esc_File.S - This script creates a toll_esc.dbf file with base distance toll rates
;;                      and replaces the original toll_esc.dbf file (renamed as toll_esc_old.dbf) in the
;;                      inputs folder

;; User defined I/O files and parameters are defined here:

;; Input Files
Old_Toll_Esc       = 'Toll_Esc_Old.dbf'

;; Output File
Base_Toll_Esc    = 'Toll_Esc.dbf'

MaxTG             =  %MAXTGRPS%         ;; MAX Toll Group Parameter

RUN PGM=MATRIX
ZONES=1

;; Read Old_Toll_Esc as Look-up tables
FileI  LOOKUPI[1] ="@Old_Toll_Esc@"
LOOKUP LOOKUPI=1,  NAME=Old_Toll_Esc,
       LOOKUP[1] = Tollgrp, RESULT=Escfac,     ;
       LOOKUP[2] = Tollgrp, RESULT=DSTFAC,     ;
       LOOKUP[3] = Tollgrp, RESULT=AM_TFTR,    ;
       LOOKUP[4] = Tollgrp, RESULT=PM_TFTR,    ;
       LOOKUP[5] = Tollgrp, RESULT=OP_TFTR,    ;
       LOOKUP[6] = Tollgrp, RESULT=AT_Min,     ;
       LOOKUP[7] = Tollgrp, RESULT=AT_Max,     ;
       LOOKUP[8] = Tollgrp, RESULT=Tolltype,   ;
       INTERPOLATE=N, FAIL= -1,-1,-1, LIST=N      ;

;;All done reading inputs!
;;Define the base DBF output file attributes 
FILEO RECO[1]    = "@Base_Toll_Esc@",fields =
                  TollGrp, Escfac(12.6), DSTFAC(12.6), AM_TFTR(12.6), PM_TFTR(12.6), OP_TFTR(12.6), AT_Min(12.6), AT_Max(12.6), Tolltype(12.6) ;
                  
;;Loop through toll groups and write output
LOOP TG=1,@MaxTG@

     ro.TollGRP    = TG
     ;;If toll group equals 1 or 2 write what is in the input file
     IF (TG = 1 || TG = 2)
        ro.Escfac     = Old_Toll_Esc(1,TG)
        ro.DSTFAC     = Old_Toll_Esc(2,TG)
        ro.AM_TFTR    = Old_Toll_Esc(3,TG)
        ro.PM_TFTR    = Old_Toll_Esc(4,TG)
        ro.OP_TFTR    = Old_Toll_Esc(5,TG)
        ro.AT_Min     = Old_Toll_Esc(6,TG)
        ro.AT_Max     = Old_Toll_Esc(7,TG)
        ro.Tolltype   = Old_Toll_Esc(8,TG)
        WRITE RECO=1
        
      ELSEIF (Old_Toll_Esc(2,TG) > 0)

        ro.Escfac     = Old_Toll_Esc(1,TG)
        ro.DSTFAC     = 20
        ro.AM_TFTR    = 1.00
        ro.PM_TFTR    = 1.00
        ro.OP_TFTR    = 0.75
        ro.AT_Min     = Old_Toll_Esc(6,TG)
        ro.AT_Max     = Old_Toll_Esc(7,TG)
        ro.Tolltype   = Old_Toll_Esc(8,TG)
        WRITE RECO=1
 ENDIF



 ENDLOOP
;;All Done!
ENDRUN






