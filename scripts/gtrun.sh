#!/bin/bash
source ~/.bashrc
# ----------------------------------------------------------------
# ----------- BEGIN SETTINGS -------------------------------------
# ----------------------------------------------------------------
# IDENTICAL TO SETTINGS IN MAKE_MODEL.PY
obj=3c120
anadir=/home/mjaniak/fermi/3c120/analysis
anaid=global_r10
# energies
# array=( "100.00"  "199.53"  "398.11"  "794.33"  "1584.89"  "3162.28"  "6309.57"  "12589.25"  "25118.86"  "50118.72"  "100000.00"  )
array=( "100.00" "100000.00"  )
# ----------------------------------------------------------------
# FERMI DATA USED
datalist=/home/mjaniak/fermi/${obj}/data/${obj}.datalist
scfile=/home/mjaniak/fermi/3c120/data/L130523115609CDAE506B31_SC00.fits
# ----------------------------------------------------------------
GTTEMPLATE=/home/mjaniak/fermi/3c120/analysis/scripts/gttemplate.sh
enumbins=4 # energy bins per global energy bin - in total at least 30 per 100-100000GeV
# coordinates
coordsys='CEL'
xref=68.30
yref=5.35
rad=15
# spatial resolution
binsz=0.2
# gtbin CMAP
# ROI is r then diameter is 2r -> nx(y)pixCMAP = 2r/binsz
# r nx(y)pixCMAP
# |---------+-----+-----+-----+-----+------+------|
# |    CMAP |     |     |     |     |      |      |
# |---------+-----+-----+-----+-----+------+------|
# | r/binsz |   5 |  10 |  15 |  20 |   25 |   30 |
# |---------+-----+-----+-----+-----+------+------|
# |    0.05 | 200 | 400 | 600 | 800 | 1000 | 1200 |
# |     0.1 | 100 | 200 | 300 | 400 |  500 |  600 |
# |     0.2 |  50 | 100 | 150 | 200 |  250 |  300 |
# |     0.3 |  34 |  67 | 100 | 134 |  167 |  200 |
# |     0.4 |  25 |  50 | 150 | 200 |  250 |  300 |
# |---------+-----+-----+-----+-----+------+------|
nxpixCMAP=150
nypixCMAP=150
# gtbin CCUBE
# s = r*1.4242
# |---------------+-----+-----+-----+-----+-----+-----|
# |         CCUBE |     |     |     |     |     |     |
# |---------------+-----+-----+-----+-----+-----+-----|
# |             r |   5 |  10 |  15 |  20 |  25 |  30 |
# |---------------+-----+-----+-----+-----+-----+-----|
# | s(diam)/binsz |   7 |  14 |  20 |  28 |  35 |  40 |
# |---------------+-----+-----+-----+-----+-----+-----|
# |          0.05 | 140 | 280 | 400 | 560 | 700 | 800 |
# |           0.1 |  70 | 140 | 200 | 280 | 350 | 400 |
# |           0.2 |  35 |  70 | 100 | 140 | 175 | 200 |
# |           0.3 |  23 |  46 |  66 |  93 | 116 | 133 |
# |           0.4 |  17 |  35 |  50 |  70 |  87 | 100 |
# |---------------+-----+-----+-----+-----+-----+-----|
nxpixCCUBE=100
nypixCCUBE=100
# gtexpcube2 - all sky
nxpixALLSKY=1800
nypixALLSKY=900
irfs='P7SOURCE_V6'
# ----------------------------------------------------------------
# MODEL - RUN MAKE_MODEL.PY FIRST TO CREATE MODEL FILE
srcmodelname=3c120_binned_model
srcmodel=${anadir}/${anaid}/${srcmodelname}.xml
# gtlike
opt1='DRMNGB'
opt2='NEWMINUIT'
# ----------------------------------------------------------------
option=$1
# ----------------------------------------------------------------
# ----------- END SETTINGS ---------------------------------------
# ----------------------------------------------------------------

