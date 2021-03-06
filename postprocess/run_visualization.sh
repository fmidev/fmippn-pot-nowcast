#!/bin/bash
if [ ! $VISUALDIR ]; then
   export PROCTIME=${PROCTIME:-"$1"}
   shift
   source ~/fmippn-oper/config/set_common_config.sh
fi
source $CONFDIR/common_functions.sh

cd $POSTPROCDIR
BIN=${POSTPROCDIR}/bin

set_BeginTime
echo "Visualization start $BeginStamp"

if [ "$DOMAIN" == "ravake" ]; then

   export SUOMI_ARGPATH=${POSTPROCDIR}/config
   export SUOMI_RAINCLASSES=${SUOMI_ARGPATH}/rainclasses.txt

   INH5=$1
   ORIGMINS=${TIMESTAMP:10}
   if [ $TESTVIS ]; then
      WWWDIR=${VISUALDIR}/ppn
      VERDIR=${VISUALDIR}/ppnverif
   else
      WWWDIR=/mnt/meru/data/prod/radman/ppn
      VERDIR=/mnt/meru/data/prod/radman/ppnverif
   fi

   cd $VISUALDIR
   rm *.p?m

   for MZ in `ls -1 $INTERPDIR/EnsmeandBZ_${TIMESTAMP}-???????????{0,5}+*.pgm` ; do
      TIMES=`basename -s .pgm ${MZ#*_} | cut -d+ -f1`
      NOWCMIN=${TIMES:24:1}

      SUOMI_MEAN=M_"$TIMES"_SUOMI1_dBZ.pgm
      pamcut 200 400 760 1226 $MZ > $SUOMI_MEAN
      $BIN/gdmap $SUOMI_MEAN ${SUOMI_MEAN%.*}.ppm 'PPN ensemble mean dBZ'
      echo "Ret $?"
      pamtogif ${SUOMI_MEAN%.*}.ppm > ${SUOMI_MEAN%.*}.gif

      SUOMI_DETERM=D_"$TIMES"_SUOMI1_dBZ.pgm
      DZ=$INTERPDIR/dBZ_M00_"$TIMES"00.pgm
      if [ -e $DZ ]; then
         pamcut 200 400 760 1226 $DZ > $SUOMI_DETERM
         $BIN/gdmap $SUOMI_DETERM ${SUOMI_DETERM%.*}.ppm 'PPN deterministic dBZ'
         pamtogif ${SUOMI_DETERM%.*}.ppm > ${SUOMI_DETERM%.*}.gif
      fi

      echo $TIMES

      if [ "$ORIGMINS" == "00" ] || [ "$ORIGMINS" == "30" ]; then
         DOLOOP=1
         if [ "$NOWCMIN" == "0" ]; then
            TUL=`ls -1 /mnt/meru/data/prod/radman/fmi/prod/run/fmi/radar/tuliset/pic/G_"$TIMES".gif`
            if [ "$TUL" != "" ]; then
               if [ -e $DZ ]; then
                  montage -tile x1 -geometry 100% -border 3x3 -background black -frame 0 $TUL ${SUOMI_DETERM%.*}.gif ${SUOMI_MEAN%.*}.gif "$TIMES"_TULISET+PPN.gif
               fi
            fi
         fi
      fi
   done

   if [ $DOLOOP ]; then
      ANIM="$TIMESTAMP"_TULISET+PPN_anim.gif 
      convert -loop 0 -delay 20 "$TIMESTAMP"-*_TULISET+PPN.gif $ANIM 
      cp $ANIM $WWWDIR
      unlink $WWWDIR/latest.gif 
      ln -s $WWWDIR/$ANIM $WWWDIR/latest.gif 
      find $WWWDIR -name '*_anim.gif' -mmin +1100 -exec rm -f {} \; &
   fi

   find . -name '*.gif' -mmin +360 -exec rm -f {} \;

   # Verification: Observer dBZ vs. PPN deterministic dBZ

   OBSNOWC=`ls -1tr D_*-"$TIMESTAMP"_SUOMI1_dBZ.gif | head -1`
   OBSTIMESTAMP=`echo $OBSNOWC | cut -d_ -f2 | cut -d- -f1`
   for DETFILE in D_"$OBSTIMESTAMP"-*.gif ; do
      OBSTIME=`echo $DETFILE | cut -d_ -f2 | cut -d- -f2`
      OBSFILE=/mnt/meru/data/prod/radman/latest/fmi/radar/iris/finland1/"$OBSTIME"_fmi.radar.iris.finland1.gif
      # montage of obs vs. determ
      if [ -e $OBSFILE ]; then
         montage -geometry 100% -border 3x3 -background black -frame 0 $OBSFILE $DETFILE "$OBSTIMESTAMP"-"$OBSTIME"_OBS+DETERM.gif
      fi
   done

   # animation of obs vs. determ
   ANIM="$OBSTIMESTAMP"_OBS+DETERM_anim.gif 
   convert -loop 0 -delay 20 "$OBSTIMESTAMP"-*_OBS+DETERM.gif $ANIM
   cp $ANIM $VERDIR
   unlink $VERDIR/latest_verif.gif 
   ln -s $VERDIR/$ANIM $VERDIR/latest_verif.gif 
   find $VERDIR -name '*_anim.gif' -mmin +1100 -exec rm -f {} \; &

fi

get_Runtime
echo "Visualization end $EndStamp"
echo "Visualization runtime $Runtime s"
 
exit
