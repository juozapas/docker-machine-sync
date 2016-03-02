#!/bin/sh
install_deps(){
    tce-load -wi make
    tce-load -wi compiletc
    #tce-load -wi bash

}

install_ocaml(){

    local OCAML_MAJOR_VERSION=3.12
    local OCAML_MINORR_VERSION=1
    wget http://caml.inria.fr/pub/distrib/ocaml-$OCAML_MAJOR_VERSION/ocaml-$OCAML_MAJOR_VERSION.$OCAML_MINORR_VERSION.tar.bz2
    tar xvf ocaml-$OCAML_MAJOR_VERSION.$OCAML_MINORR_VERSION.tar.bz2
    cd ocaml-$OCAML_MAJOR_VERSION.$OCAML_MINORR_VERSION
    ./configure
    make world opt
    sudo make install
    cd ..
    rm -rf ocaml-$OCAML_MAJOR_VERSION.$OCAML_MINORR_VERSION*
}

install_unison(){
    local readonly UNISON_VERSION=2.48.3
    wget http://www.seas.upenn.edu/~bcpierce/unison/download/releases/unison-$UNISON_VERSION/unison-$UNISON_VERSION.tar.gz
    tar xvf unison-$UNISON_VERSION.tar.gz
    cd unison-$UNISON_VERSION
    make UISTYLE=text
    sudo make GLIBC_SUPPORT_INOTIFY=true UISTYLE=text INSTALLDIR=/var/lib/boot2docker/ NATIVE=true STATIC=true install
    cd ..
    rm -rf unison-$UNISON_VERSION*



    sudo su -c "echo \"ln -s /var/lib/boot2docker/unison /usr/bin/unison\" >> /var/lib/boot2docker/bootlocal.sh"

    sudo su -c "chmod +x /var/lib/boot2docker/bootlocal.sh"

    sync
    #
    sudo /var/lib/boot2docker/bootlocal.sh
    #unison

}

install_deps
install_ocaml
install_unison