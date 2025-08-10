#!/bin/csh
# Script to plot waveforms of certain matches from rcorr
#

module load gmt
gmtset MEASURE_UNIT inch PAPER_MEDIA letter ANNOT_FONT_SIZE 10p LABEL_FONT_SIZE 12p LABEL_OFFSET 0.02i ANNOT_OFFSET_PRIMARY 0.02i ANNOT_OFFSET_SECONDARY 0.02i D_FORMAT %.12lg

# Specify a rcorr results file to use

set result=014.combine.matches.date.dy.txt
set result=400.combine.matches.date.dy.txt
set result=175.combine.matches.date.dy.txt
set result=199.combine.matches.date.dy.txt
#et result=215.combine.matches.date.dy.txt
set result=427.combine.bytemp.date.dy.txt
set result=$1.combine.matches.date.dy.txt
set result=$1.combine.bytemp.loc.date.dy.txt 
set seqnum=$result:r:r:r:r:r:r

# set temp=$result:r:r:r:r:r:e
# set sta=$result:r:r:r:r:e
# set year=$result:r:r:r:e
# set sta=HUIG

set mf=`\ls -lt match/match.$seqnum.* | awk '$5>0{print $9;exit}'`
# set sta=$mf:r:r:r:r:e
set sta=735B
set year=$mf:r:r:r:e

# @ year2 = $year + 1
# set epoch1=`echo $year-01-01 | toepoch.csh`
#  set epoch2=`echo $year2-01-01 | toepoch.csh`

if (! -e cc) mkdir cc
# Specify a data directory to use
set data=$cwd/data
# set data=/mnt/raya/rcorr/oaxaca/data

# Specify the station and channel you want to use
# set sta=PNIG
#set sta=OXIG
#set sta=HUIG

set cha=HHZ
# set cha=HHN
# set cha=HHE

# Specify the MAD threshold you want to use (15 is normal, 12 is low but can be ok)
#set cc=0
#set cc=.4
#set cc=.28
set cc=0.384
# set cc=.35
#set cc=.5
 #set cc=.6
#set cc=.8
#set cc=.73

# Specify the magnitude threshold 
set mag=0.29

# Specify the number of channels you want to require (3 is normal for one station)


# Specify the start and stop time for the waveforms in your plot (5 and 25 should be fine)

set times=( `awk -F "," 'NR>1{print $7,$8}' $seqnum.csv | minmax -C -I1 | awk '{d=int(($4-$1)/4+.5);print $1-d,$4+d*4,$4+d*5}'` )
set time1=$times[1] 
set time2=$times[2] 
set time3=$times[3] 
if ($1 == 118) set time1=3 time2=11 time3=24

# Specify the magnitude of the template event 
set tempmag=4.3

### No need to adjust things below this line

set stal=`echo $sta | awk '{print tolower($1)}'`
set chal=`echo $cha | awk '{print tolower($1)}'`

### Limit the event list by the cc and number of channels
if (! -e cc) mkdir cc



#echo $stal

if (! -e wf) mkdir wf

### WAVEFORM PROCESSING CODE BELOW, NO NEED TO CHANGE ANYTHING

echo "Getting waveforms..."

awk '$3>cc&&$6>mag{print $2}' mag=$mag cc=$cc $result | wc -l

foreach ep (`awk '$3*1>cc&&$6*1>mag{print $2}' mag=$mag cc=$cc $result`)
  if (-e wf/$sta.$cha.$ep.txt) \rm wf/$sta.$cha.$ep.txt
  echo ep=$ep
  set t1=`echo $ep | awk '{printf "%.2f", $1-1}' | /mnt/raya/bin/fromepoch.T.csh | awk '{if (substr($1,18,2) == "00") print substr($1,1,17)"01"; else print}'`
  set yj=`date -u -d "1970-01-01 + $ep sec" "+%Y.%j"`
  set yr=`date -u -d "1970-01-01 + $ep sec" "+%Y"`

  echo $data/$sta/$yr/$sta.$cha.$yj $t1 $ep
  /mnt/raya/encap/gipptools-2015.225/bin/mseedcut --output-dir=$cwd --trace-start=$t1 --trace-length=$time3 $data/$sta/$yr/$sta*$cha*$yj
  if (`\ls ${stal}*.$chal | wc -l` < 1) then
    echo "${stal}.$chal was not created"
    continue
  endif
  /mnt/raya/encap/tracedsp-0.9.8/tracedsp -od $cwd -o file.sac -RM -BP 3:8 ${stal}*.$chal
  echo "cut 0.2 $time3\nr file.sac\nw alpha file.alpha\nq" >! sac.m
  sac sac.m
  awk -f /mnt/raya/awk/sactoxy.awk file.alpha >! wf/$sta.$cha.$ep.txt
  \rm file.alpha file.sac ${stal}*.$chal
end

echo "Setting shifts..."

echo "Making plot..."
if (! -e plots) mkdir plots
# set psfile=plots/plot.wf.$temp.$year.$sta.$cha.ps
set psfile=plots/plot.wf.$result:r:r:r:r.$sta.$cha.ps
set y2=`awk '$3>cc&&$6>mag{print $2}' cc=$cc mag=$mag $result | wc -l | awk '{print $1*2+1}'`
echo 0 0 | psxy -R$time1/$time2/-1/$y2 -JX6/-9.5 -Ba5f1:"Time(s)-$seqnum":/f1Sw -K -X1.15 -P >! $psfile

