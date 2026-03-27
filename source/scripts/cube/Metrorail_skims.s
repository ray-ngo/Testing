;=================================================================
;  Metrorail_skims.S
;  MWCOG Version 2.3 Model
;
;  Step 1: Build Metrorail Staion to Station Network
;  Step 2: Build Distance skims (in 1/100s mi) to be used in the
;  MFARE1 process
;  set metrorail link file to new input name
;=================================================================
; max 'zones' (stations changed from 116 to 150)

;  Global variables:

NZONES = 150           ; Max. no. of Stations
NNODES = 10000         ; Max. no. of NODES

NODIN='inputs\trn\METNODM1.TB'    ; Input Station Nodes
LNKIN='inputs\trn\METLNKM1.TB'   ; Input Station Links
DSKMO='outputs\skims\rldist.skm'     ; Output Distance Skim File
TPENS='inputs\trn\trnpen.dat'     ; Turn Penalty file


;=================================================================
; Step 1: Build Metrorail Network
;=================================================================


RUN PGM=NETWORK
;
ZONES=@NZONES@
NODES=@NNODES@

; Node Coordinate File
; XY Units are NAD83 (in whole feet)
FILEI NODEI=@NODIN@,
        VAR=N,11-14,
        VAR=X,20-27,
        VAR=Y,34-40

; Metrorail Links
FILEI LINKI=@LNKIN@,
        VAR=A,13-17,         ; A-Node Number
        VAR=B,22-26,         ; B-Node Number
        VAR=REV,35-35,       ; Reverse Code
        VAR=DISTANCE,43-47,  ; Distance in 1/100ths of Miles
        VAR=SPEED,67-71      ; Speed Value (mph)

; output network in TP+ format
NETO=outputs\trn_net\metrail.TPN
;

;=================================================================
; Step 2: Build Station Level Distance Skims
;=================================================================

RUN PGM=HIGHWAY
  NETI   =outputs\trn_net\metrail.tpn        ; Metrorail Network
  MATO[1]=@DSKMO@,MO=1,
          FORMAT=MINUTP
  TURNPENI=@TPENS@


  PHASE=LINKREAD
       SPEED   = LI.SPEED            ; Use Link Coded Speed
       DISTANCE= LI.DISTANCE / 100   ; Set Distance in 1/100ths of mi to true mi
  ENDPHASE
;
; Now create station-to-station distance skims over minimum time
; paths.  The distance skims are in 100ths of miles
; (e.g. a skim value of '145' indicates 1.45 miles)
;
;
  PHASE=ILOOP

   PATHLOAD PATH=TIME, PENI=1,  TRACE=(I=64 && J=37),

              MW[1]=PATHTRACE(LI.DISTANCE), noaccess = 0
;----------------------------------------------------------------------
; I will print selected rows of skim files
;----------------------------------------------------------------------
     IF (i = 1-2)                      ;  for select rows (Is)
         printrow MW=1, j=1-@NZONES@   ;  print work matrices 1-3
     ENDIF                             ;  row value to all Js.
   ENDPHASE
ENDRUN

