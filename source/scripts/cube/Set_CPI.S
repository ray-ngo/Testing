;-------------------------------------------------------------------
; SET_CPI.S   Version 2.3 Model
;   Used to define Transit and Highway Deflators consistently
;
;-------------------------------------------------------------------
CPI_File        =  'INPUTS\hwy\CPI_File.TXT'   ;  Input parameters from the \INPUTS subdir.
ModeledYear     =  '%_year_%'              ;  Simulation Year (Defined in runall_ModelSteps_<year>.bat file)
;;  Two one-line files are produced:
;;                             TRN_Deflator.txt  (Transit Deflation Factor)
;;                             HWY_Deflator.txt  (Highway Deflation Factor)
;----------------------------------------------------------------------

CPI_Rept        = 'outputs\reports\MFARE2_CPI.TXT'                 ; Output Reporting file
pageheight=32767  ; Preclude header breaks
;
RUN PGM=MATRIX
ZONES=1
READ file=@CPI_File@

IF (Defl_OverRide != 0 )               ; if explicit deflation factor is provided by user
     DEFLATIONFTR  = Defl_OverRide     ; then use it, otherwise compute it using the most recent CPI table
     Print List='Deflation Factor is based on Override (Defl_OverRide)  in the CPI_File.txt file: ', DEFLATIONFTR(8.5), file=@CPI_rept@
   ELSE                                ;
;
;;
;;  Now establish the Deflation factor depending on the modeled year
;;  and available historic US BLS data
;;
       _BseCPI      = CPI_Table(1,BaseCPIYear)
       _CurCPI      = CPI_Table(1,CurrCPIYear)
       _CurCPIdefl  = CPI_Table(1,BaseCPIYear) / CPI_Table(1,CurrCPIYear)

       IF (@ModeledYear@ < BaseCPIYear)             ; Deflation ftr can't be developed if yr < 2018
           LIST = 'Modeled Year is earlier than Base Year in CPI Lookup; I Quit'
           ABORT

         ELSEIF (@ModeledYear@ = BaseCPIYear)      ; If Modeled year is Base CPI year
           _BseGrowRate = CPI_Table(2,@ModeledYear@) ;    then use the defaltion rate from table
           _AltGrowRate = CPI_Table(2,@ModeledYear@)

           _FutBseCPI   = CPI_Table(1,@ModeledYear@)
           _FutAltCPI   = CPI_Table(1,@ModeledYear@)

           DEFLATIONFTR = CPI_Table(3,@ModeledYear@)


         ELSEIF (@ModeledYear@ > BaseCPIYear && @ModeledYear@ <= CurrCPIYear)   ; If Modeled year is Base CPI year
           _BseGrowRate = CPI_Table(2,@ModeledYear@)                            ;    then use the defaltion rate from table
           _AltGrowRate = CPI_Table(2,@ModeledYear@) * INFLATIONFTR

           _FutBseCPI   = CPI_Table(1,BaseCPIYear) * ((1.0 + _BseGrowRate)^(@ModeledYear@ - BaseCPIYear))
           _FutAltCPI   = CPI_Table(1,BaseCPIYear) * ((1.0 + _AltGrowRate)^(@ModeledYear@ - BaseCPIYear))

           DEFLATIONFTR = (_FutAltCPI / _FutBseCPI)  *  CPI_Table(3,@ModeledYear@)


         ELSE
           _BseGrowRate = ( (CPI_Table(1,CurrCPIYear) / CPI_Table(1,BaseCPIYear)) ^ (1.0/ (CurrCPIYear - BaseCPIYear)) ) - 1.0
           _AltGrowRate = _BseGrowRate * INFLATIONFTR

           _FutBseCPI   = CPI_Table(1,BaseCPIYear) * ((1.0 + _BseGrowRate)^(@ModeledYear@ - BaseCPIYear))
           _FutAltCPI   = CPI_Table(1,BaseCPIYear) * ((1.0 + _AltGrowRate)^(@ModeledYear@ - BaseCPIYear))

           DEFLATIONFTR =  (_FutAltCPI / _FutBseCPI)  *  CPI_Table(3,CurrCPIYear)
        ENDIF

               ;  print out small text file containing deflation factor deriviation:
           Print List='Modeled Year:                                       ', @ModeledYear@(8.0) ,'\n',                             file=@CPI_rept@
           Print List='Base    Year & CPI:                                 ', BaseCPIYear(8.0) , _BseCPI(8.1),'\n',                 file=@CPI_rept@
           Print List='Current Year & CPI & deflator (Base CPI/Curr CPI):  ', CurrCPIYear(8.0) , _CurCPI(8.1),_CurCPIdefl(8.5),'\n',file=@CPI_rept@
           Print List='Inflation Factor Assumption (1.00 = direct CPI):    ', INFLATIONFTR(8.5),'\n',                               file=@CPI_rept@
           Print List='Modeled Year Growth rate & CPI w/  Full  CPI:    (A)', _BseGrowRate(8.5)  , _FutBseCPI(8.1),'(forecasts years only)','\n',file=@CPI_rept@
           Print List='Modeled Year growth rate & CPI w/ Infla. Factor: (B)', _AltGrowRate(8.5)  , _FutAltCPI(8.1),'(forecasts years only)','\n',file=@CPI_rept@
           Print List='Deflation Factor ((B)/(A) * Current Deflator :      ', DEFLATIONFTR(8.5)  ,                                    file=@CPI_rept@

ENDIF
          Print List = 'DEFLATIONFTR  = ', DEFLATIONFTR(8.5),'  ;; Transit Deflation Factor ',  File = outputs\reports\TRN_Deflator.txt
          Print List = 'DEFLATIONFTR  = ', DEFLATIONFTR(8.5),'  ;; Highway Deflation Factor ',  File = outputs\reports\HWY_Deflator.txt





ENDRUN
;==============================================================
; End of CPI/Deflation section                                =
;==============================================================
