#!/bin/bash
#The script is used in Jenkins jobs

echo Desc: "SDL: " ${SDL_GIT_BRANCH:7:29} " " ${SDL_GIT_COMMIT:0:8}

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
