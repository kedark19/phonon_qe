#!bin/sh
########################################################
##    Phonon calculation   #############################
########################################################

# load environment variable
PW_PATH=~/softwares/qe/qe-6.3/bin
PSEUDO_DIR=~/kedar/softwares/SSSP_precision_pseudos
TMP_DIR=./tmp

rm -rf result
mkdir result
cd result

# SCF calculation
cat > Si1.scf.in << EOF
 &control
    calculation='scf'
    restart_mode='from_scratch',
    tstress = .true.
    tprnfor = .true.
    prefix='Si1',
    pseudo_dir = '$PSEUDO_DIR/',
    outdir='$TMP_DIR/'
 /
 &system
    ibrav=  2, celldm(1) =10.32955, nat=  2, ntyp= 1,
    ecutwfc =16.0
 /
 &electrons
    conv_thr =  1.0d-8
    mixing_beta = 0.7
 /
ATOMIC_SPECIES
 Si  28.086  Si.pbe-n-rrkjus_psl.1.0.0.UPF
ATOMIC_POSITIONS (alat)
 Si 0.00 0.00 0.00
 Si 0.25 0.25 0.25
K_POINTS automatic
 4 4 4  1 1 1
EOF
echo "  running the SCF calculation ..."
$PW_PATH/pw.x < Si1.scf.in > Si1.scf.out
echo " done"


# phonon calculation on a 444 uniform grid of q-points
cat > Si1.ph.in << EOF
phonons of Si
 &inputph
  tr2_ph=1.0d-12,
  prefix='Si1',
  ldisp=.true.,
  nq1=4, nq2=4, nq3=4
  outdir='$TMP_DIR/',
  fildyn='Si1.dyn',
 /
EOF

echo "  running the phonon calculation ..."
$PW_PATH/ph.x < Si1.ph.in > Si1.ph.out
echo " done"


echo "  transforming C(q) => C(R)...  (q2r) "
cat > q2r.in <<EOF
 &input
   fildyn='Si1.dyn', 
   zasr='simple', 
   flfrc='Si1444.fc'
 /
EOF
$PW_PATH/q2r.x  < q2r.in > q2r.out
echo " done"


cat > matdyn.in <<EOF
 &input
    asr='simple',  
    flfrc='Si1444.fc', 
    flfrq='Si1.freq', 
    q_in_band_form=.true.,
 /
 6
  gG    40
  X     20
  W     20
  1.0   1.0 0.0   40
  gG    40
  L     1
EOF
echo "  recalculating omega(q) from C(R)..."
$PW_PATH/matdyn.x < matdyn.in > matdyn.out
echo " done"

cat > plotband.in <<EOF
Si1.freq
0 600
freq.plot
freq.ps
0.0
50.0 0.0
EOF
echo "  writing the phonon dispersions in freq.plot..."
$PW_PATH/plotband.x < plotband.in 
echo " done"
#plotting phonon dispersion
cat > gnuplot.phonon <<EOS
set encoding iso_8859_15
set terminal postscript enhanced solid color "Helvetica" 25
set output "Si.dispersions.pdf"
#
set key off

set xrange [0:4.280239]   # q-path range
dim=520                   # set according the frequency range
set yrange [0:dim]
set arrow from 1,0. to 1,dim nohead  lw 2
set arrow from 2,0. to 2,dim nohead  lw 2
set arrow from 1.5,0. to 1.5,dim nohead  lw 2
set arrow from 3.4142,0. to 3.4142,dim nohead  lw 2
set ylabel "frequency (cm^{-1})"
unset xtics
lpos=-15
set label "{/Symbol G}" at -0.00,lpos
set label "X" at 0.95,lpos
set label "W" at 1.45,lpos
set label "X" at 1.95,lpos
set label "{/Symbol G}" at 3.37,lpos
set label "L" at 4.1897,lpos

plot "freq.plot" u 1:2 w l lw 3
EOS
gnuplot gnuplot.phonon

###### DOS
cat > phdos.in <<EOF
 &input
    asr='simple',  
    dos=.true.
    flfrc='Si1444.fc', 
    fldos='Si1.phdos', 
    nk1=6,nk2=6,nk3=6
 /
EOF
echo "  calculating phonon DOS ..."
$PW_PATH/matdyn.x < phdos.in > phdos.out
echo " done"

# Plotting phDOS
cat > gnuplot.dos <<EOS
set encoding iso_8859_15
set terminal postscript enhanced solid color "Helvetica" 20
set output "Si.phdos.pdf"
#
set key off
set xrange [0:520]
set xlabel "frequency (cm^{-1})"
set ylabel "DOS"
plot 'Si1.phdos' u 1:2 w l lw 3
EOS
gnuplot gnuplot.dos

#
echo "Done."
##################################
