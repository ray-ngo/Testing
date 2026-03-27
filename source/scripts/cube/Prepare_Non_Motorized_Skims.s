;///////////////////////////////////////////////////////////;
;  Prepare_non_motorized_skims.S                                     //;
;  MWCOG Version 2.4_PT Model                                        //;
;                                                                    //;
;  Develop a highway network with sidewalk links using a similar     //;
;  process as in the walkacc.s script. Build shortest paths on       //;
;  this network using sidewalk links only and skim the distances     //;
;  on the paths. Walk time and bike time are then calculated         //;
;  assuming a uniform walking speed of 3 mph and a bike              //;
;  speed of 10 mph.                                                  //;

; 2/23/21 created by fxie
;//////////////////////////////////////////////////////////////////////;
;
;
;
pageheight=32767  ; Preclude header breaks

nm_skim     = 'outputs\skims\HWY_Non_Motorized.SKM'

K        = 4  ; This variable is used to calculate average distance to K nearest zones
			  ; Intrazonal_dist = Factor * mean (distance to K nearest zones) 
			  ; Where Factor is typically 0.5 and K is 3 or 4. (we chose 4) 
			  

RUN PGM=NETWORK
;
  NETI   =outputs\hwy_net\PP_HWY.NET             
  NETO   =outputs\hwy_net\PP_HWY_WALK.NET, INCLUDE=A,B,DISTANCE,WKLINK

  FileI LOOKUPI[1]= "inputs\hwy\Xtrawalk.txt"
  LOOKUP LOOKUPI=1, NAME=ADDWALK,
	LOOKUP[1]= 1, result=2,
	INTERPOLATE=N, FAIL= 0,0,0, LIST=N
		

  
  WKLINK=1

  ; No walking on freeway or expressway links
  IF(FTYPE=1,5,6) WKLINK=0 

  ; Add/remove walk links according to "Xtrawalk.dbf"

  ABPAIR=A*1000000 + B
  
  ADD=ADDWALK(1,ABPAIR)
  
  IF (ADD=1)
		WKLINK=1
  ELSEIF(ADD=9)
		WKLINK=0
  ENDIF
  
; The sidewalk links developed in the walkacc.s script also exclude
; links of which the corresponding TAZ has a 0 percent walk to transit.
; walkacc.s develops sidewalk links for building walk access transit paths and 
; thus it is reasonable to exclude those links located in zones with no walk access
; to transit. Those links, however, could be used here for walking/biking trips.

ENDRUN


RUN PGM=HIGHWAY
;
  NETI   =outputs\hwy_net\PP_HWY_WALK.NET             
  MATO[1]="@nm_skim@", MO=1-4, NAME=WKDIST10,WKTM,BKDIST10,BKTM
;

  PHASE=LINKREAD
  
  LW.DISTANCE=LI.DISTANCE
  
  IF (LI.WKLINK = 0)   ADDTOGROUP=1 ; prohibited links
;
  ENDPHASE
;


  PHASE=ILOOP



     PATHLOAD PATH=LW.DISTANCE, EXCLUDEGRP=1,              
              MW[1] =PATHTRACE(LW.DISTANCE),               NOACCESS=0	; distance


	; Calculate average distance to K nearest zones
	; Intrazonal_dist = Factor * mean (distance to K nearest zones) 
	; Where Factor is typically 0.5 and K is 3 or 4. (we chose 4) 	
	INTRAZONAL MW[1] = 0.5 * LOWEST(1, @K@, 0.01, 99999)/@K@

;----------------------------------------------------------------------
; scaling, rounding of skim tables done here!!
;----------------------------------------------------------------------
     mw[1] = ROUND(MW[1]*10)                    ; Consistent with highway skims FACTOR/ROUND DIST in tenths of miles
     mw[2] = (mw[1]/10)/3*60					; walk time in minutes assuming a uniform speed of 3 mph
     mw[3] = mw[1]								; with the assumption of uniform walking/biking speeds, walk/bike distance skims
											    ; would be identical as they're both skimmed on the shortest-distance path 	 
     mw[4] = (mw[3]/10)/10*60                   ; bike time in minutes assuming a uniform speed of 10 mph

;;
;----------------------------------------------------------------------
; Print selected rows of skim files
; for checking.
;----------------------------------------------------------------------


     IF (i = 1-2)                        ;  for select rows (Is)
         printrow MW=1-4, j=1-3722       ;  print work matrices 1-3
     ENDIF                               ;  row value to all Js.
  ENDPHASE
ENDRUN

