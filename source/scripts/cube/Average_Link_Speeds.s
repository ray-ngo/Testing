;;  Average the restrained speeds on highway links using MSA
;;  8/5/2011 Corrected NTPCTadt factor from 35.0 to 15.0.
;;  2/15/2019 RQN  Revised line 40 to fix a bug of the model using <ITER>_HWY.net 
;;                  incorrectly when the model crash at a certain step

VDF_File  ='..\support\hwy_assign_Conical_VDF.s'        ;;     Volume Delay Functions file
Iter ='%_iter_%'
Prev ='%_prev_%'

AMPctadt = 41.7
PMPctadt = 29.4
MDPctadt = 17.7
NTPctadt = 15.0

IF (iter    ='pp') itrno = 0
IF (iter    ='i1') itrno = 1
IF (iter    ='i2') itrno = 2
IF (iter    ='i3') itrno = 3
IF (iter    ='i4') itrno = 4
IF (iter    ='i5') itrno = 5
IF (iter    ='i6') itrno = 6

;; Convert the link table of i1|i2|i3|i4_Assign_Output.net to csv format
RUN PGM=NETWORK

NETI=outputs\hwy_net\@iter@_Assign_Output.net 
LINKO=outputs\hwy_net\@iter@_Assign_Output.csv, FORMAT=CS1
	
ENDRUN


;; Remove VOLUME,VMT,SPEED-relate variables from a copy of original loaded links file
RUN PGM=NETWORK
 NETI[1] = outputs\hwy_net\@iter@_HWY.tem1
 NETO    = outputs\hwy_net\@iter@_HWY.tem2,
            exclude= @iter@AMVOL,    @iter@PMVOL,    @iter@MDVOL,    @iter@NTVOL,@iter@24Vol,
                     @iter@AMVMT,    @iter@PMVMT,    @iter@MDVMT,    @iter@NTVMT,
                     @iter@AMFFSPD,  @iter@PMFFSPD,  @iter@MDFFSPD,  @iter@NTFFSPD,
                     @iter@AMHRLKCAP,@iter@PMHRLKCAP,@iter@MDHRLKCAP,@iter@NTHRLKCAP,
                     @iter@AMHRLNCAP,@iter@PMHRLNCAP,@iter@MDHRLNCAP,@iter@NTHRLNCAP,
                     @iter@AMVC,     @iter@PMVC,     @iter@MDVC,     @iter@NTVC,
                     @iter@AMVDF,    @iter@PMVDF,    @iter@MDVDF,    @iter@NTVDF,
                     @iter@AMSPD,    @iter@PMSPD,    @iter@MDSPD,    @iter@NTSPD
ENDRUN


RUN PGM=NETWORK
      NETI[1] = outputs\hwy_net\@iter@_HWY.tem2                     ;; original LL file with speeds removed
      NETI[2] = outputs\hwy_net\@prev@_HWY.net                      ;; previous iteration LL file w/ final speeds
      NETI[3] = outputs\hwy_net\@iter@_Assign_Output.net           ;; current  iteration LL file w/ traffic assigned speeds
NETO = outputs\hwy_net\@iter@_Averaged_HWY.net

_@prev@AMVOL = LI.2.@prev@AMVOL
_@prev@MDVOL = LI.2.@prev@MDVOL
_@prev@PMVOL = LI.2.@prev@PMVOL
_@prev@NTVOL = LI.2.@prev@NTVOL

_@iter@AMVOL = LI.3.@iter@AMVOL
_@iter@MDVOL = LI.3.@iter@MDVOL
_@iter@PMVOL = LI.3.@iter@PMVOL
_@iter@NTVOL = LI.3.@iter@NTVOL


;; Define averaging proportions based on iteration no.

IF     (@itrno@ = 1)
   _@prev@_VOL_Shr =  0.000
   _@iter@_VOL_Shr =  1.000
ELSEIF (@itrno@ = 2)
   _@prev@_VOL_Shr =  0.500
   _@iter@_VOL_Shr =  0.500