if [ ! -n "$1" ]
then
   echo "./gtrun.sh <option>"
   echo ""
   echo "  <option> select or fit or cleanfit"
   echo ""
   exit
fi
# ----------------------------------------------------------------
# PRINT INFO
echo "gtrun.sh - option ${option}"

if [ ${option} == 'select' ]; then
    echo "gtrun.sh - SELECT"
    # create analysis id directory
    mkdir -p ${anadir}/${anaid}
    # main energy loop
    QSUB=${anadir}/${anaid}/select.qsub
    echo '#!/bin/bash' > ${QSUB}
    chmod +x ${QSUB}
    for i in `seq 0 $((${#array[@]}-2))`; do
	echo "-----------------------------------------------"
	echo "Energy: " ${array[${i}]} - ${array[$((${i}+1))]}
	echo "-----------------------------------------------"
	DIR=${anadir}/${anaid}/Energy${array[${i}]}
	mkdir -p $DIR
	GTRUN=$DIR/select.sh
	cat $GTTEMPLATE | sed "s|CDPATH|$DIR|" > ${GTRUN}
        # ----------------------------------------------------------------
	# gtselect
	echo "echo \"Running gtselect ...\"" >> ${GTRUN}
	echo "gtselect infile=@${datalist} outfile=${DIR}/${obj}_filtered.fits ra=INDEF dec=INDEF rad=${rad} evclass=2 tmin=INDEF tmax=INDEF emin=${array[${i}]} emax=${array[$((${i}+1))]} zmax=100" >> ${GTRUN}
        # gtmktime
	echo "echo \"Running gtmktime ...\"" >> ${GTRUN}
	echo "gtmktime scfile=${scfile} filter=\"DATA_QUAL==1 && LAT_CONFIG==1 && ABS(ROCK_ANGLE)<52\" roicut=yes evfile=${DIR}/${obj}_filtered.fits outfile=${DIR}/${obj}_filtered_gti.fits" >> ${GTRUN}
        # gtbin CMAP
	echo "echo \"Running gtbin CMAP ...\"" >> ${GTRUN}
	echo "gtbin evfile=${DIR}/${obj}_filtered_gti.fits scfile=${scfile} outfile=${DIR}/${obj}_binned_cmap.fits algorithm=CMAP nxpix=${nxpixCMAP} nypix=${nypixCMAP} binsz=${binsz} coordsys=${coordsys} xref=${xref} yref=${yref} axisrot=0 proj=STG" >> ${GTRUN}
        # gtbin CCUBE
	echo "echo \"Running gtbin CCUBE ...\"" >> ${GTRUN}
	echo "gtbin evfile=${DIR}/${obj}_filtered_gti.fits scfile=${scfile} outfile=${DIR}/${obj}_binned_ccube.fits algorithm=CCUBE nxpix=${nxpixCCUBE} nypix=${nypixCCUBE} binsz=${binsz} coordsys=${coordsys} xref=${xref} yref=${yref} axisrot=0 proj=STG ebinalg=LOG emin=${array[${i}]} emax=${array[$((${i}+1))]} enumbins=${enumbins}" >> ${GTRUN}
        # gtltcube
	echo "echo \"Running gtltcube ...\"" >> ${GTRUN}
	echo "gtltcube evfile=${DIR}/${obj}_filtered_gti.fits scfile=${scfile} outfile=${DIR}/${obj}_binned_ltcube.fits dcostheta=0.025 binsz=1" >> ${GTRUN}
        # gtexpcube2
	echo "echo \"Running gtexpcube2 ...\"" >> ${GTRUN}
	echo "gtexpcube2 infile=${DIR}/${obj}_binned_ltcube.fits cmap=none outfile=${DIR}/${obj}_binned_expcube_allsky.fits irfs=${irfs} nxpix=${nxpixALLSKY} nypix=${nypixALLSKY} binsz=${binsz} coordsys=${coordsys} xref=${xref} yref=${yref} axisrot=0 proj=AIT emin=${array[${i}]} emax=${array[$((${i}+1))]} enumbins=${enumbins}" >> ${GTRUN}
	echo "qsub ${GTRUN}" >> ${QSUB}
    done
