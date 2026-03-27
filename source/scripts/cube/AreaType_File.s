; AreaType_File.S
;
;=========================================================================
;  Accumulate zonal HHs and Jobs  around each TAZ based on 1.0 mile
;  straightline distances between centroids, and then develop area types
;  for each TAZ
;;========================================================================
;
;
; Read land use zonal file in the csv format and save it dbf format

ZnFile_In  = 'inputs\landuse\land_use.csv'  ;Input Zonal data file in the CSV format
ZnFile_Out  = 'outputs\landuse\ZONE.dbf'  ;Input Zonal data file in the CSV format

RUN PGM=MATRIX

FILEI ZDATI[1] = @ZnFile_In@, Z = #1, HH = #2, HHPOP = #3, GQPOP = #4, TOTPOP = #5, TOTEMP = #6, INDEMP = #7, RETEMP = #8, OFFEMP = #9, 
  OTHEMP = #10, JURCODE = #11, LANDAREA = #12, TAZXCRD = #13, TAZYCRD = #14, K_8 = #15, G9_12 = #16,
  COLLEGE = #17, Park_Acres = #18, GC_Acres = #19, PRKCST = #20, OPRKCST = #21, TERMINAL = #22, AREATYPE = #23
FILEO RECO[1] = @ZnFile_Out@ FIELDS = TAZ(10.0), HH(10.0), HHPOP(10.0), GQPOP(10.0), TOTPOP(10.0), TOTEMP(10.0), INDEMP(10.0), RETEMP(10.0), OFFEMP(10.0), 
  OTHEMP(10.0), JURCODE(10.0), LANDAREA(10.4), HHINCIDX(10.0), ADISTTOX(10.2), TAZXCRD(10.0), TAZYCRD(10.0), K_8(10.0), G9_12(10.0),
  COLLEGE(10.0), Park_Acres(10.6), GC_Acres(10.6), PRKCST(10.3), OPRKCST(10.0), TERMINAL(10.0), AREATYPE(10.0)
  
PAR ZONES = 3675

RO.TAZ = I
RO.HH = ZI.1.HH
RO.HHPOP = ZI.1.HHPOP
RO.GQPOP = ZI.1.GQPOP
RO.TOTPOP = ZI.1.TOTPOP
RO.TOTEMP = ZI.1.TOTEMP
RO.INDEMP = ZI.1.INDEMP
RO.RETEMP = ZI.1.RETEMP
RO.OFFEMP = ZI.1.OFFEMP
RO.OTHEMP = ZI.1.OTHEMP
RO.JURCODE = ZI.1.JURCODE
RO.LANDAREA = ZI.1.LANDAREA
RO.TAZXCRD = ZI.1.TAZXCRD
RO.TAZYCRD = ZI.1.TAZYCRD
RO.K_8 = ZI.1.K_8
RO.G9_12 = ZI.1.G9_12
RO.COLLEGE = ZI.1.COLLEGE
RO.Park_Acres = ZI.1.Park_Acres
RO.GC_Acres = ZI.1.GC_Acres
RO.PRKCST = ZI.1.PRKCST
RO.OPRKCST = ZI.1.OPRKCST
RO.TERMINAL = ZI.1.TERMINAL
RO.AREATYPE = ZI.1.AREATYPE
WRITE RECO=1
ENDRUN

;Define Inputs Files:
nodefile='inputs\hwy\node.dbf'
LUFile  ='outputs\landuse\ZONE.dbf'
ATover  ='inputs\landuse\AT_override.txt'

;Output Files:
TAZxys  = 'outputs\landuse\TAZ_XYs.dbf'
FloatLU = 'outputs\landuse\Floating_LU.dbf'
ATFile  = 'outputs\landuse\AreaType_File.dbf'


RUN PGM=MATRIX

ZONES=1

FILEI DBI[1]  = "@nodefile@", sort = N
FILEO RECO[1] = "@TAZxys@", Fields = N(5),X(10),Y(10)

 LOOP L= 1,dbi.1.NUMRECORDS
         x=DBIReadRecord(1,L)
         if (DI.1.N <= 3722 )
            ro.N  = di.1.N         ; Node Number
            ro.X  = di.1.X         ; X-Coordinate (feet NAD/83)
            ro.Y  = di.1.Y         ; Y-Coordinate (feet NAD/83)
            WRITE RECO=1 ;
         endif
ENDLOOP
ENDRUN

