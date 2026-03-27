
; ==============================================
;V2.5_PTNet_Build_Iteration.s
;RM
;Program: Build PT Network for individual iterations: 2.5
; This program is executed during I2, I3 and I4 and attaches the previous iteration highway times, speeds
; to the PT network used in skimming/assigning
; (the process is similar to the V2.5_PTNet_Build.s script used in the pp and i1 iterations)
; sko 03-09-2022 Based on fxie's update, this file follwed the change: PT_NET.NET should be built from zonehwy_unbuild.net instead of the link/node files,
;					because the facility type, number of lanes and limit codes of many centroid connectors
;                   have been updated when building zonehwy_unbuild.net in V2.3_Highway_Build.s

*del voya*.prn
*del outputs\trn_net\PT_Net.NET

RUN PGM = NETWORK
ZONES=3722

;FILEI NODEI=Inputs\hwy\NODE.dbf
;FILEI LINKI=Inputs\hwy\LINK.dbf
NETI=outputs\hwy_net\zonehwy_unbuild.net

NETO=outputs\trn_net\PT_NET.NET

ENDRUN

itr ='%_iter_%'  ; current  iteration
pre ='%_prev_%'  ; previous iteration

IF (itr  = 'i1') NETINP= 'inputs\trn\i4_Assign_Output.NET' ; loaded highway networks for speeds in the transit network
IF (itr  = 'i2') NETINP= 'outputs\hwy_net\i1_HWY.NET' ;
IF (itr  = 'i3') NETINP= 'outputs\hwy_net\i2_HWY.NET' ;
IF (itr  = 'i4') NETINP= 'outputs\hwy_net\i3_HWY.NET' ;

IF (itr  = 'i1') iterno =1
IF (itr  = 'i2') iterno =2
IF (itr  = 'i3') iterno =3
IF (itr  = 'i4') iterno =4


IF (itr  = 'i1') spdvar ='i4'
IF (itr  = 'i2') spdvar ='i1'
IF (itr  = 'i3') spdvar ='i2'
IF (itr  = 'i4') spdvar ='i3'

LOOP period = 1,4
 IF (period=1)
  PRD = 'AM'
  time = 'AM'
 ELSEIF (period=2)
  PRD = 'MD'
  time = 'MD'
 ELSEIF (period=3)
  PRD = 'PM'
  time = 'PM'
 ELSE
  PRD = 'NT'
  time = 'NT'
 



 ENDIF

	RUN PGM=NETWORK
	
  NETI[1]  = outputs\trn_net\PT_Net.NET
  NETI[2]  = @NETINP@

  NETO= outputs\trn_net\@itr@_@PRD@_PT_INI.Net include = a,b,distance,jur,screen,FTYPE,
	                                        toll,tollgrp,amlane,amlimit,pmlane,pmlimit,oplane,oplimit, edgeid,
	                                        LINKID,NETYEAR,Shape_LENG,Projectid,TRANTIME,WKTIME,MODE,
	                                        @itr@@PRD@SPD,@itr@@PRD@_HTIME
	  MERGE record = F
	
	  IF (li.1.a =li.2.a && li.1.b = li.2.b)

        @itr@@time@SPD     =  li.2.@spdvar@@time@SPD                         ; from the initial highway network (from inputs SD)
        @itr@@time@_HTIME  = (li.2.distance*60.0)/li.2.@spdvar@@time@SPD     ;
	       TRANTIME           = @itr@@time@_HTIME

   ENDIF

	
	ENDRUN

ENDLOOP






