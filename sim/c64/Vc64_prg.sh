PRG=$1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

python3 $SCRIPT_DIR/prg2crt.py $PRG $SCRIPT_DIR/tmp.crt

pushd $SCRIPT_DIR

cartconv -i tmp.crt -o cartrige.bin > /dev/null
#rm -f frame_*.png
./Vc64 -c cartrige.bin -t $2 #-d c64.vcd
exitcode=$?
popd

exit $exitcode 