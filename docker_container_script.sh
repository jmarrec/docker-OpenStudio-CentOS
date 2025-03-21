#!/usr/bin/env bash

set -e -x

# This isn't needed if you pass --login to bash or if you are already attached to the container
# source scl_source enable devtoolset-10
gcc --version
g++ --version

# TODO: temp: I'm trying to avoid redownloading everything all the time
#cp ../dropbox/EnergyPlus-23.1.0-87ed9199d4-Linux-CentOS7.9.2009-x86_64.tar.gz .
#tar xfz EnergyPlus-23.1.0-87ed9199d4-Linux-CentOS7.9.2009-x86_64.tar.gz
#cp ../dropbox/openstudio3-gems-20230427-linux.tar.gz .
#tar xfz openstudio3-gems-20230427-linux.tar.gz
#cp ../dropbox/radiance-5.0.a.12-Redhat.tar.gz .
#tar xfz radiance-5.0.a.12-Redhat.tar.gz
mkdir EnergyPlus-build-release
cd EnergyPlus-build-release

cmake -G Ninja -DCMAKE_BUILD_TYPE:STRING=Release \
  -DLINK_WITH_PYTHON:BOOL=ON -DBUILD_TESTING:BOOL=ON \
  -DBUILD_FORTRAN:BOOL=ON -DDOCUMENTATION_BUILD:STRING=DoNotBuild \
  -DENABLE_GTEST_DEBUG_MODE=OFF \
  -DBUILD_PACKAGE:BOOL=ON -DCPACK_BINARY_IFW:BOOL=OFF -DCPACK_BINARY_STGZ:BOOL=OFF -DCPACK_BINARY_TGZ:BOOL=ON \
  -DPython_REQUIRED_VERSION:STRING=3.12.2 \
  -DPython_ROOT_DIR:PATH=$HOME/.pyenv/versions/3.12.2 \
  -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON \
  ../EnergyPlus
ninja package

cd ..

cd OpenStudio

CONAN_FIRST_TIME_BUILD_ALL=false
echo "CONAN_FIRST_TIME_BUILD_ALL=$CONAN_FIRST_TIME_BUILD_ALL"

if [[ "$CONAN_FIRST_TIME_BUILD_ALL" == true ]]; then
  conan install . --output-folder=../OS-build-release --build='*' -c tools.cmake.cmaketoolchain:generator=Ninja -s compiler.cppstd=20 -s build_type=Release
else
  conan install . --output-folder=../OS-build-release --build=missing -c tools.cmake.cmaketoolchain:generator=Ninja -s compiler.cppstd=20 -s build_type=Release
fi
CONAN_FIRST_TIME_BUILD_ALL=false

cmake --preset conan-release \
      -DPYTHON_VERSION=3.12.2 -DPython_ROOT_DIR:PATH=$HOME/.pyenv/versions/3.12.2 \
      -DCPACK_BINARY_TGZ:BOOL=ON -DCPACK_BINARY_RPM:BOOL=ON \
      -DCPACK_BINARY_IFW:BOOL=OFF -DCPACK_BINARY_DEB:BOOL=OFF -DCPACK_BINARY_NSIS:BOOL=OFF \
      -DCPACK_BINARY_STGZ:BOOL=OFF -DCPACK_BINARY_TBZ2:BOOL=OFF -DCPACK_BINARY_TXZ:BOOL=OFF -DCPACK_BINARY_TZ:BOOL=OFF \
      -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON

# Initially I set that to ON, then I did
# conan remote add -i 0 openstudio-centos https://conan.openstudio.net/artifactory/api/conan/openstudio-centos
# conan user -p <TOKEN> -r openstudio-centos jmarrec
# conan upload -r openstudio-centos --all --parallel --no-overwrite all --confirm "*"




echo "Changing shebang line in radiance"
sed -i "s:#\!/usr/local/bin/wish4.0:#\!/usr/bin/env wish:g" radiance-5.0.a.12-Linux/usr/local/radiance/bin/trad

ninja

ninja package

# Move that back to the dropbox
cp OpenStudio-3* ../dropbox/
# Get the openstudio.spec too
cp _CPack_Packages/Linux/RPM/SPECS/openstudio*.spec ../dropbox/