elif [ ${option} == 'fit' ]; then
    echo "gtrun.sh - FIT"
    # main energy loop
    QSUB=${anadir}/${anaid}/fit.qsub
    echo '#!/bin/bash' > ${QSUB}
    chmod +x ${QSUB}
    for i in `seq 0 $((${#array[@]}-2))`; do
	echo "-----------------------------------------------"
	echo "Energy: " ${array[${i}]} - ${array[$((${i}+1))]}
	echo "-----------------------------------------------"
	DIR=${anadir}/${anaid}/Energy${array[${i}]}
	mkdir -p $DIR
	GTRUN=$DIR/fit.sh
	cat $GTTEMPLATE | sed "s|CDPATH|$DIR|" > ${GTRUN}
        # ----------------------------------------------------------------	
        # gtsrcmaps
	echo "echo \"Running gtsrcmaps ...\"" >> ${GTRUN}
	echo "gtsrcmaps scfile=${scfile} expcube=${DIR}/${obj}_binned_ltcube.fits cmap=${DIR}/${obj}_binned_ccube.fits srcmdl=${srcmodel} bexpmap=${DIR}/${obj}_binned_expcube_allsky.fits outfile=${DIR}/${obj}_binned_srcmaps.fits irfs=${irfs}" >> ${GTRUN}
        # gtlike
	echo "echo \"Running gtlike ...\"" >> ${GTRUN}
	echo "gtlike irfs=${irfs} expcube=${DIR}/${obj}_binned_ltcube.fits srcmdl=${srcmodel} statistic=BINNED optimizer=${opt1} cmap=${DIR}/${obj}_binned_srcmaps.fits bexpmap=${DIR}/${obj}_binned_expcube_allsky.fits sfile=${DIR}/${srcmodelname}_${opt1}_model.xml specfile=${DIR}/${srcmodelname}_${opt1}_counts_spectra.fits results=${DIR}/${srcmodelname}_${opt1}_results.dat" >> ${GTRUN}
        # gtlike - refit
	echo "echo \"Running gtlike - refit ...\"" >> ${GTRUN}
	echo "gtlike irfs=${irfs} expcube=${DIR}/${obj}_binned_ltcube.fits srcmdl=${DIR}/${srcmodelname}_${opt1}_model.xml statistic=BINNED optimizer=${opt2} cmap=${DIR}/${obj}_binned_srcmaps.fits bexpmap=${DIR}/${obj}_binned_expcube_allsky.fits sfile=${DIR}/${srcmodelname}_${opt2}_model.xml specfile=${DIR}/${srcmodelname}_${opt2}_counts_spectra.fits results=${DIR}/${srcmodelname}_${opt2}_results.dat" >> ${GTRUN}
	echo "qsub ${GTRUN}" >> ${QSUB}
    done
elif [ ${option} == 'cleanfit' ]; then
    echo "gtrun.sh - CLEAN FIT"
    # main energy loop
    for i in `seq 0 $((${#array[@]}-2))`; do
	echo "-----------------------------------------------"
	echo "Energy: " ${array[${i}]} - ${array[$((${i}+1))]}
	echo "-----------------------------------------------"
	echo " CLEAN! "
	DIR=${anadir}/${anaid}/Energy${array[${i}]}
	rm -fv ${DIR}/${obj}_binned_srcmaps.fits
	rm -fv ${DIR}/${srcmodelname}_${opt1}_model.xml
	rm -fv ${DIR}/${srcmodelname}_${opt1}_counts_spectra.fits
	rm -fv ${DIR}/${srcmodelname}_${opt1}_results.dat
	rm -fv ${DIR}/${srcmodelname}_${opt2}_model.xml
	rm -fv ${DIR}/${srcmodelname}_${opt2}_counts_spectra.fits
	rm -fv ${DIR}/${srcmodelname}_${opt2}_results.dat
	echo "-----------------------------------------------"
    done
else
    echo "Choose 'select' or 'fit'"
    exit
fi