ELSEIF (@itrno@ = 3)
   _@prev@_VOL_Shr =  0.666
   _@iter@_VOL_Shr =  0.334
ELSEIF (@itrno@ = 4)
   _@prev@_VOL_Shr =  0.750
   _@iter@_VOL_Shr =  0.250
ELSEIF (@itrno@ = 5)
   _@prev@_VOL_Shr =  0.800
   _@iter@_VOL_Shr =  0.200
ELSEIF (@itrno@ = 6)
   _@prev@_VOL_Shr =  0.833
   _@iter@_VOL_Shr =  0.167
ENDIF

;
;------------------------------------------------------$
;    VDF (Volume Delay Function) establishment:        $
;------------------------------------------------------$
; Note:  curves updated 2/16/06 rjm/msm
;
LOOKUP NAME=VCRV,
       lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
       lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
       lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
       lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
       lookup[5] = 1,result = 6,  ;Colls       old VCRV5
       lookup[6] = 1,result = 7,  ;Expways     old VCRV6
       lookup[7] = 1,result = 8,  ;Rmps
       FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@


  @iter@AMVOL = _@prev@AMVOL * _@prev@_VOL_Shr +  _@iter@AMVOL * _@iter@_VOL_Shr  ;  Final AM Link Volume
  @iter@PMVOL = _@prev@PMVOL * _@prev@_VOL_Shr +  _@iter@PMVOL * _@iter@_VOL_Shr  ;  Final PM Link Volume
  @iter@MDVOL = _@prev@MDVOL * _@prev@_VOL_Shr +  _@iter@MDVOL * _@iter@_VOL_Shr  ;  Final MD Link Volume
  @iter@NTVOL = _@prev@NTVOL * _@prev@_VOL_Shr +  _@iter@NTVOL * _@iter@_VOL_Shr  ;  Final NT Link Volume
  @iter@24VOL =  @iter@AMVOL + @iter@MDVOL +@iter@PMVOL +@iter@NTVOL              ;  Final 24hr Link Volume

     @iter@AMVMT = @iter@AMVOL * distance                                            ;  Final AM link VMT
     @iter@PMVMT = @iter@PMVOL * distance                                            ;  Final PM link VMT
     @iter@MDVMT = @iter@MDVOL * distance                                            ;  Final MD link VMT
     @iter@NTVMT = @iter@NTVOL * distance                                            ;  Final NT link VMT
     @iter@24VMT =(@iter@AMVol + @iter@MDVol + @iter@PMVol + @iter@NTVol)* distance  ;  Final daily   VMT


  @iter@AMFFSPD  =SPEEDFOR(AMLANE,SPDCLASS)                                       ;  Freeflow AM speed
  @iter@PMFFSPD  =SPEEDFOR(PMLANE,SPDCLASS)                                       ;  Freeflow PM speed
  @iter@MDFFSPD  =SPEEDFOR(OPLANE,SPDCLASS)                                       ;  Freeflow MD speed
  @iter@NTFFSPD  =SPEEDFOR(OPLANE,SPDCLASS)                                       ;  Freeflow NT speed

  AMHRLKCAP=CAPACITYFOR(AMLANE,CAPCLASS)                                          ;  Hrly Link capacity
  PMHRLKCAP=CAPACITYFOR(PMLANE,CAPCLASS)                                          ;  Hrly Link capacity
  MDHRLKCAP=CAPACITYFOR(OPLANE,CAPCLASS)                                          ;  Hrly Link capacity
  NTHRLKCAP=CAPACITYFOR(OPLANE,CAPCLASS)                                          ;  Hrly Link capacity

  AMHRLNCAP=CAPACITYFOR(1,CAPCLASS)                                               ;  Hrly Lane capacity
  PMHRLNCAP=CAPACITYFOR(1,CAPCLASS)                                               ;  Hrly Lane capacity
  MDHRLNCAP=CAPACITYFOR(1,CAPCLASS)                                               ;  Hrly Lane capacity
  NTHRLNCAP=CAPACITYFOR(1,CAPCLASS)                                               ;  Hrly Lane capacity

  @iter@AMVC=(@iter@AMVOL*(@AMpctadt@/100.0)/AMHRLKCAP)                           ;  AM VC  ratio
  @iter@PMVC=(@iter@PMVOL*(@PMpctadt@/100.0)/PMHRLKCAP)                           ;  PM VC  ratio
  @iter@MDVC=(@iter@MDVOL*(@MDpctadt@/100.0)/MDHRLKCAP)                           ;  MD VC  ratio
  @iter@NTVC=(@iter@NTVOL*(@NTpctadt@/100.0)/NTHRLKCAP)                           ;  NT VC  ratio

  @iter@AMVDF = VCRV((Ftype + 1), @iter@AMVC)                                     ;  AM VDF
  @iter@PMVDF = VCRV((Ftype + 1), @iter@PMVC)                                     ;  PM VDF
  @iter@MDVDF = VCRV((Ftype + 1), @iter@MDVC)                                     ;  MD VDF
  @iter@NTVDF = VCRV((Ftype + 1), @iter@NTVC)                                     ;  NT VDF

  @iter@AMSPD = @iter@AMFFSPD                                                     ;  AM restrained speed
  @iter@PMSPD = @iter@PMFFSPD                                                     ;  PM restrained speed
  @iter@MDSPD = @iter@MDFFSPD                                                     ;  MD restrained speed
  @iter@NTSPD = @iter@NTFFSPD                                                     ;  NT restrained speed

  if (@iter@AMVDF > 0)  @iter@AMSPD = @iter@AMFFSPD / @iter@AMVDF                 ;  AM restrained speed
  if (@iter@PMVDF > 0)  @iter@PMSPD = @iter@PMFFSPD / @iter@PMVDF                 ;  PM restrained speed
  if (@iter@MDVDF > 0)  @iter@MDSPD = @iter@MDFFSPD / @iter@MDVDF                 ;  MD restrained speed
  if (@iter@NTVDF > 0)  @iter@NTSPD = @iter@NTFFSPD / @iter@NTVDF                 ;  NT restrained speed

  _ATYPE=SPDCLASS%10                                                              ; Area Type
  _cnt = 1.0
  ;

  ;; debug section   - select some links to check with ;;
    IF (li.1.a =1-13,23000-23100,33000-33200)
     print form=5.2  list = a(6), b(6),
           ' AM_Prev_Vol >  ', _@prev@AMVol,
           ' AM_Prev_Shr >  ', _@prev@_VOL_Shr,
           ' AM_Curr_Vol >  ', _@iter@AMVol,
           ' AM_Curr_Shr >  ', _@iter@_VOL_shr,
           ' AMAvgVOL    >  ',  @iter@AMVOL,
           ' AMLnkCap    >  ',  AMHRLKCAP,
           ' AMVC        >  ',  @iter@AMVC,
           ' AMVDF       >  ',  @iter@AMVDF,
           ' AMSpd       >  ',  @iter@AMSPD,

           ' PM_Prev_Vol >  ', _@prev@PMVol,
           ' PM_Prev_Shr >  ', _@prev@_VOL_Shr,
           ' PM_Curr_Vol >  ', _@iter@PMVol,
           ' PM_Curr_Shr >  ', _@iter@_VOL_shr,
           ' PMAvgVOL    >  ',  @iter@PMVOL,
           ' PMLnkCap    >  ',  PMHRLKCAP,
           ' PMVC        >  ',  @iter@PMVC,
           ' PMVDF       >  ',  @iter@PMVDF,
           ' PMSpd       >  ',  @iter@PMSPD,

           ' MD_Prev_Vol >  ', _@prev@MDVol,
           ' MD_Prev_Shr >  ', _@prev@_VOL_Shr,
           ' MD_Curr_Vol >  ', _@iter@MDVol,
           ' MD_Curr_Shr >  ', _@iter@_VOL_shr,
           ' MDAvgVOL    >  ',  @iter@MDVOL,
           ' MDLnkCap    >  ',  MDHRLKCAP,
           ' MDVC        >  ',  @iter@MDVC,
           ' MDVDF       >  ',  @iter@MDVDF,
           ' MDSpd       >  ',  @iter@MDSPD,

           ' NT_Prev_Vol >  ', _@prev@NTVol,
           ' NT_Prev_Shr >  ', _@prev@_VOL_Shr,
           ' NT_Curr_Vol >  ', _@iter@NTVol,
           ' NT_Curr_Shr >  ', _@iter@_VOL_shr,
           ' NTAvgVOL    >  ',  @iter@NTVOL,
           ' NTLnkCap    >  ',  NTHRLKCAP,
           ' NTVC        >  ',  @iter@NTVC,
           ' NTVDF       >  ',  @iter@NTVDF,
           ' NTSpd       >  ',  @iter@NTSPD,

             file= outputs\hwy_net\@iter@_Average_Link_Speeds.txt

    ENDIF



