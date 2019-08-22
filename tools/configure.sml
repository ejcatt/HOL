(* ----------------------------------------------------------------------
              HOL configuration script


   DO NOT EDIT THIS FILE UNLESS YOU HAVE TRIED AND FAILED WITH

     smart-configure

   AND

     config-override.

   ---------------------------------------------------------------------- *)


(* Uncomment these lines and fill in correct values if smart-configure doesn't
   get the correct values itself.  Then run

      mosml < configure.sml

   If you are specifying directories under Windows, we recommend you
   use forward slashes (the "/" character) as a directory separator,
   rather than the 'traditional' backslash (the "\" character).

   The problem with the latter is that you have to double them up
   (i.e., write "\\") in order to 'escape' them and make the string
   valid for SML.  For example, write "c:/dir1/dir2/mosml", rather
   than "c:\\dir1\\dir2\\mosml", and certainly DON'T write
   "c:\dir1\dir2\mosml".
*)


(*
val mosmldir:string =
val holdir :string  =

val OS :string      =
                           (* Operating system; choices are:
                                "linux", "solaris", "unix", "macosx",
                                "winNT"   *)
*)


val CC:string       = "cc";       (* C compiler                       *)
val GNUMAKE:string  = "make";     (* for bdd library and SMV          *)
val DEPDIR:string   = ".HOLMK";   (* where Holmake dependencies kept  *)

(*---------------------------------------------------------------------------
          END user-settable parameters
 ---------------------------------------------------------------------------*)

val version_number = 13
val release_string = "Kananaskis"


val _ = Meta.quietdec := true;
app load ["OS", "Substring", "BinIO", "Lexing", "Nonstdio"];


fun check_is_dir role dir =
    (FileSys.isDir dir handle e => false) orelse
    (print "\n*** Bogus directory ("; print dir; print ") given for ";
     print role; print "! ***\n";
     Process.exit Process.failure)

val _ = check_is_dir "mosmldir" mosmldir
val _ = check_is_dir "holdir" holdir
val _ =
    if List.exists (fn s => s = OS)
                   ["linux", "solaris", "unix", "winNT", "macosx"]
    then ()
    else (print ("\n*** Bad OS specified: "^OS^" ***\n");
          Process.exit Process.failure)

fun normPath s = Path.toString(Path.fromString s)
fun itstrings f [] = raise Fail "itstrings: empty list"
  | itstrings f [x] = x
  | itstrings f (h::t) = f h (itstrings f t);

fun fullPath slist = normPath
   (itstrings (fn chunk => fn path => Path.concat (chunk,path)) slist);

fun quote s = String.concat ["\"",String.toString s,"\""]
fun optquote NONE = "NONE"
  | optquote (SOME p) = "SOME " ^ quote p

val holmakedir = fullPath [holdir, "tools", "Holmake"];
val compiler = fullPath [mosmldir, "mosmlc"];

(*---------------------------------------------------------------------------
      File handling. The following implements a very simple line
      replacement function: it searchs the source file for a line that
      contains "redex" and then replaces the whole line by "residue". As it
      searches, it copies lines to the target. Each replacement happens
      once; the replacements occur in order. After the last replacement
      is done, the rest of the source is copied to the target.
 ---------------------------------------------------------------------------*)

fun processLinesUntil (istrm,ostrm) (redex,residue) = let
  open TextIO
  fun loop () =
      case inputLine istrm of
        NONE   => ()
      | SOME line => let
          val ssline = Substring.full line
          val (pref, suff) = Substring.position redex ssline
        in
          if Substring.size suff > 0
          then TextIO.output(ostrm, residue)
          else (TextIO.output(ostrm, line); loop())
        end
in
  loop()
end;

fun fill_holes (src,target) repls =
 let open TextIO
     val istrm = openIn src
     val ostrm = openOut target
  in
     List.app (processLinesUntil (istrm, ostrm)) repls;
     output(ostrm, inputAll istrm);
     closeIn istrm; closeOut ostrm
  end;

infix -->
fun (x --> y) = (x,y);

fun text_copy src dest = fill_holes(src, dest) [];

fun bincopy src dest = let
  val instr = BinIO.openIn src
  val outstr = BinIO.openOut dest
  fun loop () = let
    val v = BinIO.inputN(instr, 1024)
  in
    if Word8Vector.length v = 0 then (BinIO.flushOut outstr;
                                      BinIO.closeOut outstr;
                                      BinIO.closeIn instr)
    else (BinIO.output(outstr, v); loop())
  end
in
  loop()
end;



(*---------------------------------------------------------------------------
     Generate "Systeml" file in tools/Holmake and then load in that file,
     thus defining the Systeml structure for the rest of the configuration
     (with OS-specific stuff available).
 ---------------------------------------------------------------------------*)

exception GetOut;
fun canread s = FileSys.access(s, [FileSys.A_READ])
val sigobj = fullPath [holdir, "sigobj"]
fun to_sigobj s = bincopy s (fullPath [sigobj, s]);

(* default values ensure that later things fail if Systeml doesn't compile *)
fun systeml x = (print "Systeml not correctly loaded.\n";
                 Process.exit Process.failure);
val mk_xable = systeml;
val xable_string = systeml;

val OSkind = if OS="linux" orelse OS="solaris" orelse OS="macosx" then "unix"
             else OS
val _ = let
  (* copy system-specific implementation of Systeml into place *)
  val srcfile = fullPath [holmakedir, OSkind ^"-systeml.sml"]
  val destfile = fullPath [holmakedir, "Systeml.sml"]
  val sigfile = fullPath [holmakedir, "Systeml.sig"]
in
  print "\nLoading system specific functions\n";
  use sigfile;
  fill_holes (srcfile, destfile)
  ["val HOLDIR ="   --> ("val HOLDIR = "^quote holdir^"\n"),
   "val MOSMLDIR =" --> ("val MOSMLDIR = "^quote mosmldir^"\n"),
   "val OS ="       --> ("val OS = "^quote OS^"\n"),
   "val CC ="       --> ("val CC = "^quote CC^"\n"),
   "val DEPDIR ="   --> ("val DEPDIR = "^quote DEPDIR^"\n"),
   "val GNUMAKE ="  --> ("val GNUMAKE = "^quote GNUMAKE^"\n"),
   "val DYNLIB ="   --> ("val DYNLIB = "^Bool.toString dynlib_available^"\n"),
   "val version ="  --> ("val version = "^Int.toString version_number^"\n"),
   "val ML_SYSNAME =" --> "val ML_SYSNAME = \"mosml\"\n",
   "val release ="  --> ("val release = "^quote release_string^"\n"),
   "val DOT_PATH =" --> ("val DOT_PATH = "^optquote DOT_PATH^"\n")
  ];
  use destfile
end;

open Systeml;

(*---------------------------------------------------------------------------
     Now compile Systeml.sml in tools/Holmake/
 ---------------------------------------------------------------------------*)


let
  val _ = print "Compiling system specific functions ("
  val modTime = FileSys.modTime
  val dir_0 = FileSys.getDir()
  val sigfile = fullPath [holmakedir, "Systeml.sig"]
  val uifile = fullPath [holmakedir, "Systeml.ui"]
  val rebuild_sigfile =
      not (canread uifile) orelse
      Time.>(modTime sigfile, modTime uifile) orelse
      (* if the ui in sigobj is too small to be a compiled mosml thing, it
         is probably a Poly/ML thing from a previous installation. If it's
         not there at all, we need to recompile and copy across too. *)
      (FileSys.fileSize (fullPath [sigobj, "Systeml.ui"]) < 100
       handle SysErr _ => true)
  fun die () = (print ")\nFailed to compile system-specific code\n";
                Process.exit Process.failure)
  val systeml = fn l =>
                   if not (Process.isSuccess (systeml l)) then die() else ()
in
  FileSys.chDir holmakedir;
  if rebuild_sigfile then
    (systeml ([compiler, "-c"] @
              ["Systeml.sig"]);
     app to_sigobj ["Systeml.sig", "Systeml.ui"];
     print "sig ") else ();
  systeml ([compiler, "-c"] @
           ["Systeml.sml"]);
  to_sigobj "Systeml.uo";
  print "sml)\n";
  FileSys.chDir dir_0
end;


(*---------------------------------------------------------------------------
          String and path operations.
 ---------------------------------------------------------------------------*)

fun echo s = (TextIO.output(TextIO.stdOut, s^"\n");
              TextIO.flushOut TextIO.stdOut);

val _ = echo "Beginning configuration.";

(* ----------------------------------------------------------------------
    remove the quotation filter from the bin directory, if it exists
  ---------------------------------------------------------------------- *)

val _ = let
  val unquote = fullPath [holdir, "bin", xable_string "unquote"]
in
  if FileSys.access(unquote, [FileSys.A_READ]) then
    (print "Removing old quotation filter from bin/\n";
     FileSys.remove unquote
     handle Interrupt => raise Interrupt
          | _ => print "*** Tried to remove quotation filter from bin/ but \
                       \couldn't!  Proceeding anyway.\n")
  else ()
end

(* ----------------------------------------------------------------------
    Compile our local copy of mllex
   ---------------------------------------------------------------------- *)


fun die s = (print s; print "\n"; Process.exit Process.failure)

val _ = let
  val _ = echo "Making tools/mllex/mllex.exe"
  val cdir = FileSys.getDir()
  val destdir = fullPath [holdir, "tools/mllex"]
  val systeml = fn clist => if Process.isSuccess (systeml clist) then ()
                            else die "Failed to build mllex"
in
  FileSys.chDir destdir;
  systeml ([compiler, "-I", "../../sigobj", "-c", "-toplevel"] @
           ["mllex.sml"]);
  systeml [compiler, "-c", "mllex.ui", "mosmlmain.sml"];
  systeml [compiler, "-I", "../../sigobj", "-o", "mllex.exe", "mllex.uo",
           "mosmlmain.uo"];
  FileSys.chDir cdir
end handle _ => die "Failed to build mllex.";


(*---------------------------------------------------------------------------
    Compile Holmake (bypassing the makefile in directory Holmake), then
    put the executable bin/Holmake.
 ---------------------------------------------------------------------------*)

fun compile opts s =
      Process.isSuccess (systeml ([compiler, "-c"] @ opts @ [s]))

val _ =
 let val _ = echo "Making bin/Holmake."
     val cdir      = FileSys.getDir()
     val hmakedir  = normPath(Path.concat(holdir, "tools/Holmake"))
     val _         = FileSys.chDir hmakedir
     val bin       = fullPath [holdir,   "bin/Holmake"]
     val mllex     = fullPath [holdir, "tools", "mllex", "mllex.exe"]
     val systeml   = fn clist => if not (Process.isSuccess (systeml clist)) then
                                   die "Holmake compilation failed."
                                 else ()
     fun link {extras,srcobj,tgt} = let
       val pfx = if OS <> "winNT" then [compiler, "-standalone", "-o", tgt]
                 else [compiler, "-o", tgt]
     in
       systeml (pfx @ extras @ [srcobj])
     end
  in
    systeml [mllex, "QuoteFilter"];
    compile [] "QuoteFilter.sml";
    compile [] "QFRead.sig";
    compile [] "QFRead.sml";
    compile [] "FunctionalRecordUpdate.sml";
    compile [] "GetOpt.sig";
    compile [] "GetOpt.sml";
    compile [] "HM_Core_Cline.sig";
    compile [] "HM_Core_Cline.sml";
    compile [] "Holdep_tokens.sig";
    compile [] "Holdep_tokens.sml";
    compile [] "holdeptool.sml";
    compile [] "mosml_holdeptool.sml";
    link{extras = [], srcobj = "mosml_holdeptool.uo",
         tgt = fullPath[holdir, "bin", "holdeptool.exe"]};
    compile ["-I", "mosml"] "Holdep.sig";
    compile ["-I", "mosml"] "Holdep.sml";
    compile [] "regexpMatch.sig";
    compile [] "regexpMatch.sml";
    compile [] "parse_glob.sig";
    compile [] "parse_glob.sml";
    compile [] "internal_functions.sig";
    compile [] "internal_functions.sml";
    compile [] "Holmake_tools_dtype.sml";
    compile [] "holpathdb.sig";
    compile [] "holpathdb.sml";
    compile [] "Holmake_tools.sig";
    compile [] "Holmake_tools.sml";
    compile [] "Holmake_types.sig";
    compile [] "Holmake_types.sml";
    compile [] "ReadHMF.sig";
    compile [] "ReadHMF.sml";
    compile [] "HM_DepGraph.sig";
    compile [] "HM_DepGraph.sml";
    compile [] "HM_GraphBuildJ1.sig";
    compile [] "HM_GraphBuildJ1.sml";
    FileSys.chDir "mosml";
    compile ["-I", ".."] "HM_Cline.sig";
    compile ["-I", ".."] "HM_Cline.sml";
    compile ["-I", ".."] "HM_BaseEnv.sig";
    compile ["-I", ".."] "HM_BaseEnv.sml";
    FileSys.chDir "..";
    compile ["-I", "mosml"] "BuildCommand.sig";
    FileSys.chDir "mosml";
    compile ["-I", ".."] "BuildCommand.sml";
    FileSys.chDir "..";
    compile ["-I", "mosml"] "Holmake.sml";
    compile [] "mosml_Holmake.sml";
    link{extras = ["-I", "mosml"], tgt = bin, srcobj = "mosml_Holmake.uo"};
    mk_xable bin;
    FileSys.chDir cdir
  end
handle _ => (print "*** Couldn't build Holmake\n";
             Process.exit Process.failure);

(* ----------------------------------------------------------------------
    Compile our local copy of mlyacc
   ---------------------------------------------------------------------- *)

val _ = let
  val _ = echo "Making tooks/mlyacc/src/mlyacc.exe"
  val cdir = FileSys.getDir()
  val destdir = fullPath [holdir, "tools/mlyacc"]
  val systeml = fn clist => if Process.isSuccess (systeml clist) then ()
                            else die "Failed to build mlyacc"
  val holmake = fullPath [holdir, "bin/Holmake"]
in
  FileSys.chDir destdir;
  FileSys.chDir "mlyacclib";
  systeml [holmake, "cleanAll"];
  systeml [holmake, "all"];
  FileSys.chDir "../src";
  systeml [holmake, "cleanAll"];
  systeml [holmake, "mlyacc.exe"];
  FileSys.chDir cdir
end

(*---------------------------------------------------------------------------
    Compile build.sml, and put it in bin/build.
 ---------------------------------------------------------------------------*)

val _ = let
  open TextIO
  val _ = echo "Making bin/build."
  val cwd = FileSys.getDir()
  val _ = FileSys.chDir (fullPath[holdir, "tools"])
  (* cline stuff *)
  val _ = if compile ["-I", holmakedir] "buildcline_dtype.sml" andalso
             compile ["-I", holmakedir] "buildcline.sig" andalso
             compile ["-I", holmakedir] "buildcline.sml"
          then ()
          else die "Failed to build buildcline module"
  (* utils first *)
  val _ = let
    val utilsig = "buildutils.sig"
    val utilsml = "buildutils.sml"
  in
    if compile ["-I", holmakedir] utilsig andalso
       compile ["-I", holmakedir] utilsml
    then ()
    else die "Failed to build buildutils module"
  end

  val target = "build.sml"
  val bin    = fullPath [holdir, "bin/build"]
  val command =
      [compiler, "-o", bin, "-I", holmakedir,
       "-I", Path.concat(holmakedir, "mosml"),
       target]
in
  if Process.isSuccess (systeml command) then ()
  else (print "*** Failed to build build executable.\n";
        Process.exit Process.failure) ;
  FileSys.remove (fullPath [holdir,"tools/build.ui"]);
  FileSys.remove (fullPath [holdir,"tools/build.uo"]);
  mk_xable bin;
  FileSys.chDir cwd
end;


(*---------------------------------------------------------------------------
    Instantiate tools/hol-mode.src, and put it in tools/hol-mode.el
 ---------------------------------------------------------------------------*)

val _ =
 let open TextIO
     val _ = echo "Making hol-mode.el (for Emacs)"
     val src = fullPath [holdir, "tools/hol-mode.src"]
    val target = fullPath [holdir, "tools/hol-mode.el"]
 in
    fill_holes (src, target)
      ["(defcustom hol-executable HOL-EXECUTABLE\n"
        -->
       ("(defcustom hol-executable \n  "^
        quote (fullPath [holdir, "bin/hol"])^"\n"),
       "(defcustom holmake-executable HOLMAKE-EXECUTABLE\n"
        -->
       ("(defcustom holmake-executable \n  "^
        quote (fullPath [holdir, "bin/Holmake"])^"\n")]
 end;


(*---------------------------------------------------------------------------
      Generate shell scripts for running HOL.
 ---------------------------------------------------------------------------*)

val _ =
 let val _ = echo "Generating bin/hol."
     val target      = fullPath [holdir, "bin/hol.bare"]
     val qend        = fullPath [holdir, "tools/end-init.sml"]
     val target_boss = fullPath [holdir, "bin/hol"]
     val qend_boss   = fullPath [holdir, "tools/end-init-boss.sml"]
 in
   (* "unquote" scripts use the unquote executable to provide nice
      handling of double-backquote characters *)
   emit_hol_unquote_script target qend [];
   emit_hol_unquote_script target_boss qend_boss []
 end;

val _ =
 let val _ = echo "Generating bin/hol.noquote."
     val target      = fullPath [holdir,   "bin/hol.bare.noquote"]
     val target_boss = fullPath [holdir,   "bin/hol.noquote"]
     val qend        = fullPath [holdir,   "tools/end-init.sml"]
     val qend_boss   = fullPath [holdir,   "tools/end-init-boss.sml"]
 in
  emit_hol_script target qend [];
  emit_hol_script target_boss qend_boss []
 end;

(* Remove Poly/HOL executables from bin, if they're there *)
val _ = FileSys.remove (fullPath [holdir, "bin", "heapname"]) handle _ => ()
val _ = FileSys.remove (fullPath [holdir, "bin", "buildheap"]) handle _ => ()


(*---------------------------------------------------------------------------
    Compile the quotation preprocessor used by bin/hol.unquote and
    put it in bin/
 ---------------------------------------------------------------------------*)

val _ = let
  val _ = print "Attempting to compile quote filter ... "
  val tgt0 = fullPath [holdir, "tools/quote-filter/quote-filter"]
  val tgt = fullPath [holdir, "bin/unquote"]
  val cwd = FileSys.getDir()
  val _ = FileSys.chDir (fullPath [holdir, "tools/quote-filter"])
  val _ = systeml [fullPath [holdir, "bin/Holmake"], "cleanAll"]
in
  if Process.isSuccess (systeml [fullPath [holdir, "bin/Holmake"]]) then let
      val instrm = BinIO.openIn tgt0
      val ostrm = BinIO.openOut tgt
      val v = BinIO.inputAll instrm
    in
      BinIO.output(ostrm, v);
      BinIO.closeIn instrm;
      BinIO.closeOut ostrm;
      mk_xable tgt;
      print "Quote-filter built\n"
    end handle e => print "0.Quote-filter build failed (continuing anyway)\n"
  else              print "1.Quote-filter build failed (continuing anyway)\n"
  ;
  FileSys.chDir cwd
end

(*---------------------------------------------------------------------------
    Configure the muddy library.
 ---------------------------------------------------------------------------*)

local val CFLAGS =
        case OS
         of "linux"   => SOME " -Dunix -O3 -fPIC $(CINCLUDE)"
          | "solaris" => SOME " -Dunix -O3 $(CINCLUDE)"
          | "macosx"  => SOME " -Dunix -O3 $(CINCLUDE)"
          |     _     => NONE
      val DLLIBCOMP =
        case OS
         of "linux"   => SOME "ld -shared -o $@ $(COBJS) $(LIBS)"
          | "solaris" => SOME "ld -G -B dynamic -o $@ $(COBJS) $(LIBS)"
          | "macosx"  => SOME "gcc -bundle -flat_namespace -undefined suppress\
                              \ -o $@ $(COBJS) $(LIBS)"
          |    _      => NONE
      val ALL =
        if OS="linux" orelse OS="solaris" orelse OS="macosx"
        then SOME " muddy.so"
        else NONE
in
val _ =
 let open TextIO
     val _ = echo "Setting up the muddy library Makefile."
     val src    = fullPath [holdir, "tools/makefile.muddy.src"]
     val target = fullPath [holdir, "examples/muddy/muddyC/Makefile"]
     val mosmlhome = Path.getParent mosmldir
 in
   case (CFLAGS, DLLIBCOMP, ALL) of
     (SOME s1, SOME s2, SOME s3) => let
       val (cflags, dllibcomp, all) = (s1, s2, s3)
     in
       fill_holes (src,target)
       ["MOSMLHOME=\n"  -->  String.concat["MOSMLHOME=", mosmlhome,"\n"],
        "CC=\n"         -->  String.concat["CC=", CC, "\n"],
        "CFLAGS="       -->  String.concat["CFLAGS=",cflags,"\n"],
        "all:\n"        -->  String.concat["all: ",all,"\n"],
        "DLLIBCOMP"     -->  String.concat["\t", dllibcomp, "\n"]]
     end
   | _ =>  print (String.concat
                  ["   Warning! (non-fatal):\n    The muddy package is not ",
                   "expected to build in OS flavour ", quote OS, ".\n",
                   "   On winNT, muddy will be installed from binaries.\n",
                   "   End Warning.\n"])
 end
end; (* local *)

val _ = print "\nFinished configuration!\n";
