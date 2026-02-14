#!/bin/bash

set -e
set -o pipefail
set -x

SOCAT_VERSION=1.8.1.1
NCURSES_VERSION=6.6-20260207
READLINE_VERSION=8.3
OPENSSL_VERSION=3.6.1
mkdir -p /build
mkdir -p /output

function build_ncurses() {
    cd /build

    # Download
    curl -LO  http://invisible-mirror.net/archives/ncurses/current/ncurses-${NCURSES_VERSION}.tgz
    tar zxvf ncurses-${NCURSES_VERSION}.tgz
    cd ncurses-${NCURSES_VERSION}

    # Build
    CC='/usr/bin/gcc -static' CFLAGS='-fPIC' ./configure \
        --disable-shared \
        --enable-static
}

function build_readline() {

    cd /build

    # Download
    curl -LO ftp://ftp.cwru.edu/pub/bash/readline-${READLINE_VERSION}.tar.gz
    tar xzvf readline-${READLINE_VERSION}.tar.gz
    cd readline-${READLINE_VERSION}

    # Build
    CC='/usr/bin/gcc -static' CFLAGS='-fPIC' ./configure \
        --disable-shared \
        --enable-static
    make -j4

    # Note that socat looks for readline in <readline/readline.h>, so we need
    # that directory to exist.
     if [ -e /build/readline ];then
      rm /build/readline
     fi
     ln -s /build/readline-${READLINE_VERSION} /build/readline
}

function build_openssl() {
    cd /build

    # Download
    curl -LO https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz

    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}

    # Configure
    CC='/usr/bin/gcc -static' CFLAGS='-fPIC' ./Configure no-shared no-async linux-x86_64

    # Build
    make -j4
    echo "** Finished building OpenSSL"
}

function build_socat() {
    cd /build

    # Download
    curl -LO http://www.dest-unreach.org/socat/download/socat-${SOCAT_VERSION}.tar.gz
    tar xzvf socat-${SOCAT_VERSION}.tar.gz
    cd socat-${SOCAT_VERSION}

    # Build
    # NOTE: `NETDB_INTERNAL` is non-POSIX, and thus not defined by MUSL.
    # We define it this way manually.
    CC='/usr/bin/gcc -static' \
        CFLAGS='-fPIC' \
        CPPFLAGS="-I/build -I/build/openssl-${OPENSSL_VERSION}/include -DNETDB_INTERNAL=-1" \
        LDFLAGS="-L/build/readline-${READLINE_VERSION} -L/build/ncurses-${NCURSES_VERSION}/lib -L/build/openssl-${OPENSSL_VERSION}" \
        ./configure
    make -j4
    strip socat
}

function doit() {
    build_ncurses
    build_readline
    build_openssl
    build_socat

    # Copy to output
    if [ -d /output ]
    then
        OUT_DIR=/output/`uname | tr 'A-Z' 'a-z'`/`uname -m`
        mkdir -p $OUT_DIR
        cp /build/socat-${SOCAT_VERSION}/socat $OUT_DIR/
        echo "** Finished **"
    else
        echo "** /output does not exist **"
    fi
}

doit

