#!/usr/bin/env bash
set -e -u -o pipefail

source ../../build-common.sh

cat >$HERE/_oasis <<EOF
#AUTOGENERATED FILE; EDIT oasis.sh INSTEAD

OASISFormat:  0.3
OCamlVersion: >= 3.12
Name:         core
Version:      $core_version
Synopsis:     Jane Street Capital's standard library overlay
Authors:      Jane street capital
Copyrights:   (C) 2008-2012 Jane Street Capital LLC
License:      LGPL-2.1 with OCaml linking exception
LicenseFile:  LICENSE
Plugins:      StdFiles (0.3), DevFiles (0.3), META (0.3)
BuildTools:   ocamlbuild
Description:  Jane Street Capital's standard library overlay
FindlibVersion: >= 1.2.7
XStdFilesAUTHORS: false
XStdFilesINSTALLFilename: INSTALL
XStdFilesREADME: false

Flag linux
  Description: Enable linux specific extensions
  Default\$:   false   # actually, the default is detected

Flag "posix-timers"
  Description: Enable POSIX timers
  Default\$:   false   # actually, the default is detected

PostConfCommand: lib/discover.sh lib/config.mlh lib/config.h

PreDistCleanCommand: \$rm lib/config.mlh lib/config.h

Library core
  Path:               lib
  FindlibName:        core
  Pack:               true
  Modules:            $(list_mods  "$HERE/lib")
  CSources:           $(list_stubs "$HERE/lib"),config.h
  BuildDepends:       variantslib,
                      variantslib.syntax,
                      sexplib.syntax,
                      sexplib,
                      fieldslib.syntax,
                      fieldslib,
                      bin_prot,
                      bin_prot.syntax,
                      bigarray,
                      pa_ounit,
                      pa_pipebang,
                      res,
                      unix,
                      threads

Library core_top
  Path:               top
  FindlibName:        top
  FindlibParent:      core
  Modules:            Install_printers
  XMETARequires:      core
  XMETADescription:   Toplevel printers for Core
  BuildDepends:       core

Executable test_runner
  Path:               lib_test
  MainIs:             test_runner.ml
  Build\$:            flag(tests)
  Custom:             true
#  CompiledObject:     best
  Install:            false
  BuildDepends:       core,oUnit (>= 1.0.2)

Test test_runner
  Run\$:               flag(tests)
  Command:            \$test_runner
  WorkingDirectory:   lib_test

Document "core"
  Title:                Jane street's core library
  Type:                 ocamlbuild (0.3)
  BuildTools+:          ocamldoc
  XOCamlbuildPath:      lib
  XOCamlbuildLibraries: core

EOF

make_tags "$HERE/_tags" <<EOF
<lib{,_test}/*.ml{,i}>     : syntax_camlp4o
"lib/backtrace.ml"         : mlh, pkg_camlp4.macro
"lib/bigstring.ml"         : mlh, pkg_camlp4.macro
"lib/bigstring_marshal.ml" : mlh, pkg_camlp4.macro
"lib/core_int63.ml"        : mlh, pkg_camlp4.macro
"lib/core_mutex.ml"        : mlh, pkg_camlp4.macro
"lib/core_unix.ml"         : mlh, pkg_camlp4.macro
"lib/linux_ext.ml"         : mlh, pkg_camlp4.macro
EOF

make_myocamlbuild "$HERE/myocamlbuild.ml" <<EOF
$useful_ocaml_functions

let dispatch = function
  | After_rules as e ->

    dep  ["ocaml"; "ocamldep"; "mlh"] (select_files "lib/" ".mlh");

    flag ["mlh"; "ocaml"; "ocamldep"] (S[A"-ppopt"; A"-Ilib/"]);
    flag ["mlh"; "ocaml"; "compile"]  (S[A"-ppopt"; A"-Ilib/"]);

    begin match getconf "LFS64_CFLAGS" with
    | None -> ()
    | Some flags -> flag ["compile"; "c"] (S[A"-ccopt"; A flags])
    end;

    if test "ld -lrt -shared -o /dev/null 2>/dev/null" then begin
      flag ["ocamlmklib"; "c"]                      (S[A"-lrt"]);
      flag ["use_libcore_stubs"; "link"] (S[A"-cclib"; A"-lrt"]);
    end;

    let cflags =
      let flags =
        [
          "-pipe";
          "-g";
          "-fPIC";
          "-O2";
          "-fomit-frame-pointer";
          "-fsigned-char";
          "-Wall";
          "-pedantic";
          "-Wextra";
          "-Wunused";
(*          "-Werror"; *)
          "-Wno-long-long";
        ]
      in
      let f flag = [A "-ccopt"; A flag] in
      List.concat (List.map f flags)
    in
    flag ["compile"; "c"] (S cflags);
    flag ["compile"; "ocaml"] (S [A "-w"; A "@Ae" ]);

    dispatch_default e
  | e -> dispatch_default e

let () = Ocamlbuild_plugin.dispatch dispatch
EOF

make_setup_ml "$HERE/setup.ml" <<EOF
$useful_ocaml_functions

let linux_possible = test "uname | grep -q -i linux"
let timers_possible =
  match getconf "_POSIX_TIMERS" with
  | None   -> false
  | Some x -> (try int_of_string x >= 200112 with _ -> false)

let map_section = function
  | Flag (cs, flag) when cs.cs_name = "linux" ->
    Flag (cs, { flag with
                flag_default = [OASISExpr.EBool true,      linux_possible;
                                OASISExpr.EBool false, not linux_possible] })
  | Flag (cs, flag) when cs.cs_name = "posix-timers" ->
    Flag (cs, { flag with
                flag_default = [OASISExpr.EBool true,      timers_possible;
                                OASISExpr.EBool false, not timers_possible] })
  | section -> section

let setup_t = { setup_t with
  BaseSetup.package = { setup_t.BaseSetup.package with
    sections = List.map map_section setup_t.BaseSetup.package.sections;
  }
}
EOF

cd $HERE
oasis setup