echo -n "" >! mag.wf.$seqnum.$cha
# echo -n "" >! cc/seis.xyz.$temp.$year

@ n = -1
# foreach ep (`awk '$3>cc&&$6>mag{print $2}' cc=$cc mag=$mag $result`)
awk '$3==1&&$6>mag{print $2,$8,$3*1,$13}' cc=$cc mag=$mag $result >! result.in
awk '$3*1>cc&&$6*1>mag{print $2,$8,$3*1,$13}' cc=$cc mag=$mag $result >> result.in
foreach line ( "`cat result.in`" )
  set l=( $line )
  set ep=$l[1]
set shift=0
  echo $ep $l[1] $shift $l[2] $ep:e
  set file=wf/$sta.$cha.$ep.txt

  @ n ++
  set max=`awk '$1>=t1&&$2<=t2{print sqrt($2*$2)}' t1=$time1 t2=$time2 $file | awk -f /mnt/raya/awk/max.awk`
  set sps=`awk '{if (NR==1) t1=$1; else {print 1/($1-t1);exit}}' $file`
  set col=""
  if ($l[3] == 1) set col=",red"
  #if (`grep -c $l[4] $seqnum.combine.matches.full.cat`) set col=",blue"
  if (`grep -c $l[4] $result`) set col=",blue"
  \cp $file seis.xy
  if ($n == 0) then
    \cp seis.xy temp.xy
    set tempmax=$max shift=0
  endif
  set cc=`paste temp.xy seis.xy | awk '{n++;t[n]=$2/mt;s[n]=$4/m}END{for (i=-sps*6;i<sps*6;i++) { for (j=t1*sps;j<t2*sps;j++) {a=t[j]*s[j+i];c+=sqrt(a^2)} print i,c; c=0}}' m=1 mt=$tempmax t1=$time1 t2=$time2 sps=$sps  | awk -f /mnt/raya/awk/maxline.awk c=2`
  set shift=`echo $cc | awk '{print -1*$1/s}' s=$sps`
  set amp=`echo $cc | awk '{print $2}'`
  if ($n == 0) then
    set tempamp=$amp
  endif

  set mag=`echo $amp $tempamp $tempmag | awk '{print log($1/$2)/log(10)+$3}'`
  echo $file $cc $shift $mag >> mag.wf.$seqnum.$cha

plot:
  awk '{print $1+s,$2/m+n*2}' s=$shift n=$n m=$max $file | psxy -W2$col -M -R -J -K -O >> $psfile
  set epdate=`awk '$2==e{printf "%s",$1;exit}' e=$ep $result`
  echo $time1 $time2 $epdate |awk '{print $1-($2-$1)*.011,n*2,7,0,0,"RM",$3,$4}' n=$n m=$max | pstext -R -J -K -O -N >> $psfile
  set epcc=`awk '$2==e{printf "%.1f",$3*100;exit}' e=$ep $result`
  echo $time1 $time2 $epcc | awk '{print $2+($2-$1)*.011,n*2,7,0,0,"LM",$3}' n=$n m=$max | pstext -R -J -K -O -N >> $psfile
  set eptemp=`awk '$2==e{printf "%s",$8;exit}' e=$ep $result`
  echo $time1 $time2 $eptemp | awk '{print $2+($2-$1)*.06,n*2,7,0,0,"LM",$3}' n=$n m=$max | pstext -R -J -K -O -N >> $psfile
  set epmag=`awk '$2==e{printf "%s",$6;exit}' e=$ep $result`
  echo $time1 $time2 $epmag | awk '{print $2+($2-$1)*.17,n*2-1,7,0,0,"LM",$3}' n=$n m=$max | pstext -R -J -K -O -N >> $psfile
  echo $time1 $time2 $mag | awk '{print $2+($2-$1)*.17,n*2,7,0,0,"LM",int($3*100+.5)/100}' n=$n m=$max | pstext -R -J -K -O -N >> $psfile
end

goto done
set mcc=`head -1 mag.wf.$temp.$year.$cha | awk '{print log($3)}'`
set ep0=`echo 2012-01-01 | toepoch.csh`
awk '{OFMT="%.6f";split($1,s,".");if (NF>=5) print (s[3]-ep)/86400/365.25+2012,$5,log($3)/m;else print (s[3]-ep)/86400/365.25+2012,0,0}' ep=$ep0 m=$mcc mag.wf.$temp.$year.$cha >! ep.mag.corr.xyz
set range=`awk '{print $1-.02,$2-.2"\n"$1+.02,$2+.2}' ep.mag.corr.xyz | minmax -I.02/.2`

echo 0 0 | psxy $range -JX7/2 -Y7.5 -Ba.05f.01/a1f.2WSne -K -O >> $psfile
makecpt -T0.5/1/.1 -Z -D >! corr.cpt
# psxy ep.mag.corr.xyz -R -J -Ccorr.cpt -Sc.08 -K -O >> $psfile
psxy ep.mag.corr.xyz -R -J -Sc.08 -W2 -K -O >> $psfile
head -1 ep.mag.corr.xyz | psxy -R -J -Sd.1 -G0 -K -O >> $psfile

done:
echo 0 0 | psxy -R -JX7.2/-7 -O -X-.5 -Y0 >> $psfile
gv $psfile
convert -density 300 -rotate 90 $psfile $psfile:r.jpg
