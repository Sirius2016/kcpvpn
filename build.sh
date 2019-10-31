#!/bin/bash
# apt install build-essential gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-mipsel-linux-gnu gcc-mips64el-linux-gnuabi64 linux-libc-dev-i386-cross pbzip2
set -x
KCPVPN_CC=""
KCPVPN_CFLAGS=""
KCPVPN_LDFLAGS=""
function set_cc_for_architecture() {
  case $1 in
  "386")
    KCPVPN_CC="gcc"
    KCPVPN_CFLAGS="-m32 -L/usr/lib32 -I/usr/i686-linux-gnu/include"
    KCPVPN_LDFLAGS="-m32 -L/usr/lib32"
    ;;
  "amd64")
    KCPVPN_CC="gcc"
    KCPVPN_CFLAGS=""
    KCPVPN_LDFLAGS=""
    ;;
  "arm")
    KCPVPN_CC="arm-linux-gnueabihf-gcc"
    KCPVPN_CFLAGS=""
    KCPVPN_LDFLAGS=""
    ;;
  "arm64")
    KCPVPN_CC="aarch64-linux-gnu-gcc"
    KCPVPN_CFLAGS=""
    KCPVPN_LDFLAGS=""
    ;;
  "mipsle")
    KCPVPN_CC="mipsel-linux-gnu-gcc"
    KCPVPN_CFLAGS=""
    KCPVPN_LDFLAGS=""
    ;;
  "mips64le")
    KCPVPN_CC="mips64el-linux-gnuabi64-gcc"
    KCPVPN_CFLAGS=""
    KCPVPN_LDFLAGS=""
    ;;
  *)
    echo "unknown archicture"
    exit 1
    ;;
  esac
}

BUILD_DIR="kcpvpn-build"
ARCHITECTURES="386 amd64 arm arm64 mipsle mips64le"
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
pushd ${BUILD_DIR} || exit 1

if [ -d libtuntap4go ]; then
  pushd libtuntap4go
  git pull || exit 1
  popd
else
  git clone https://github.com/yzsme/libtuntap4go.git || exit 1
fi

go get -v -d -u github.com/yzsme/kcpvpn/...

for arch in ${ARCHITECTURES}; do
  set_cc_for_architecture ${arch}
  libtuntap4go_build_dir="libtuntap4go-${arch}"
  mkdir ${libtuntap4go_build_dir}
  pushd ${libtuntap4go_build_dir}
  CC=${KCPVPN_CC} CFLAGS=${KCPVPN_CFLAGS} LDFLAGS=${KCPVPN_LDFLAGS} cmake -DCMAKE_BUILD_TYPE=Release ../libtuntap4go && make || exit 1
  popd

  CC=${KCPVPN_CC} CGO_ENABLED=1 GOOS=linux GOARCH=${arch} CGO_CFLAGS="-g -O2 -I$(pwd)/libtuntap4go ${KCPVPN_CFLAGS}" CGO_LDFLAGS="-g -O2 -L$(pwd)/${libtuntap4go_build_dir}" go build -ldflags "-s -w -linkmode \"external\" -extldflags \"-static ${LDFLAGS}\"" -o kcpvpn-${arch} github.com/yzsme/kcpvpn || exit 1
  pbzip2 kcpvpn-${arch}
done

sha1sum kcpvpn-*.bz2
popd || exit 1