;--------------------------------------------------------------------------------

 RUN PGM=MATRIX
 ZONES=1

 FILEO RECO[1]    = "@FloatLU@",
                     fields = TAZ(5),HH00(10),POP00(10),EMP00(10),AREA00(10.4),
                                     HH10(10),POP10(10),EMP10(10),AREA10(10.4)


 FileI LOOKUPI[1] = "@TAZxys@"
 LOOKUP LOOKUPI=1, NAME=tazxys,
        LOOKUP[1] = N, RESULT=x,   ;                                                                                                                                                                                                                     a2
        LOOKUP[2] = N, RESULT=y,   ;                                                                                                                                                                                                                     a2
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

 FileI LOOKUPI[2] = "@LUFILE@"
 LOOKUP LOOKUPI=2, NAME=Landuse,
        LOOKUP[1] = taz, RESULT= HH,
        LOOKUP[2] = taz, RESULT= TOTPOP,
        LOOKUP[3] = taz, RESULT= TOTEMP,
        LOOKUP[4] = taz, RESULT= landarea,
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

ARRAY HH00     =3722, HH10     =3722,
      POP00    =3722, POP10    =3722,
      EMP00    =3722, EMP10    =3722,
      AREA00   =3722, AREA10   =3722


 LOOP L = 1,3675  ;  Loop through each zone
   Xi      = tazxys(1,L)
   Yi      = tazxys(2,L)
   IF (Xi  = 0.00)  Continue


      LOOP M= 1,3675  ; Loop through all proximate zones
           Xj      = tazxys(1,M)
           Yj      = tazxys(2,M)
           IF (Xj  = 0.00)  Continue

           Xdiff   = abs(Xi-Xj)
           Ydiff   = abs(Yi-Yj)

           d_ft    = sqrt(xdiff*xdiff + Ydiff*Ydiff)
           d_mi    = d_ft/5280.0

           IF (d_mi >= 1.000)  Continue
           ;debug1
           If (l=1)
                print form=10  list = l,m,xi,yi,xj,yj,d_ft,d_mi(6.2), file=outputs\reports\debug1.txt
           endif
           ;debug1


           IF    (D_mi <  1.000)
                 HH10[L]      = HH10[L]         +  Landuse(1,m)
                 POP10[L]     = POP10[L]        +  Landuse(2,m)
                 EMP10[L]     = EMP10[L]        +  Landuse(3,m)
                 AREA10[L]    = AREA10[L]       +  Landuse(4,m)
           ENDIF

           IF    (D_mi =  0.000)
                 HH00[L]      = HH00[L]         +  Landuse(1,m)
                 POP00[L]     = POP00[L]        +  Landuse(2,m)
                 EMP00[L]     = EMP00[L]        +  Landuse(3,m)
                 AREA00[L]    = AREA00[L]       +  Landuse(4,m)
           ENDIF
           ;debug2
           If (L=1)
                     print form=8.2  list = l,m, d_mi(6.2),
                     HH00[L],POP00[L],EMP00[L],AREA00[L],
                     HH10[L],POP10[L],EMP10[L],AREA10[L],
                     file=outputs\reports\debug2.txt
           endif
           ;debug2
       ENDLOOP

 ENDLOOP


LOOP M= 1, 3675
        ro.TAZ      = M

        ro.HH00     = HH00[M]
        ro.POP00    = POP00[M]
        ro.EMP00    = EMP00[M]
        ro.AREA00   = AREA00[M]

        ro.HH10     = HH10[M]
        ro.POP10    = POP10[M]
        ro.EMP10    = EMP10[M]
        ro.AREA10   = AREA10[M]

        WRITE RECO= 1

 ENDLOOP
 endrun

;;========================================================================
;  Compute Area Type  based on updated 1-mile floating Pop/Emp density
;  doucumented by M. Martchouk on June 10, 2010
;;========================================================================
;

 RUN PGM=MATRIX
 ZONES=1

 FILEO RECO[1]    = "@ATFile@",fields =
                     TAZ(5), POP_10(10.0), EMP_10(10.0), area_10(10.2),
                             POPden(10.2), Empden(10.2),
                             POPcode(5),   EMPcode(5),
                             Atype(5)


 FileI LOOKUPI[1] = "@FloatLU@"      ; One-mile floating land use
 LOOKUP LOOKUPI=1, NAME=PopEmpArea10,
        LOOKUP[1] = TAZ, RESULT=POP10,     ;                                                                                                                                                                                                                     a2
        LOOKUP[2] = TAZ, RESULT=EMP10,     ;                                                                                                                                                                                                                     a2
        LOOKUP[3] = TAZ, RESULT=Area10,    ;                                                                                                                                                                                                                     a2
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N

;; Read in Area Type override file:
 LOOKUP NAME=ATover,
        LOOKUP[1] = 1, RESULT=2,   ;  TAZ & Area Type overide no. 1-6                                                                                                                                                                                                                   a2
        INTERPOLATE=N, FAIL= 0,0,0, LIST=Y, File= @ATover@


ARRAY ATYPEMtx = 7,7  EmpClassDen=6     POPClassDen=6  , atcount= 7

