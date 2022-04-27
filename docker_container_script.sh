#!/usr/bin/env bash

set -e -x

cd OS-build-release

# This isn't needed if you pass --login to bash or if you are already attached to the container
# source scl_source enable devtoolset-10

gcc --version
g++ --version
cmake -G Ninja  -DCMAKE_BUILD_TYPE:STRING=Release \
       -DBUILD_TESTING:BOOL=ON -DBUILD_PACKAGE:BOOL=ON -DCPACK_BINARY_TGZ:BOOL=ON -DCPACK_BINARY_RPM:BOOL=OFF \
      -DCPACK_BINARY_IFW:BOOL=OFF -DCPACK_BINARY_NSIS:BOOL=OFF  -DCPACK_BINARY_DEB:BOOL=OFF -DCPACK_BINARY_STGZ:BOOL=OFF \
      -DCPACK_BINARY_TBZ2:BOOL=OFF -DCPACK_BINARY_TXZ:BOOL=OFF -DCPACK_BINARY_TZ:BOOL=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON \
      -DCMAKE_C_COMPILER:FILEPATH=$C -DCMAKE_CXX_COMPILER:FILEPATH=$CXX \
      -DCONAN_FIRST_TIME_BUILD_ALL:BOOL=ON -D_GLIBCXX_USE_CXX11_ABI=0 \
      ../OpenStudio

ninja
