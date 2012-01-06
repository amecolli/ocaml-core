#!/usr/bin/env bash
set -e -u -o pipefail

here="$(dirname "${BASH_SOURCE[0]}")"

my_join () {
    local FIRST="true"
    while read line; do
        if [[ "$FIRST" != "true" ]]; then
            echo -n ","
        else
            FIRST="false"
        fi
        echo -n "$line"
    done
    echo
}

list_mods () {
    echo Std
    for i in $here/$1/*.ml; do
        bname="$(basename $i)"
        j=${bname%%.ml*};
        case $j in
            inline_tests_runner) continue;;
            *);;
        esac
        echo -n "${j:0:1}" | tr "[:lower:]" "[:upper:]"; echo ${j:1};
    done
}

list_stubs () {
    for i in "$here"/lib/*.{c,h} "$here"/lib/*.{c,h}; do
        bname="$(basename $i)"
        j=${bname%%.?};
        case $j in
            *);;
        esac
        echo "$bname"
    done
}

cat >$here/_oasis <<EOF
#AUTOGENERATED FILE; EDIT oasis.sh INSTEAD

OASISFormat:  0.2
OCamlVersion: >= 3.12
Name:         async_core
Version:      107.01
Synopsis:     Jane Street Capital's asynchronous execution library (core)
Authors:      Jane street capital
Copyrights:   (C) 2008-2011 Jane Street Capital LLC
License:      LGPL-2.1 with OCaml linking exception
LicenseFile:  LICENSE
Plugins:      StdFiles (0.2),
              DevFiles (0.2),
              META (0.2)
BuildTools:   ocamlbuild
Description:  Jane Street Capital's asynchronous execution library
FindlibVersion: >= 1.2.7
XStdFilesAUTHORS: false
XStdFilesINSTALLFilename: INSTALL
XStdFilesREADME: false


Library async_core
  Path:               lib
  FindlibName:        async_core
  Pack:               true
  Modules:$(list_mods lib | sort -u | my_join)
  BuildDepends:       sexplib.syntax,
                      sexplib,
                      fieldslib.syntax,
                      fieldslib,
                      bin_prot,
                      bin_prot.syntax,
                      core,
                      threads

EOF

cat >$here/_tags <<EOF
# OASIS_START
# OASIS_STOP
<lib/*.ml{,i}>: syntax_camlp4o
EOF

cd $here
oasis setup
./configure "$@"