;;compute WEIGHTED restrained and freeflow SPEEDS for Aggregate summaries

   _AMWRSPD =ROUND(@iter@AMVMT * @iter@AMSPD)
   _AMWFFSPD=ROUND(@iter@AMVMT * @iter@AMFFSPD)

   _PMWRSPD =ROUND(@iter@PMVMT * @iter@PMSPD)
   _PMWFFSPD=ROUND(@iter@PMVMT * @iter@PMFFSPD)

   _MDWRSPD =ROUND(@iter@MDVMT * @iter@MDSPD)
   _MDWFFSPD=ROUND(@iter@MDVMT * @iter@MDFFSPD)

   _NTWRSPD =ROUND(@iter@NTVMT * @iter@NTSPD)
   _NTWFFSPD=ROUND(@iter@NTVMT * @iter@NTFFSPD)

;;=================================================================================
;;  AM X-Tabs
;;=================================================================================
;;  Crosstab AM  VMT,Weighted Restrained Speed, Weighted FF Speed by JUR and FTYPE
    CROSSTAB VAR=@iter@AMVMT,_AMWRSPD,_AMWFFSPD, FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_AMWRSPD/@iter@AMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_AMWFFSPD/@iter@AMVMT, FORM=12.2cs     ; AVG FINAL SPD

