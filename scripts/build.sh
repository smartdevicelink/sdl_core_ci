#!/bin/bash
#The script is used in Jenkins jobs
set -x

echo Desc: "SDL: " ${GIT_BRANCH:7:29} " " ${GIT_COMMIT:0:8}
#set limit of core file size (blocks) unlimited
echo "===Prepare for coredumps========================"
ulimit -c unlimited;
echo "ulimit is set to unlimited"
rm -rf /tmp/corefiles
mkdir /tmp/corefiles
echo '/tmp/corefiles/core.%e.%p' | sudo tee /proc/sys/kernel/core_pattern
echo "===End of Prepare for coredumps================="

#Cppcheck is a static analysis tool for C/C++ code
echo "===Cppcheck - static analyse===================="
cppcheck --enable=all --inconclusive -i "src/3rd_party-static" -i "src/3rd_party" --xml --xml-version=2 -q src 2> cppcheck.xml
echo "===END of Cppcheck - static analyse============="

#Set up ENV 3rd-party variables
#export WORKSPACE=~
export THIRD_PARTY_INSTALL_PREFIX=${WORKSPACE}/build/src/3rdparty/LINUX
export THIRD_PARTY_INSTALL_PREFIX_ARCH=${THIRD_PARTY_INSTALL_PREFIX}/x86
export LD_LIBRARY_PATH=$THIRD_PARTY_INSTALL_PREFIX_ARCH/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$THIRD_PARTY_INSTALL_PREFIX/lib
#cmake -DBUILD_TESTS=ON ..

#Check style
echo "===Check style=================================="
./tools/infrastructure/check_style.sh || exit 1
echo "===END of style checking========================"

#Build
echo "===Build 3rd_party=============================="
cd build
make install-3rd_party_logger
echo "===END of Build 3rd_party======================="

echo "===Build========================================"
make install -j4 || exit 1
echo "===END of Build================================="

sudo ldconfig
#Run Unit tests
echo "===Unit tests==================================="
make test | tee ut.log || true; result=${PIPESTATUS[0]};
if [ $result -ne 0 ]; then
 COREFILE=$(find /tmp/corefiles -type f -name 'core*');
 echo $COREFILE;
 grep -w "SegFault" ut.log | while read -r line; do 
  arr=($line); 
  echo ${arr[3]};
 done > res.txt;
 test_file=$(find ${WORKSPACE}/build/src/components/ -type f -name "$(cat res.txt)");
 echo $test_file;
 echo "Started gdb!";
 echo thread apply all bt | gdb $test_file $COREFILE;
 tar -zcf coredump.tar.gz /tmp/corefiles/
 pwd
 find ${WORKSPACE}/build/src/components/ -maxdepth 3 -mindepth 3 -type f -executable| xargs tar -uf tests.tar
 gzip -c tests.tar > tests.tar.gz
 exit 2
fi
echo "===End of Unit tests============================"

echo "===Copy src into bin============================"
cp -r ${WORKSPACE}/build/src/3rdparty/LINUX/x86/lib/* ${WORKSPACE}/build/bin/
cp -r ${WORKSPACE}/build/src/3rdparty/LINUX/lib/* ${WORKSPACE}/build/bin/
mkdir ${WORKSPACE}/build/bin/api
cp -r ${WORKSPACE}/src/components/interfaces/* ${WORKSPACE}/build/bin/api/
cp ${WORKSPACE}/build/CMakeCache.txt ${WORKSPACE}/build/bin/
echo "===End of Copy src into bin====================="

#archive bin
echo "===Archive artifacts============================"
tar -zcf OpenSDL.tar.gz bin/
echo "===End of Archive artifacts====================="
