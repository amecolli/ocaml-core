#!/usr/bin/env bash
set -e -u -o pipefail

here="$(dirname "${BASH_SOURCE[0]}")"

cat >$here/_oasis <<EOF
#AUTOGENERATED FILE; EDIT oasis.sh INSTEAD
OASISFormat:  0.1
OCamlVersion: >= 3.11
Name:         type-conv
Version:      2.3.0
Synopsis:     support library for preprocessor type conversions
Authors:      Martin Sandin,
              Markus Mottl,
              Jane street capital
License:      LGPL-2.1 with OCaml linking exception
LicenseFile:  LICENSE
Plugins:      StdFiles (0.2),
              DevFiles (0.2),
              META (0.2)
BuildTools:   ocamlbuild
XStdFilesAUTHORS: false
XStdFilesINSTALLFilename: INSTALL
XStdFilesREADME: false

Library pa_type_conv
  Path:               syntax
  Modules:            Pa_type_conv
  FindlibName:        type-conv
  BuildDepends:       camlp4.lib, camlp4.quotations , camlp4.extend
  CompiledObject:     byte
  XMETAType:          syntax
  XMETARequires:      camlp4
  XMETADescription:   Syntax extension for type-conv

Document "type-conv"
  Title:                API reference for Type-conv
  Type:                 ocamlbuild (0.2)
  BuildTools+:          ocamldoc
  XOCamlbuildPath:      lib
  XOCamlbuildLibraries: type-conv
EOF

cat >$here/_tags <<EOF
# OASIS_START
# OASIS_STOP
<syntax/pa_type_conv.ml>: syntax_camlp4o
EOF

cd $here
oasis setup
./configure "$@"