;;  Crosstab AM  VMT,Weighted Restrained Speed, Weighted FF Speed by ATYPE and FTYPE
     CROSSTAB VAR=@iter@AMVMT,_AMWRSPD,_AMWFFSPD, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_AMWRSPD/@iter@AMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_AMWFFSPD/@iter@AMVMT, FORM=12.2cs     ; AVG FINAL SPD


;;  Crosstab AM  VMT,Weighted Restrained Speed, Weighted FF Speed by AM V/C and FTYPE
     CROSSTAB VAR=@iter@AMVMT,_AMWRSPD,_AMWFFSPD, FORM=12cs,
     ROW=@iter@AMVC, RANGE=0-2-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_AMWRSPD/@iter@AMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_AMWFFSPD/@iter@AMVMT, FORM=12.2cs     ; AVG FINAL SPD

;;
;;=================================================================================
;;  PM X-Tabs
;;=================================================================================
;;  Crosstab PM  VMT,Weighted Restrained Speed, Weighted FF Speed by JUR and FTYPE
    CROSSTAB VAR=@iter@PMVMT,_PMWRSPD,_PMWFFSPD, FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_PMWRSPD/@iter@PMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_PMWFFSPD/@iter@PMVMT, FORM=12.2cs     ; AVG FINAL SPD

;;  Crosstab PM  VMT,Weighted Restrained Speed, Weighted FF Speed by ATYPE and FTYPE
     CROSSTAB VAR=@iter@PMVMT,_PMWRSPD,_PMWFFSPD, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_PMWRSPD/@iter@PMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_PMWFFSPD/@iter@PMVMT, FORM=12.2cs     ; AVG FINAL SPD