;; Define Area type code matrix
   ATYPEMtx[1][1]=6  ATYPEMtx[1][2]=6 ATYPEMtx[1][3]=5 ATYPEMtx[1][4]=3 ATYPEMtx[1][5]=3 ATYPEMtx[1][6]=3  ATYPEMtx[1][7]=2
   ATYPEMtx[2][1]=6  ATYPEMtx[2][2]=5 ATYPEMtx[2][3]=5 ATYPEMtx[2][4]=3 ATYPEMtx[2][5]=3 ATYPEMtx[2][6]=3  ATYPEMtx[2][7]=2
   ATYPEMtx[3][1]=6  ATYPEMtx[3][2]=5 ATYPEMtx[3][3]=5 ATYPEMtx[3][4]=3 ATYPEMtx[3][5]=3 ATYPEMtx[3][6]=2  ATYPEMtx[3][7]=2
   ATYPEMtx[4][1]=6  ATYPEMtx[4][2]=4 ATYPEMtx[4][3]=4 ATYPEMtx[4][4]=3 ATYPEMtx[4][5]=2 ATYPEMtx[4][6]=2  ATYPEMtx[4][7]=1
   ATYPEMtx[5][1]=4  ATYPEMtx[5][2]=4 ATYPEMtx[5][3]=4 ATYPEMtx[5][4]=2 ATYPEMtx[5][5]=2 ATYPEMtx[5][6]=2  ATYPEMtx[5][7]=1
   ATYPEMtx[6][1]=4  ATYPEMtx[6][2]=4 ATYPEMtx[6][3]=4 ATYPEMtx[6][4]=2 ATYPEMtx[6][5]=2 ATYPEMtx[6][6]=2  ATYPEMtx[6][7]=1
   ATYPEMtx[7][1]=2  ATYPEMtx[7][2]=2 ATYPEMtx[7][3]=2 ATYPEMtx[7][4]=2 ATYPEMtx[7][5]=2 ATYPEMtx[7][6]=1  ATYPEMtx[7][7]=1

;; Define top end of pop, emp. density ranges for classes 1-6
   PopClassDen[1] =     750.0
   PopClassDen[2] =    1500.0
   PopClassDen[3] =    3500.0
   PopClassDen[4] =    6000.0
   PopClassDen[5] =   10000.0
   PopClassDen[6] =   15000.0


   EmpClassDen[1] =     100.0
   EmpClassDen[2] =     350.0
   EmpClassDen[3] =    1500.0
   EmpClassDen[4] =    3550.0
   EmpClassDen[5] =   13750.0
   EmpClassDen[6] =   15000.0





  LOOP L = 1,3675  ;  Loop through each zone, read one-mile floating land use, area

      _pop         = PopEmpArea10(1,L)
      _emp         = PopEmpArea10(2,L)
      _area        = PopEmpArea10(3,L)

      IF (_area > 0)  _popden    = Round(_pop/_area)    ; calc. densities
      IF (_area > 0)  _empden    = Round(_emp/_area)    ;


        popcode  = 1                                    ; initialize density classes
        empcode  = 1                                    ;

         LOOP M= 1,6   ; slot TAZ into the higher pop/emp density classes as appropriate

              IF (_popden > PopClassDen[M]) Popcode = M + 1.0
              IF (_empden > EmpClassDen[M]) Empcode = M + 1.0

         ENDLOOP

         IF (popcode < 0 || popcode > 7) abort
         IF (empcode < 0 || empcode > 7) abort

         _Atype = AtypeMtx[PopCode][EmpCode]

         ;;  Impose Area type override if necessary
         ;;  From file: inputs\AT_override.txt which contains two columns, TAZ and Area Type Override (1-6)

             IF (ATover(1,L) > 0)

                 IF (ATover(1,L) < 0 || ATover(1,L) > 6) abort ;; make sure override value is reasonable
                _Atype = ATover(1,L)

             ENDIF
         ;;

         atcount[_Atype] = atcount[_Atype] + 1.0
         totcnt          = totcnt          + 1.0

         Ro.TAZ     = L
         Ro.POP_10  = _pop
         Ro.EMP_10  = _emp
         Ro.area_10 = _area
         Ro.POPden  = _popden
         Ro.Empden  = _empden
         Ro.POPcode = POPCode
         RO.EMPcode = EmpCode
         RO.Atype   = _Atype
         WRITE RECO=1


  ENDLOOP

  loop kk= 1,6
       print list= 'area type ', kk(5), ' TAZ Count is: ', atcount[KK](6.0), file = outputs\landuse\AreaType_File.txt
  endloop
       print list= 'total     ','     ',' TAZ Count is: ', totcnt(6.0),     file = outputs\landuse\AreaType_File.txt

 endrun

