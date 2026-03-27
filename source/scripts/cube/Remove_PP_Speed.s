;;  Remove initial 'lookup' speeds on highway links defined during hwy network building
;;  The speeds will be replaced by restrained speeds created in the 'pump prime' assignment
;;
*copy outputs\hwy_net\zonehwy.net outputs\hwy_net\zonehwy.tem
*del  outputs\hwy_net\zonehwy.net
RUN PGM=NETWORK
NETI = outputs\hwy_net\ZONEHWY.tem
NETO = outputs\hwy_net\zonehwy.net, exclude= PPAMSPD,PPPMSPD,PPMDSPD,PPNTSPD,PPOPSPD
ENDRUN
