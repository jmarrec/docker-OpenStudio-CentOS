#!/usr/bin/env bash

set -e -x

cd OS-build-release

# This isn't needed if you pass --login to bash or if you are already attached to the container
# source scl_source enable devtoolset-10

gcc --version
g++ --version

# Initially I set that to ON, then I did
# conan remote add openstudio-centos https://conan.openstudio.net/artifactory/api/conan/openstudio-centos
# conan user -p <TOKEN> -r openstudio-centos jmarrec
# conan upload -r openstudio-centos --all --parallel --no-overwrite all --confirm "*"
CONAN_FIRST_TIME_BUILD_ALL=OFF
echo "CONAN_FIRST_TIME_BUILD_ALL=$CONAN_FIRST_TIME_BUILD_ALL"

cmake -G Ninja  -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_TESTING:BOOL=ON -DBUILD_PACKAGE:BOOL=ON -DCPACK_BINARY_TGZ:BOOL=ON -DCPACK_BINARY_RPM:BOOL=ON \
      -DCPACK_BINARY_IFW:BOOL=OFF -DCPACK_BINARY_NSIS:BOOL=OFF  -DCPACK_BINARY_DEB:BOOL=OFF -DCPACK_BINARY_STGZ:BOOL=OFF \
      -DCPACK_BINARY_TBZ2:BOOL=OFF -DCPACK_BINARY_TXZ:BOOL=OFF -DCPACK_BINARY_TZ:BOOL=OFF \
      -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON \
      -DCMAKE_C_COMPILER:FILEPATH=$CC -DCMAKE_CXX_COMPILER:FILEPATH=$CXX \
      -DCONAN_FIRST_TIME_BUILD_ALL:BOOL=$CONAN_FIRST_TIME_BUILD_ALL -D_GLIBCXX_USE_CXX11_ABI=0 \
      -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON \
      ../OpenStudio

echo "Changing shebang line in radiance"
sed -i "s:#\!/usr/local/bin/wish4.0:#\!/usr/bin/env wish:g" radiance-5.0.a.12-Linux/usr/local/radiance/bin/trad

ninja

ninja package

# Move that back to the dropbox
cp OpenStudio-3* ../dropbox/
# Get the openstudio.spec too
cp _CPack_Packages/Linux/RPM/SPECS/openstudio.spec ../dropbox/
