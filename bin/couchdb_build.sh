#!/bin/sh
COUCH_TOP=`pwd`
export COUCH_TOP

make 2>&1 | tee $COUCH_TOP/build_make.txt
echo DONE. | tee -a $COUCH_TOP/build_make.txt

make check 2>&1  | tee $COUCH_TOP/build_check.txt
echo DONE. | tee -a $COUCH_TOP/build_check.txt

make install 2>&1  | tee $COUCH_TOP/build_install.txt
echo DONE. | tee -a $COUCH_TOP/build_install.txt

make dist 2>&1   | tee $COUCH_TOP/build_dist.txt
echo DONE. | tee -a $COUCH_TOP/build_dist.txt

echo DONE.
echo to move build files to release area run the following:
echo pushd $COUCH_TOP/etc/windows/
echo rename .exe _otp_$OTP_VER.exe setup-couchdb-*
echo mv setup-couchdb-* /relax/release
echo popd

echo DONE.