;;  Crosstab PM  VMT,Weighted Restrained Speed, Weighted FF Speed by AM V/C and FTYPE
     CROSSTAB VAR=@iter@PMVMT,_PMWRSPD,_PMWFFSPD, FORM=12cs,
     ROW=@iter@PMVC, RANGE=0-2-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_PMWRSPD/@iter@PMVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_PMWFFSPD/@iter@PMVMT, FORM=12.2cs     ; AVG FINAL SPD

;;
;;=================================================================================
;;  MD X-Tabs
;;=================================================================================
;;  Crosstab MD  VMT,Weighted Restrained Speed, Weighted FF Speed by JUR and FTYPE
    CROSSTAB VAR=@iter@MDVMT,_MDWRSPD,_MDWFFSPD, FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_MDWRSPD/@iter@MDVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_MDWFFSPD/@iter@MDVMT, FORM=12.2cs     ; AVG FINAL SPD

;;  Crosstab MD  VMT,Weighted Restrained Speed, Weighted FF Speed by ATYPE and FTYPE
     CROSSTAB VAR=@iter@MDVMT,_MDWRSPD,_MDWFFSPD, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_MDWRSPD/@iter@MDVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_MDWFFSPD/@iter@MDVMT, FORM=12.2cs     ; AVG FINAL SPD


;;  Crosstab MD  VMT,Weighted Restrained Speed, Weighted FF Speed by AM V/C and FTYPE
     CROSSTAB VAR=@iter@MDVMT,_MDWRSPD,_MDWFFSPD, FORM=12cs,
     ROW=@iter@MDVC, RANGE=0-2-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_MDWRSPD/@iter@MDVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_MDWFFSPD/@iter@MDVMT, FORM=12.2cs     ; AVG FINAL SPD

;;
;;=================================================================================
;;  NT X-Tabs
;;=================================================================================
;;  Crosstab NT  VMT,Weighted Restrained Speed, Weighted FF Speed by JUR and FTYPE
    CROSSTAB VAR=@iter@NTVMT,_NTWRSPD,_NTWFFSPD, FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_NTWRSPD/@iter@NTVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_NTWFFSPD/@iter@NTVMT, FORM=12.2cs     ; AVG FINAL SPD

;;  Crosstab NT  VMT,Weighted Restrained Speed, Weighted FF Speed by ATYPE and FTYPE
     CROSSTAB VAR=@iter@NTVMT,_NTWRSPD,_NTWFFSPD, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_NTWRSPD/@iter@NTVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_NTWFFSPD/@iter@NTVMT, FORM=12.2cs     ; AVG FINAL SPD


;;  Crosstab NT  VMT,Weighted Restrained Speed, Weighted FF Speed by AM V/C and FTYPE
     CROSSTAB VAR=@iter@NTVMT,_NTWRSPD,_NTWFFSPD, FORM=12cs,
     ROW=@iter@NTVC, RANGE=0-2-0.1,,1-99,
     COL=FTYPE, RANGE=1-6-1,1-6,
     COMP=_NTWRSPD/@iter@NTVMT,  FORM=12.2cs,    ; AVG INITIAL SPD
     COMP=_NTWFFSPD/@iter@NTVMT, FORM=12.2cs     ; AVG FINAL SPD


;;
;;=================================================================================
;; DAILY X-Tabs
;;=================================================================================
;;  Crosstab DAILY  VMT by JUR and FTYPE
    CROSSTAB VAR=@iter@24VMT,  FORM=12cs,
     ROW=JUR,   RANGE=0-23-1,,0-23,
     COL=FTYPE, RANGE=1-6-1,1-6

;;  Crosstab DAILY VMT by ATYPE and FTYPE
     CROSSTAB VAR=@iter@24VMT, FORM=12cs,
     ROW=ATYPE, RANGE=1-7-1,,1-7,
     COL=FTYPE, RANGE=1-6-1,1-6


ENDRUN
