#
#
#
#set seqnum=190 mad=25
#set seqnum=200 mad=25
#set seqnum=300 mad=25
#set seqnum=298 mad=25
#set seqnum=050 mad=25
#set seqnum=650 mad=25
#set seqnum=400 mad=25
#set seqnum=225 mad=25
#set seqnum=118 mad=25
#set seqnum=220 mad=25
#set seqnum=277 mad=25
# set seqnum=$1 mad=1 cc1=.10
set seqnum=$1 mad=1 cc1=.05
# fix.mad.csh $seqnum
# set mad=35 # MAD threshold
# set cha=3 # Number of channels required
# set cha=1 # Number of channels required
set cha=6 # Number of channels required
# set cha=7 # Number of channels required

set sta="3sta"
# set sta=HUIG
# set sta=PNIG

# set files=( match/match*$seqnum.*$sta* )
# set files=( `\ls -l match/match*$seqnum.*$sta*| awk '$5>0{print $9}'` )
set files=( `\ls -l match/match*$seqnum.*$sta*2025*| awk '$5>0{print $9}'` )
# echo $files
if (`echo $files | wc -w` < 1) then
echo ".99" 
else
module load gmt
# awk '$2>cc&&$2/$3>mad&&$4>=cha' mad=$mad cc=$cc cha=$cha $files | sort -n | awk '{if ($1-o1>20&&NR>1) {print o0;o0=$0;o2=$2;if (sqrt(($1-$7)^2)<20)o2=1000} else if (o2<$2||sqrt(($1-$7)^2)<20) {o0=$0; o2=$2;if (sqrt(($1-$7)^2)<20)o2=1000} o1=$1}END{print o0}' >! lcurve.matches
awk '$2>cc&&$2/$3>mad&&$4>=cha' mad=$mad cc=$cc1 cha=$cha $files | sort -n | awk '{if ($1-o1>5&&NR>1) {print o0;o0=$0;o2=$2;if (sqrt(($1-$7)^2)<5)o2=1000} else if (o2<$2||sqrt(($1-$7)^2)<5) {o0=$0; o2=$2;if (sqrt(($1-$7)^2)<5)o2=1000} o1=$1}END{print o0}' >! lcurve.matches
(awk '{print $2}' lcurve.matches | pshistogram -R$cc1/1/0/1 -W.01 -IO >! lcurve.hist) >& /dev/null
# tac lcurve.hist | awk '{s+=$2; print $1,s}' >! lcurve.cuml
# tac lcurve.hist | awk '{s+=$2; print $1,s}' | awk -f ~/awk/runningmeanall.awk n=10 >! lcurve.cuml
tac lcurve.hist | awk '{s+=$2; print $1,s}' | awk -f ~/awk/runningmeanall.awk n=5 >! lcurve.cuml
cat lcurve.cuml | awk '{s+=$2; print $1,s}' >! lcurve.2cuml
# \cp lcurve.2cuml lcurve.cuml

set max=`awk -f ~/awk/max.awk c=2 lcurve.cuml`
awk '{print $1,$2/m}' m=$max lcurve.cuml >! lcurve.norm
awk '{print $1+$2,$2-$1,$1,$2}' m=$max lcurve.norm >! lcurve.rot
set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3*100}'`
# echo -n "$seqnum $cc "
# awk '$1==s{print $6}' s=$seqnum table.txt
set cc0=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3}'`
# set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3+.125}'`
# set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3+.04}'`
# set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3*1.08}'`
# set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3*1.15}'`
set cc=`awk -f ~/awk/minline.awk lcurve.rot | awk '{print $3*1.2}'`
# echo $cc $cc0
echo $cc
# goto skipplot
set tick=`echo 0 $max | awk -f ~/awk/tick.awk`
set psfile=lcurve.ps
psxy lcurve.cuml -R$cc1/1/0/$max -JX7 -W5 -Ba.2f.1/$tick -K >! $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml | awk '$1==cc' cc=$cc0 | psxy -R -J -Sc.15 -W5 -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml | awk '$1==cc' cc=$cc | psxy -R -J -Sc.15 -W5 -O >> $psfile
# psxy lcurve.norm -R$cc1/1/0/1 -JX7 -Ba.2f.1 >! $psfile
# psxy lcurve.rot -R-1/1/-1/1 -JX7 -Ba.2f.1 >! $psfile
# gv $psfile
# convert -density 200 $psfile $psfile:r.jpg
skipplot:
endif
exit

awk '{print $1}' $seqnum.combine.matches.txt | fromepoch.T.csh | paste - $seqnum.combine.matches.txt >! $seqnum.combine.matches.date.txt

# set mine=`echo 2020-01-01 | toepoch.csh my=2020`
set mine=`echo 2015-01-01 | toepoch.csh` my=2015
awk '{OFMT="%.6f";print $0,($2-mine)/86400/365.25+my}' my=$my mine=$mine $seqnum.combine.matches.date.txt >! $seqnum.combine.matches.date.dy.txt

awk '{print $9,$3,$4,$6}' $seqnum.combine.matches.date.dy.txt >! sequences/seq.match.$seqnum

echo -n "" >! $seqnum.combine.matches.full.cat
echo -n "" >! $seqnum.combine.matches.nocat.txt
# foreach ep ( `awk '$3<1{print $2}' $seqnum.combine.matches.date.dy.txt` )
foreach line ( "`cat $seqnum.combine.matches.date.dy.txt`" )
  set l=( $line )
  set loc=( `awk '$6==e{print $3,$2}' e=$l[8] sequences/seq.full.$seqnum` )  
  
#  awk '($6-e)^2<50' e=$ep full.2010-2022_09_01.cat >! match.out
#  awk '($6-e)^2<50{print $0,cc}' e=$l[2] cc=$l[3] full.2010-2022_09_01.cat >! match.out
  awk '($6-e)^2<50&&($3-x)^2<1&&($2-y)^2<1{print $0,cc}' x=$loc[1] y=$loc[2] e=$l[2] cc=$l[3] full.2010-2022_09_01.cat >! match.out

  if (`wc -l < match.out` > 0 && `echo $l[3] | awk '{if ($1<1) print 1; else print 0}'`) then
    cat match.out >>! $seqnum.combine.matches.full.cat
  else
