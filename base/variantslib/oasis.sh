#!/usr/bin/env bash
set -e -u -o -pipefail

here="$(dirname "${BASH_SOURCE[0]}")"

cat >$here/_oasis <<EOF
#AUTOGENERATED FILE; EDIT oasis.sh INSTEAD
OASISFormat:  0.2
OCamlVersion: >= 3.12
Name:         variantslib
Version:      107.01
Synopsis:     OCaml variants as first class values.
Authors:      Jane street capital
Copyrights:   (C) 2009-2011 Jane Street Capital LLC
License:      LGPL-2.1 with OCaml linking exception
LicenseFile:  LICENSE
Plugins:      StdFiles (0.2),
              DevFiles (0.2),
              META (0.2)
XStdFilesREADME: false
XStdFilesAUTHORS: false
XStdFilesINSTALLFilename: INSTALL
BuildTools:   ocamlbuild

Library variantslib
  Path:               lib
  FindlibName:        variantslib
  Pack:               true
  Modules:            Variant
  XMETAType:          library

Library pa_variants_conv
  Path:               syntax
  Modules:            Pa_variants_conv
  FindlibParent:      variantslib
  FindlibName:        syntax
  BuildDepends:       camlp4.lib,
                      camlp4.quotations,
                      type-conv (>= 2.0.1)
  CompiledObject:     byte
  XMETAType:          syntax
  XMETARequires:      camlp4,type-conv,variantslib
  XMETADescription:   Syntax extension for Variantslib

Document "variantslib"
  Title:                API reference for variantslib
  Type:                 ocamlbuild (0.2)
  BuildTools+:          ocamldoc
  XOCamlbuildPath:      lib
  XOCamlbuildLibraries: variantslib
EOF

cat >$here/_tags <<EOF
# OASIS_START
# OASIS_STOP
<syntax/*.ml{,i}>: syntax_camlp4o
EOF

cd $here
oasis setup
./configure "$@"

